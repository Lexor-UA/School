import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/shared/widgets/premium_loading_indicator.dart';
import 'package:swimming_school_app/features/auth/presentation/password_recovery_screen.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart' as swimming_school_app;

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isLoading = false;
  bool _splashFinished = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      setState(() => _splashFinished = true);
      
      final prefs = ref.read(swimming_school_app.sharedPrefsProvider);
      final authState = ref.read(authControllerProvider);
      
      UserRole? targetRole;
      if (authState != null) {
        targetRole = authState.role;
      } else {
        final savedRole = prefs.getString('userRole');
        if (savedRole != null) {
          targetRole = UserRole.values.firstWhere((e) => e.name == savedRole, orElse: () => UserRole.parent);
        }
      }

      if (targetRole != null) {
        // User is authorized, attempt Face ID / Biometrics
        bool authenticated = false;
        if (kIsWeb) {
          // Skip biometrics on Web
          authenticated = true;
        } else {
          try {
            final canCheckBiometrics = await _auth.canCheckBiometrics;
            final isDeviceSupported = await _auth.isDeviceSupported();
            
            if (canCheckBiometrics || isDeviceSupported) {
              authenticated = await _auth.authenticate(
                localizedReason: 'Відскануйте обличчя або відбиток пальця для входу',
                biometricOnly: false,
                persistAcrossBackgrounding: true,
              );
            } else {
              // Device doesn't support biometrics, just let them in
              authenticated = true;
            }
          } catch (e) {
            debugPrint('Biometric auth error: $e');
            // If biometrics fail unexpectedly, fallback to requiring manual login
            authenticated = false; 
          }
        }

        if (authenticated) {
          if (mounted) _navigateBasedOnRole(targetRole, authState);
        } else {
          // User cancelled biometrics or it failed. 
          // Show the login buttons so they can log in manually.
          // Optional: clear the session so they are forced to log in again.
          ref.read(authControllerProvider.notifier).logout();
          if (mounted) {

          }
        }
      } else {
        // No saved session, show login buttons

      }
    });
  }

  void _navigateBasedOnRole(UserRole role, [AppUser? user]) {
    if (role == UserRole.parent && user != null && user.phone == null) {
      context.go('/onboarding');
      return;
    }

    switch (role) {
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final splashOffset =
        screenHeight * 0.25; // Відступ для центрування логотипу

    ref.listen(authControllerProvider, (previous, next) {
      if (!_splashFinished) return;
      
      if (next != null) {
        if (next.role == UserRole.parent && next.phone == null) {
          context.go('/onboarding');
          return;
        }

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
            errorBuilder: (context, error, stackTrace) =>
                Container(color: const Color(0xFF003B73)),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _buildLanguageButton(context),
                  ),
                ).animate().fadeIn(delay: 3800.ms, duration: 800.ms),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 30),
                                // Logo
                                ClipRect(
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        heightFactor:
                                            0.8, // Відрізаємо нижні 20% логотипу, де написано "KYIV"
                                        child: Image.asset(
                                          'assets/images/logo_light.png',
                                          height: 75, // Збільшений розмір логотипу
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => const Text(
                                                'CITY SWIM',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(
                                      duration: 1200.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .moveY(
                                      begin: splashOffset,
                                      end: 0,
                                      duration: 4500.ms,
                                      delay: 2400.ms, // Starts a bit earlier for smoother transition
                                      curve: Curves.easeOutQuint, // Extremely smooth and slow deceleration
                                    )
                                    .scaleXY(
                                      begin: 1.6,
                                      end: 1.0,
                                      duration: 4500.ms,
                                      delay: 2400.ms,
                                      curve: Curves.easeOutQuint,
                                    ),

                                const SizedBox(height: 80),

                                // Google Button
                                OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.blue.withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        minimumSize: const Size(double.infinity, 56),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              try {
                                                setState(
                                                  () => _isLoading = true,
                                                );
                                                await ref
                                                    .read(
                                                      authControllerProvider
                                                          .notifier,
                                                    )
                                                    .signInWithGoogle();
                                              } catch (e) {
                                                if (mounted) {
                                                  setState(
                                                    () => _isLoading = false,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Помилка Google Sign In: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/google_logo.png',
                                            height: 24,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(
                                                  LucideIcons.globe,
                                                  color: Colors.blue,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'auth.login_google'.tr(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: 3200.ms, duration: 1000.ms)
                                    .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 1000.ms,
                                      delay: 3200.ms,
                                      curve: Curves.easeOutExpo,
                                    ),

                                const SizedBox(height: 24),

                                // OR Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'auth.or'.tr(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(
                                  delay: 3300.ms,
                                  duration: 1000.ms,
                                ),

                                const SizedBox(height: 24),

                                // Email Button
                                OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.blue.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 1.5,
                                        ), // Синя обводка
                                        minimumSize: const Size(
                                          double.infinity,
                                          56,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          _showEmailLoginModal(context, ref),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            LucideIcons.mail,
                                            size: 20,
                                            color: Colors.blueAccent,
                                          ), // Синя іконка
                                          const SizedBox(width: 12),
                                          Text(
                                            'auth.login_email'.tr(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: 3400.ms, duration: 1000.ms)
                                    .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 1000.ms,
                                      delay: 3400.ms,
                                      curve: Curves.easeOutExpo,
                                    ),

                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox.shrink(),
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
                        const PremiumLoadingIndicator(
                          size: 80,
                          color: Colors.cyanAccent,
                        ),
                        const SizedBox(height: 32),
                        const Text(
                              'CITY SWIM',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(duration: 1500.ms, color: Colors.white),
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.0,
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.globe,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.locale.languageCode.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.chevronDown,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
                color: Colors.white.withValues(
                  alpha: 0.05,
                ), // Lighter frosted glass
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
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
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLangItem(
                    context,
                    'Ukrainian',
                    'UKR',
                    const Locale('uk'),
                    currentLocale == 'uk',
                  ),
                  _buildLangItem(
                    context,
                    'English',
                    'ENG',
                    const Locale('en'),
                    currentLocale == 'en',
                  ),
                  _buildLangItem(
                    context,
                    'Russian',
                    'RUS',
                    const Locale('ru'),
                    currentLocale == 'ru',
                  ),
                  _buildLangItem(
                    context,
                    'German',
                    'DEU',
                    const Locale('de'),
                    currentLocale == 'de',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangItem(
    BuildContext context,
    String title,
    String code,
    Locale locale,
    bool isActive,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            context.setLocale(locale);
            Navigator.pop(context);
          },
          leading: Text(
            code,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: isActive
              ? const Icon(LucideIcons.checkCircle2, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  void _showEmailLoginModal(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    String t(
      BuildContext ctx,
      String key, {
      required String uk,
      required String en,
      required String de,
      required String ru,
    }) {
      final res = key.tr();
      if (res != key && !res.startsWith('auth.')) {
        return res;
      }
      try {
        final lang = ctx.locale.languageCode;
        switch (lang) {
          case 'en':
            return en;
          case 'de':
            return de;
          case 'ru':
            return ru;
          case 'uk':
          default:
            return uk;
        }
      } catch (_) {
        return uk;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      isScrollControlled: true,
      builder: (modalContext) {
        bool isModalLoading = false;
        bool obscurePassword = true;

        return StatefulBuilder(
          builder: (BuildContext builderContext, StateSetter setModalState) {
            Future<void> submitLogin() async {
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              if (email.isEmpty || password.isEmpty) return;

              try {
                setModalState(() => isModalLoading = true);
                final notifier = ref.read(authControllerProvider.notifier);
                await notifier.signInWithEmail(email, password);
                if (modalContext.mounted) {
                  Navigator.of(modalContext).pop();
                }
              } catch (e) {
                if (modalContext.mounted) {
                  setModalState(() => isModalLoading = false);
                }
                if (context.mounted) {
                  final errStr = 'auth.login_error'.tr(args: [e.toString()]);
                  final displayErr = errStr.startsWith('auth.') ? 'Помилка входу: $e' : errStr;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(displayErr),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0F2642).withValues(alpha: 0.96),
                          const Color(0xFF071220).withValues(alpha: 0.98),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                          blurRadius: 40,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Glowing Drag Handle
                            Center(
                              child: Container(
                                width: 46,
                                height: 4.5,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF10B981)],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Header row with Icon Badge, Title + Subtitle, and Close button
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                        const Color(0xFF0288D1).withValues(alpha: 0.08),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    LucideIcons.shieldCheck,
                                    color: Color(0xFF00E5FF),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t(
                                          builderContext,
                                          'auth.authorization',
                                          uk: 'АВТОРИЗАЦІЯ',
                                          en: 'AUTHORIZATION',
                                          de: 'AUTORISIERUNG',
                                          ru: 'АВТОРИЗАЦИЯ',
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        t(
                                          builderContext,
                                          'auth.login_subtitle',
                                          uk: 'Введіть ваші дані для входу в кабінет',
                                          en: 'Enter your credentials to log in',
                                          de: 'Geben Sie Ihre Daten ein, um sich anzumelden',
                                          ru: 'Введите ваши данные для входа в кабинет',
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.x, size: 20, color: Colors.white70),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  onPressed: () => Navigator.of(modalContext).pop(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Email / Login input
                            TextField(
                              controller: emailController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setModalState(() {}),
                              decoration: InputDecoration(
                                hintText: t(
                                  builderContext,
                                  'auth.email_login',
                                  uk: 'Email / Логін',
                                  en: 'Email / Login',
                                  de: 'E-Mail / Login',
                                  ru: 'Email / Логин',
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 14,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                filled: true,
                                fillColor: const Color(0xFF091C30).withValues(alpha: 0.75),
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(left: 12, right: 10),
                                  child: const Icon(
                                    LucideIcons.mail,
                                    color: Color(0xFF00E5FF),
                                    size: 20,
                                  ),
                                ),
                                suffixIcon: emailController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          LucideIcons.circleX,
                                          color: Colors.white.withValues(alpha: 0.45),
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          emailController.clear();
                                          setModalState(() {});
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00E5FF),
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Password input
                            TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => submitLogin(),
                              decoration: InputDecoration(
                                hintText: t(
                                  builderContext,
                                  'auth.password',
                                  uk: 'Пароль',
                                  en: 'Password',
                                  de: 'Passwort',
                                  ru: 'Пароль',
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 14,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                filled: true,
                                fillColor: const Color(0xFF091C30).withValues(alpha: 0.75),
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(left: 12, right: 10),
                                  child: const Icon(
                                    LucideIcons.lock,
                                    color: Color(0xFF00E5FF),
                                    size: 20,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00E5FF),
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Forgot Password Row -> Opens PasswordRecoveryScreen with Admin
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00E5FF),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  final email = emailController.text.trim();
                                  Navigator.of(modalContext).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PasswordRecoveryScreen(initialLogin: email),
                                    ),
                                  );
                                },
                                icon: const Icon(LucideIcons.keyRound, size: 14),
                                label: Text(
                                  t(
                                    builderContext,
                                    'auth.forgot_password',
                                    uk: 'Забули пароль?',
                                    en: 'Forgot password?',
                                    de: 'Passwort vergessen?',
                                    ru: 'Забыли пароль?',
                                  ),
                                  style: TextStyle(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Submit Button
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00E5FF),
                                    Color(0xFF0072FF),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
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
                                onPressed: isModalLoading ? null : submitLogin,
                                child: isModalLoading
                                    ? const PremiumLoadingIndicator(
                                        size: 26,
                                        color: Colors.white,
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            LucideIcons.logIn,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            t(
                                              builderContext,
                                              'auth.login_action',
                                              uk: 'УВІЙТИ',
                                              en: 'LOG IN',
                                              de: 'ANMELDEN',
                                              ru: 'ВОЙТИ',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(reverse: true),
                            )
                            .shimmer(
                              duration: 2500.ms,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
