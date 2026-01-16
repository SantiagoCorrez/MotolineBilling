import 'package:flutter/material.dart';

class DottedBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color dotColor;

  const DottedBackground({
    Key? key,
    required this.child,
    this.backgroundColor = const Color(0xFF1E1E2C), // Dark background
    this.dotColor = const Color(0xFF3E3E4C), // Slightly lighter dot
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(
        backgroundColor: backgroundColor,
        dotColor: dotColor,
      ),
      child: child,
    );
  }
}

class _DottedPainter extends CustomPainter {
  final Color backgroundColor;
  final Color dotColor;

  _DottedPainter({
    required this.backgroundColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final paint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const double spacing = 20.0;
    const double radius = 1.5;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
