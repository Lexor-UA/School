import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumLoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const PremiumLoadingIndicator({
    super.key,
    this.size = 64,
    this.color = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer subtle glowing ring (breathing)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.1),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2000.ms, curve: Curves.easeInOut)
              .fade(begin: 0.5, end: 1.0, duration: 2000.ms, curve: Curves.easeInOut),

          // Inner rotating elegant arc
          SizedBox(
            width: size * 0.7,
            height: size * 0.7,
            child: CustomPaint(
              painter: _ArcPainter(color: color),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1500.ms, curve: Curves.easeInOutCubic)
              .then()
              .rotate(duration: 1500.ms, curve: Curves.easeInOutCubic),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw a calm, elegant arc (approx 120 degrees)
    canvas.drawArc(rect, 0, 3.141592653589793 * 0.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
