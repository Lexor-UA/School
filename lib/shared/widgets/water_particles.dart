import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaterParticles extends StatefulWidget {
  const WaterParticles({super.key});

  @override
  State<WaterParticles> createState() => _WaterParticlesState();
}

class _WaterParticlesState extends State<WaterParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    
    // Generate initial particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_generateParticle());
    }

    _controller.addListener(() {
      for (var particle in _particles) {
        // Move particle up
        particle.y -= particle.speed;
        // Sway left and right
        particle.x += math.sin(particle.y * 0.05 + particle.seed) * 0.5;
        
        // Reset if it goes off screen top
        if (particle.y < -10) {
          final newP = _generateParticle();
          particle.x = newP.x;
          particle.y = 110; // start slightly below bottom
          particle.size = newP.size;
          particle.speed = newP.speed;
        }
      }
    });
  }

  _Particle _generateParticle() {
    return _Particle(
      x: _random.nextDouble() * 100, // percentage width
      y: _random.nextDouble() * 100, // percentage height
      size: _random.nextDouble() * 4 + 1, // 1 to 5 radius
      speed: _random.nextDouble() * 0.2 + 0.05,
      seed: _random.nextDouble() * math.pi * 2,
    );
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
          painter: _ParticlePainter(_particles),
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

  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.seed});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final dx = (particle.x / 100) * size.width;
      final dy = (particle.y / 100) * size.height;
      canvas.drawCircle(Offset(dx, dy), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true; // Always repaint on tick
}
