import 'dart:ui';
import 'package:flutter/material.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF09182B), // Rich Deep Ocean Slate
      body: Stack(
        children: [
          // 1. Full-fidelity animated water ripples and particles (like in Client screen)
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),

          // 2. Fluid aquatic gradient overlay (seamlessly harmonized with Parent screen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00B4DB).withValues(alpha: 0.20), // Fresh cyan aqua top
                    const Color(0xFF0284C7).withValues(alpha: 0.12), // Cerulean
                    const Color(0xFF0F172A).withValues(alpha: 0.72), // Smooth eye-friendly slate base
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
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
                    const Color(0xFF38BDF8).withValues(alpha: 0.22),
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
                    const Color(0xFF00B4D8).withValues(alpha: 0.18),
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
                    const Color(0xFF818CF8).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, ref, dashboardState.recentActions),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                    child: _buildSearchBar().animate().fadeIn(delay: 100.ms).slideY(begin: 0.06),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Live Status Telemetry Bar (Ізюминка адмінки: витончений статус-бар)
                      _buildLivePulseBar(dashboardState).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06),
                      const SizedBox(height: 18),

                      // 2. Неоплачені абонементи (якщо є)
                      if (dashboardState.unpaidSubscriptions > 0) ...[
                        _buildSectionTitle(
                          'Потребує уваги',
                          LucideIcons.alertTriangle,
                          const Color(0xFFF43F5E),
                          gradientColors: const [Color(0xFFFB7185), Color(0xFFE11D48)],
                          badgeText: '${dashboardState.unpaidSubscriptions} борж.',
                          badgeColor: const Color(0xFFF43F5E),
                        ),
                        const SizedBox(height: 12),
                        _buildUnpaidAttentionItem(dashboardState.unpaidSubscriptions).animate().fadeIn(delay: 250.ms).slideY(begin: 0.06),
                        const SizedBox(height: 24),
                      ],

                      // 3. Центр підтримки клієнтів (без дублювання заголовка)
                      _buildSupportCenterCard(unreadCount).animate().fadeIn(delay: 300.ms).slideY(begin: 0.06),
                      const SizedBox(height: 22),

                      // 4. Швидкі дії (3x2 ідеально збалансована сітка з 6 кнопок)
                      _buildSectionTitle(
                        'admin.quick_actions'.tr(),
                        LucideIcons.zap,
                        const Color(0xFF00E5FF),
                        gradientColors: const [Color(0xFF00D2FF), Color(0xFF0077B6)],
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(context).animate().fadeIn(delay: 400.ms).slideY(begin: 0.06),
                      const SizedBox(height: 32),

                      // 5. Найближче заняття з аватарками учнів
                      if (dashboardState.nearestClass != null) ...[
                        _buildSectionTitle(
                          'admin.nearest_class'.tr(),
                          LucideIcons.clock,
                          const Color(0xFF00E5FF),
                          gradientColors: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          badgeText: 'admin.today'.tr(),
                          badgeColor: const Color(0xFF38BDF8),
                        ),
                        const SizedBox(height: 12),
                        _buildNearestClass(dashboardState.nearestClass!).animate().fadeIn(delay: 500.ms).slideY(begin: 0.06),
                        const SizedBox(height: 24),
                      ],

                      const SizedBox(height: 24),
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
          style: const TextStyle(
            color: Colors.white,
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
              color: (badgeColor ?? color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (badgeColor ?? color).withValues(alpha: 0.40),
                width: 0.8,
              ),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor ?? Colors.white.withValues(alpha: 0.90),
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
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.02),
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

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
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
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const AvatarPicker(
                      heroTag: 'hero_avatar_Адміністраторам',
                      radius: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'admin.hello'.tr()}, ${user?.name ?? "Admin"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
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
                                'CitySwim Admin · ${'admin.online_status'.tr()}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
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
            // Right actions: History log & Logout buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.history, color: Colors.white, size: 20),
                    tooltip: 'admin.recent_actions'.tr(),
                    onPressed: () => _showRecentActionsSheet(context, recentActions),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.logOut, color: Colors.white, size: 20),
                    tooltip: 'Вийти',
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

  void _openGlobalSearch({int initialCategoryIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminGlobalSearchSheet(initialCategoryIndex: initialCategoryIndex),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => _openGlobalSearch(initialCategoryIndex: 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B385C).withValues(alpha: 0.75),
              const Color(0xFF102640).withValues(alpha: 0.80),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.30),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003B73).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  const Icon(LucideIcons.search, color: Color(0xFF38BDF8), size: 19),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'admin.search_hint'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openGlobalSearch(initialCategoryIndex: 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.slidersHorizontal, color: Color(0xFF38BDF8), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'admin.filter_btn'.tr(),
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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

  // ==========================================
  // 1. LIVE TELEMETRY STATUS BAR (HUD ІЗЮМИНКА)
  // ==========================================
  Widget _buildLivePulseBar(AdminDashboardState state) {
    final bool isSessionActive = state.ongoingClassesCount > 0;

    // 1. Скільки активних занять зараз проводяться
    final int classesValue = state.ongoingClassesCount;

    // 2. Скільки клієнтів займаються зараз
    final int clientsValue = isSessionActive ? state.ongoingClientsCount : state.activeClientsCount;

    // 3. Скільки тренерів працюють зараз
    final int coachesValue = isSessionActive ? state.ongoingCoachesCount : state.totalCoachesCount;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            const Color(0xFF0284C7).withValues(alpha: 0.14),
            const Color(0xFF031933).withValues(alpha: 0.40),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003B73).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              color: isSessionActive ? const Color(0xFF10B981) : const Color(0xFF00E5FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isSessionActive ? const Color(0xFF10B981) : const Color(0xFF00E5FF)).withValues(alpha: 0.85),
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
                                isSessionActive ? 'admin.live_beacon_active'.tr() : 'admin.live_beacon_idle'.tr(),
                                style: TextStyle(
                                  color: isSessionActive ? const Color(0xFF10B981) : Colors.white,
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
                                  color: Color(0xFF34D399),
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
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.activity, color: Color(0xFF38BDF8), size: 11),
                          const SizedBox(width: 4),
                          Text(
                            'admin.realtime'.tr(),
                            style: const TextStyle(
                              color: Colors.white70,
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
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.15),
                        const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // 3 Telemetry Gauges (Non-clickable, elegant high-end readout)
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // 1. Активні заняття
                      Expanded(
                        child: _buildTelemetryGauge(
                          icon: LucideIcons.calendarClock,
                          gradientColors: const [Color(0xFF00E5FF), Color(0xFF0077B6)],
                          accentColor: const Color(0xFF38BDF8),
                          title: 'admin.classes_telemetry'.tr(),
                          value: '$classesValue',
                          status: 'admin.classes_status'.tr(),
                        ),
                      ),

                      // Vertical Hairline
                      _buildVerticalHairline(),

                      // 2. Клієнти
                      Expanded(
                        child: _buildTelemetryGauge(
                          icon: LucideIcons.users,
                          gradientColors: const [Color(0xFF34D399), Color(0xFF059669)],
                          accentColor: const Color(0xFF10B981),
                          title: 'admin.clients_telemetry'.tr(),
                          value: '$clientsValue',
                          status: 'admin.clients_status'.tr(),
                        ),
                      ),

                      // Vertical Hairline
                      _buildVerticalHairline(),

                      // 3. Тренери
                      Expanded(
                        child: _buildTelemetryGauge(
                          icon: LucideIcons.award,
                          gradientColors: const [Color(0xFFA855F7), Color(0xFF6D28D9)],
                          accentColor: const Color(0xFFA855F7),
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
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
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
                        color: isSessionActive ? const Color(0xFF10B981) : const Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSessionActive
                              ? 'admin.in_pool_now_desc'.tr(args: [state.ongoingClasses.first.title, state.ongoingClientsCount.toString()])
                              : (state.nearestClass != null
                                  ? 'admin.nearest_class_at'.tr(args: [DateFormat('HH:mm').format(state.nearestClass!.startTime), state.nearestClass!.title])
                                  : 'admin.normal_mode'.tr()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.40),
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '●',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 7),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'admin.normal_badge'.tr(),
                              style: const TextStyle(
                                color: Color(0xFF10B981),
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

  Widget _buildTelemetryGauge({
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    required String title,
    required String value,
    required String status,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Squircle Jewel Icon Badge (36x36)
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(height: 8),

        // Big Precision Telemetry Value
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.0,
              shadows: [
                Shadow(
                  color: accentColor.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),

        // Category Name
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 2),

        // Refined Live Status Subtitle (Clean single line, fits any screen)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            status,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: accentColor.withValues(alpha: 0.90),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalHairline() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. ЦЕНТР ПІДТРИМКИ КЛІЄНТІВ (КРИШТАЛЕВА АЕРО-КАРТКА)
  // ==========================================
  Widget _buildSupportCenterCard(int unreadCount) {
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: hasUnread ? 0.24 : 0.16),
                    Colors.white.withValues(alpha: hasUnread ? 0.12 : 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasUnread
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.28),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  if (hasUnread)
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 2),
                    ),
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
                        Row(
                          children: [
                            if (hasUnread) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF38BDF8),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'admin.new_sms'.tr(),
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'admin.support_center'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasUnread
                              ? 'admin.new_messages_count'.tr(args: [unreadCount.toString()])
                              : 'admin.quick_answers'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
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
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.chevronRight, color: Colors.white, size: 18),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const PaymentSheet(initialTabIndex: 1),
          );
        },
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFFF43F5E).withValues(alpha: 0.15),
        highlightColor: const Color(0xFFF43F5E).withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF43F5E).withValues(alpha: 0.18),
                const Color(0xFF152A44).withValues(alpha: 0.82),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(LucideIcons.creditCard, color: Color(0xFFF43F5E), size: 20),
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
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'admin.attention'.tr(),
                            style: const TextStyle(
                              color: Color(0xFFF43F5E),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$unpaidCount ${'admin.unpaid_subs_title'.tr()}',
                            style: const TextStyle(
                              color: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white60,
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
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LucideIcons.chevronRight, color: Color(0xFFF43F5E), size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. ШВИДКІ ДІЇ (КРИШТАЛЕВИЙ BENTO-БЛОК ДІЙ)
  // ==========================================
  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        final columns = isWide ? 3 : 2;
        const spacing = 10.0;
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _InteractiveActionCard(
                icon: LucideIcons.calendarPlus,
                label: _capitalize('admin.create'.tr()),
                sublabel: 'admin.sub_classes'.tr(),
                accentColor: const Color(0xFF10B981),
                gradientColors: const [Color(0xFF34D399), Color(0xFF059669)],
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
                accentColor: const Color(0xFF3B82F6),
                gradientColors: const [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
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
                accentColor: const Color(0xFFA855F7),
                gradientColors: const [Color(0xFFC084FC), Color(0xFF7C3AED)],
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
                accentColor: const Color(0xFF06B6D4),
                gradientColors: const [Color(0xFF22D3EE), Color(0xFF0891B2)],
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
                accentColor: const Color(0xFF6366F1),
                gradientColors: const [Color(0xFF818CF8), Color(0xFF4338CA)],
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
                accentColor: const Color(0xFFF59E0B),
                gradientColors: const [Color(0xFFFBBF24), Color(0xFFD97706)],
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

  // ==========================================
  // 4. НАЙБЛИЖЧЕ ЗАНЯТТЯ З АВАТАРКАМИ УЧНІВ
  // ==========================================
  Widget _buildNearestClass(GroupClass nearest) {
    final timeFormat = DateFormat('HH:mm');
    final startTimeStr = timeFormat.format(nearest.startTime);
    final endTimeStr = timeFormat.format(nearest.endTime);
    final occupancy = nearest.enrolledChildIds.length;
    final maxCapacity = nearest.maxCapacity;
    final percent = maxCapacity > 0 ? (occupancy / maxCapacity).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003B73), Color(0xFF006DAE), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003B73).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.clock, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$startTimeStr – $endTimeStr',
                      style: const TextStyle(
                        color: Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    nearest.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location and Coach
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  nearest.lane.isNotEmpty ? 'Басейн · ${nearest.lane}' : 'Басейн · Всі доріжки',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(LucideIcons.user, color: Colors.white70, size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${'admin.class_coach'.tr()}: ${nearest.coachName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$occupancy / $maxCapacity учнів',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),

          // Student Facepile (Аватарки учнів, що підтягуються від клієнта)
          if (nearest.enrolledChildIds.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _buildEnrolledFacepile(nearest.enrolledChildIds),
                const SizedBox(width: 10),
                Text(
                  '${'admin.enrolled_swimmers'.tr()} (${nearest.enrolledChildIds.length})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminCalendarScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF003B73),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF003B73)),
                  const SizedBox(width: 8),
                  Text(
                    'admin.open_in_schedule'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF003B73),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledFacepile(List<String> childIds) {
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
                  border: Border.all(color: const Color(0xFF003B73), width: 2),
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(displayIds[i])
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final avatarUrl = data?['avatarUrl'] as String?;
                    final name = data?['name'] as String? ?? 'У';

                    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
                      return CircleAvatar(
                        radius: 13,
                        backgroundImage: NetworkImage(avatarUrl),
                        backgroundColor: Colors.white24,
                      );
                    }
                    return CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFF00B4D8),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'У',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF003B73), width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: const TextStyle(
                      color: Colors.white,
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
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF13233C).withValues(alpha: 0.96),
                    const Color(0xFF0C1626).withValues(alpha: 0.98),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
                    blurRadius: 30,
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 18, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.history,
                            color: Color(0xFF38BDF8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'admin.recent_actions'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Журнал активностей адміністратора',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(
                    color: Colors.white10,
                    height: 1,
                  ),

                  // List of actions or empty state
                  Flexible(
                    child: actions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.clockAlert,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Поки немає записів',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Усі ключові дії та зміни в системі відображатимуться тут',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: actions.length,
                            separatorBuilder: (context, index) => Divider(
                              color: Colors.white.withValues(alpha: 0.06),
                              height: 16,
                            ),
                            itemBuilder: (context, index) {
                              final a = actions[index];
                              final diff = DateTime.now().difference(a.timestamp);
                              String timeStr;
                              if (diff.inMinutes < 60) {
                                timeStr = '${diff.inMinutes} ${'admin.mins_ago'.tr()}';
                              } else if (diff.inHours < 24) {
                                timeStr = '${diff.inHours} ${'admin.hours_ago'.tr()}';
                              } else {
                                timeStr = DateFormat('dd.MM HH:mm').format(a.timestamp);
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF38BDF8),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        a.action,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        timeStr,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// INTERACTIVE ACTION CARD (FROSTED BENTO GLASS)
// ==========================================
class _InteractiveActionCard extends StatefulWidget {
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
  State<_InteractiveActionCard> createState() => _InteractiveActionCardState();
}

class _InteractiveActionCardState extends State<_InteractiveActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.gradientColors ?? [
      widget.accentColor,
      widget.accentColor.withValues(alpha: 0.8),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(18),
                splashColor: widget.accentColor.withValues(alpha: 0.25),
                highlightColor: widget.accentColor.withValues(alpha: 0.12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: _isHovered ? 0.30 : 0.22),
                        widget.accentColor.withValues(alpha: _isHovered ? 0.15 : 0.07),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isHovered
                          ? widget.accentColor.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isHovered ? 0.30 : 0.18),
                        blurRadius: _isHovered ? 14 : 8,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: _isHovered ? 0.32 : 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Vibrant Glowing Jewel Emblem
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
                          boxShadow: [
                            BoxShadow(
                              color: effectiveGradient.first.withValues(alpha: _isHovered ? 0.60 : 0.40),
                              blurRadius: _isHovered ? 12 : 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(widget.icon, color: Colors.white, size: 19),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              widget.sublabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: _isHovered ? 0.90 : 0.70),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: Colors.white.withValues(alpha: _isHovered ? 0.85 : 0.35),
                      ),
                    ],
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
