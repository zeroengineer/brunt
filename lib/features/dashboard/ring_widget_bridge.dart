import 'dart:io';

import 'package:flutter/services.dart';

import 'dashboard_data.dart';

/// Feeds the Android home-screen widget. Only each ring part's share (per mille) and colour
/// are sent — never an amount — so the widget can sit on the home screen while the app is locked.
abstract final class RingWidgetBridge {
  static const _channel = MethodChannel('brunt/platform');
  static String? _last;

  static Future<void> update(List<RingPart> parts) => _send(encode(parts));

  /// "share:argb,…" with shares in per mille of the ring — no amounts.
  static String encode(List<RingPart> parts) {
    final total = parts.fold<int>(0, (s, p) => s + (p.planned > 0 ? p.planned : 0));
    if (total <= 0) return '';
    return [
      for (final p in parts)
        if (p.planned > 0) '${(p.planned * 1000 / total).round().clamp(1, 1000)}:${p.color.toARGB32()}',
    ].join(',');
  }

  /// Empties the widget (used when everything is erased).
  static Future<void> clear() => _send('');

  static Future<void> _send(String encoded) async {
    if (!Platform.isAndroid || encoded == _last) return;
    try {
      await _channel.invokeMethod<bool>('updateWidget', encoded);
      _last = encoded;
    } catch (_) {
      // No widget host (tests, old builds): nothing to do.
    }
  }
}
