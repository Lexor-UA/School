import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../controllers/auth_controller.dart';
import '../widgets/animated_water_background.dart';
import 'parent_main.dart';
import 'coach_main.dart';
import 'owner_main.dart';
import 'admin_main.dart';
import '../utils/page_transitions.dart';
import '../widgets/water_particles.dart';

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
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Section
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow behind the logo to make it stand out
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  blurRadius: 80,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          // Original Logo Image, made larger
                          Image.asset(
                            'assets/images/logo.png',
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Column(
                              children: [
                                const Icon(
                                  LucideIcons.waves,
                                  size: 100,
                                  color: Colors.white,
                                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                                const SizedBox(height: 16),
                                Text(
                                  'CITY SWIM',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Portal Text
                      const Text(
                        'ОБЕРІТЬ ПОРТАЛ',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 24),

                      // Login Options
                      _buildLoginRow(
                        context: context,
                        title: 'Клієнтам',
                        icon: LucideIcons.user,
                        delay: 700,
                        onTap: () {
                          ref.read(authControllerProvider.notifier).loginAsParent();
                          Navigator.push(context, FadeScaleRoute(page: const ParentMain()));
                        },
                      ),
                      _buildLoginRow(
                        context: context,
                        title: 'Тренерам',
                        icon: LucideIcons.activity,
                        delay: 800,
                        onTap: () {
                          ref.read(authControllerProvider.notifier).loginAsCoach();
                          Navigator.push(context, FadeScaleRoute(page: const CoachMain()));
                        },
                      ),
                      _buildLoginRow(
                        context: context,
                        title: 'Адміністраторам',
                        icon: LucideIcons.laptop,
                        delay: 900,
                        onTap: () {
                          ref.read(authControllerProvider.notifier).loginAsAdmin();
                          Navigator.push(context, FadeScaleRoute(page: const AdminMain()));
                        },
                      ),
                      _buildLoginRow(
                        context: context,
                        title: 'Власникам',
                        icon: LucideIcons.briefcase,
                        delay: 1000,
                        onTap: () {
                          ref.read(authControllerProvider.notifier).loginAsOwner();
                          Navigator.push(context, FadeScaleRoute(page: const OwnerMain()));
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Motto
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Мистецтво води.\nВаш шлях до досконалості.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 1.0,
                            height: 1.3,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2)),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(delay: 1200.ms),
                    ],
                  ),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2), // Glass effect
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
