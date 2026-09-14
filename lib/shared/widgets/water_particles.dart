import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class WaterParticles extends ConsumerStatefulWidget {
  const WaterParticles({super.key});

  @override
  ConsumerState<WaterParticles> createState() => _WaterParticlesState();
}

class _WaterParticlesState extends ConsumerState<WaterParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    
    // Generate initial rich pool of particles
    for (int i = 0; i < 40; i++) {
      _particles.add(_generateParticle(initial: true));
    }

    _controller.addListener(() {
      for (var particle in _particles) {
        // Move particle up
        particle.y -= particle.speed;
        // Sway left and right with natural buoyancy
        particle.x += math.sin(particle.y * 0.04 + particle.seed) * 0.35;
        
        // Reset if it goes off screen top
        if (particle.y < -12) {
          final newP = _generateParticle(initial: false);
          particle.x = newP.x;
          particle.y = 112; // Start slightly below bottom
          particle.size = newP.size;
          particle.speed = newP.speed;
          particle.alpha = newP.alpha;
        }
      }
    });
  }

  _Particle _generateParticle({required bool initial}) {
    return _Particle(
      x: _random.nextDouble() * 100, // percentage width
      y: initial ? _random.nextDouble() * 100 : 110 + _random.nextDouble() * 10,
      size: _random.nextDouble() * 4.5 + 2.0, // 2 to 6.5 radius for visible presence
      speed: _random.nextDouble() * 0.22 + 0.08,
      seed: _random.nextDouble() * math.pi * 2,
      alpha: _random.nextDouble() * 0.35 + 0.65, // Opacity variation
    );
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
          painter: _ParticlePainter(_particles, theme),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double seed;
  double alpha;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.seed,
    required this.alpha,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final AppThemeConfig theme;

  _ParticlePainter(this.particles, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    // Theme-tailored 3D bubble styling
    final Color rimColor;
    final Color bodyColor;
    final Color highlightColor;

    if (theme.isDark) {
      rimColor = const Color(0xFF00E5FF).withValues(alpha: 0.55);
      bodyColor = const Color(0xFF0284C7).withValues(alpha: 0.22);
      highlightColor = Colors.white.withValues(alpha: 0.90);
    } else if (theme.id == AppThemeMode.lightPearlCoral) {
      // Warm Silk & Champagne: Effervescent golden pearl / rose-gold fizz
      rimColor = const Color(0xFFD97706).withValues(alpha: 0.48);
      bodyColor = const Color(0xFFFDE68A).withValues(alpha: 0.28);
      highlightColor = Colors.white.withValues(alpha: 0.95);
    } else if (theme.id == AppThemeMode.lightAzure) {
      // Ocean Pearl: Crystal azure and sky blue water bubbles
      rimColor = const Color(0xFF0284C7).withValues(alpha: 0.45);
      bodyColor = const Color(0xFF38BDF8).withValues(alpha: 0.24);
      highlightColor = Colors.white.withValues(alpha: 0.95);
    } else {
      // Nordic Mint & others
      rimColor = theme.accentPrimary.withValues(alpha: 0.45);
      bodyColor = theme.accentSecondary.withValues(alpha: 0.22);
      highlightColor = Colors.white.withValues(alpha: 0.90);
    }

    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final highlightPaint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      final dx = (particle.x / 100) * size.width;
      final dy = (particle.y / 100) * size.height;
      final center = Offset(dx, dy);
      final r = particle.size;

      // 1. Translucent bubble sphere body
      bodyPaint.color = bodyColor.withValues(alpha: (bodyColor.a * particle.alpha).clamp(0.0, 1.0));
      canvas.drawCircle(center, r, bodyPaint);

      // 2. Delicate spherical rim contour
      rimPaint.color = rimColor.withValues(alpha: (rimColor.a * particle.alpha).clamp(0.0, 1.0));
      canvas.drawCircle(center, r, rimPaint);

      // 3. Primary 3D specular light reflection (top-left glint)
      if (r >= 2.2) {
        highlightPaint.color = highlightColor.withValues(alpha: (0.85 * particle.alpha).clamp(0.0, 1.0));
        final glintCenter = Offset(center.dx - r * 0.32, center.dy - r * 0.32);
        canvas.drawCircle(glintCenter, math.max(0.6, r * 0.28), highlightPaint);

        // 4. Secondary micro-reflection (bottom-right ambient bounce)
        highlightPaint.color = highlightColor.withValues(alpha: (0.35 * particle.alpha).clamp(0.0, 1.0));
        final bounceCenter = Offset(center.dx + r * 0.28, center.dy + r * 0.28);
        canvas.drawCircle(bounceCenter, math.max(0.4, r * 0.16), highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true; // Continuous tick
}
