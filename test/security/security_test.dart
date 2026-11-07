import 'package:brunt/security/backoff.dart';
import 'package:brunt/security/key_manager.dart';
import 'package:brunt/security/pin_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVault implements BiometricVault {
  String? stored;
  bool ok = true;
  @override
  Future<bool> available() async => true;
  @override
  Future<void> clear() async => stored = null;
  @override
  Future<String?> load() async => ok ? stored : null;
  @override
  Future<void> save(String value) async => stored = value;
}

void main() {
  KeyManager km() => KeyManager(MemorySecretStore(), FakeVault(), params: KdfParams.test, useIsolate: false);

  test('PIN wraps and unwraps the DB key', () async {
    final m = km();
    final key = await m.setup('123456');
    expect(key.length, 32);
    expect(await m.isSetUp(), isTrue);
    expect(await m.unlockWithPin('123456'), key);
  });

  test('wrong PIN fails', () async {
    final m = km();
    await m.setup('123456');
    expect(await m.unlockWithPin('654321'), isNull);
  });

  test('change PIN keeps the same DB key', () async {
    final m = km();
    final key = await m.setup('111111');
    expect(await m.changePin('111111', '222222'), isTrue);
    expect(await m.unlockWithPin('111111'), isNull);
    expect(await m.unlockWithPin('222222'), key);
  });

  test('biometric unlock returns the key; cancel returns null', () async {
    final vault = FakeVault();
    final m = KeyManager(MemorySecretStore(), vault, params: KdfParams.test, useIsolate: false);
    final key = await m.setup('123456');
    await m.enableBiometric(key);
    expect(await m.unlockWithBiometric(), key);
    vault.ok = false;
    expect(await m.unlockWithBiometric(), isNull);
  });

  test('wipe destroys keys', () async {
    final m = km();
    await m.setup('123456');
    await m.wipeKeys();
    expect(await m.isSetUp(), isFalse);
  });

  test('AES-GCM detects tampering', () async {
    final k = PinCrypto.randomBytes(32);
    final sealed = await PinCrypto.seal([1, 2, 3], k);
    sealed[sealed.length - 1] ^= 1;
    expect(await PinCrypto.open(sealed, k), isNull);
  });

  test('backoff schedule', () {
    expect(PinBackoff.lockoutAfter(4), Duration.zero);
    expect(PinBackoff.lockoutAfter(5), const Duration(seconds: 30));
    expect(PinBackoff.lockoutAfter(6), const Duration(seconds: 60));
    expect(PinBackoff.lockoutAfter(8), const Duration(seconds: 240));
    expect(PinBackoff.lockoutAfter(40), const Duration(hours: 1));
    expect(PinBackoff.shouldWipe(15, 15), isTrue);
    expect(PinBackoff.shouldWipe(14, 15), isFalse);
    expect(PinBackoff.shouldWipe(99, 0), isFalse);
  });

  test('Argon2id derivation is deterministic per salt', () async {
    final salt = PinCrypto.randomBytes(16);
    final a = await PinCrypto.deriveKey('123456', salt, KdfParams.test, isolate: false);
    final b = await PinCrypto.deriveKey('123456', salt, KdfParams.test, isolate: false);
    expect(a, b);
  });
}
