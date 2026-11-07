import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Argon2id parameters, persisted next to the wrapped key so they can be raised later.
class KdfParams {
  const KdfParams({this.memoryKiB = 19456, this.iterations = 2, this.parallelism = 1});

  /// PIN wrapping. Argon2id runs in pure Dart, so on a budget 32-bit phone the
  /// OWASP 19 MiB setting costs ~3 s per unlock. The PIN key is only one of two
  /// layers (the other is hardware-backed biometric storage) and PIN guesses are
  /// rate-limited with optional wipe, so 8 MiB keeps unlock around a second.
  static const pin = KdfParams(memoryKiB: 8192, iterations: 2, parallelism: 1);

  /// Fast parameters for unit tests only.
  static const test = KdfParams(memoryKiB: 64, iterations: 1, parallelism: 1);

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  String encode() => '$memoryKiB,$iterations,$parallelism';
  static KdfParams decode(String? s) {
    if (s == null) return const KdfParams();
    final p = s.split(',').map(int.parse).toList();
    return KdfParams(memoryKiB: p[0], iterations: p[1], parallelism: p[2]);
  }
}

/// PIN / password key derivation (Argon2id) and AES-256-GCM key wrapping. Pure Dart.
abstract final class PinCrypto {
  static final _rng = Random.secure();
  static final _aes = AesGcm.with256bits();

  static Uint8List randomBytes(int n) => Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));

  /// Derives a 256-bit key from [secret] with Argon2id. Runs in a background isolate so the UI
  /// never stutters.
  static Future<Uint8List> deriveKey(String secret, List<int> salt, KdfParams p, {bool isolate = true}) async {
    final s = secret;
    final sl = List<int>.from(salt);
    final pp = p;
    Future<Uint8List> run() async {
      // Pure-Dart implementation explicitly — safe inside an isolate.
      final kdf = DartArgon2id(parallelism: pp.parallelism, memory: pp.memoryKiB, iterations: pp.iterations, hashLength: 32);
      final k = await kdf.deriveKey(secretKey: SecretKey(utf8.encode(s)), nonce: sl);
      return Uint8List.fromList(await k.extractBytes());
    }

    return isolate ? Isolate.run(run) : run();
  }

  /// AES-256-GCM: returns nonce(12) | ciphertext | mac(16).
  static Future<Uint8List> seal(List<int> plain, List<int> key, {List<int> aad = const []}) async {
    final box = await _aes.encrypt(plain, secretKey: SecretKey(key), nonce: randomBytes(12), aad: aad);
    return box.concatenation();
  }

  /// Returns null when the key is wrong or the data was tampered with.
  static Future<Uint8List?> open(List<int> sealed, List<int> key, {List<int> aad = const []}) async {
    try {
      final box = SecretBox.fromConcatenation(sealed, nonceLength: 12, macLength: 16, copy: true);
      return Uint8List.fromList(await _aes.decrypt(box, secretKey: SecretKey(key), aad: aad));
    } on SecretBoxAuthenticationError {
      return null;
    } catch (_) {
      return null;
    }
  }

  static String hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
