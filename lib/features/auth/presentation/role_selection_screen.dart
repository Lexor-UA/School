import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';


class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Backgrounds
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          
          // Realistic Ultra-HD Background overlay
          Image.asset(
            'assets/images/bg_kids.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.3),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF0D47A1),
            ),
          ).animate().fadeIn(duration: 1000.ms),

          // Main Content
          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo Section
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 120,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Column(
                        children: [
                          const Icon(
                            LucideIcons.waves,
                            size: 80,
                            color: Colors.white,
                          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 8),
                          Text(
                            'CITY SWIM',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  ],
                ),
                
                const Spacer(),
                
                // Portal Text
                const Text(
                  'ОБЕРІТЬ ПОРТАЛ',
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 4.0,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 20),

                // Login Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildLoginRow(
                        context: context,
                        title: 'Клієнтам',
                        icon: LucideIcons.user,
                        delay: 500,
                        onTap: () {
                          ref.read(authControllerProvider.notifier).loginAsParent();
                          context.go('/parent');
                        },
                      ),
                      _buildLoginRow(
                        context: context,
                        title: 'Тренерам',
                        icon: LucideIcons.activity,
                        delay: 600,
                        onTap: () {
                          ref.read(authControllerProvider.notifier).loginAsCoach();
                          context.go('/coach');
                        },
                      ),
                      _buildLoginRow(
                        context: context,
                        title: 'Адміністраторам',
                        icon: LucideIcons.laptop,
                        delay: 700,
                        onTap: () {
                          ref.read(authControllerProvider.notifier).loginAsAdmin();
                          context.go('/admin');
                        },
                      ),
                      _buildLoginRow(
                        context: context,
                        title: 'Власникам',
                        icon: LucideIcons.briefcase,
                        delay: 800,
                        onTap: () {
                          ref.read(authControllerProvider.notifier).loginAsOwner();
                          context.go('/owner');
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Motto
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Мистецтво води.\nВаш шлях до досконалості.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1.0,
                      height: 1.3,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 1000.ms),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRow({
    required BuildContext context,
    required String title,
    required IconData icon,
    required int delay,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3), // Glass effect
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
              ]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.cyanAccent, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 24),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }
}
