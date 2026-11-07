import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Colour tokens, taken from design-reference.png (spec §11.1).
abstract final class BColors {
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF15191D);
  static const surfaceRaised = Color(0xFF1E2328);
  static const primary = Color(0xFF1B539A);
  static const primaryLight = Color(0xFF7AAEEE);
  static const primarySoft = Color(0xFFC6DFFF);
  static const text = Color(0xFFF5F5F5);
  static const textMuted = Color(0xFF8A929C);
  static const border = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const borderStrong = Color(0x24FFFFFF);
  static const success = Color(0xFF4CC38A);
  static const warning = Color(0xFFF2B84B);
  static const danger = Color(0xFFF06A6A);
  static const disabled = Color(0xFF5C646E);

  static const tierPriority = Color(0xFF1B539A);
  static const tierSavings = Color(0xFF7AAEEE);
  static const tierFixed = Color(0xFFC6DFFF);
  static const tierDaily = Color(0xFFF5F5F5);
  static const tierVariable = Color(0xFF3A4048);

  static Color tier(Tier t) => switch (t) {
        Tier.income => success,
        Tier.priority => tierPriority,
        Tier.savings => tierSavings,
        Tier.fixed => tierFixed,
        Tier.daily => tierDaily,
        Tier.variable => tierVariable,
      };

  /// Palette offered when users pick a colour for an account or category.
  static const palette = <Color>[
    Color(0xFF1B539A), Color(0xFF7AAEEE), Color(0xFFC6DFFF), Color(0xFF4CC38A),
    Color(0xFFF2B84B), Color(0xFFF06A6A), Color(0xFFB48CF2), Color(0xFF5BC8D8),
    Color(0xFFF59ECB), Color(0xFFF5F5F5), Color(0xFF8A929C), Color(0xFF3A4048),
  ];

  static String hex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  static Color fromHex(String? h, {Color fallback = primaryLight}) {
    if (h == null || h.isEmpty) return fallback;
    final v = int.tryParse(h.replaceFirst('#', ''), radix: 16);
    if (v == null) return fallback;
    return Color(0xFF000000 | v);
  }

  /// Readable foreground for a fill colour.
  static Color onColor(Color c) => c.computeLuminance() > 0.45 ? const Color(0xFF0B1A2E) : text;
}

abstract final class BSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const gutter = 16.0;
}

abstract final class BRadius {
  static const card = 24.0;
  static const sheet = 28.0;
  static const field = 16.0;
  static const pill = 999.0;
}

/// Typography — Manrope (bundled). Amounts use tabular figures.
abstract final class BText {
  static const family = 'Manrope';
  static const _tab = [FontFeature.tabularFigures()];

  static const display = TextStyle(
      fontFamily: family, fontSize: 44, fontWeight: FontWeight.w800, color: BColors.text, height: 1.1, letterSpacing: -1, fontFeatures: _tab);
  static const h1 = TextStyle(fontFamily: family, fontSize: 28, fontWeight: FontWeight.w700, color: BColors.text, height: 1.2, letterSpacing: -0.4);
  static const h2 = TextStyle(fontFamily: family, fontSize: 20, fontWeight: FontWeight.w600, color: BColors.text, height: 1.25);
  static const body = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w500, color: BColors.text, height: 1.35);
  static const bodyMuted = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w500, color: BColors.textMuted, height: 1.35);
  static const caption = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500, color: BColors.textMuted, height: 1.3);
  static const label = TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w600, color: BColors.text, height: 1.2);

  /// Amount style: tabular figures always.
  static TextStyle amount({double size = 15, FontWeight weight = FontWeight.w700, Color color = BColors.text}) =>
      TextStyle(fontFamily: family, fontSize: size, fontWeight: weight, color: color, fontFeatures: _tab, height: 1.2);
}
