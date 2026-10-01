import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class GoogleWordmark extends StatelessWidget {
  final double fontSize;
  final bool showIcon;
  const GoogleWordmark({super.key, this.fontSize = 20, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showIcon) ...[
          GoogleLogo(size: fontSize * 0.95),
          const SizedBox(width: 10),
        ],
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              letterSpacing: 0.5,
            ),
            children: const [
              TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
              TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
              TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
              TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
              TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
              TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double stroke = w * 0.22;
    final Rect rect = Rect.fromLTWH(stroke / 2, stroke / 2, w - stroke, h - stroke);

    // Paints
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // 1. Red Arc (Top)
    canvas.drawArc(rect, -3.14159 * 0.75, 3.14159 * 0.5, false, redPaint);

    // 2. Yellow Arc (Top-Left to Bottom-Left)
    canvas.drawArc(rect, -3.14159 * 1.25, 3.14159 * 0.5, false, yellowPaint);

    // 3. Green Arc (Bottom)
    canvas.drawArc(rect, 3.14159 * 0.25, 3.14159 * 0.5, false, greenPaint);

    // 4. Blue Arc (Bottom-Right)
    canvas.drawArc(rect, -3.14159 * 0.25, 3.14159 * 0.5, false, bluePaint);

    // 5. Blue Horizontal Bar
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final double barHeight = stroke;
    final double barWidth = (w / 2);
    final double barTop = (h / 2) - (barHeight / 2);
    final double barLeft = (w / 2) - (stroke * 0.1);

    canvas.drawRect(
      Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
