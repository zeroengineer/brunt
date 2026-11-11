import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

class RingSegment {
  const RingSegment(this.value, this.color, [this.label]);
  final int value;
  final Color color;
  final String? label;
}

/// Geometry shared by the dashboard ring and the app mark: segments share one full circle,
/// split by equal gaps that stay the same visible width once the round caps are drawn.
class RingLayout {
  RingLayout._(this.starts, this.sweeps);

  /// Start angle and sweep (radians) of each *visible* arc, in input order. Zero-value
  /// segments get a null entry so indices line up with the input list.
  final List<double?> starts;
  final List<double?> sweeps;

  static const top = -math.pi / 2;

  /// [gap] is the visible gap between two arcs, in radians, measured edge to edge.
  factory RingLayout.of(List<int> values, {required double radius, required double thickness, double gap = 0.05}) {
    final total = values.where((v) => v > 0).fold<int>(0, (a, v) => a + v);
    final n = values.where((v) => v > 0).length;
    final starts = List<double?>.filled(values.length, null);
    final sweeps = List<double?>.filled(values.length, null);
    if (total <= 0) return RingLayout._(starts, sweeps);
    if (n == 1) {
      final i = values.indexWhere((v) => v > 0);
      starts[i] = top;
      sweeps[i] = math.pi * 2;
      return RingLayout._(starts, sweeps);
    }
    // A round cap adds thickness/2 of arc length at each end of a stroke.
    final cap = (thickness / 2) / radius;
    final slot = gap + cap * 2; // angle consumed between two drawn arcs
    final available = math.pi * 2 - slot * n;
    // Every arc gets at least a dot's worth so tiny tiers stay visible.
    const minSweep = 0.02;
    var start = top + slot / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final share = math.max(minSweep, available * values[i] / total);
      starts[i] = start;
      sweeps[i] = share;
      start += share + slot;
    }
    // Normalise so the arcs and gaps add up to exactly one full turn.
    final used = start - top - slot / 2;
    final k = (math.pi * 2) / used;
    var s = top + slot / 2;
    for (var i = 0; i < values.length; i++) {
      if (sweeps[i] == null) continue;
      final sw = sweeps[i]!;
      starts[i] = s;
      sweeps[i] = (sw + slot) * k - slot;
      s += (sw + slot) * k;
    }
    return RingLayout._(starts, sweeps);
  }

  /// Which arc (index in the input list) contains [angle] (radians, any range), counting
  /// half of each neighbouring gap so taps between arcs still land on one.
  int? hit(double angle) {
    int? best;
    var bestDist = double.infinity;
    for (var i = 0; i < starts.length; i++) {
      if (starts[i] == null) continue;
      final mid = starts[i]! + sweeps[i]! / 2;
      var d = (angle - mid) % (math.pi * 2);
      if (d > math.pi) d -= math.pi * 2;
      d = d.abs();
      if (d <= sweeps[i]! / 2) return i;
      final edge = d - sweeps[i]! / 2;
      if (edge < bestDist) {
        bestDist = edge;
        best = i;
      }
    }
    return best;
  }
}

/// The colour ring: thick, rounded segments per tier forming one closed circle, with a soft
/// glow and a centre widget. Touching a segment selects it while the finger is down; sliding
/// moves the selection; lifting the finger clears it (see [onSelect]).
class MoneyRing extends StatelessWidget {
  const MoneyRing({
    super.key,
    required this.segments,
    required this.child,
    this.size = 260,
    this.thickness = 30,
    this.selected,
    this.onSelect,
  });

  final List<RingSegment> segments;
  final Widget child;
  final double size;
  final double thickness;

  /// Index into [segments] of the highlighted segment.
  final int? selected;

  /// Called with the touched segment's index, or null when the finger lifts or is over the centre.
  final ValueChanged<int?>? onSelect;

  int? _hitAt(Offset local) {
    final c = Offset(size / 2, size / 2);
    final v = local - c;
    final dist = v.distance;
    final r = size / 2 - thickness / 2;
    if (dist < r - thickness * 0.9 || dist > size / 2 + 8) return null;
    final layout = RingLayout.of([for (final s in segments) s.value], radius: r, thickness: thickness);
    return layout.hit(math.atan2(v.dy, v.dx));
  }

  @override
  Widget build(BuildContext context) {
    // Raw pointer events: shows the moment a finger touches a segment, follows it while it
    // slides, and clears as soon as it lifts. Doesn't take part in the gesture arena, so the
    // page still scrolls normally.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: onSelect == null ? null : (e) => onSelect!(_hitAt(e.localPosition)),
      onPointerMove: onSelect == null ? null : (e) => onSelect!(_hitAt(e.localPosition)),
      onPointerUp: onSelect == null ? null : (_) => onSelect!(null),
      onPointerCancel: onSelect == null ? null : (_) => onSelect!(null),
      child: SizedBox(
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
                painter: _RingPainter(segments: segments, thickness: thickness, progress: t, selected: selected),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.all(thickness + 18), child: child),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.segments, required this.thickness, required this.progress, this.selected});

  final List<RingSegment> segments;
  final double thickness;
  final double progress;
  final int? selected;

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

    final rect = Rect.fromCircle(center: c, radius: r);
    final layout = RingLayout.of([for (final s in segments) s.value], radius: r, thickness: thickness);
    final visible = layout.sweeps.whereType<double>().length;

    if (visible == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = thickness
            ..color = BColors.surface);
      return;
    }

    for (var i = 0; i < segments.length; i++) {
      final start = layout.starts[i];
      if (start == null) continue;
      final dim = selected != null && selected != i;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected == i ? thickness * 1.18 : thickness
        ..strokeCap = visible > 1 ? StrokeCap.round : StrokeCap.butt
        ..color = dim ? segments[i].color.withValues(alpha: 0.28) : segments[i].color;
      canvas.drawArc(rect, start, layout.sweeps[i]! * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.thickness != thickness ||
      old.selected != selected ||
      !_same(old.segments, segments);

  bool _same(List<RingSegment> a, List<RingSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}
