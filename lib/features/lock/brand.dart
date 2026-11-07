import 'package:flutter/material.dart';

import '../../design/tokens.dart';

/// App mark: a stacked ring segment glyph + wordmark.
class BruntMark extends StatelessWidget {
  const BruntMark({super.key, this.size = 64, this.showWord = true});
  final double size;
  final bool showWord;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _MarkPainter()),
      ),
      if (showWord) ...[
        const SizedBox(height: 14),
        Text('BRUNT', style: BText.h1.copyWith(letterSpacing: 6, fontWeight: FontWeight.w800)),
      ],
    ]);
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    const colors = [BColors.tierPriority, BColors.tierSavings, BColors.tierFixed, BColors.tierDaily];
    const sweep = 1.2;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -1.9 + i * (sweep + 0.37),
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
