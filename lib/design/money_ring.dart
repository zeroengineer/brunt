import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

class RingSegment {
  const RingSegment(this.value, this.color, [this.label]);
  final int value;
  final Color color;
  final String? label;
}

/// The colour ring from the reference: thick, gapped, rounded segments per tier with
/// a soft glow and the balance in the centre.
class MoneyRing extends StatelessWidget {
  const MoneyRing({super.key, required this.segments, required this.child, this.size = 260, this.thickness = 30});

  final List<RingSegment> segments;
  final Widget child;
  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, t, _) => CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(segments: segments, thickness: thickness, progress: t),
            ),
          ),
        ),
        Padding(padding: EdgeInsets.all(thickness + 18), child: child),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.segments, required this.thickness, required this.progress});

  final List<RingSegment> segments;
  final double thickness;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - thickness / 2;

    // centre glow
    final glowRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          BColors.primary.withValues(alpha: 0.38),
          BColors.primary.withValues(alpha: 0.0),
        ]).createShader(glowRect),
    );

    final visible = segments.where((s) => s.value > 0).toList();
    final total = visible.fold<int>(0, (a, s) => a + s.value);
    final rect = Rect.fromCircle(center: c, radius: r);

    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = thickness
            ..color = BColors.surface);
      return;
    }

    // Rounded caps eat into the gap: cap angle = (thickness/2)/r per end.
    final capAngle = (thickness / 2) / r;
    final gap = visible.length > 1 ? 0.10 + capAngle * 2 : 0.0;
    final available = math.pi * 2 - gap * visible.length;
    var start = -math.pi / 2 - math.pi / 5;
    final minSweep = capAngle * 0.2;
    for (final s in visible) {
      final full = available * s.value / total;
      final sweep = math.max(minSweep, full) * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = visible.length > 1 ? StrokeCap.round : StrokeCap.butt
        ..color = s.color;
      canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      start += full + gap;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.thickness != thickness || !_same(old.segments, segments);

  bool _same(List<RingSegment> a, List<RingSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}
