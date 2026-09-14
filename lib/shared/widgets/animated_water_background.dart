import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class AnimatedWaterBackground extends ConsumerStatefulWidget {
  const AnimatedWaterBackground({super.key});

  @override
  ConsumerState<AnimatedWaterBackground> createState() => _AnimatedWaterBackgroundState();
}

class _AnimatedWaterBackgroundState extends ConsumerState<AnimatedWaterBackground> with SingleTickerProviderStateMixin {
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
    final theme = ref.watch(appThemeControllerProvider);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WaterPainter(_controller.value, theme),
          child: Container(), // Fills the available space
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double animationValue;
  final AppThemeConfig theme;

  _WaterPainter(this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base gradient canvas
    final Rect rect = Offset.zero & size;
    final Paint backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.waterBgTop,
          theme.waterBgBottom,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final path1 = Path();
    final path2 = Path();
    final path3 = Path();

    final crest1 = Path();
    final crest2 = Path();
    final crest3 = Path();

    // Wave baseline heights — balanced for clear screen presence
    final bool isLight = !theme.isDark;
    final y1 = size.height * (isLight ? 0.38 : 0.45);
    final y2 = size.height * (isLight ? 0.48 : 0.55);
    final y3 = size.height * (isLight ? 0.58 : 0.70);

    // Amplitudes for expressive dynamic crests
    final amp1 = isLight ? 42.0 : 32.0;
    final amp2 = isLight ? 52.0 : 42.0;
    final amp3 = isLight ? 60.0 : 50.0;

    path1.moveTo(0, size.height);
    path2.moveTo(0, size.height);
    path3.moveTo(0, size.height);

    path1.lineTo(0, y1);
    path2.lineTo(0, y2);
    path3.lineTo(0, y3);

    bool first = true;
    for (double i = 0; i <= size.width; i += 2) {
      // Wave 1: Slow, wide rolling swell
      final double h1 = y1 + math.sin((i / size.width * 1.5 * math.pi) + (animationValue * 2 * math.pi)) * amp1;
      path1.lineTo(i, h1);

      // Wave 2: Medium harmonic flow
      final double h2 = y2 + math.cos((i / size.width * 2.0 * math.pi) + (animationValue * 2 * math.pi)) * amp2;
      path2.lineTo(i, h2);

      // Wave 3: Faster counter-current swell
      final double h3 = y3 + math.sin((i / size.width * 2.5 * math.pi) - (animationValue * 2 * math.pi)) * amp3;
      path3.lineTo(i, h3);

      if (first) {
        crest1.moveTo(i, h1);
        crest2.moveTo(i, h2);
        crest3.moveTo(i, h3);
        first = false;
      } else {
        crest1.lineTo(i, h1);
        crest2.lineTo(i, h2);
        crest3.lineTo(i, h3);
      }
    }

    path1.lineTo(size.width, size.height);
    path2.lineTo(size.width, size.height);
    path3.lineTo(size.width, size.height);

    path1.close();
    path2.close();
    path3.close();

    final paint1 = Paint()
      ..color = theme.waterWave1
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = theme.waterWave2
      ..style = PaintingStyle.fill;
      
    final paint3 = Paint()
      ..color = theme.waterWave3
      ..style = PaintingStyle.fill;

    // Specular wave crest highlight strokes for crisp visual definition
    final crestPaint1 = Paint()
      ..color = Colors.white.withValues(alpha: isLight ? 0.38 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLight ? 1.5 : 1.0;

    final crestPaint2 = Paint()
      ..color = Colors.white.withValues(alpha: isLight ? 0.48 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLight ? 1.8 : 1.2;

    final crestPaint3 = Paint()
      ..color = Colors.white.withValues(alpha: isLight ? 0.58 : 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLight ? 2.2 : 1.5;

    // Draw waves in back-to-front depth order
    canvas.drawPath(path1, paint1);
    canvas.drawPath(crest1, crestPaint1);

    canvas.drawPath(path2, paint2);
    canvas.drawPath(crest2, crestPaint2);

    canvas.drawPath(path3, paint3);
    canvas.drawPath(crest3, crestPaint3);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.theme.id != theme.id;
  }
}
