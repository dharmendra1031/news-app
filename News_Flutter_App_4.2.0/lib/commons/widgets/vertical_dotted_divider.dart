import 'package:flutter/material.dart';

class VerticalDottedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double strokeWidth;
  final double dashHeight;
  final double dashSpace;

  const VerticalDottedDivider({
    super.key,
    this.height = 42,
    this.color = const Color(0xFFD6D6D6),
    this.strokeWidth = 1,
    this.dashHeight = 2,
    this.dashSpace = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: strokeWidth,
      height: height,
      child: CustomPaint(
        painter: DottedLinePainter(
          color: color,
          strokeWidth: strokeWidth,
          dashHeight: dashHeight,
          dashSpace: dashSpace,
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashHeight;
  final double dashSpace;

  DottedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashHeight,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );

      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DottedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashHeight != dashHeight ||
        oldDelegate.dashSpace != dashSpace;
  }
}
