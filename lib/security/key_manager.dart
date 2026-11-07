import 'dart:convert';
import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pin_crypto.dart';

/// Small key/value secret store (Keychain / Keystore-backed in the app, in-memory in tests).
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class PlatformSecretStore implements SecretStore {
  static const _s = FlutterSecureStorage(
    // Never auto-reset: that would destroy the wrapped DB key.
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device, synchronizable: false),
  );

  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
  @override
  Future<void> deleteAll() => _s.deleteAll();
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
  @override
  Future<void> deleteAll() async => data.clear();
}

/// Biometric-gated storage for the DB key (Android Keystore / iOS Secure Enclave).
abstract class BiometricVault {
  Future<bool> available();
  Future<void> save(String value);

  /// Prompts for biometrics. Returns null when cancelled or failed.
  Future<String?> load();
  Future<void> clear();
}

class PlatformBiometricVault implements BiometricVault {
  static const _name = 'brunt_db_key';
  static const _prompt = PromptInfo(
    androidPromptInfo: AndroidPromptInfo(title: 'Unlock BRUNT', negativeButton: 'Use PIN', confirmationRequired: false),
    iosPromptInfo: IosPromptInfo(accessTitle: 'Unlock BRUNT', saveTitle: 'Enable biometric unlock'),
  );

  Future<BiometricStorageFile> _file() => BiometricStorage().getStorage(
        _name,
        options: StorageFileInitOptions(authenticationRequired: true, androidBiometricOnly: true, darwinBiometricOnly: true),
        promptInfo: _prompt,
      );

  @override
  Future<bool> available() async {
    try {
      return await BiometricStorage().canAuthenticate() == CanAuthenticateResponse.success;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> save(String value) async => (await _file()).write(value);

  @override
  Future<String?> load() async {
    try {
      return await (await _file()).read();
    } on AuthException {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await (await _file()).delete();
    } catch (_) {}
  }
}

/// Manages the random 256-bit database key (spec §9.2). The key is stored only wrapped:
///  • by a key derived from the 6-digit PIN with Argon2id, and
///  • optionally inside biometric-gated platform storage.
class KeyManager {
  KeyManager(this.store, this.vault, {this.params = KdfParams.pin, this.useIsolate = true});

  final SecretStore store;
  final BiometricVault vault;
  final KdfParams params;
  final bool useIsolate;

  static const kSalt = 'pin_salt';
  static const kWrapped = 'pin_wrapped';
  static const kParams = 'kdf_params';
  static const kBio = 'bio_enabled';
  static const kFailures = 'pin_failures';
  static const kLockedUntil = 'pin_locked_until';
  static const kWipeAfter = 'wipe_after';
  static const _aad = 'brunt-db-key-v1';

  Future<bool> isSetUp() async => await store.read(kWrapped) != null;

  /// First launch: generates the DB key and wraps it with the PIN.
  Future<Uint8List> setup(String pin) async {
    final key = PinCrypto.randomBytes(32);
    await _wrapWithPin(key, pin);
    return key;
  }

  Future<void> _wrapWithPin(List<int> key, String pin) async {
    final salt = PinCrypto.randomBytes(16);
    final kek = await PinCrypto.deriveKey(pin, salt, params, isolate: useIsolate);
    final wrapped = await PinCrypto.seal(key, kek, aad: utf8.encode(_aad));
    await store.write(kSalt, base64Encode(salt));
    await store.write(kParams, params.encode());
    await store.write(kWrapped, base64Encode(wrapped));
  }

  /// Returns the DB key, or null for a wrong PIN.
  Future<Uint8List?> unlockWithPin(String pin) async {
    final salt = await store.read(kSalt);
    final wrapped = await store.read(kWrapped);
    if (salt == null || wrapped == null) return null;
    final p = KdfParams.decode(await store.read(kParams));
    final kek = await PinCrypto.deriveKey(pin, base64Decode(salt), p, isolate: useIsolate);
    return PinCrypto.open(base64Decode(wrapped), kek, aad: utf8.encode(_aad));
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    final key = await unlockWithPin(oldPin);
    if (key == null) return false;
    await _wrapWithPin(key, newPin);
    return true;
  }

  Future<bool> biometricAvailable() => vault.available();
  Future<bool> biometricEnabled() async => await store.read(kBio) == '1';

  Future<bool> enableBiometric(List<int> key) async {
    if (!await vault.available()) return false;
    await vault.save(base64Encode(key));
    await store.write(kBio, '1');
    return true;
  }

  Future<void> disableBiometric() async {
    await vault.clear();
    await store.write(kBio, '0');
  }

  Future<Uint8List?> unlockWithBiometric() async {
    if (!await biometricEnabled()) return null;
    final v = await vault.load();
    if (v == null) return null;
    try {
      final k = base64Decode(v);
      return k.length == 32 ? k : null;
    } catch (_) {
      return null;
    }
  }

  // ----- attempt tracking (kept outside the DB: the DB is locked when it matters)

  Future<int> failures() async => int.tryParse(await store.read(kFailures) ?? '') ?? 0;
  Future<void> setFailures(int n) => store.write(kFailures, '$n');

  Future<DateTime?> lockedUntil() async {
    final v = await store.read(kLockedUntil);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> setLockedUntil(DateTime? t) =>
      t == null ? store.delete(kLockedUntil) : store.write(kLockedUntil, t.toIso8601String());

  Future<int> wipeAfter() async => int.tryParse(await store.read(kWipeAfter) ?? '') ?? 0;
  Future<void> setWipeAfter(int n) => store.write(kWipeAfter, '$n');

  /// Destroys every key. The encrypted DB becomes permanently unreadable.
  Future<void> wipeKeys() async {
    await vault.clear();
    await store.deleteAll();
  }
}
