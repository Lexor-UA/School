import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  Future<void> _navigateToAuth() async {
    // Wait for the animation to play out
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFF0F0229), // Deep dark purple
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'assets/images/splash_bg_1.jpg',
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ).animate().fadeIn(duration: 800.ms).scale(
                        begin: const Offset(1.10, 1.10),
                        end: const Offset(1.0, 1.0),
                        duration: 3000.ms,
                        curve: Curves.easeOutQuart,
                      ),
                ),
                // Gradient vignette to smoothly blend the image into the background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xAA0F0229),
                          Color(0xFF0F0229),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subtle water particles overlaid for theme
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: const WaterParticles(),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo is part of the background image
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
