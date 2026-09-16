import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';

import 'add_client_sheet.dart';
import 'payment_sheet.dart';
import 'chat_sheet.dart';
import 'create_class_sheet.dart';
import 'admin_clients_screen.dart';
import 'admin_calendar_screen.dart';
import 'admin_coaches_screen.dart';
import 'admin_global_search_sheet.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/admin/models/activity_log.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';

class AdminMain extends ConsumerStatefulWidget {
  const AdminMain({super.key});

  @override
  ConsumerState<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends ConsumerState<AdminMain> {
  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);
    final unreadCount = ref.watch(unreadAdminChatBadgeProvider);
    final currentTheme = ref.watch(appThemeControllerProvider);

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBg,
      body: Stack(
        children: [
          // 1. Full-fidelity animated water ripples
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),

          // 2. Fluid aquatic gradient overlay harmonized with active theme
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentTheme.bgGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Theme-tailored 3D animated water bubbles
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),

          // 3. Ambient volumetric glow orbs for soft, eye-friendly depth
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentTheme.orb1Color,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 360,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentTheme.orb2Color,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentTheme.orb3Color,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildAppBar(context, ref, dashboardState.recentActions),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                    child: _buildSearchBar().animate().fadeIn(delay: 100.ms).slideY(begin: 0.06),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Швидкі дії (3x2 ідеально збалансована сітка з 6 кнопок під пошуком)
                      _buildSectionTitle(
                        'admin.quick_actions'.tr(),
                        LucideIcons.zap,
                        currentTheme.accentPrimary,
                        gradientColors: currentTheme.accentGradient,
                      ),
                      const SizedBox(height: 10),
                      _buildQuickActions(context).animate().fadeIn(delay: 150.ms).slideY(begin: 0.06),
                      const SizedBox(height: 18),

                      // 2. Важливі повідомлення / Неоплачені абонементи (якщо є)
                      if (dashboardState.unpaidSubscriptions > 0) ...[
                        _buildSectionTitle(
                          'admin.needs_attention'.tr(),
                          LucideIcons.alertTriangle,
                          const Color(0xFFF43F5E),
                          gradientColors: const [Color(0xFFFB7185), Color(0xFFE11D48)],
                          badgeText: '${dashboardState.unpaidSubscriptions} ${'admin.debtors_short'.tr()}',
                          badgeColor: const Color(0xFFF43F5E),
                        ),
                        const SizedBox(height: 10),
                        _buildUnpaidAttentionItem(dashboardState.unpaidSubscriptions).animate().fadeIn(delay: 220.ms).slideY(begin: 0.06),
                        const SizedBox(height: 18),
                      ],

                      // 3. Пульс клубу (Телеметрія активності басейну в реальному часі)
                      _buildLivePulseBar(dashboardState).animate().fadeIn(delay: 300.ms).slideY(begin: 0.06),
                      const SizedBox(height: 18),

                      // 4. Центр підтримки клієнтів (швидкий перехід до чатів)
                      _buildSupportCenterCard(unreadCount).animate().fadeIn(delay: 380.ms).slideY(begin: 0.06),
                      const SizedBox(height: 20),

                      // 5. Найближче заняття з аватарками учнів
                      if (dashboardState.nearestClass != null) ...[
                        _buildSectionTitle(
                          'admin.nearest_class'.tr(),
                          LucideIcons.clock,
                          currentTheme.accentPrimary,
                          gradientColors: currentTheme.accentGradient,
                          badgeText: 'admin.today'.tr(),
                          badgeColor: currentTheme.accentPrimary,
                        ),
                        const SizedBox(height: 10),
                        _buildNearestClass(dashboardState.nearestClass!).animate().fadeIn(delay: 450.ms).slideY(begin: 0.06),
                        const SizedBox(height: 20),
                      ],

                      // Generous bottom buffer ensuring the entire screen can be scrolled comfortably above the home indicator
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 64),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color, {
    List<Color>? gradientColors,
    String? badgeText,
    Color? badgeColor,
    bool showTrailingLine = true,
  }) {
    final effectiveGradient = gradientColors ?? [
      color,
      color.withValues(alpha: 0.75),
    ];

    final currentTheme = ref.watch(appThemeControllerProvider);

    return Row(
      children: [
        // Glowing Jewel Emblem Squircle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: effectiveGradient,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveGradient.first.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        // Title Text
        Text(
          _capitalize(title),
          style: TextStyle(
            color: currentTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        // Optional Capsule Badge
        if (badgeText != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: currentTheme.isDark
                  ? (badgeColor ?? color).withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (badgeColor ?? color).withValues(alpha: currentTheme.isDark ? 0.40 : 0.50),
                width: 0.8,
              ),
              boxShadow: currentTheme.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: (badgeColor ?? color).withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor ?? (currentTheme.isDark ? Colors.white.withValues(alpha: 0.90) : color),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
        // Luminous Hairline
        if (showTrailingLine) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    currentTheme.isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                        : currentTheme.accentPrimary.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, List<ActivityLog> recentActions) {
    final user = ref.watch(authControllerProvider);
    final currentTheme = ref.watch(appThemeControllerProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const AvatarPicker(
                      heroTag: 'hero_avatar_Адміністраторам',
                      radius: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (user?.name != null &&
                                  user!.name.trim().isNotEmpty &&
                                  user.name.trim() != 'Admin' &&
                                  user.name.trim() != 'Адміністратор')
                              ? 'admin.welcome_admin'.tr(namedArgs: {'name': user.name.trim()})
                              : '${'admin.hello'.tr()} 👋',
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF10B981),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'CitySwim Admin',
                                style: TextStyle(
                                  color: currentTheme.accentSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            ),
            // Right actions: Theme Switcher, History log & Logout buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThemeHeaderButton(size: 40),
                const SizedBox(width: 8),
                _buildActivityLogHeaderButton(context, recentActions, currentTheme),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: currentTheme.isDark
                        ? const Color(0xFFEF4444).withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentTheme.isDark
                          ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                          : Colors.redAccent.withValues(alpha: 0.30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (currentTheme.isDark ? const Color(0xFFEF4444) : Colors.black)
                            .withValues(alpha: currentTheme.isDark ? 0.18 : 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                    icon: Icon(
                      LucideIcons.logOut,
                      color: currentTheme.isDark ? const Color(0xFFF87171) : Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: 'parent.logout_short'.tr(),
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                      context.go('/');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogHeaderButton(
    BuildContext context,
    List<ActivityLog> recentActions,
    AppThemeConfig currentTheme,
  ) {
    final now = DateTime.now();
    final hasRecentToday = recentActions.any((a) =>
        a.timestamp.isAfter(now.subtract(const Duration(hours: 24))) ||
        (a.timestamp.year == now.year && a.timestamp.month == now.month && a.timestamp.day == now.day));

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: currentTheme.isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(
          color: currentTheme.isDark
              ? Colors.white.withValues(alpha: 0.20)
              : currentTheme.accentPrimary.withValues(alpha: 0.30),
        ),
        boxShadow: currentTheme.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                ),
              ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: Icon(
              LucideIcons.history,
              color: currentTheme.accentPrimary,
              size: 20,
            ),
            tooltip: 'admin.recent_actions'.tr(),
            onPressed: () => _showRecentActionsSheet(context, recentActions),
          ),
          if (hasRecentToday)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 7.5,
                height: 7.5,
                decoration: BoxDecoration(
                  color: currentTheme.accentPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentTheme.isDark ? const Color(0xFF0F1E36) : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentTheme.accentPrimary.withValues(alpha: 0.7),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openGlobalSearch({int initialCategoryIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminGlobalSearchSheet(initialCategoryIndex: initialCategoryIndex),
    );
  }

  Widget _buildSearchBar() {
    final currentTheme = ref.watch(appThemeControllerProvider);

    return GestureDetector(
      onTap: () => _openGlobalSearch(initialCategoryIndex: 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: currentTheme.isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B385C).withValues(alpha: 0.75),
                    const Color(0xFF102640).withValues(alpha: 0.80),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFF8FAFC),
                  ],
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: currentTheme.isDark
                ? const Color(0xFF38BDF8).withValues(alpha: 0.30)
                : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
          boxShadow: [
            if (currentTheme.isDark) ...[
              // Layer 1: Deep cyan-tinted shadow
              BoxShadow(
                color: const Color(0xFF003B73).withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ] else ...[
              // Premium glassmorphism shadow
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
                blurRadius: 12,
              ),
            ]
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: currentTheme.isDark
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                          : const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentTheme.isDark
                            ? Colors.transparent
                            : const Color(0xFFBAE6FD),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.search,
                        color: currentTheme.accentPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'admin.search_hint'.tr().replaceFirst('групи чи ', '').replaceFirst('группы или ', '').replaceFirst('group or ', '').replaceFirst('Gruppe oder ', ''),
                      style: TextStyle(
                        color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openGlobalSearch(initialCategoryIndex: 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentTheme.isDark
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: currentTheme.isDark
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                              : const Color(0xFFBAE6FD),
                          width: 1.1,
                        ),
                        boxShadow: currentTheme.isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.slidersHorizontal,
                            color: currentTheme.accentPrimary,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'admin.filter_btn'.tr(),
                            style: TextStyle(
                              color: currentTheme.accentPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPulseBeaconTitle(bool isSessionActive) {
    if (isSessionActive) {
      return 'admin.live_beacon_active'.tr();
    }
    final raw = 'admin.live_beacon_idle'.tr();
    final upper = raw.toUpperCase();
    if (upper.contains('ПУЛЬС КЛУБУ')) {
      return 'ПУЛЬС КЛУБУ';
    }
    if (upper.contains('ПУЛЬС КЛУБА')) {
      return 'ПУЛЬС КЛУБА';
    }
    if (upper.contains('CLUB PULSE')) {
      return 'CLUB PULSE';
    }
    if (upper.contains('CLUB-PULS')) {
      return 'CLUB-PULS';
    }
    return raw.split(RegExp(r'[\s·•\-\|\:\.]+онлайн|online', caseSensitive: false)).first.trim();
  }

  // ==========================================
  // 1. LIVE TELEMETRY STATUS BAR (HUD ІЗЮМИНКА)
  // ==========================================
  Widget _buildLivePulseBar(AdminDashboardState state) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final bool isSessionActive = state.ongoingClassesCount > 0;

    // 1. Скільки активних занять зараз проводяться
    final int classesValue = state.ongoingClassesCount;

    // 2. Скільки клієнтів займаються зараз
    final int clientsValue = isSessionActive ? state.ongoingClientsCount : state.activeClientsCount;

    // 3. Скільки тренерів працюють зараз
    final int coachesValue = isSessionActive ? state.ongoingCoachesCount : state.totalCoachesCount;

    return Container(
      decoration: BoxDecoration(
        color: currentTheme.glassCardBg,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  const Color(0xFF0284C7).withValues(alpha: 0.14),
                  const Color(0xFF031933).withValues(alpha: 0.40),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.65),
                  Colors.white.withValues(alpha: 0.45),
                ],
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.30)
              : currentTheme.cardBorder,
          width: isDark ? 1.2 : 0.8,
        ),
        boxShadow: [
          if (isDark) ...[
            // Layer 1: Deep accent shadow
            BoxShadow(
              color: const Color(0xFF003B73).withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ] else ...[
            // Minimalist iOS style soft shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ]
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Live Beacon Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Live breathing neon beacon
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSessionActive
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isSessionActive
                                          ? const Color(0xFF10B981)
                                          : (isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary))
                                      .withValues(alpha: 0.85),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatPulseBeaconTitle(isSessionActive),
                                style: TextStyle(
                                  color: isSessionActive
                                      ? const Color(0xFF059669)
                                      : currentTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          if (isSessionActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.40),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'admin.live_badge'.tr(),
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.18)
                              : currentTheme.cardBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.activity, color: currentTheme.accentPrimary, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            'admin.realtime'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white70 : currentTheme.textSecondary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Luminous Hairline Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.15),
                              const Color(0xFF38BDF8).withValues(alpha: 0.35),
                              Colors.white.withValues(alpha: 0.15),
                              Colors.transparent,
                            ]
                          : [
                              Colors.transparent,
                              currentTheme.cardBorder,
                              currentTheme.cardBorder,
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),

                // 3 Telemetry Columns (Spacious, elegant high-end vertical readout)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // 1. Активні заняття
                      Expanded(
                        child: _buildTelemetryColumn(
                          icon: LucideIcons.calendarClock,
                          gradientColors: isDark
                              ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                              : currentTheme.actionCardGradients[1],
                          accentColor: isDark
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF0284C7),
                          title: 'admin.classes_telemetry'.tr(),
                          value: '$classesValue',
                          status: 'admin.classes_status'.tr(),
                        ),
                      ),

                      // Vertical Divider 1
                      Container(
                        width: 1,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    Colors.transparent,
                                    const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                    Colors.transparent,
                                  ]
                                : [
                                    Colors.transparent,
                                    currentTheme.cardBorder,
                                    Colors.transparent,
                                  ],
                          ),
                        ),
                      ),

                      // 2. Клієнти
                      Expanded(
                        child: _buildTelemetryColumn(
                          icon: LucideIcons.users,
                          gradientColors: isDark
                              ? const [Color(0xFF10B981), Color(0xFF059669)]
                              : currentTheme.actionCardGradients[0],
                          accentColor: isDark
                              ? const Color(0xFF10B981)
                              : const Color(0xFF059669),
                          title: 'admin.clients_telemetry'.tr(),
                          value: '$clientsValue',
                          status: 'admin.clients_status'.tr(),
                        ),
                      ),

                      // Vertical Divider 2
                      Container(
                        width: 1,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    Colors.transparent,
                                    const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                    Colors.transparent,
                                  ]
                                : [
                                    Colors.transparent,
                                    currentTheme.cardBorder,
                                    Colors.transparent,
                                  ],
                          ),
                        ),
                      ),

                      // 3. Тренери
                      Expanded(
                        child: _buildTelemetryColumn(
                          icon: LucideIcons.award,
                          gradientColors: isDark
                              ? const [Color(0xFFA855F7), Color(0xFF7C3AED)]
                              : currentTheme.actionCardGradients[2],
                          accentColor: isDark
                              ? const Color(0xFFA855F7)
                              : const Color(0xFF7C3AED),
                          title: 'admin.coaches_telemetry'.tr(),
                          value: '$coachesValue',
                          status: 'admin.coaches_status'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Contextual Micro-Strip (Subtle Immersion Bar)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : currentTheme.cardBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSessionActive
                            ? LucideIcons.waves
                            : (state.nearestClass != null ? LucideIcons.clock : LucideIcons.shieldCheck),
                        size: 14,
                        color: isSessionActive ? const Color(0xFF059669) : currentTheme.accentPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSessionActive
                              ? 'admin.in_pool_now_desc'.tr(args: [
                                  _formatCompactClassTitle(state.ongoingClasses.first.title),
                                  state.ongoingClientsCount.toString(),
                                ])
                              : (state.nearestClass != null
                                  ? 'admin.nearest_class_at'.tr(args: [
                                      DateFormat('HH:mm').format(state.nearestClass!.startTime),
                                      _formatCompactClassTitle(state.nearestClass!.title),
                                    ])
                                  : 'admin.normal_mode'.tr()),
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : currentTheme.statusActiveBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                : currentTheme.statusActiveBadgeText.withValues(alpha: 0.35),
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '●',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF059669) : currentTheme.statusActiveBadgeText,
                                fontSize: 7,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'admin.normal_badge'.tr(),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF059669) : currentTheme.statusActiveBadgeText,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCompactClassTitle(String title) {
    var cleaned = title.trim();
    if (cleaned.toLowerCase().contains('доросла') || cleaned.toLowerCase().contains('дорослих')) {
      return 'Доросла група';
    }
    if (cleaned.toLowerCase().contains('дитяч') || cleaned.toLowerCase().contains('дітей')) {
      return 'Дитяча група';
    }
    cleaned = cleaned.replaceFirst(RegExp(r'^(Групові|Індивідуальні)\s+заняття\s+(для\s+)?', caseSensitive: false), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^(Групове|Індивідуальне)\s+тренування\s+(для\s+)?', caseSensitive: false), '');
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    return cleaned.isEmpty ? title : cleaned;
  }

  String _cleanCoachDisplay(String coachName) {
    var name = coachName.trim();
    if (name.toLowerCase().startsWith('тренер ')) {
      name = name.substring(7).trim();
    } else if (name.toLowerCase().startsWith('coach ')) {
      name = name.substring(6).trim();
    }
    return name.isEmpty ? coachName : name;
  }

  Widget _buildTelemetryColumn({
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    required String title,
    required String value,
    required String status,
  }) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Squircle Jewel Icon Badge (38x38) with glowing aura
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: isDark ? 0.45 : 0.28),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
        const SizedBox(height: 8),

        // Big Precision Telemetry Value
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : currentTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.0,
              shadows: [
                if (isDark)
                  Shadow(
                    color: accentColor.withValues(alpha: 0.45),
                    blurRadius: 12,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Category Name
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : currentTheme.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 3),

        // Refined Live Status Subtitle (accent colored)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            status,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: accentColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }


  // ==========================================
  // 2. ЦЕНТР ПІДТРИМКИ КЛІЄНТІВ (КРИШТАЛЕВА АЕРО-КАРТКА)
  // ==========================================
  Widget _buildSupportCenterCard(int unreadCount) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final bool hasUnread = unreadCount > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ChatSheet(),
              );
            },
            borderRadius: BorderRadius.circular(22),
            splashColor: const Color(0xFF38BDF8).withValues(alpha: 0.20),
            highlightColor: const Color(0xFF38BDF8).withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: hasUnread ? 0.24 : 0.16),
                          Colors.white.withValues(alpha: hasUnread ? 0.12 : 0.06),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: hasUnread ? 0.85 : 0.65),
                          Colors.white.withValues(alpha: hasUnread ? 0.60 : 0.45),
                        ],
                      ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: hasUnread
                      ? (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.85) : currentTheme.accentPrimary.withValues(alpha: 0.5))
                      : (isDark ? Colors.white.withValues(alpha: 0.28) : currentTheme.cardBorder),
                  width: isDark ? 1.2 : 1.0,
                ),
                boxShadow: [
                  if (isDark) ...[
                    // Layer 1: Deep accent elevation
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                    if (hasUnread)
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 2),
                      ),
                  ] else ...[
                    // Minimalist iOS style soft shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                ],
              ),
              child: Row(
                children: [
                  // Glowing Squircle badge with headset icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF00D2FF),
                          Color(0xFF0077B6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B4D8).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(LucideIcons.headset, color: Colors.white, size: 22),
                        if (hasUnread)
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF43F5E),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFF43F5E),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'admin.support_center'.tr(),
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasUnread
                              ? 'admin.new_messages_count'.tr(args: [unreadCount.toString()])
                              : 'admin.quick_answers'.tr(),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Right badge or arrow
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B4D8).withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '+$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.20)
                              : Colors.white,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.chevronRight,
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnpaidAttentionItem(int unpaidCount) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const PaymentSheet(initialTabIndex: 1),
              );
            },
            borderRadius: BorderRadius.circular(18),
            splashColor: const Color(0xFFF43F5E).withValues(alpha: 0.20),
            highlightColor: const Color(0xFFF43F5E).withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          const Color(0xFFF43F5E).withValues(alpha: 0.22),
                          const Color(0xFF0F1E32).withValues(alpha: 0.45),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.90),
                          const Color(0xFFFFF1F2).withValues(alpha: 0.75),
                        ],
                      ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFFFECDD3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.28 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.45 : 0.32),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.creditCard, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFFF43F5E).withValues(alpha: 0.25)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.5 : 0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'admin.attention'.tr(),
                                style: const TextStyle(
                                  color: Color(0xFFE11D48),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                unpaidCount == 1
                                    ? '1 неоплачений абонемент'
                                    : (unpaidCount >= 2 && unpaidCount <= 4)
                                        ? '$unpaidCount неоплачені абонементи'
                                        : '$unpaidCount неоплачених абонементів',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF9F1239),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'admin.awaiting_payment_desc'.tr(),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFFB7185).withValues(alpha: 0.45),
                        width: 0.9,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.chevronRight,
                        color: isDark ? Colors.white : const Color(0xFFE11D48),
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. ШВИДКІ ДІЇ (КРИШТАЛЕВИЙ BENTO-БЛОК ДІЙ)
  // ==========================================
  Widget _buildQuickActions(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final gradients = currentTheme.actionCardGradients;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        final columns = isWide ? 3 : 2;
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _InteractiveActionCard(
                icon: LucideIcons.users,
                label: _capitalize('admin.create'.tr()),
                sublabel: 'admin.sub_group'.tr(),
                accentColor: gradients[0].first,
                gradientColors: gradients[0],
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CreateClassSheet(),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InteractiveActionCard(
                icon: LucideIcons.calendar,
                label: _capitalize('admin.calendar'.tr()),
                sublabel: 'admin.sub_schedule'.tr(),
                accentColor: gradients[1].first,
                gradientColors: gradients[1],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminCalendarScreen()),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InteractiveActionCard(
                icon: LucideIcons.users,
                label: _capitalize('admin.clients_menu'.tr()),
                sublabel: 'admin.sub_base'.tr(),
                accentColor: gradients[2].first,
                gradientColors: gradients[2],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminClientsScreen()),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InteractiveActionCard(
                icon: LucideIcons.userPlus,
                label: _capitalize('admin.new_client'.tr()),
                sublabel: 'admin.sub_profile'.tr(),
                accentColor: gradients[3].first,
                gradientColors: gradients[3],
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddClientSheet(),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InteractiveActionCard(
                icon: LucideIcons.award,
                label: _capitalize('admin.coaches_menu'.tr()),
                sublabel: 'admin.sub_team'.tr(),
                accentColor: gradients[4].first,
                gradientColors: gradients[4],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminCoachesScreen()),
                  );
                },
              ),
            ),
            // 6-та кнопка: Оплата / Каса
            SizedBox(
              width: itemWidth,
              child: _InteractiveActionCard(
                icon: LucideIcons.creditCard,
                label: _capitalize('admin.payment'.tr()),
                sublabel: 'admin.sub_cash'.tr(),
                accentColor: gradients[5].first,
                gradientColors: gradients[5],
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const PaymentSheet(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatStudentsCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return '$count учень';
    } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return '$count учні';
    } else {
      return '$count учнів';
    }
  }

  // ==========================================
  // 4. НАЙБЛИЖЧЕ ЗАНЯТТЯ З АВАТАРКАМИ УЧНІВ
  // ==========================================
  Widget _buildNearestClass(GroupClass nearest) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final timeFormat = DateFormat('HH:mm');
    final startTimeStr = timeFormat.format(nearest.startTime);
    final endTimeStr = timeFormat.format(nearest.endTime);
    final occupancy = nearest.enrolledChildIds.length;
    final maxCapacity = nearest.maxCapacity;
    final percent = maxCapacity > 0 ? (occupancy / maxCapacity).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: currentTheme.glassCardBg,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF003B73), Color(0xFF006DAE), Color(0xFF00B4D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.88),
                  Colors.white.withValues(alpha: 0.72),
                ],
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.95),
          width: isDark ? 1.2 : 1.0,
        ),
        boxShadow: [
          if (isDark) ...[
            // Layer 1: Deep accent shadow
            BoxShadow(
              color: const Color(0xFF003B73).withValues(alpha: 0.40),
              blurRadius: 22,
              offset: const Offset(0, 7),
            ),
          ] else ...[
            // Minimalist iOS style soft shadow
            BoxShadow(
              color: currentTheme.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: currentTheme.accentPrimary.withValues(alpha: 0.05),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ]
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Time + Compact Category Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.20)
                            : currentTheme.accentPrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : currentTheme.accentPrimary.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clock, color: isDark ? Colors.white : currentTheme.accentPrimary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '$startTimeStr – $endTimeStr',
                            style: TextStyle(
                              color: isDark ? Colors.white : currentTheme.accentPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.40)
                                : currentTheme.cardBorder,
                            width: 0.8,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatCompactClassTitle(nearest.title),
                            style: TextStyle(
                              color: isDark ? Colors.white : currentTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Location and Coach (Adaptive Wrap with zero ellipsis!)
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : currentTheme.cardBorder,
                          width: 0.8,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            color: isDark ? Colors.white : currentTheme.accentPrimary,
                            size: 13.5,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            nearest.lane.isNotEmpty ? nearest.lane : 'Всі доріжки',
                            style: TextStyle(
                              color: isDark ? Colors.white : currentTheme.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : currentTheme.cardBorder,
                          width: 0.8,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.user,
                            color: isDark ? Colors.white70 : currentTheme.accentPrimary,
                            size: 13.5,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${'admin.class_coach'.tr()}: ${_cleanCoachDisplay(nearest.coachName)}',
                            style: TextStyle(
                              color: isDark ? Colors.white : currentTheme.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Capacity Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Заповненість групи',
                      style: TextStyle(
                        color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$occupancy / ${_formatStudentsCount(maxCapacity)}',
                      style: TextStyle(
                        color: isDark ? Colors.white : currentTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Premium gradient progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [Colors.white, Colors.white.withValues(alpha: 0.85)]
                                : currentTheme.accentGradient,
                          ),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Student Facepile (Аватарки учнів, що підтягуються від клієнта)
                if (nearest.enrolledChildIds.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildEnrolledFacepile(nearest.enrolledChildIds, isDark),
                      const SizedBox(width: 10),
                      Text(
                        '${'admin.enrolled_swimmers'.tr()} (${nearest.enrolledChildIds.length})',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : currentTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 18),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? null
                          : LinearGradient(
                              colors: currentTheme.accentGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF003B73) : currentTheme.accentPrimary).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminCalendarScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.transparent,
                        foregroundColor: isDark ? const Color(0xFF003B73) : Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.calendar, size: 16, color: isDark ? const Color(0xFF003B73) : Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'admin.open_in_schedule'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? const Color(0xFF003B73) : Colors.white,
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
      ),
    );
  }

  Widget _buildEnrolledFacepile(List<String> childIds, bool isDark) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final displayIds = childIds.take(4).toList();
    final remainingCount = childIds.length - displayIds.length;

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < displayIds.length; i++)
            Transform.translate(
              offset: Offset(i * -8.0, 0),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF003B73) : Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : currentTheme.cardShadow).withValues(alpha: 0.20),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(displayIds[i])
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final avatarUrl = data?['avatarUrl'] as String?;
                    final rawName = data?['name'] as String? ?? '';
                    final cleanName = (rawName.trim().isEmpty || rawName.trim().toLowerCase() == 'user') ? 'Учень' : rawName.trim();

                    final parts = cleanName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
                    final initials = parts.length >= 2
                        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                        : (cleanName.length >= 2 ? cleanName.substring(0, 2).toUpperCase() : cleanName.toUpperCase());

                    final hash = displayIds[i].hashCode.abs();
                    final gradient = currentTheme.actionCardGradients[hash % currentTheme.actionCardGradients.length];

                    if (avatarUrl != null &&
                        avatarUrl.isNotEmpty &&
                        avatarUrl.startsWith('http') &&
                        !avatarUrl.contains('ui-avatars.com')) {
                      return CircleAvatar(
                        radius: 13,
                        backgroundImage: NetworkImage(avatarUrl),
                        backgroundColor: Colors.white24,
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (remainingCount > 0)
            Transform.translate(
              offset: Offset(displayIds.length * -8.0, 0),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF003B73) : Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }



  // ==========================================
  // ІСТОРІЯ ОСТАННІХ ДІЙ (MODAL BOTTOM SHEET)
  // ==========================================
  void _showRecentActionsSheet(BuildContext context, List<ActivityLog> actions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdminActivityLogSheet(actions: actions),
    );
  }
}

// ==========================================
// ЖУРНАЛ АКТИВНОСТЕЙ АДМІНІСТРАТОРА (ДЕНЬ / ТИЖДЕНЬ / МІСЯЦЬ)
// ==========================================
enum _ActivityPeriod { day, week, month }

class _AdminActivityLogSheet extends ConsumerStatefulWidget {
  final List<ActivityLog> actions;

  const _AdminActivityLogSheet({
    required this.actions,
  });

  @override
  ConsumerState<_AdminActivityLogSheet> createState() => _AdminActivityLogSheetState();
}

class _AdminActivityLogSheetState extends ConsumerState<_AdminActivityLogSheet> {
  _ActivityPeriod _selectedPeriod = _ActivityPeriod.day;

  IconData _getActionIcon(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('абонемент') || lower.contains('абон')) {
      return LucideIcons.creditCard;
    }
    if (lower.contains('учен') || lower.contains('клієнт') || lower.contains('дитин')) {
      return LucideIcons.userCheck;
    }
    if (lower.contains('тренер') || lower.contains('інструктор')) {
      return LucideIcons.award;
    }
    if (lower.contains('заняття') || lower.contains('тренуван') || lower.contains('розклад')) {
      return LucideIcons.calendar;
    }
    if (lower.contains('оплат') || lower.contains('чек') || lower.contains('грн') || lower.contains('грош')) {
      return LucideIcons.wallet;
    }
    if (lower.contains('видален') || lower.contains('скасув')) {
      return LucideIcons.trash2;
    }
    return LucideIcons.activity;
  }

  Color _getActionColor(String action, AppThemeConfig currentTheme) {
    final lower = action.toLowerCase();
    if (lower.contains('видален') || lower.contains('скасув')) {
      return const Color(0xFFF43F5E);
    }
    if (lower.contains('оплат') || lower.contains('чек') || lower.contains('грн')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('абонемент')) {
      return const Color(0xFF38BDF8);
    }
    if (lower.contains('тренер')) {
      return const Color(0xFFF59E0B);
    }
    if (lower.contains('учен') || lower.contains('клієнт')) {
      return const Color(0xFF8B5CF6);
    }
    return currentTheme.accentPrimary;
  }

  String _formatActionTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Щойно';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${'admin.mins_ago'.tr()}';
    } else if (diff.inHours < 24 && timestamp.day == now.day) {
      return '${'admin.today'.tr()}, ${DateFormat('HH:mm').format(timestamp)}';
    } else if (diff.inHours < 48 && timestamp.day == now.subtract(const Duration(days: 1)).day) {
      return 'Вчора, ${DateFormat('HH:mm').format(timestamp)}';
    } else if (timestamp.year == now.year) {
      return DateFormat('d MMM, HH:mm', 'uk').format(timestamp);
    } else {
      return DateFormat('dd.MM.yyyy, HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    final now = DateTime.now();
    final dayCutoff = now.subtract(const Duration(hours: 24));
    final weekCutoff = now.subtract(const Duration(days: 7));
    final monthCutoff = now.subtract(const Duration(days: 30));

    final dayActions = widget.actions.where((a) =>
        a.timestamp.isAfter(dayCutoff) ||
        (a.timestamp.year == now.year && a.timestamp.month == now.month && a.timestamp.day == now.day)).toList();
    final weekActions = widget.actions.where((a) => a.timestamp.isAfter(weekCutoff)).toList();
    final monthActions = widget.actions.where((a) => a.timestamp.isAfter(monthCutoff)).toList();

    final List<ActivityLog> currentList;
    final String emptyTitle;
    final String emptySubtitle;

    switch (_selectedPeriod) {
      case _ActivityPeriod.day:
        currentList = dayActions;
        emptyTitle = 'Немає дій за день';
        emptySubtitle = 'За останні 24 години нових змін чи активностей не зафіксовано';
        break;
      case _ActivityPeriod.week:
        currentList = weekActions;
        emptyTitle = 'Немає дій за тиждень';
        emptySubtitle = 'За останні 7 днів нових записів активностей не знайдено';
        break;
      case _ActivityPeriod.month:
        currentList = monthActions;
        emptyTitle = 'Немає дій за місяць';
        emptySubtitle = 'За останні 30 днів записи дій адміністратора відсутні';
        break;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: isDark ? null : Colors.white,
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF13233C).withValues(alpha: 0.96),
                      const Color(0xFF0C1626).withValues(alpha: 0.98),
                    ],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                  : currentTheme.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 18, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: currentTheme.accentGradient,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentTheme.accentPrimary.withValues(alpha: 0.40),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.history,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.recent_actions'.tr(),
                            style: TextStyle(
                              color: currentTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Журнал активностей адміністратора',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isDark ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : currentTheme.textSecondary, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Control: День | Тиждень | Місяць
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : currentTheme.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    _buildPeriodTab(
                      title: 'День',
                      count: dayActions.length,
                      period: _ActivityPeriod.day,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                    _buildPeriodTab(
                      title: 'Тиждень',
                      count: weekActions.length,
                      period: _ActivityPeriod.week,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                    _buildPeriodTab(
                      title: 'Місяць',
                      count: monthActions.length,
                      period: _ActivityPeriod.month,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              Divider(
                color: isDark ? Colors.white10 : currentTheme.cardBorder,
                height: 1,
              ),

              // List of actions or period empty state
              Flexible(
                child: currentList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.clockAlert,
                                  size: 32,
                                  color: currentTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              emptyTitle,
                              style: TextStyle(
                                color: currentTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              emptySubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: currentTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: currentList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final a = currentList[index];
                          final actionIcon = _getActionIcon(a.action);
                          final actionColor = _getActionColor(a.action, currentTheme);
                          final timeStr = _formatActionTime(a.timestamp);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.03),
                                      ],
                                    )
                                  : null,
                              color: isDark ? null : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : currentTheme.cardBorder,
                              ),
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.20),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: isDark ? 0.22 : 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: actionColor.withValues(alpha: isDark ? 0.45 : 0.25),
                                    ),
                                    boxShadow: isDark
                                        ? [
                                            BoxShadow(
                                              color: actionColor.withValues(alpha: 0.28),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      actionIcon,
                                      color: actionColor,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.action,
                                        style: TextStyle(
                                          color: currentTheme.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.clock,
                                            size: 11,
                                            color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textMuted,
                                              fontSize: 11.5,
                                              fontWeight: isDark ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab({
    required String title,
    required int count,
    required _ActivityPeriod period,
    required AppThemeConfig currentTheme,
    required bool isDark,
  }) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() {
              _selectedPeriod = period;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: currentTheme.accentGradient,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.28)
                      : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// INTERACTIVE ACTION CARD (FROSTED BENTO GLASS)
// ==========================================
class _InteractiveActionCard extends ConsumerStatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color accentColor;
  final List<Color>? gradientColors;
  final VoidCallback onTap;

  const _InteractiveActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.accentColor,
    this.gradientColors,
    required this.onTap,
  });

  @override
  ConsumerState<_InteractiveActionCard> createState() => _InteractiveActionCardState();
}

class _InteractiveActionCardState extends ConsumerState<_InteractiveActionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final effectiveGradient = widget.gradientColors ?? [
      widget.accentColor,
      widget.accentColor.withValues(alpha: 0.8),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.lightImpact();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.025 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isHovered ? -2.5 : 0, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(20),
                    splashColor: widget.accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    highlightColor: widget.accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: _isHovered ? 0.30 : 0.22),
                                  widget.accentColor.withValues(alpha: _isHovered ? 0.15 : 0.07),
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFF8FAFC),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isHovered
                              ? (isDark
                                  ? widget.accentColor.withValues(alpha: 0.85)
                                  : widget.accentColor.withValues(alpha: 0.65))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.28)
                                  : const Color(0xFFBAE6FD)),
                          width: _isHovered ? 1.2 : 1.15,
                        ),
                        boxShadow: [
                          if (isDark) ...[
                            // Layer 1: Deep colored base shadow
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isHovered ? 0.30 : 0.18),
                              blurRadius: _isHovered ? 20 : 14,
                              offset: const Offset(0, 6),
                            ),
                            // Layer 2: Medium elevation shadow
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: _isHovered ? 0.32 : 0.14),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ] else ...[
                            // Layer 1: Ambient Jewel Bloom (colored reflection on the water)
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: _isHovered ? 0.28 : 0.12),
                              blurRadius: _isHovered ? 16 : 10,
                              offset: Offset(0, _isHovered ? 4 : 2),
                            ),
                            // Layer 2: Deep grounding shadow
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        ],
                      ),
                      child: Row(
                        children: [
                          // Vibrant Glowing Jewel Emblem — 3D gemstone badge
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: effectiveGradient,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: isDark ? 0.50 : 0.65),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: effectiveGradient.first.withValues(alpha: _isHovered ? 0.65 : (isDark ? 0.42 : 0.36)),
                                  blurRadius: _isHovered ? 16 : (isDark ? 10 : 8),
                                  offset: Offset(0, isDark ? 3 : 2),
                                ),
                                if (!isDark)
                                  BoxShadow(
                                    color: effectiveGradient.last.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    spreadRadius: -1,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Icon(widget.icon, color: Colors.white, size: isDark ? 20 : 22),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Titles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.label,
                                    style: TextStyle(
                                      color: currentTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.sublabel,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFB0D4EC)
                                        : const Color(0xFF64748B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Chevron capsule with accent tint for light theme
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: _isHovered ? 0.16 : 0.08)
                                  : (_isHovered
                                      ? widget.accentColor.withValues(alpha: 0.18)
                                      : const Color(0xFFF0F9FF)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : (_isHovered
                                        ? widget.accentColor.withValues(alpha: 0.45)
                                        : const Color(0xFFBAE6FD)),
                                width: 1.0,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: widget.accentColor.withValues(alpha: 0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.chevronRight,
                                size: 12,
                                color: _isHovered
                                    ? widget.accentColor
                                    : (isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.75)
                                        : widget.accentColor),
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
          ),
        ),
      ),
    );
  }
}

