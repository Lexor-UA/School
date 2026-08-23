import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';


class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next != null) {
        switch (next.role) {
          case UserRole.parent:
            context.go('/parent');
            break;
          case UserRole.coach:
            context.go('/coach');
            break;
          case UserRole.admin:
            context.go('/admin');
            break;
          case UserRole.owner:
            context.go('/owner');
            break;
        }
      }
    });

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
                // Consistent Language Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24.0, top: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showLanguageSelector(context),
                          splashColor: Colors.white.withValues(alpha: 0.2),
                          highlightColor: Colors.white.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.globe, color: Colors.cyanAccent, size: 14),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'auth.subtitle'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.chevronDown, color: Colors.white54, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ),
                ),
                const SizedBox(height: 16),
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
                Text(
                  'auth.choose_portal'.tr(),
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
                        title: 'auth.login_google'.tr(),
                        icon: LucideIcons.globe,
                        delay: 500,
                        onTap: () async {
                          try {
                            await ref.read(authControllerProvider.notifier).signInWithGoogle();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Помилка Google Sign In: $e')),
                              );
                            }
                          }
                        },
                      ),
                      _buildLoginRow(
                        context: context,
                        title: 'auth.login_email'.tr(),
                        icon: LucideIcons.mail,
                        delay: 600,
                        onTap: () {
                          _showEmailLoginModal(context, ref);
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Motto
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'auth.motto'.tr(),
                    style: const TextStyle(
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

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final currentLocale = context.locale.languageCode;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05), // Lighter frosted glass
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  left: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'auth.choose_language'.tr(),
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 2,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLangItem(context, 'auth.languages.uk'.tr(), 'UKR', const Locale('uk'), currentLocale == 'uk'),
                  _buildLangItem(context, 'auth.languages.en'.tr(), 'ENG', const Locale('en'), currentLocale == 'en'),
                  _buildLangItem(context, 'auth.languages.ru'.tr(), 'RUS', const Locale('ru'), currentLocale == 'ru'),
                  _buildLangItem(context, 'auth.languages.de'.tr(), 'DEU', const Locale('de'), currentLocale == 'de'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangItem(BuildContext context, String title, String code, Locale locale, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            context.setLocale(locale);
            Navigator.pop(context);
          },
          leading: Text(code, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
          title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
          trailing: isActive ? const Icon(LucideIcons.checkCircle2, color: Colors.white) : null,
        ),
      ),
    );
  }

  void _showEmailLoginModal(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'АВТОРИЗАЦІЯ',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(LucideIcons.mail, color: Colors.cyanAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Пароль',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(LucideIcons.lock, color: Colors.cyanAccent),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                          foregroundColor: Colors.cyanAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.cyanAccent),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(authControllerProvider.notifier).signInWithEmail(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Помилка входу: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('УВІЙТИ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
