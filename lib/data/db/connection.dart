import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../security/pin_crypto.dart';
import 'database.dart';

class WrongKeyException implements Exception {
  @override
  String toString() => 'Database key rejected';
}

/// Opens the SQLCipher (AES-256) database with the unwrapped key. The key is passed as a raw
/// hex key so it is never derived again per query, and never written to disk in plain form.
abstract final class DbConnection {
  static const fileName = 'brunt.db';

  static Future<File> dbFile() async {
    final dir = await getApplicationSupportDirectory();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File(p.join(dir.path, fileName));
  }

  static Future<bool> exists() async => (await dbFile()).existsSync();

  static Future<AppDatabase> open(Uint8List key) async {
    final file = await dbFile();
    final hexKey = PinCrypto.hex(key);
    final executor = NativeDatabase.createInBackground(
      file,
      readPool: 0,
      setup: (raw) {
        raw.execute("PRAGMA key = \"x'$hexKey'\";");
        final v = raw.select('PRAGMA cipher_version;');
        if (v.isEmpty) throw StateError('SQLCipher is not available — refusing to open an unencrypted database');
        raw.execute('PRAGMA cipher_memory_security = ON;');
        raw.execute('PRAGMA journal_mode = WAL;');
        raw.execute('PRAGMA foreign_keys = ON;');
      },
    );
    final db = AppDatabase(executor);
    try {
      await db.customSelect('SELECT count(*) AS n FROM sqlite_master').getSingle();
    } catch (e) {
      await db.close();
      if (e.toString().contains('not a database')) throw WrongKeyException();
      rethrow;
    }
    return db;
  }

  /// Deletes the database and its WAL/SHM files.
  static Future<void> deleteFiles() async {
    final f = await dbFile();
    for (final path in [f.path, '${f.path}-wal', '${f.path}-shm', '${f.path}-journal']) {
      final x = File(path);
      if (x.existsSync()) x.deleteSync();
    }
  }
}

