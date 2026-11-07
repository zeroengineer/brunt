import 'package:drift/drift.dart';

import '../db/database.dart';

/// Turns the whole database into a JSON-able map and back (used by encrypted backups).
class BackupRepo {
  BackupRepo(this.db);
  final AppDatabase db;

  /// Parents before children (insert order); reversed for deletes.
  static const tables = [
    'accounts',
    'months',
    'categories',
    'templates',
    'account_month_balances',
    'planned_items',
    'transactions',
    'daily_logs',
    'month_summary',
    'stats_cache',
    'settings',
  ];

  Future<Map<String, Object?>> export() async {
    final out = <String, Object?>{};
    for (final t in tables) {
      final rows = await db.customSelect('SELECT * FROM $t').get();
      out[t] = [for (final r in rows) r.data];
    }
    return {
      'app': 'brunt',
      'schema': db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': out,
    };
  }

  /// Replaces all data with the backup, atomically.
  Future<void> restore(Map<String, Object?> backup) async {
    if (backup['app'] != 'brunt') throw ArgumentError('Not a BRUNT backup');
    final schema = backup['schema'];
    if (schema is! int || schema > db.schemaVersion) throw ArgumentError('Backup is from a newer schema');
    final data = backup['tables'];
    if (data is! Map<String, Object?>) throw ArgumentError('Backup has no tables');

    await db.customStatement('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction(() async {
        for (final t in tables.reversed) {
          await db.customStatement('DELETE FROM $t');
        }
        for (final t in tables) {
          final rows = data[t];
          if (rows is! List) continue;
          for (final r in rows) {
            if (r is! Map<String, Object?> || r.isEmpty) continue;
            final cols = r.keys.toList();
            for (final c in cols) {
              if (!RegExp(r'^[a-z_]+$').hasMatch(c)) throw ArgumentError('Bad column name');
            }
            await db.customInsert(
              'INSERT INTO $t (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
              variables: [for (final c in cols) _v(r[c])],
            );
          }
        }
        final fk = await db.customSelect('PRAGMA foreign_key_check').get();
        if (fk.isNotEmpty) throw StateError('Backup has broken references');
      });
    } finally {
      await db.customStatement('PRAGMA foreign_keys = ON');
    }
    await db.customUpdate('UPDATE months SET version = version + 1', updates: db.allTables.toSet());
  }

  static Variable<Object> _v(Object? v) => switch (v) {
        null => const Variable(null),
        final int i => Variable.withInt(i),
        final double d => Variable.withReal(d),
        final bool b => Variable.withBool(b),
        final String s => Variable.withString(s),
        _ => Variable.withString(v.toString()),
      };
}
