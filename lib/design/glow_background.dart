import 'package:flutter/material.dart';

import 'tokens.dart';

/// Pure black background with large soft blue glows (spec §11.2).
/// Painted with radial gradients (visually equivalent to a 120px blur, but far cheaper)
/// and isolated in a [RepaintBoundary] so scrolling never re-renders it.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.child, this.centerGlow = false});

  final Widget child;
  final bool centerGlow;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BColors.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: _GlowPainter(centerGlow: centerGlow))),
          child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.centerGlow});
  final bool centerGlow;

  void _glow(Canvas canvas, Offset c, double radius, double opacity) {
    final rect = Rect.fromCircle(center: c, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          BColors.primary.withValues(alpha: opacity),
          BColors.primary.withValues(alpha: opacity * 0.45),
          BColors.primary.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(rect);
    canvas.drawCircle(c, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // top-right ~420px, bottom-left ~380px (+ blur spread)
    _glow(canvas, Offset(size.width + 40, -30), 330, 0.42);
    _glow(canvas, Offset(-60, size.height + 10), 300, 0.36);
    if (centerGlow) _glow(canvas, Offset(size.width / 2, size.height * 0.38), 220, 0.30);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.centerGlow != centerGlow;
}

/// Standard screen frame: glow + safe area + transparent scaffold.
class BruntScaffold extends StatelessWidget {
  const BruntScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottom,
    this.centerGlow = false,
    this.showBack = false,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottom;
  final bool centerGlow;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return GlowBackground(
      centerGlow: centerGlow,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottom,
        appBar: title == null && !showBack && actions == null
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: showBack,
                leading: leading,
                titleSpacing: showBack ? 0 : BSpace.gutter,
                title: title == null ? null : Text(title!, style: BText.h2),
                actions: [...?actions, const SizedBox(width: 8)],
              ),
        body: SafeArea(top: title == null && !showBack && actions == null, bottom: false, child: body),
      ),
    );
  }
}
