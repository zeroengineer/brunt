import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/session.dart';
import '../core/constants.dart';
import '../data/db/connection.dart';
import 'backoff.dart';
import 'key_manager.dart';
import '../features/dashboard/ring_widget_bridge.dart';

enum LockPhase { booting, needsSetup, locked, unlocked }

@immutable
class LockState {
  const LockState({
    required this.phase,
    this.session,
    this.onboarded = false,
    this.error,
    this.lockedUntil,
    this.failures = 0,
    this.busy = false,
    this.biometricEnabled = false,
  });

  final LockPhase phase;
  final Session? session;
  final bool onboarded;
  final String? error;
  final DateTime? lockedUntil;
  final int failures;
  final bool busy;
  final bool biometricEnabled;

  LockState copyWith({
    LockPhase? phase,
    Session? session,
    bool clearSession = false,
    bool? onboarded,
    String? error,
    bool clearError = false,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
    int? failures,
    bool? busy,
    bool? biometricEnabled,
  }) =>
      LockState(
        phase: phase ?? this.phase,
        session: clearSession ? null : (session ?? this.session),
        onboarded: onboarded ?? this.onboarded,
        error: clearError ? null : (error ?? this.error),
        lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
        failures: failures ?? this.failures,
        busy: busy ?? this.busy,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      );
}

final keyManagerProvider = Provider<KeyManager>((ref) => KeyManager(PlatformSecretStore(), PlatformBiometricVault()));

final lockProvider = NotifierProvider<LockController, LockState>(LockController.new);

/// Owns the unlock flow, the in-memory DB key and auto-lock (spec §9).
class LockController extends Notifier<LockState> {
  Uint8List? _key;
  int _suppress = 0;
  DateTime? _backgroundedAt;
  Duration autoLockAfter = Duration.zero;

  KeyManager get _km => ref.read(keyManagerProvider);

  @override
  LockState build() {
    Future.microtask(_init);
    return const LockState(phase: LockPhase.booting);
  }

  Future<void> _init() async {
    if (!await _km.isSetUp()) {
      // Keys are gone (fresh install or wiped) — any DB file left behind is unreadable junk.
      if (await DbConnection.exists()) await DbConnection.deleteFiles();
      state = const LockState(phase: LockPhase.needsSetup);
      return;
    }
    state = LockState(
      phase: LockPhase.locked,
      failures: await _km.failures(),
      lockedUntil: await _km.lockedUntil(),
      biometricEnabled: await _km.biometricEnabled(),
    );
  }

  /// Onboarding: creates the PIN-wrapped key and a fresh encrypted database.
  Future<void> createPin(String pin) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      if (await DbConnection.exists()) await DbConnection.deleteFiles();
      final key = await _km.setup(pin);
      await _open(key);
    } catch (e) {
      state = state.copyWith(busy: false, error: 'Could not set up secure storage: $e');
    }
  }

  Future<bool> biometricAvailable() => _km.biometricAvailable();

  /// Stores the DB key behind biometrics (needs the in-memory key: only while unlocked).
  Future<bool> enableBiometric() async {
    final key = _key;
    if (key == null) return false;
    return suppressWhile(() async {
      try {
        final ok = await _km.enableBiometric(key);
        state = state.copyWith(biometricEnabled: ok);
        return ok;
      } catch (_) {
        return false;
      }
    });
  }

  Future<void> disableBiometric() async {
    await _km.disableBiometric();
    state = state.copyWith(biometricEnabled: false);
  }

  Future<bool> changePin(String oldPin, String newPin) => _km.changePin(oldPin, newPin);

  /// Verifies a PIN without changing lock state (re-auth for sensitive actions).
  Future<bool> verifyPin(String pin) async => await _km.unlockWithPin(pin) != null;

  Future<void> unlockWithPin(String pin) async {
    final until = state.lockedUntil;
    if (until != null && until.isAfter(DateTime.now())) return;
    state = state.copyWith(busy: true, clearError: true);
    final key = await _km.unlockWithPin(pin);
    if (key == null) {
      final failures = state.failures + 1;
      await _km.setFailures(failures);
      final wipeAfter = await _km.wipeAfter();
      if (PinBackoff.shouldWipe(failures, wipeAfter)) {
        await wipeEverything();
        return;
      }
      final lockout = PinBackoff.lockoutAfter(failures);
      final lockedUntil = lockout == Duration.zero ? null : DateTime.now().add(lockout);
      await _km.setLockedUntil(lockedUntil);
      final left = wipeAfter > 0 ? ' · ${wipeAfter - failures} tries before wipe' : '';
      state = state.copyWith(
        busy: false,
        failures: failures,
        lockedUntil: lockedUntil,
        clearLockedUntil: lockedUntil == null,
        error: 'Wrong PIN$left',
      );
      return;
    }
    await _km.setFailures(0);
    await _km.setLockedUntil(null);
    await _open(key);
  }

  Future<void> unlockWithBiometric() async {
    if (state.phase != LockPhase.locked || state.busy) return;
    state = state.copyWith(busy: true, clearError: true);
    final key = await suppressWhile(_km.unlockWithBiometric);
    if (key == null) {
      state = state.copyWith(busy: false);
      return;
    }
    await _km.setFailures(0);
    await _km.setLockedUntil(null);
    await _open(key);
  }

  Future<void> _open(Uint8List key) async {
    try {
      final db = await DbConnection.open(key);
      final session = Session(db);
      final onboarded = await session.isOnboarded();
      if (onboarded) await session.onOpen();
      await _loadAutoLock(session);
      _key = key;
      state = state.copyWith(
        phase: LockPhase.unlocked,
        session: session,
        onboarded: onboarded,
        busy: false,
        failures: 0,
        clearLockedUntil: true,
        clearError: true,
        biometricEnabled: await _km.biometricEnabled(),
      );
    } on WrongKeyException {
      state = state.copyWith(busy: false, error: 'Database key rejected');
    } catch (e) {
      state = state.copyWith(busy: false, error: 'Could not open your data: $e');
    }
  }

  Future<void> _loadAutoLock(Session s) async {
    final v = await s.settings.get(SettingKeys.autoLock) ?? 'immediate';
    autoLockAfter = switch (v) {
      '1m' => const Duration(minutes: 1),
      '5m' => const Duration(minutes: 5),
      _ => Duration.zero,
    };
  }

  Future<void> reloadAutoLock() async {
    final s = state.session;
    if (s != null) await _loadAutoLock(s);
  }

  void markOnboarded() => state = state.copyWith(onboarded: true);

  /// Closes the DB and drops the key from memory.
  Future<void> lock() async {
    final s = state.session;
    if (state.phase != LockPhase.unlocked) return;
    _key = null;
    state = LockState(
      phase: LockPhase.locked,
      biometricEnabled: await _km.biometricEnabled(),
    );
    // let the UI leave data screens before the connection goes away
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await s?.close();
  }

  /// Destroys keys and data (optional "wipe after N attempts", or reset from settings).
  Future<void> wipeEverything() async {
    final s = state.session;
    _key = null;
    state = const LockState(phase: LockPhase.needsSetup);
    await s?.close();
    await _km.wipeKeys();
    await DbConnection.deleteFiles();
    await RingWidgetBridge.clear();
  }

  /// Wrap system UI (biometric prompt, file picker, share sheet) so leaving the app for it
  /// doesn't trigger auto-lock.
  Future<T> suppressWhile<T>(Future<T> Function() action) async {
    _suppress++;
    try {
      return await action();
    } finally {
      // the resume event arrives slightly after the future completes
      Timer(const Duration(milliseconds: 800), () => _suppress--);
    }
  }

  void onBackground() {
    if (_suppress > 0 || state.phase != LockPhase.unlocked) return;
    _backgroundedAt = DateTime.now();
    if (autoLockAfter == Duration.zero) unawaited(lock());
  }

  void onForeground() {
    final at = _backgroundedAt;
    _backgroundedAt = null;
    if (state.phase == LockPhase.unlocked) {
      if (_suppress == 0 && at != null && DateTime.now().difference(at) >= autoLockAfter) {
        unawaited(lock());
      } else {
        unawaited(state.session?.onOpen());
      }
    }
  }
}
