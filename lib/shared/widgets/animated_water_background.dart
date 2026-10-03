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
      duration: const Duration(seconds: 8),
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
    final Rect rect = Offset.zero & size;
    final bool isDark = theme.isDark;
    final bool isLight = !isDark;
    final double phase = animationValue * 2 * math.pi;

    // 1. Base deep oceanic canvas background
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

    // 2. Ambient caustic subsurface light beam (Sunbeams / Volumetric Depth)
    final Paint sunlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.65),
        radius: 1.25,
        colors: [
          (isLight ? const Color(0xFF38BDF8) : const Color(0xFF00E5FF)).withValues(alpha: isLight ? 0.30 : 0.18),
          (isLight ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7)).withValues(alpha: isLight ? 0.15 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, sunlightPaint);


    final path1 = Path();
    final path2 = Path();
    final path3 = Path();

    final crestPath1 = Path();
    final crestPath2 = Path();
    final crestPath3 = Path();

    // Wave baseline heights — balanced for depth & screen presence
    final y1 = size.height * (isLight ? 0.38 : 0.44);
    final y2 = size.height * (isLight ? 0.50 : 0.56);
    final y3 = size.height * (isLight ? 0.62 : 0.70);

    // Amplitudes for dual-harmonic hydrodynamics (Calm & delicate oceanic presence)
    final amp1 = isLight ? 22.0 : 18.0;
    final amp2 = isLight ? 28.0 : 24.0;
    final amp3 = isLight ? 34.0 : 28.0;

    path1.moveTo(0, size.height);
    path2.moveTo(0, size.height);
    path3.moveTo(0, size.height);

    path1.lineTo(0, y1);
    path2.lineTo(0, y2);
    path3.lineTo(0, y3);

    bool first = true;
    final double step = 4.0;
    for (double x = 0; x <= size.width + step; x += step) {
      final double clampedX = x.clamp(0.0, size.width);
      final double nx = clampedX / size.width;

      // Wave 1: Slow, deep oceanic swell with subtle rolling counter-wave
      final double h1 = y1 +
          math.sin((nx * 1.6 * math.pi) + phase) * (amp1 * 0.78) +
          math.cos((nx * 3.2 * math.pi) - phase) * (amp1 * 0.22);
      path1.lineTo(clampedX, h1);

      // Wave 2: Harmonic mid-depth tide
      final double h2 = y2 +
          math.cos((nx * 2.0 * math.pi) + phase) * (amp2 * 0.72) +
          math.sin((nx * 4.0 * math.pi) + (phase * 2)) * (amp2 * 0.28);
      path2.lineTo(clampedX, h2);

      // Wave 3: Expressive surface counter-current
      final double h3 = y3 +
          math.sin((nx * 2.4 * math.pi) - phase) * (amp3 * 0.74) +
          math.cos((nx * 4.8 * math.pi) + (phase * 2)) * (amp3 * 0.26);
      path3.lineTo(clampedX, h3);

      if (first) {
        crestPath1.moveTo(clampedX, h1);
        crestPath2.moveTo(clampedX, h2);
        crestPath3.moveTo(clampedX, h3);
        first = false;
      } else {
        crestPath1.lineTo(clampedX, h1);
        crestPath2.lineTo(clampedX, h2);
        crestPath3.lineTo(clampedX, h3);
      }
    }

    path1.lineTo(size.width, size.height);
    path2.lineTo(size.width, size.height);
    path3.lineTo(size.width, size.height);

    path1.close();
    path2.close();
    path3.close();

    // 4. Wave Shaders
    // Wave 1 (Deepest):
    final Rect waveRect1 = Rect.fromLTWH(0, y1 - amp1, size.width, size.height - (y1 - amp1));
    final Paint wavePaint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF0284C7).withValues(alpha: 0.32),
                const Color(0xFF003B73).withValues(alpha: 0.50),
                const Color(0xFF001B3A).withValues(alpha: 0.78),
              ]
            : [
                const Color(0xFF7DD3FC).withValues(alpha: 0.45),
                const Color(0xFF38BDF8).withValues(alpha: 0.35),
                const Color(0xFF0284C7).withValues(alpha: 0.28),
              ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(waveRect1);

    // Wave 2 (Mid-depth):
    final Rect waveRect2 = Rect.fromLTWH(0, y2 - amp2, size.width, size.height - (y2 - amp2));
    final Paint wavePaint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF00E5FF).withValues(alpha: 0.28),
                const Color(0xFF0369A1).withValues(alpha: 0.55),
                const Color(0xFF001F3F).withValues(alpha: 0.82),
              ]
            : [
                const Color(0xFF38BDF8).withValues(alpha: 0.50),
                const Color(0xFF0EA5E9).withValues(alpha: 0.38),
                const Color(0xFF0369A1).withValues(alpha: 0.32),
              ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(waveRect2);

    // Wave 3 (Foreground swell):
    final Rect waveRect3 = Rect.fromLTWH(0, y3 - amp3, size.width, size.height - (y3 - amp3));
    final Paint wavePaint3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF00B4D8).withValues(alpha: 0.38),
                const Color(0xFF002E54).withValues(alpha: 0.58),
                const Color(0xFF001428).withValues(alpha: 0.72),
              ]
            : [
                const Color(0xFF0EA5E9).withValues(alpha: 0.50),
                const Color(0xFF0284C7).withValues(alpha: 0.38),
                const Color(0xFF003B73).withValues(alpha: 0.30),
              ],
        stops: const [0.0, 0.30, 1.0],
      ).createShader(waveRect3);

    // Draw Wave 1
    canvas.drawPath(path1, wavePaint1);
    final Paint softCrest1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          (isLight ? const Color(0xFF7DD3FC) : const Color(0xFF38BDF8)).withValues(alpha: 0.05),
          (isLight ? const Color(0xFF38BDF8) : const Color(0xFF00E5FF)).withValues(alpha: isLight ? 0.32 : 0.22),
          (isLight ? const Color(0xFF7DD3FC) : const Color(0xFF38BDF8)).withValues(alpha: 0.05),
        ],
      ).createShader(waveRect1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(crestPath1, softCrest1);

    // Draw Wave 2
    canvas.drawPath(path2, wavePaint2);
    final Paint softCrest2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          (isLight ? const Color(0xFF38BDF8) : const Color(0xFF00E5FF)).withValues(alpha: 0.05),
          (isLight ? const Color(0xFF0EA5E9) : const Color(0xFF38BDF8)).withValues(alpha: isLight ? 0.42 : 0.30),
          (isLight ? const Color(0xFF38BDF8) : const Color(0xFF00E5FF)).withValues(alpha: 0.05),
        ],
      ).createShader(waveRect2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(crestPath2, softCrest2);

    // Draw Wave 3 (Foreground swell)
    canvas.drawPath(path3, wavePaint3);
    final Paint softCrest3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          (isLight ? const Color(0xFF0EA5E9) : const Color(0xFF00B4D8)).withValues(alpha: 0.08),
          (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: isLight ? 0.50 : 0.38),
          (isLight ? const Color(0xFF0EA5E9) : const Color(0xFF00B4D8)).withValues(alpha: 0.08),
        ],
      ).createShader(waveRect3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(crestPath3, softCrest3);

    // 5. Diagonal Volumetric God Rays (Streaming through water depth with Screen blend over waves)
    final double sunOriginX = size.width * 0.72;
    final double sunOriginY = -size.height * 0.08;

    final rayAngles = [-0.64, -0.42, -0.20, 0.04];
    final rayWidths = [size.width * 0.28, size.width * 0.36, size.width * 0.32, size.width * 0.26];

    for (int r = 0; r < rayAngles.length; r++) {
      // Exact integer harmonic phase shift (smooth continuous 360 loop)
      final double rayOffset = r * (math.pi / 2);
      final double rAlpha = (isLight ? 0.15 : 0.10) +
          math.sin(phase + rayOffset) * (isLight ? 0.04 : 0.028);
      final double angle = rayAngles[r] + math.sin(phase + rayOffset) * 0.035;
      final double length = size.height * 1.45;

      final double rayCenterX = sunOriginX + math.sin(angle) * length;
      final double rayCenterY = sunOriginY + math.cos(angle) * length;
      final double halfWidth = rayWidths[r] * (0.85 + math.cos(phase * 2 + rayOffset) * 0.15);

      final rayPath = Path()
        ..moveTo(sunOriginX - 25, sunOriginY)
        ..lineTo(sunOriginX + 25, sunOriginY)
        ..lineTo(rayCenterX + halfWidth, rayCenterY)
        ..lineTo(rayCenterX - halfWidth, rayCenterY)
        ..close();

      final rayShaderRect = Rect.fromPoints(
        Offset(sunOriginX, sunOriginY),
        Offset(rayCenterX, rayCenterY),
      );

      final Paint rayPaint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isLight ? const Color(0xFF38BDF8) : const Color(0xFF00E5FF)).withValues(alpha: rAlpha * 1.8),
            (isLight ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7)).withValues(alpha: rAlpha * 0.8),
            Colors.transparent,
          ],
          stops: const [0.0, 0.40, 1.0],
        ).createShader(rayShaderRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);

      canvas.drawPath(rayPath, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.theme.id != theme.id;
  }
}
