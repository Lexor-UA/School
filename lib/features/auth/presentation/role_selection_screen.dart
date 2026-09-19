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
    final prefs = ref.read(swimming_school_app.sharedPrefsProvider);
    final needsOnboarding = prefs.getBool('needsOnboarding') ?? false;

    if (role == UserRole.parent && user != null && (user.phone == null || needsOnboarding)) {
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
        // Dismiss any open modal bottom sheet or dialog on root navigator first
        final rootNav = Navigator.of(context, rootNavigator: true);
        if (rootNav.canPop()) {
          rootNav.pop();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateBasedOnRole(next.role, next);
          }
        });
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
                                                if (!context.mounted) return;
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

                                // Primary Client Hub Login Button
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
                                  onPressed: () => _showClientAuthModal(context, ref, initialTab: 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        LucideIcons.logIn,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'auth.tab_login'.tr().isNotEmpty &&
                                                !'auth.tab_login'.tr().startsWith('auth.')
                                            ? 'auth.tab_login'.tr()
                                            : 'Увійти',
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

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Isolated Staff Access Portal Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.85),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    onPressed: () => _showStaffLoginModal(context, ref),
                    icon: const Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF00E5FF)),
                    label: Text(
                      'auth.staff_portal'.tr().isNotEmpty && !'auth.staff_portal'.tr().startsWith('auth.')
                          ? 'auth.staff_portal'.tr()
                          : '🔐 Вхід для співробітників (Команда)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 3600.ms, duration: 1000.ms),
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

  void _showClientAuthModal(BuildContext context, WidgetRef ref, {int initialTab = 0}) {
    final loginController = TextEditingController();
    final loginPasswordController = TextEditingController();

    final regNameController = TextEditingController();
    final regLoginController = TextEditingController();
    final regPasswordController = TextEditingController();

    int activeTab = initialTab;
    bool isModalLoading = false;
    bool obscureLoginPassword = true;
    bool obscureRegPassword = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext builderContext, StateSetter setModalState) {
            Future<void> submitLogin() async {
              final login = loginController.text.trim();
              final password = loginPasswordController.text.trim();
              if (login.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Будь ласка, заповніть усі поля для входу'),
                    backgroundColor: Colors.amber.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }

              try {
                setModalState(() => isModalLoading = true);
                final notifier = ref.read(authControllerProvider.notifier);
                await notifier.signInWithEmail(login, password);
              } catch (e) {
                if (modalContext.mounted) {
                  setModalState(() => isModalLoading = false);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Помилка входу: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            }

            Future<void> submitRegister() async {
              final name = regNameController.text.trim();
              final login = regLoginController.text.trim();
              final password = regPasswordController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Введіть ваше ім'я та прізвище"),
                    backgroundColor: Colors.amber.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }

              if (login.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Введіть логін'),
                    backgroundColor: Colors.amber.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }

              if (password.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Пароль має містити щонайменше 4 символи'),
                    backgroundColor: Colors.amber.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }

              try {
                setModalState(() => isModalLoading = true);
                final notifier = ref.read(authControllerProvider.notifier);
                await notifier.registerParentWithPhoneOrEmail(
                  name: name,
                  phone: login,
                  password: password,
                );
              } catch (e) {
                if (modalContext.mounted) {
                  setModalState(() => isModalLoading = false);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Помилка реєстрації: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            }

            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(34),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0D223B).withValues(alpha: 0.97),
                          const Color(0xFF06111D).withValues(alpha: 0.99),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          blurRadius: 36,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Glowing Oceanic Drag Handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Top bar: Segmented tabs & Close button
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.all(3.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.14),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (activeTab != 0) {
                                                setModalState(() => activeTab = 0);
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 220),
                                              curve: Curves.easeOutCubic,
                                              decoration: BoxDecoration(
                                                gradient: activeTab == 0
                                                    ? const LinearGradient(
                                                        colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                                                      )
                                                    : null,
                                                borderRadius: BorderRadius.circular(18),
                                                boxShadow: activeTab == 0
                                                    ? [
                                                        BoxShadow(
                                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                                          blurRadius: 8,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    LucideIcons.logIn,
                                                    size: 15,
                                                    color: activeTab == 0 ? Colors.white : Colors.white60,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'auth.tab_login'.tr().isNotEmpty && !'auth.tab_login'.tr().startsWith('auth.')
                                                        ? 'auth.tab_login'.tr()
                                                        : 'Увійти',
                                                    style: TextStyle(
                                                      color: activeTab == 0 ? Colors.white : Colors.white60,
                                                      fontSize: 13.5,
                                                      fontWeight: activeTab == 0 ? FontWeight.bold : FontWeight.w600,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (activeTab != 1) {
                                                setModalState(() => activeTab = 1);
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 220),
                                              curve: Curves.easeOutCubic,
                                              decoration: BoxDecoration(
                                                gradient: activeTab == 1
                                                    ? const LinearGradient(
                                                        colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                                                      )
                                                    : null,
                                                borderRadius: BorderRadius.circular(18),
                                                boxShadow: activeTab == 1
                                                    ? [
                                                        BoxShadow(
                                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                                          blurRadius: 8,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    LucideIcons.userPlus,
                                                    size: 15,
                                                    color: activeTab == 1 ? Colors.white : Colors.white60,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'auth.tab_register'.tr().isNotEmpty && !'auth.tab_register'.tr().startsWith('auth.')
                                                        ? 'auth.tab_register'.tr()
                                                        : 'Реєстрація',
                                                    style: TextStyle(
                                                      color: activeTab == 1 ? Colors.white : Colors.white60,
                                                      fontSize: 13.5,
                                                      fontWeight: activeTab == 1 ? FontWeight.bold : FontWeight.w600,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(LucideIcons.x, size: 20, color: Colors.white70),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(7),
                                  ),
                                  onPressed: () => Navigator.of(modalContext).pop(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // FORM BODY WITH SMOOTH SIZE & FADE ANIMATIONS
                            AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: activeTab == 0
                                    ? KeyedSubtree(
                                        key: const ValueKey<int>(0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Login or Phone
                                            TextField(
                                              controller: loginController,
                                              style: const TextStyle(color: Colors.white, fontSize: 14.5),
                                              keyboardType: TextInputType.text,
                                              autocorrect: false,
                                              textInputAction: TextInputAction.next,
                                              decoration: _modalInputDecoration(
                                                hintText: 'Логін',
                                                prefixIcon: LucideIcons.userCheck,
                                                suffixIcon: loginController.text.isNotEmpty
                                                    ? IconButton(
                                                        icon: Icon(LucideIcons.circleX, color: Colors.white.withValues(alpha: 0.5), size: 18),
                                                        onPressed: () {
                                                          loginController.clear();
                                                          setModalState(() {});
                                                        },
                                                      )
                                                    : null,
                                              ),
                                              onChanged: (_) => setModalState(() {}),
                                            ),

                                            const SizedBox(height: 12),

                                            // Password
                                            TextField(
                                              controller: loginPasswordController,
                                              obscureText: obscureLoginPassword,
                                              style: const TextStyle(color: Colors.white, fontSize: 14.5),
                                              textInputAction: TextInputAction.done,
                                              onSubmitted: (_) => submitLogin(),
                                              decoration: _modalInputDecoration(
                                                hintText: 'Пароль',
                                                prefixIcon: LucideIcons.lock,
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    obscureLoginPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                                    color: Colors.white.withValues(alpha: 0.65),
                                                    size: 19,
                                                  ),
                                                  onPressed: () {
                                                    setModalState(() => obscureLoginPassword = !obscureLoginPassword);
                                                  },
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            // Forgot password
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton.icon(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: const Color(0xFF00E5FF),
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                onPressed: () {
                                                  final initialLogin = loginController.text.trim();
                                                  Navigator.of(modalContext).pop();
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => PasswordRecoveryScreen(initialLogin: initialLogin),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(LucideIcons.keyRound, size: 13),
                                                label: const Text(
                                                  'Забули пароль?',
                                                  style: TextStyle(
                                                    color: Color(0xFF00E5FF),
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 14),

                                            // Login Submit Button
                                            _buildSubmitButton(
                                              title: 'Увійти',
                                              icon: LucideIcons.logIn,
                                              isLoading: isModalLoading,
                                              onPressed: submitLogin,
                                            ),
                                          ],
                                        ),
                                      )
                                    : KeyedSubtree(
                                        key: const ValueKey<int>(1),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Full Name
                                            TextField(
                                              controller: regNameController,
                                              textCapitalization: TextCapitalization.words,
                                              style: const TextStyle(color: Colors.white, fontSize: 14.5),
                                              textInputAction: TextInputAction.next,
                                              decoration: _modalInputDecoration(
                                                hintText: "Ім'я та прізвище",
                                                prefixIcon: LucideIcons.user,
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            // Login (Phone, Email, or Username)
                                            TextField(
                                              controller: regLoginController,
                                              keyboardType: TextInputType.text,
                                              autocorrect: false,
                                              style: const TextStyle(color: Colors.white, fontSize: 14.5),
                                              textInputAction: TextInputAction.next,
                                              decoration: _modalInputDecoration(
                                                hintText: 'Логін',
                                                prefixIcon: LucideIcons.userCheck,
                                                suffixIcon: regLoginController.text.isNotEmpty
                                                    ? IconButton(
                                                        icon: Icon(LucideIcons.circleX, color: Colors.white.withValues(alpha: 0.5), size: 18),
                                                        onPressed: () {
                                                          regLoginController.clear();
                                                          setModalState(() {});
                                                        },
                                                      )
                                                    : null,
                                              ),
                                              onChanged: (_) => setModalState(() {}),
                                            ),

                                            const SizedBox(height: 12),

                                            // Password
                                            TextField(
                                              controller: regPasswordController,
                                              obscureText: obscureRegPassword,
                                              style: const TextStyle(color: Colors.white, fontSize: 14.5),
                                              textInputAction: TextInputAction.done,
                                              onSubmitted: (_) => submitRegister(),
                                              decoration: _modalInputDecoration(
                                                hintText: 'Пароль',
                                                prefixIcon: LucideIcons.lock,
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    obscureRegPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                                    color: Colors.white.withValues(alpha: 0.65),
                                                    size: 19,
                                                  ),
                                                  onPressed: () {
                                                    setModalState(() => obscureRegPassword = !obscureRegPassword);
                                                  },
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 18),

                                            // Register Submit Button
                                            _buildSubmitButton(
                                              title: 'Зареєструватися',
                                              icon: LucideIcons.userCheck,
                                              isLoading: isModalLoading,
                                              onPressed: submitRegister,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
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

  void _showStaffLoginModal(BuildContext context, WidgetRef ref) {
    final staffLoginController = TextEditingController();
    final staffPasswordController = TextEditingController();

    bool isStaffLoading = false;
    bool obscureStaffPassword = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext builderContext, StateSetter setModalState) {
            Future<void> submitStaffLogin() async {
              final login = staffLoginController.text.trim();
              final password = staffPasswordController.text.trim();
              if (login.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Введіть службовий логін та пароль'),
                    backgroundColor: Colors.amber.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }

              try {
                setModalState(() => isStaffLoading = true);
                final notifier = ref.read(authControllerProvider.notifier);
                await notifier.signInWithEmail(login, password);
              } catch (e) {
                if (modalContext.mounted) {
                  setModalState(() => isStaffLoading = false);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Помилка службового входу: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            }

            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(34),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF141F32).withValues(alpha: 0.98),
                          const Color(0xFF090E18).withValues(alpha: 0.99),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.12),
                          blurRadius: 36,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Glowing Amber Handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFB300), Color(0xFFE65100)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Header row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.shieldAlert,
                                    color: Color(0xFFFFB300),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PORTAL ДЛЯ КОМАНДИ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Тренери • Адміністрація • Власник',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
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
                                    padding: const EdgeInsets.all(7),
                                  ),
                                  onPressed: () => Navigator.of(modalContext).pop(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Staff Login Input
                            TextField(
                              controller: staffLoginController,
                              style: const TextStyle(color: Colors.white, fontSize: 14.5),
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: _modalInputDecoration(
                                hintText: 'Робочий логін (admin, coach...) або email',
                                prefixIcon: LucideIcons.badgeCheck,
                                accentColor: const Color(0xFFFFB300),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Staff Password Input
                            TextField(
                              controller: staffPasswordController,
                              obscureText: obscureStaffPassword,
                              style: const TextStyle(color: Colors.white, fontSize: 14.5),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => submitStaffLogin(),
                              decoration: _modalInputDecoration(
                                hintText: 'Службовий пароль',
                                prefixIcon: LucideIcons.keyRound,
                                accentColor: const Color(0xFFFFB300),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureStaffPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    size: 19,
                                  ),
                                  onPressed: () {
                                    setModalState(() => obscureStaffPassword = !obscureStaffPassword);
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Notice
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.info, size: 14, color: Colors.amber.withValues(alpha: 0.8)),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Вхід лише для співробітників за робочими обліковими записами.',
                                      style: TextStyle(color: Colors.white60, fontSize: 11.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Staff Submit Button
                            _buildSubmitButton(
                              title: 'СЛУЖБОВИЙ ВХІД',
                              icon: LucideIcons.logIn,
                              isLoading: isStaffLoading,
                              accentColors: const [Color(0xFFFFB300), Color(0xFFE65100)],
                              onPressed: submitStaffLogin,
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

  InputDecoration _modalInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    Color accentColor = const Color(0xFF00E5FF),
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.38),
        fontSize: 14,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(
          prefixIcon,
          color: accentColor,
          size: 19,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentColor, width: 1.6),
      ),
    );
  }

  Widget _buildSubmitButton({
    required String title,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
    List<Color> accentColors = const [Color(0xFF00E5FF), Color(0xFF0072FF)],
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: accentColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColors.first.withValues(alpha: 0.40),
            blurRadius: 18,
            offset: const Offset(0, 5),
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
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const PremiumLoadingIndicator(size: 24, color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
