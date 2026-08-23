import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
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
          // Premium dark blue/purple gradient background with cinematic scale animation
          // Shifted up so the logo is perfectly centered between top and buttons
          Positioned.fill(
            child: Container(
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
                    ).animate()
                        .fadeIn(duration: 800.ms)
                        .scale(
                          begin: const Offset(1.10, 1.10),
                          end: const Offset(1.0, 1.0),
                          duration: 3000.ms,
                          curve: Curves.easeOutQuart,
                        )
                        .blurXY(begin: 10, end: 0, duration: 1500.ms, curve: Curves.easeInOut),
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
          ),

          // Subtle water particles overlaid for theme
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: const WaterParticles(),
            ),
          ),

          // Main Content
          // Main Content
          // Language Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _showLanguageSelector(context),
                      splashColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor: Colors.white.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.globe, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.chevronDown, color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate()
             .fadeIn(delay: 1500.ms, duration: 800.ms)
             .slideX(begin: 0.5, end: 0, duration: 1000.ms, curve: Curves.easeOutExpo),
          ),

          // Bottom Content (Buttons and Motto)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.08, // 8% from bottom
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Login Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildLoginRow(
                        context: context,
                        title: 'auth.login_google'.tr(),
                        icon: LucideIcons.globe,
                        isGoogle: true,
                        delay: 1600,
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
                        delay: 1800,
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      letterSpacing: 2.0,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate()
                 .fadeIn(delay: 2000.ms, duration: 1200.ms)
                 .slideY(begin: 0.5, end: 0, duration: 1200.ms, curve: Curves.easeOutExpo),
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
    bool isGoogle = false,
    required int delay,
    required VoidCallback onTap,
  }) {
    final textColor = isGoogle ? const Color(0xFF0F2027) : const Color(0xFF0072FF);
    final iconBgColor = isGoogle ? Colors.transparent : const Color(0xFF0072FF).withValues(alpha: 0.1);
    final iconColor = isGoogle ? Colors.transparent : const Color(0xFF0072FF);
    final chevronColor = Colors.black38;

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: Colors.black.withValues(alpha: 0.05),
        highlightColor: Colors.black.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(isGoogle ? 0 : 8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: isGoogle
                        ? Image.asset('assets/images/google_logo.png', width: 26, height: 26)
                        : Icon(icon, color: iconColor, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w700, 
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, color: chevronColor, size: 20),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: content,
      ),
    ).animate()
     .fadeIn(delay: delay.ms, duration: 800.ms)
     .slideY(begin: 0.8, end: 0, duration: 1200.ms, curve: Curves.easeOutBack)
     .shimmer(delay: (delay + 1200).ms, duration: 1500.ms, color: Colors.white.withValues(alpha: 0.2));
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
                        hintText: 'Email / Логін',
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
