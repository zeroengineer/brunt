import 'dart:io';

import 'package:flutter/services.dart';

/// FLAG_SECURE on Android: blocks screenshots / screen recording and blanks the
/// app-switcher preview. It is set natively in MainActivity before the first frame;
/// this only lets Settings turn it off and back on.
abstract final class ScreenGuard {
  static const _channel = MethodChannel('brunt/platform');

  static Future<void> enable() => _set(true);
  static Future<void> disable() => _set(false);

  static Future<void> _set(bool on) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('setSecure', on);
    } catch (_) {}
  }
}
