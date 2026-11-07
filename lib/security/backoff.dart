/// PIN brute-force policy (spec §9.3): 5 wrong attempts → 30 s, then exponential backoff.
abstract final class PinBackoff {
  static const freeAttempts = 5;
  static const base = Duration(seconds: 30);
  static const cap = Duration(hours: 1);

  /// Lockout after the [failures]-th consecutive wrong PIN.
  static Duration lockoutAfter(int failures) {
    if (failures < freeAttempts) return Duration.zero;
    final exp = failures - freeAttempts; // 0 → 30s, 1 → 60s, 2 → 120s …
    final secs = base.inSeconds * (1 << (exp > 16 ? 16 : exp));
    return secs > cap.inSeconds ? cap : Duration(seconds: secs);
  }

  /// Whether the optional "wipe after N attempts" should fire.
  static bool shouldWipe(int failures, int wipeAfter) => wipeAfter > 0 && failures >= wipeAfter;
}
