import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:swimming_school_app/core/theme/theme.dart';

class AnimatedWaterBackground extends StatefulWidget {
  const AnimatedWaterBackground({super.key});

  @override
  State<AnimatedWaterBackground> createState() => _AnimatedWaterBackgroundState();
}

class _AnimatedWaterBackgroundState extends State<AnimatedWaterBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WaterPainter(_controller.value),
          child: Container(), // Fills the available space
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double animationValue;

  _WaterPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background with a deep blue gradient
    final Rect rect = Offset.zero & size;
    final Paint backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryBlue,
          AppTheme.primaryBlue.withValues(alpha: 0.8),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final path1 = Path();
    final path2 = Path();
    final path3 = Path();

    // The vertical offsets for the 3 waves
    final y1 = size.height * 0.45;
    final y2 = size.height * 0.55;
    final y3 = size.height * 0.70;

    path1.moveTo(0, size.height);
    path2.moveTo(0, size.height);
    path3.moveTo(0, size.height);

    path1.lineTo(0, y1);
    path2.lineTo(0, y2);
    path3.lineTo(0, y3);

    for (double i = 0; i <= size.width; i++) {
      // Wave 1 (slow, wide)
      path1.lineTo(
          i, y1 + math.sin((i / size.width * 1.5 * math.pi) + (animationValue * 2 * math.pi)) * 30);
      // Wave 2 (medium)
      path2.lineTo(
          i, y2 + math.cos((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 40);
      // Wave 3 (fast, opposite direction)
      path3.lineTo(
          i, y3 + math.sin((i / size.width * 2.5 * math.pi) - (animationValue * 2 * math.pi)) * 50);
    }

    path1.lineTo(size.width, size.height);
    path2.lineTo(size.width, size.height);
    path3.lineTo(size.width, size.height);

    path1.close();
    path2.close();
    path3.close();

    final paint1 = Paint()
      ..color = AppTheme.accentTeal.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = AppTheme.accentTeal.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
      
    final paint3 = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
