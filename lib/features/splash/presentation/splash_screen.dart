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
          // Premium dark blue/purple gradient background with cinematic scale animation
          Image.asset(
            'assets/images/splash_bg_1.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms).scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(1.05, 1.05),
                duration: 3000.ms,
                curve: Curves.easeOutQuart,
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
