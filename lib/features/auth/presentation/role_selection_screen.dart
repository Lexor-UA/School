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
import 'package:swimming_school_app/shared/widgets/premium_loading_indicator.dart';


class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
          // Background Image
          Image.asset(
            'assets/images/new_background.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF003B73)),
          ),
          
          // Gradient overlay for better text readability at the bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  const Color(0xFF001F3F).withValues(alpha: 0.5),
                  const Color(0xFF001F3F).withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Language Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _buildLanguageButton(context),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          // Logo
                          ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: 0.8, // Відрізаємо нижні 20% логотипу, де написано "KYIV"
                              child: Image.asset(
                                'assets/images/logo_light.png',
                                height: 50, // Початкова висота (до обрізки)
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Text('CITY SWIM', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0, duration: 800.ms),
                          const SizedBox(height: 16),
                          Text(
                            'auth.slogan'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF4FC3F7), // Світло-блакитний колір як на макеті
                              letterSpacing: 3.5,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
                          
                          const SizedBox(height: 60),
                          
                          Text(
                            'auth.welcome_back'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
                          
                          const SizedBox(height: 12),
                          
                          Text(
                            'auth.login_desc'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ).animate().fadeIn(delay: 800.ms, duration: 800.ms),
                          
                          const SizedBox(height: 40),
                          
                          // Google Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : () async {
                              try {
                                setState(() => _isLoading = true);
                                await ref.read(authControllerProvider.notifier).signInWithGoogle();
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Помилка Google Sign In: $e')),
                                  );
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/google_logo.png', height: 24, errorBuilder: (c,e,s) => const Icon(LucideIcons.globe, color: Colors.blue)),
                                const SizedBox(width: 12),
                                Text('auth.login_google'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ).animate().fadeIn(delay: 1000.ms, duration: 800.ms).slideY(begin: 0.2, end: 0, duration: 800.ms),
                          
                          const SizedBox(height: 24),
                          
                          // OR Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('auth.or'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                              ),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                            ],
                          ).animate().fadeIn(delay: 1100.ms, duration: 800.ms),
                          
                          const SizedBox(height: 24),
                          
                          // Email Button
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.blue.withValues(alpha: 0.5), width: 1.5), // Синя обводка
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _showEmailLoginModal(context, ref),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.mail, size: 20, color: Colors.blueAccent), // Синя іконка
                                const SizedBox(width: 12),
                                Text('auth.login_email'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ).animate().fadeIn(delay: 1200.ms, duration: 800.ms).slideY(begin: 0.2, end: 0, duration: 800.ms),
                          
                          const SizedBox(height: 40),
                          
                          // Features Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFeatureItem(LucideIcons.calendarDays, 'auth.feature_booking'.tr()),
                              const SizedBox(width: 8),
                              _buildFeatureItem(LucideIcons.barChart2, 'auth.feature_progress'.tr()),
                              const SizedBox(width: 8),
                              _buildFeatureItem(LucideIcons.trophy, 'auth.feature_goals'.tr()),
                            ],
                          ).animate().fadeIn(delay: 1400.ms, duration: 800.ms),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom Motto
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.waves, color: Colors.white.withValues(alpha: 0.6), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'auth.motto_bottom'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1600.ms, duration: 800.ms),
              ],
            ),
          ),
          
          // Loading Overlay (Thematic)
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: const Color(0xFF001F3F).withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PremiumLoadingIndicator(size: 80, color: Colors.cyanAccent),
                        const SizedBox(height: 32),
                        const Text(
                          'CITY SWIM',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1500.ms, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _showLanguageSelector(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.globe, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      context.locale.languageCode.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.chevronDown, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
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
      builder: (modalContext) {
        bool isModalLoading = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
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
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)], // Premium fresh gradient
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C9FF).withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isModalLoading ? null : () async {
                          try {
                            setModalState(() => isModalLoading = true);
                            final notifier = ref.read(authControllerProvider.notifier);
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();
                            
                            // Спочатку закриваємо модалку, щоб не конфліктувати з GoRouter
                            if (modalContext.mounted) Navigator.pop(modalContext);
                            
                            await notifier.signInWithEmail(email, password);
                          } catch (e) {
                            if (modalContext.mounted) {
                              setModalState(() => isModalLoading = false);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Помилка входу: $e')),
                              );
                            }
                          }
                        },
                        child: isModalLoading
                            ? const PremiumLoadingIndicator(size: 26, color: Colors.white)
                            : const Text(
                                'УВІЙТИ', 
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 16, 
                                  fontWeight: FontWeight.w800, 
                                  letterSpacing: 2
                                )
                              ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .shimmer(duration: 2500.ms, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      });
      },
    );
  }
}
