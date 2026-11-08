import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import 'ambient_bubbles.dart';

class NeighborhoodIllustration extends StatelessWidget {
  const NeighborhoodIllustration({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 150,
    height: 108,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: .24, child: AmbientBubbles()),
        CustomPaint(painter: _NeighborhoodPainter()),
      ],
    ),
  );
}

class _NeighborhoodPainter extends CustomPainter {
  const _NeighborhoodPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = YuntaColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final roofFill = Paint()..color = YuntaColors.action.withValues(alpha: .45);
    final wallFill = Paint()..color = YuntaColors.surfaceBlue;
    final scale = size.width / 150;
    canvas.save();
    canvas.scale(scale, scale);

    _house(
      canvas,
      const Rect.fromLTWH(3, 46, 44, 40),
      outline,
      roofFill,
      wallFill,
    );
    _house(
      canvas,
      const Rect.fromLTWH(49, 31, 54, 55),
      outline,
      roofFill,
      wallFill,
    );
    _house(
      canvas,
      const Rect.fromLTWH(105, 47, 41, 39),
      outline,
      roofFill,
      wallFill,
    );
    canvas.drawLine(const Offset(2, 87), const Offset(148, 87), outline);

    final accent = Paint()
      ..color = YuntaColors.action
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(76, 5), const Offset(76, 15), accent);
    canvas.drawLine(const Offset(62, 9), const Offset(68, 16), accent);
    canvas.drawLine(const Offset(90, 9), const Offset(84, 16), accent);
    canvas.restore();
  }

  void _house(Canvas canvas, Rect rect, Paint stroke, Paint roof, Paint wall) {
    final left = rect.left;
    final right = rect.right;
    final base = rect.bottom;
    final top = rect.top;
    final peak = Offset(rect.center.dx, top - rect.height * .52);
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(body, wall);
    canvas.drawRRect(body, stroke);
    final roofPath = Path()
      ..moveTo(left - 5, top + 1)
      ..lineTo(peak.dx, peak.dy)
      ..lineTo(right + 5, top + 1)
      ..close();
    canvas.drawPath(roofPath, roof);
    canvas.drawPath(roofPath, stroke);
    final door = Rect.fromLTWH(rect.center.dx - 5, base - 22, 10, 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, const Radius.circular(5)),
      stroke,
    );
    for (final offset in [
      Offset(left + 9, top + 13),
      Offset(right - 17, top + 13),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx, offset.dy, 8, 10),
          const Radius.circular(1),
        ),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeighborhoodPainter oldDelegate) => false;
}
