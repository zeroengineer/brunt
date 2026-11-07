import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/dart.dart';

import 'pin_crypto.dart';

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Encrypted backup file (spec §4.8, §9.3):
///
/// ```
/// magic "BRUNTBK1" (8) | format u16 | kdf memKiB u32 | kdf iters u16 | kdf par u16 |
/// salt (16) | sha256(gzip payload) (32) | AES-256-GCM(nonce 12 | ciphertext | mac 16)
/// ```
/// The header is bound to the ciphertext as AAD, so any tampering fails authentication.
/// Key = Argon2id(password, salt). Payload = gzip(JSON of every table).
abstract final class BackupCrypto {
  static const magic = 'BRUNTBK1';
  static const format = 1;
  static const _headerLen = 8 + 2 + 4 + 2 + 2 + 16 + 32;

  static Future<Uint8List> encrypt(Map<String, Object?> payload, String password, {KdfParams params = const KdfParams()}) {
    final json = jsonEncode(payload);
    return Isolate.run(() => _encrypt(json, password, params));
  }

  static Future<Map<String, Object?>> decrypt(Uint8List file, String password) async {
    final json = await Isolate.run(() => _decrypt(file, password));
    final v = jsonDecode(json);
    if (v is! Map<String, Object?>) throw const BackupException('Backup content is not valid');
    return v;
  }

  /// Non-isolate variants (tests).
  static Future<Uint8List> encryptSync(Map<String, Object?> payload, String password, {KdfParams params = const KdfParams()}) =>
      _encrypt(jsonEncode(payload), password, params);
  static Future<Map<String, Object?>> decryptSync(Uint8List file, String password) async =>
      jsonDecode(await _decrypt(file, password)) as Map<String, Object?>;

  static Future<Uint8List> _encrypt(String json, String password, KdfParams p) async {
    final compressed = gzip.encode(utf8.encode(json));
    final digest = (await const DartSha256().hash(compressed)).bytes;
    final salt = PinCrypto.randomBytes(16);
    final header = BytesBuilder()
      ..add(ascii.encode(magic))
      ..add(_u16(format))
      ..add(_u32(p.memoryKiB))
      ..add(_u16(p.iterations))
      ..add(_u16(p.parallelism))
      ..add(salt)
      ..add(digest);
    final h = header.toBytes();
    final key = await PinCrypto.deriveKey(password, salt, p, isolate: false);
    final sealed = await PinCrypto.seal(compressed, key, aad: h);
    return (BytesBuilder()
          ..add(h)
          ..add(sealed))
        .toBytes();
  }

  static Future<String> _decrypt(Uint8List file, String password) async {
    if (file.length < _headerLen + 28 || ascii.decode(file.sublist(0, 8), allowInvalid: true) != magic) {
      throw const BackupException('This is not a BRUNT backup file');
    }
    final bd = ByteData.sublistView(file);
    final fmt = bd.getUint16(8);
    if (fmt > format) throw const BackupException('Backup was made by a newer version of BRUNT');
    final p = KdfParams(memoryKiB: bd.getUint32(10), iterations: bd.getUint16(14), parallelism: bd.getUint16(16));
    if (p.memoryKiB > 1 << 20 || p.iterations > 64 || p.parallelism > 16) throw const BackupException('Backup header is invalid');
    final salt = file.sublist(18, 34);
    final digest = file.sublist(34, 66);
    final header = file.sublist(0, _headerLen);
    final key = await PinCrypto.deriveKey(password, salt, p, isolate: false);
    final compressed = await PinCrypto.open(file.sublist(_headerLen), key, aad: header);
    if (compressed == null) throw const BackupException('Wrong password, or the file is damaged');
    final check = (await const DartSha256().hash(compressed)).bytes;
    if (!_eq(check, digest)) throw const BackupException('Checksum mismatch — the file is damaged');
    return utf8.decode(gzip.decode(compressed));
  }

  static bool _eq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var d = 0;
    for (var i = 0; i < a.length; i++) {
      d |= a[i] ^ b[i];
    }
    return d == 0;
  }

  static Uint8List _u16(int v) => (ByteData(2)..setUint16(0, v)).buffer.asUint8List();
  static Uint8List _u32(int v) => (ByteData(4)..setUint32(0, v)).buffer.asUint8List();
}
