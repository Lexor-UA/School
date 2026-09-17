import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/coach/presentation/qr_scanner_screen.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'coach_journal_screen.dart';
import 'coach_changes_banner.dart';
import 'coach_class_attendees_sheet.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class SelectedCoachClassIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setClassId(String? id) {
    state = id;
  }
}

/// Active class selected for the Coach Journal
final selectedCoachClassIdProvider = NotifierProvider<SelectedCoachClassIdNotifier, String?>(SelectedCoachClassIdNotifier.new);

class CoachTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

/// Provider for active coach tab
final coachTabProvider = NotifierProvider<CoachTabNotifier, int>(CoachTabNotifier.new);

/// Safe translation helper that always provides clean Ukrainian fallbacks
/// even if asset bundles were not reloaded during hot reload.
String _coachTr(String key, String fallback, {List<String>? args}) {
  final val = args != null ? key.tr(args: args) : key.tr();
  if (val == key || val.isEmpty) {
    if (args != null && args.isNotEmpty) {
      String res = fallback;
      for (int i = 0; i < args.length; i++) {
        res = res.replaceAll('{$i}', args[i]);
      }
      return res;
    }
    return fallback;
  }
  return val;
}

// ============================================================================
// TAB 1: COACH SCHEDULE & SHIFT (Розклад та Зміна)
// ============================================================================

class CoachScheduleTab extends ConsumerStatefulWidget {
  const CoachScheduleTab({super.key});

  @override
  ConsumerState<CoachScheduleTab> createState() => _CoachScheduleTabState();
}

class _CoachScheduleTabState extends ConsumerState<CoachScheduleTab> {
  final bool _showAllPoolClassesFallback = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayClasses = allClasses.where((c) {
      final classDate = DateTime(c.startTime.year, c.startTime.month, c.startTime.day);
      if (!classDate.isAtSameMomentAs(today)) return false;
      final isMock = user?.id == 'mock_coach';
      final matchesId = c.coachId == user?.id;
      final matchesName = user != null &&
          user.name.isNotEmpty &&
          c.coachName.toLowerCase().contains(user.name.toLowerCase());
      return matchesId || matchesName || isMock;
    }).toList();

    final int totalKidsToday = todayClasses.fold<int>(0, (acc, c) => acc + c.enrolledChildIds.length);
    final int totalCapToday = todayClasses.fold<int>(0, (acc, c) => acc + (c.maxCapacity > 0 ? c.maxCapacity : 8));
    final int totalFreeToday = (totalCapToday - totalKidsToday).clamp(0, 9999);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top Bar Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coach Identity & Live Beacon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF10B981)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const AvatarPicker(
                          heroTag: 'hero_avatar_Тренерам_schedule',
                          radius: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'coach.greeting'.tr(args: [user?.name ?? 'coach.title'.tr()]),
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: themeConfig.isDark
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : Colors.white.withValues(alpha: 0.70),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: themeConfig.isDark ? 0.35 : 0.45),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'coach.on_shift'.tr(),
                                        style: TextStyle(
                                          color: themeConfig.isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Theme Switcher Button
                      const ThemeHeaderButton(size: 42),
                      const SizedBox(width: 8),
                      // Quick QR Scanner Action Button (Sleek circular cyber-glass badge)
                      Tooltip(
                        message: _coachTr('coach.scan_qr_pass', 'Сканувати перепустку'),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                          ),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: themeConfig.isDark
                                  ? const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.95),
                                        const Color(0xFFE0F2FE).withValues(alpha: 0.85),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              border: Border.all(
                                color: themeConfig.isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : const Color(0xFF0284C7).withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: themeConfig.isDark ? 0.45 : 0.12),
                                  blurRadius: themeConfig.isDark ? 14 : 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: themeConfig.isDark ? Colors.white : const Color(0xFF0284C7),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Logout button (Matching circular glass with soft coral glow)
                      Tooltip(
                        message: 'Вийти з кабінету',
                        child: GestureDetector(
                          onTap: () => _confirmCoachLogout(context, ref),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: themeConfig.isDark
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.95),
                                        const Color(0xFFFFF1F2).withValues(alpha: 0.85),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: themeConfig.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : null,
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: themeConfig.isDark ? 0.28 : 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.logOut, color: Color(0xFFEF4444), size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 20),

                  // Shift telemetry card
                  _buildShiftTelemetryCard(themeConfig),

                  const SizedBox(height: 20),

                  // Section title & Today Date Badge (Розклад на сьогодні)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: themeConfig.isDark ? const Color(0xFF00E5FF) : themeConfig.accentPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (themeConfig.isDark ? const Color(0xFF00E5FF) : themeConfig.accentPrimary).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'coach.schedule_today'.tr(),
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Tooltip(
                        message: 'Відкрити календар на місяць / рік',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => ref.read(coachTabProvider.notifier).setTab(1),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: themeConfig.isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                                    : Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: themeConfig.isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                      : const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF003B73)).withValues(alpha: 0.10),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 13,
                                    color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('d MMMM', context.locale.languageCode).format(DateTime.now()),
                                    style: TextStyle(
                                      color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.chevronRight,
                                    size: 12,
                                    color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 1. Schedule list content (Розклад першим)
          scheduleAsync.when(
            data: (allClasses) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              // Filter strictly by TODAY
              List<GroupClass> dateFiltered = allClasses.where((c) {
                final classDate = DateTime(c.startTime.year, c.startTime.month, c.startTime.day);
                return classDate.isAtSameMomentAs(today);
              }).toList();

              // Filter by coach
              List<GroupClass> coachClasses = dateFiltered.where((c) {
                if (_showAllPoolClassesFallback) return true;
                final isMock = user?.id == 'mock_coach';
                final matchesId = c.coachId == user?.id;
                final matchesName = user != null &&
                    user.name.isNotEmpty &&
                    c.coachName.toLowerCase().contains(user.name.toLowerCase());
                return matchesId || matchesName || isMock;
              }).toList();

              // If specific coach has 0 classes, fall back smoothly to showing all pool sessions for today
              final bool isUsingFallback = coachClasses.isEmpty && dateFiltered.isNotEmpty;
              final displayClasses = isUsingFallback ? dateFiltered : coachClasses;

              if (displayClasses.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: themeConfig.isDark
                                  ? [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.white.withValues(alpha: 0.04),
                                    ]
                                  : [
                                      Colors.white.withValues(alpha: 0.78),
                                      Colors.white.withValues(alpha: 0.62),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: themeConfig.isDark
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.95),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: themeConfig.isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                                    : const Color(0xFF003B73).withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: themeConfig.isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.07)
                                        : const Color(0xFF0284C7).withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: themeConfig.isDark
                                          ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                                          : const Color(0xFF0284C7).withValues(alpha: 0.20),
                                      width: 1.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: themeConfig.isDark ? 0.18 : 0.12),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: themeConfig.isDark
                                              ? [
                                                  const Color(0xFF00E5FF).withValues(alpha: 0.30),
                                                  const Color(0xFF00E5FF).withValues(alpha: 0.08),
                                                ]
                                              : [
                                                  const Color(0xFFBAE6FD).withValues(alpha: 0.65),
                                                  const Color(0xFFE0F2FE).withValues(alpha: 0.30),
                                                ],
                                        ),
                                        border: Border.all(
                                          color: themeConfig.isDark
                                              ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                                              : const Color(0xFF38BDF8).withValues(alpha: 0.50),
                                          width: 1.4,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.calendarCheck2,
                                          color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'coach.no_classes_today_title'.tr(),
                                  style: TextStyle(
                                    color: themeConfig.textPrimary,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'coach.no_classes_today_desc'.tr(),
                                  style: TextStyle(
                                    color: themeConfig.textSecondary,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      ref.read(coachTabProvider.notifier).setTab(1);
                                    },
                                    borderRadius: BorderRadius.circular(18),
                                    child: Ink(
                                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12.5),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.40),
                                          width: 1.1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: themeConfig.isDark ? 0.42 : 0.28),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.calendarDays, color: Colors.white, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'coach.open_calendar'.tr(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
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
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildClassCard(displayClasses[index], index, themeConfig);
                    },
                    childCount: displayClasses.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text('coach.load_error'.tr(args: ['$e']), style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
          ),

          // 2. Потім зміни. Потім журнал відвідування.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Changes & Activity Feed Banner ("Потім зміни")
                  const CoachChangesBanner(),

                  const SizedBox(height: 14),

                  // Daily Headcount & Capacity Summary
                  if (todayClasses.isNotEmpty) ...[
                    _buildDailyHeadcountCard(
                      totalKidsToday,
                      todayClasses.length,
                      totalFreeToday,
                      totalCapToday,
                      themeConfig,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Quick Attendance Journal Action Button ("Потім журнал відвідування")
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CoachJournalScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: themeConfig.isDark
                                    ? [
                                        Colors.white.withValues(alpha: 0.12),
                                        Colors.white.withValues(alpha: 0.04),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.78),
                                        Colors.white.withValues(alpha: 0.62),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: themeConfig.isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.95),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeConfig.isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                                      : const Color(0xFF003B73).withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.38),
                                      width: 1.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: themeConfig.isDark ? 0.38 : 0.28),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(LucideIcons.clipboardCheck, color: Colors.white, size: 21),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'coach.quick_attendance'.tr(),
                                        style: TextStyle(
                                          color: themeConfig.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'coach.quick_attendance_sub'.tr(),
                                        style: TextStyle(
                                          color: themeConfig.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: themeConfig.isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                                        : const Color(0xFFE0F2FE).withValues(alpha: 0.85),
                                    border: Border.all(
                                      color: themeConfig.isDark
                                          ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                          : const Color(0xFF38BDF8).withValues(alpha: 0.50),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.chevronRight,
                                      color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                      size: 16,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTelemetryCard(AppThemeConfig themeConfig) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeConfig.isDark
                  ? [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.62),
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: themeConfig.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.95),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: themeConfig.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                    : const Color(0xFF003B73).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildTelemetryMetric(
                icon: LucideIcons.waves,
                iconColor: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                label: 'coach.telemetry_water_temp'.tr(),
                value: '27.8°C',
                themeConfig: themeConfig,
              ),
              Container(
                width: 1.2,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      themeConfig.isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFF0284C7).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              _buildTelemetryMetric(
                icon: LucideIcons.clock3,
                iconColor: themeConfig.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                label: 'coach.telemetry_duty'.tr(),
                value: '08:00 – 20:00',
                themeConfig: themeConfig,
              ),
              Container(
                width: 1.2,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      themeConfig.isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFF0284C7).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              _buildTelemetryMetric(
                icon: LucideIcons.shieldCheck,
                iconColor: themeConfig.isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                label: 'coach.telemetry_shift_status'.tr(),
                value: 'coach.status_active'.tr(),
                valueColor: themeConfig.isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                isLiveBeacon: true,
                themeConfig: themeConfig,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryMetric({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required AppThemeConfig themeConfig,
    Color? valueColor,
    bool isLiveBeacon = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: themeConfig.isDark
                    ? [
                        iconColor.withValues(alpha: 0.22),
                        iconColor.withValues(alpha: 0.08),
                      ]
                    : [
                        Colors.white,
                        iconColor.withValues(alpha: 0.12),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: themeConfig.isDark ? 0.38 : 0.32),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: themeConfig.isDark ? 0.22 : 0.12),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLiveBeacon) ...[
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: valueColor ?? const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: valueColor ?? const Color(0xFF10B981),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? themeConfig.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: themeConfig.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHeadcountCard(int totalKids, int totalClasses, int freeSlots, int totalCapacity, AppThemeConfig themeConfig) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeConfig.isDark
                  ? [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.62),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeConfig.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.95),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: themeConfig.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                    : const Color(0xFF003B73).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.users, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'НА СЬОГОДНІ: ',
                          style: TextStyle(
                            color: themeConfig.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '$totalKids дітей у $totalClasses ${totalClasses == 1 ? "групі" : "групах"}',
                          style: TextStyle(
                            color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      freeSlots > 0
                          ? 'Вільних місць: $freeSlots (з $totalCapacity місць)'
                          : 'Всі групи заповнені ($totalCapacity місць)',
                      style: TextStyle(
                        color: freeSlots > 0
                            ? (themeConfig.isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
                            : const Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(GroupClass gClass, int index, AppThemeConfig themeConfig) {
    final startTimeStr = '${gClass.startTime.hour.toString().padLeft(2, '0')}:${gClass.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${gClass.endTime.hour.toString().padLeft(2, '0')}:${gClass.endTime.minute.toString().padLeft(2, '0')}';
    final enrolledCount = gClass.enrolledChildIds.length;
    final attendedCount = gClass.attendedChildIds.length;
    final maxCap = gClass.maxCapacity > 0 ? gClass.maxCapacity : 8;
    final freeSlots = (maxCap - enrolledCount).clamp(0, maxCap);
    final fillFraction = (enrolledCount / maxCap).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeConfig.isDark
                    ? [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.78),
                        Colors.white.withValues(alpha: 0.62),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: themeConfig.isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.95),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeConfig.isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                      : const Color(0xFF003B73).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category pill, Lane Badge & Free Spots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: themeConfig.isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: themeConfig.isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                                    : const Color(0xFF0284C7).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              gClass.category.isNotEmpty ? gClass.category : 'parent.swimming'.tr(),
                              style: TextStyle(
                                color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (gClass.lane.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: themeConfig.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                gClass.lane,
                                style: TextStyle(
                                  color: themeConfig.isDark ? Colors.white70 : themeConfig.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // Free slots indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: freeSlots == 0
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.16)
                                  : (freeSlots <= 2
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.16)
                                      : const Color(0xFF10B981).withValues(alpha: 0.16)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: freeSlots == 0
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                                    : (freeSlots <= 2
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                                        : const Color(0xFF10B981).withValues(alpha: 0.45)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  freeSlots == 0 ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
                                  size: 11,
                                  color: freeSlots == 0
                                      ? const Color(0xFFEF4444)
                                      : (freeSlots <= 2 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  freeSlots == 0 ? 'Заповнено' : 'Вільно: $freeSlots',
                                  style: TextStyle(
                                    color: freeSlots == 0
                                        ? const Color(0xFFEF4444)
                                        : (freeSlots <= 2
                                            ? const Color(0xFFF59E0B)
                                            : (themeConfig.isDark ? const Color(0xFF10B981) : const Color(0xFF059669))),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.clock, color: themeConfig.textMuted, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '$startTimeStr - $endTimeStr',
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Class Title & Coach
                Text(
                  gClass.title,
                  style: TextStyle(
                    color: themeConfig.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.user, color: themeConfig.textMuted, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'coach.assigned_coach'.tr(args: [gClass.coachName.isNotEmpty ? gClass.coachName : 'coach.title'.tr()]),
                        style: TextStyle(color: themeConfig.textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Capacity & Attendance Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Записано: $enrolledCount з $maxCap учнів (присутні: $attendedCount)',
                        style: TextStyle(color: themeConfig.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(fillFraction * 100).toInt()}%',
                      style: TextStyle(
                        color: fillFraction > 0.85
                            ? const Color(0xFFF59E0B)
                            : (themeConfig.isDark ? const Color(0xFF10B981) : const Color(0xFF059669)),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fillFraction,
                    minHeight: 6,
                    backgroundColor: themeConfig.isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF0284C7).withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fillFraction > 0.85
                          ? const Color(0xFFF59E0B)
                          : (themeConfig.isDark ? const Color(0xFF00E5FF) : themeConfig.accentPrimary),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Action Button: Attendee Roster (Option A)
                GestureDetector(
                  onTap: () => showCoachClassAttendeesSheet(context, gClass),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.users, color: Colors.white, size: 17),
                        const SizedBox(width: 8),
                        Text(
                          'Склад групи ($enrolledCount)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
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
    ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
  }
}

// ============================================================================
// SHARED COACH ACTIONS: MEDALS, XP, NOTES & SWIMMER PROFILE
// ============================================================================

Future<void> quickAddChildXp(BuildContext context, Child child, int amount) async {
  var newXp = child.xp + amount;
  var newLevel = child.level;
  var newMaxXp = child.maxXp > 0 ? child.maxXp : 100;
  bool leveledUp = false;
  while (newXp >= newMaxXp) {
    newXp -= newMaxXp;
    newLevel += 1;
    newMaxXp = (newMaxXp * 1.25).toInt();
    leveledUp = true;
  }

  try {
    await FirebaseFirestore.instance.collection('children').doc(child.id).update({
      'xp': newXp,
      'level': newLevel,
      'maxXp': newMaxXp,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.zap, color: Color(0xFF00E5FF), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  leveledUp
                      ? '+$amount XP для ${child.name}! 🎉 Новий рівень $newLevel!'
                      : '+$amount XP успішно нараховано плавцю ${child.name}! 🚀',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error updating XP: $e');
  }
}

Widget _buildMedalTile(BuildContext context, Child child, String id, String name, String desc, String icon) {
  return Container(
    margin: const EdgeInsets.only(bottom: 11),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.09),
          Colors.white.withValues(alpha: 0.04),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        width: 1.1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB703), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Text(
          desc,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Icon(LucideIcons.chevronRight, color: Color(0xFFFFB703), size: 16),
        ),
        onTap: () async {
          Navigator.pop(context);
          final achievement = Achievement(
            id: id,
            name: name,
            description: desc,
            iconType: icon,
            isUnlocked: true,
          );
          final newAchievements = List<Achievement>.from(child.achievements)..add(achievement);

          var newXp = child.xp + 25;
          var newLevel = child.level;
          var newMaxXp = child.maxXp > 0 ? child.maxXp : 100;
          bool leveledUp = false;
          while (newXp >= newMaxXp) {
            newXp -= newMaxXp;
            newLevel += 1;
            newMaxXp = (newMaxXp * 1.25).toInt();
            leveledUp = true;
          }

          try {
            await FirebaseFirestore.instance.collection('children').doc(child.id).update({
              'achievements': newAchievements.map((a) => a.toJson()).toList(),
              'xp': newXp,
              'level': newLevel,
              'maxXp': newMaxXp,
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          leveledUp
                              ? '${_coachTr('coach.medal_awarded', 'Нагороду "{0}" успішно вручено плавцю {1}!', args: [name, child.name])} 🎉 Новий рівень $newLevel!'
                              : _coachTr('coach.medal_awarded', 'Нагороду "{0}" успішно вручено плавцю {1}!', args: [name, child.name]),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF0284C7),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error awarding medal: $e');
          }
        },
      ),
    ),
  );
}

void showAwardMedalSheet(BuildContext context, Child child) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF071424).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
              blurRadius: 30,
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _coachTr('coach.award_title', 'Вручити нагороду'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _coachTr('coach.award_select_for', 'Оберіть відзнаку для плавця {0}', args: [child.name]),
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    _buildMedalTile(
                      context,
                      child,
                      'champion',
                      _coachTr('coach.medal_champion_name', 'Чемпіон дня'),
                      _coachTr('coach.medal_champion_desc', 'За найкраще старання та витривалість'),
                      '🏆',
                    ),
                    _buildMedalTile(
                      context,
                      child,
                      'dolphin',
                      _coachTr('coach.medal_dolphin_name', 'Дельфін'),
                      _coachTr('coach.medal_dolphin_desc', 'Ідеальне ковзання та техніка гребка'),
                      '🐬',
                    ),
                    _buildMedalTile(
                      context,
                      child,
                      'torpedo',
                      _coachTr('coach.medal_torpedo_name', 'Швидкісна торпеда'),
                      _coachTr('coach.medal_torpedo_desc', 'За швидкість та реакцію на старті'),
                      '⚡',
                    ),
                    _buildMedalTile(
                      context,
                      child,
                      'superstar',
                      _coachTr('coach.medal_superstar_name', 'Супер Зірка'),
                      _coachTr('coach.medal_superstar_desc', 'За дисципліну та командну підтримку'),
                      '⭐',
                    ),
                    _buildMedalTile(
                      context,
                      child,
                      'diver',
                      _coachTr('coach.medal_diver_name', 'Майстер занурення'),
                      _coachTr('coach.medal_diver_desc', 'Впевнене плавання під водою'),
                      '🤿',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showCoachNoteDialog(BuildContext context, Child child) {
  final textController = TextEditingController();
  FirebaseFirestore.instance.collection('children').doc(child.id).get().then((doc) {
    if (doc.exists && doc.data() != null && doc.data()!['notes'] != null) {
      textController.text = doc.data()!['notes'].toString();
    }
  });

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      backgroundColor: const Color(0xFF09182B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
      ),
      title: Text(
        _coachTr('coach.note_for', 'Нотатка про плавця {0}', args: [child.name]),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: textController,
        style: const TextStyle(color: Colors.white),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: _coachTr('coach.note_hint', 'Наприклад: Відпрацювати вдих під праву руку...'),
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(_coachTr('coach.btn_cancel', 'Скасувати'), style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final note = textController.text.trim();
            await FirebaseFirestore.instance.collection('children').doc(child.id).update({
              'notes': note,
            });
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_coachTr('coach.save_success', 'Нотатку збережено!'))),
              );
            }
          },
          child: Text(_coachTr('admin.save', 'Зберегти'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

void showSwimmerDetailsSheet(BuildContext context, Child initialChild) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('children').doc(initialChild.id).snapshots(),
        builder: (bottomSheetContext, snapshot) {
          final child = (snapshot.hasData && snapshot.data != null && snapshot.data!.exists)
              ? Child.fromJson({'id': snapshot.data!.id, ...snapshot.data!.data() as Map<String, dynamic>})
              : initialChild;

          String? note;
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null && data['notes'] != null) {
              note = data['notes'].toString();
            }
          }

          final double progress = child.maxXp > 0
              ? (child.xp / child.maxXp).clamp(0.0, 1.0)
              : 0.0;
          final int xpLeft = (child.maxXp - child.xp).clamp(0, 99999);

          final standardMedals = [
            {
              'id': 'champion',
              'name': _coachTr('coach.medal_champion_name', 'Чемпіон дня'),
              'desc': _coachTr('coach.medal_champion_desc', 'За найкраще старання та витривалість'),
              'icon': '🏆'
            },
            {
              'id': 'dolphin',
              'name': _coachTr('coach.medal_dolphin_name', 'Дельфін'),
              'desc': _coachTr('coach.medal_dolphin_desc', 'Ідеальне ковзання та техніка гребка'),
              'icon': '🐬'
            },
            {
              'id': 'torpedo',
              'name': _coachTr('coach.medal_torpedo_name', 'Швидкісна торпеда'),
              'desc': _coachTr('coach.medal_torpedo_desc', 'За швидкість та реакцію на старті'),
              'icon': '⚡'
            },
            {
              'id': 'superstar',
              'name': _coachTr('coach.medal_superstar_name', 'Супер Зірка'),
              'desc': _coachTr('coach.medal_superstar_desc', 'За дисципліну та командну підтримку'),
              'icon': '⭐'
            },
            {
              'id': 'diver',
              'name': _coachTr('coach.medal_diver_name', 'Майстер занурення'),
              'desc': _coachTr('coach.medal_diver_desc', 'Впевнене плавання під водою'),
              'icon': '🤿'
            },
          ];

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF09182B).withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top drag bar & close button
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _coachTr('coach.swimmer_details_title', 'ПРОФІЛЬ ТА ДОСЯГНЕННЯ ПЛАВЦЯ'),
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, color: Colors.white60, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Swimmer Hero Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00E5FF).withValues(alpha: 0.12),
                                const Color(0xFF0284C7).withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            '${_coachTr('coach.level_label', 'Рівень')} ${child.level}',
                                            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${child.xp}/${child.maxXp} XP',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // XP Progress Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_coachTr('coach.level_label', 'Рівень').toUpperCase()} ${child.level}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  Text(
                                    _coachTr('coach.to_next_level', 'До наст. рівня: {0} XP', args: ['$xpLeft']),
                                    style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 10,
                                  width: double.infinity,
                                  color: Colors.white.withValues(alpha: 0.08),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons Hub - Perfectly Responsive, Zero Overflows!
                        Row(
                          children: [
                            // 1. Award Medal Button
                            Expanded(
                              flex: 3,
                              child: GestureDetector(
                                onTap: () => showAwardMedalSheet(context, child),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('🏅', style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _coachTr('coach.award_medal_btn', 'Вручити нагороду'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. +25 XP Bonus Button
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: () => quickAddChildXp(context, child, 25),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.zap, color: Colors.white, size: 15),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _coachTr('coach.bonus_xp_btn', '+25 XP Бонус'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 3. Note button
                            GestureDetector(
                              onTap: () => showCoachNoteDialog(context, child),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: const Icon(LucideIcons.fileText, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Note Preview if exists
                        if (note != null && note.trim().isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.notepadText, color: Color(0xFF38BDF8), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _coachTr('coach.coach_note_label', 'Нотатка тренера:'),
                                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        note,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.pencil, color: Colors.white60, size: 15),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => showCoachNoteDialog(context, child),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Awards Collection Shelf
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_coachTr('coach.swimmer_collection_title', 'КОЛЕКЦІЯ НАГОРОД')} (${child.achievements.length})',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => showAwardMedalSheet(context, child),
                              child: Text(
                                '+ ${_coachTr('coach.award_action', 'Вручити')}',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // List of medals
                        ...standardMedals.map((m) {
                          final count = child.achievements.where((a) => a.id == m['id']).length;
                          final isUnlocked = count > 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnlocked
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.06),
                                    shape: BoxShape.circle,
                                    border: isUnlocked
                                        ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5))
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      m['icon']!,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: isUnlocked ? null : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m['name']!,
                                        style: TextStyle(
                                          color: isUnlocked ? Colors.white : Colors.white60,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m['desc']!,
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isUnlocked)
                                  GestureDetector(
                                    onTap: () {
                                      showAwardMedalSheet(context, child);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        count > 1 ? '${_coachTr('coach.awarded_status', 'Здобуто ✓')} ($count)' : _coachTr('coach.awarded_status', 'Здобуто ✓'),
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () {
                                      showAwardMedalSheet(context, child);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '+ ${_coachTr('coach.award_action', 'Вручити')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
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

// ============================================================================
// TAB 2: COACH JOURNAL & ATTENDANCE (Журнал та Відвідуваність)
// ============================================================================

class CoachJournalTab extends ConsumerStatefulWidget {
  const CoachJournalTab({super.key});

  @override
  ConsumerState<CoachJournalTab> createState() => _CoachJournalTabState();
}

class _CoachJournalTabState extends ConsumerState<CoachJournalTab> {
  List<Child> _enrolledChildren = [];
  bool _isLoadingChildren = false;

  Future<void> _fetchChildren(List<String> childIds) async {
    if (childIds.isEmpty) {
      if (mounted) setState(() => _enrolledChildren = []);
      return;
    }

    setState(() => _isLoadingChildren = true);
    try {
      final idsToFetch = childIds.take(20).toList();
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where(FieldPath.documentId, whereIn: idsToFetch)
          .get();

      final children = snapshot.docs.map((doc) => Child.fromJson({'id': doc.id, ...doc.data()})).toList();
      final foundIds = children.map((c) => c.id).toSet();
      final missingIds = idsToFetch.where((id) => !foundIds.contains(id)).toList();

      if (missingIds.isNotEmpty) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: missingIds)
            .get();

        for (final doc in userSnapshot.docs) {
          final data = doc.data();
          children.add(
            Child(
              id: doc.id,
              parentId: '',
              name: (data['name'] as String?)?.trim().isNotEmpty == true
                  ? (data['name'] as String).trim()
                  : 'Клієнт',
              level: (data['level'] as num?)?.toInt() ?? 1,
              xp: (data['xp'] as num?)?.toInt() ?? 0,
              maxXp: (data['maxXp'] as num?)?.toInt() ?? 100,
              colorHex: '0xFF00E5FF',
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _enrolledChildren = children;
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching children: $e');
      if (mounted) setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _toggleAttendance(GroupClass gClass, String childId) async {
    final isAttended = gClass.attendedChildIds.contains(childId);
    final newAttended = isAttended
        ? (List<String>.from(gClass.attendedChildIds)..remove(childId))
        : (List<String>.from(gClass.attendedChildIds)..add(childId));

    try {
      await FirebaseFirestore.instance.collection('classes').doc(gClass.id).update({
        'attendedChildIds': newAttended,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAttended ? 'coach.attendance_unmarked'.tr() : 'coach.attendance_marked'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isAttended ? const Color(0xFF334155) : const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling attendance: $e');
    }
  }

  void _awardMedal(Child child) => showAwardMedalSheet(context, child);
  void _showNoteDialog(Child child) => showCoachNoteDialog(context, child);

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final selectedClassId = ref.watch(selectedCoachClassIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: scheduleAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Text(
                'coach.no_active_classes'.tr(),
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
            );
          }

          // Pick or preserve selected class
          final activeClass = classes.firstWhere(
            (c) => c.id == selectedClassId,
            orElse: () => classes.first,
          );

          // Update provider & fetch children if needed
          if (selectedClassId != activeClass.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedCoachClassIdProvider.notifier).setClassId(activeClass.id);
              _fetchChildren(activeClass.enrolledChildIds);
            });
          } else if (_enrolledChildren.isEmpty && activeClass.enrolledChildIds.isNotEmpty && !_isLoadingChildren) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchChildren(activeClass.enrolledChildIds);
            });
          }

          final presentCount = activeClass.attendedChildIds.length;
          final enrolledCount = activeClass.enrolledChildIds.length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Class Selector & Action Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header Bar: Frosted back button + Live status badge + Title
                      Row(
                        children: [
                          if (Navigator.canPop(context)) ...[
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 42,
                                height: 42,
                                margin: const EdgeInsets.only(right: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'ТРЕНЕРСЬКИЙ ЖУРНАЛ',
                                      style: TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _coachTr('coach.journal_heading', 'Відвідуваність та нагороди'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 2. Full-Width Segmented Class Selector (Zero horizontal scroll)
                      Builder(
                        builder: (context) {
                          Widget buildClassCard(GroupClass c, {bool isExpanded = false}) {
                            final isSel = c.id == activeClass.id;
                            final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
                            final isGym = c.category.toLowerCase().contains('gym') || c.title.toLowerCase().contains('gym') || c.title.toLowerCase().contains('зал');
                            final sportIcon = isGym ? '🏋️' : '🏊';
                            final count = c.enrolledChildIds.length;

                            final card = GestureDetector(
                              onTap: () {
                                ref.read(selectedCoachClassIdProvider.notifier).setClassId(c.id);
                                _fetchChildren(c.enrolledChildIds);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  gradient: isSel
                                      ? LinearGradient(
                                          colors: [
                                            const Color(0xFF00E5FF).withValues(alpha: 0.28),
                                            const Color(0xFF0284C7).withValues(alpha: 0.18),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSel ? null : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.12),
                                    width: isSel ? 1.6 : 1,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(sportIcon, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 7),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            color: isSel ? const Color(0xFF00E5FF) : Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isSel)
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00E5FF),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isSel ? Colors.white : Colors.white70,
                                              fontSize: 12.5,
                                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                                                : Colors.white.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSel
                                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                                  : Colors.white.withValues(alpha: 0.08),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                LucideIcons.users,
                                                size: 10.5,
                                                color: isSel ? const Color(0xFF00E5FF) : Colors.white60,
                                              ),
                                              const SizedBox(width: 3.5),
                                              Text(
                                                '$count',
                                                style: TextStyle(
                                                  color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );

                            return isExpanded ? Expanded(child: card) : card;
                          }

                          if (classes.length == 1) {
                            return buildClassCard(classes.first);
                          } else if (classes.length == 2) {
                            return Row(
                              children: [
                                buildClassCard(classes[0], isExpanded: true),
                                const SizedBox(width: 10),
                                buildClassCard(classes[1], isExpanded: true),
                              ],
                            );
                          } else {
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth = (constraints.maxWidth - 10) / 2;
                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: classes.map((c) {
                                    final isLastOdd = classes.length % 2 != 0 && c == classes.last;
                                    return SizedBox(
                                      width: isLastOdd ? constraints.maxWidth : cardWidth,
                                      child: buildClassCard(c),
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Cyber-Luxe Smart QR Scanner Card with modern QR code scanner icon
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Glowing modern QR Scanner Badge with viewfinder & laser beam
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Text hierarchy
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _coachTr('coach.scan_qr_pass', 'СКАНУВАТИ ПЕРЕПУСТКУ'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.5,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Миттєва відмітка входу учня біля басейну',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right arrow indicator circle
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(LucideIcons.chevronRight, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Attendance count header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'СПИСОК ПЛАВЦІВ (${_enrolledChildren.length})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.check, size: 13, color: Color(0xFF10B981)),
                                const SizedBox(width: 5),
                                Text(
                                  'Присутні: $presentCount з $enrolledCount',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Enrolled Students List
              if (_isLoadingChildren)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    ),
                  ),
                )
              else if (_enrolledChildren.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.users, color: Color(0xFF00E5FF), size: 28),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'На це заняття ще немає записаних учнів',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Учні з\'являться тут автоматично після запису або сканування QR-перепустки',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final child = _enrolledChildren[index];
                        final isPresent = activeClass.attendedChildIds.contains(child.id);
                        return _buildSwimmerCard(child, isPresent, activeClass, index);
                      },
                      childCount: _enrolledChildren.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
        error: (e, _) => Center(child: Text('coach.load_error'.tr(args: ['$e']), style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildSwimmerCard(Child child, bool isPresent, GroupClass gClass, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPresent ? const Color(0xFF10B981).withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent ? const Color(0xFF10B981).withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: isPresent
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  blurRadius: 14,
                  spreadRadius: -1,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Glowing swimmer avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isPresent
                          ? [const Color(0xFF10B981), const Color(0xFF047857)]
                          : [const Color(0xFF00E5FF), const Color(0xFF0284C7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isPresent ? const Color(0xFF10B981) : const Color(0xFF00E5FF)).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Name, level & XP
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${'coach.level_label'.tr()} ${child.level}',
                              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${child.xp} XP',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Action buttons: Medal & Attendance toggle
                Row(
                  children: [
                    // Note button
                    IconButton(
                      icon: const Icon(LucideIcons.fileText, color: Colors.white60, size: 20),
                      onPressed: () => _showNoteDialog(child),
                      tooltip: 'coach.btn_add_note'.tr(),
                    ),

                    // Medal Award button
                    IconButton(
                      icon: const Icon(LucideIcons.medal, color: Color(0xFFF59E0B), size: 22),
                      onPressed: () => _awardMedal(child),
                      tooltip: 'coach.btn_award_medal'.tr(),
                    ),

                    // One-tap attendance check
                    GestureDetector(
                      onTap: () => _toggleAttendance(gClass, child.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPresent ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          boxShadow: isPresent
                              ? [
                                  const BoxShadow(
                                    color: Color(0xFF10B981),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isPresent ? LucideIcons.check : LucideIcons.userCheck,
                          color: isPresent ? Colors.black : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05, end: 0);
  }
}

// ============================================================================
// TAB 3: COACH SWIMMERS & GROUPS DIRECTORY (Групи школи та плавці)
// ============================================================================

class CoachSwimmersTab extends ConsumerStatefulWidget {
  const CoachSwimmersTab({super.key});

  @override
  ConsumerState<CoachSwimmersTab> createState() => _CoachSwimmersTabState();
}

class _CoachSwimmersTabState extends ConsumerState<CoachSwimmersTab> {
  int _selectedSegment = 0; // 0: Групи школи, 1: Всі плавці
  int _categoryFilter = 0;  // 0: Всі, 1: Діти, 2: Дорослі
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AppThemeConfig _themeConfig;
  late bool _isLight;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _categoryFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _categoryFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (_isLight ? Colors.white.withValues(alpha: 0.82) : Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.45)
                : (_isLight ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.12)),
            width: 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : (_isLight
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF032238)
                : (_isLight ? const Color(0xFF334155) : Colors.white70),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _themeConfig = ref.watch(appThemeControllerProvider);
    _isLight = !_themeConfig.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.users, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Групи та плавці',
                              style: TextStyle(
                                color: _themeConfig.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Каталог груп школи та база всіх плавців',
                              style: TextStyle(
                                color: _themeConfig.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Segmented Switcher: [ 🏊 Групи школи ] / [ 👤 Всі плавці ]
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isLight ? Colors.white.withValues(alpha: 0.78) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isLight ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.12),
                      ),
                      boxShadow: _isLight
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSegment = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: _selectedSegment == 0
                                    ? const LinearGradient(
                                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                border: _selectedSegment == 0
                                    ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.0)
                                    : null,
                                boxShadow: _selectedSegment == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.32),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.layers,
                                    size: 15,
                                    color: _selectedSegment == 0
                                        ? const Color(0xFF032238)
                                        : (_isLight ? const Color(0xFF475569) : Colors.white70),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Групи школи',
                                    style: TextStyle(
                                      color: _selectedSegment == 0
                                          ? const Color(0xFF032238)
                                          : (_isLight ? const Color(0xFF475569) : Colors.white70),
                                      fontWeight: _selectedSegment == 0 ? FontWeight.w900 : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSegment = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: _selectedSegment == 1
                                    ? const LinearGradient(
                                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                border: _selectedSegment == 1
                                    ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.0)
                                    : null,
                                boxShadow: _selectedSegment == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.32),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.users,
                                    size: 15,
                                    color: _selectedSegment == 1
                                        ? const Color(0xFF032238)
                                        : (_isLight ? const Color(0xFF475569) : Colors.white70),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Всі плавці',
                                    style: TextStyle(
                                      color: _selectedSegment == 1
                                          ? const Color(0xFF032238)
                                          : (_isLight ? const Color(0xFF475569) : Colors.white70),
                                      fontWeight: _selectedSegment == 1 ? FontWeight.w900 : FontWeight.w600,
                                      fontSize: 13,
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

                  const SizedBox(height: 14),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: _isLight ? Colors.white.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isLight ? Colors.white : Colors.white.withValues(alpha: 0.14),
                      ),
                      boxShadow: _isLight
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: _themeConfig.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: _selectedSegment == 0
                            ? 'Пошук групи за назвою, басейном чи тренером...'
                            : 'Пошук плавця за ім\'ям...',
                        hintStyle: TextStyle(
                          color: _isLight ? const Color(0xFF94A3B8) : Colors.white38,
                          fontSize: 13.5,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                          size: 18,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  color: _isLight ? const Color(0xFF64748B) : Colors.white54,
                                  size: 16,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Filter Chips: [ Всі ] [ 🧒 Діти ] [ 👤 Дорослі ]
                  Row(
                    children: [
                      _buildFilterChip('Всі', 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('🧒 Діти', 1),
                      const SizedBox(width: 8),
                      _buildFilterChip('👤 Дорослі', 2),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content body based on segment
          if (_selectedSegment == 0)
            _buildGroupsSliver()
          else
            _buildSwimmersSliver(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: GROUPS CATALOG
  // ==========================================
  Widget _buildGroupsSliver() {
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    if (scheduleAsync.isLoading && allClasses.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
          ),
        ),
      );
    }

    // Extract unique school groups (by title and lane)
    final Map<String, GroupClass> uniqueGroupsMap = {};
    for (final c in allClasses) {
      final key = '${c.title.trim().toLowerCase()}_${c.lane.trim().toLowerCase()}';
      if (!uniqueGroupsMap.containsKey(key)) {
        uniqueGroupsMap[key] = c;
      } else {
        final existing = uniqueGroupsMap[key]!;
        final combinedEnrolled = {...existing.enrolledChildIds, ...c.enrolledChildIds}.toList();
        uniqueGroupsMap[key] = existing.copyWith(
          enrolledChildIds: combinedEnrolled,
          maxCapacity: c.maxCapacity > existing.maxCapacity ? c.maxCapacity : existing.maxCapacity,
        );
      }
    }

    var groups = uniqueGroupsMap.values.toList();

    // Category filter: 0: All, 1: Kids, 2: Adults
    groups = groups.where((g) {
      final isAdult = g.category.toLowerCase().contains('доросла') ||
          g.title.toLowerCase().contains('доросла') ||
          g.title.toLowerCase().contains('аквафітнес');
      if (_categoryFilter == 1 && isAdult) return false;
      if (_categoryFilter == 2 && !isAdult) return false;
      if (_searchQuery.isNotEmpty) {
        final matchesTitle = g.title.toLowerCase().contains(_searchQuery);
        final matchesLane = g.lane.toLowerCase().contains(_searchQuery);
        final matchesCoach = g.coachName.toLowerCase().contains(_searchQuery);
        if (!matchesTitle && !matchesLane && !matchesCoach) return false;
      }
      return true;
    }).toList();

    // Sort alphabetically by title
    groups.sort((a, b) => a.title.compareTo(b.title));

    if (groups.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.layers,
                  color: _isLight ? const Color(0xFF94A3B8) : Colors.white30,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  'Груп за вашим запитом не знайдено',
                  style: TextStyle(
                    color: _themeConfig.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 180),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildGroupCard(groups[index], index);
          },
          childCount: groups.length,
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupClass group, int index) {
    final isAdult = group.category.toLowerCase().contains('доросла') ||
        group.title.toLowerCase().contains('доросла') ||
        group.title.toLowerCase().contains('аквафітнес');
    final enrolledCount = group.enrolledChildIds.length;
    final capacity = group.maxCapacity > 0 ? group.maxCapacity : 10;
    final fillRatio = (enrolledCount / capacity).clamp(0.0, 1.0);
    final accentColor = isAdult
        ? (_isLight ? const Color(0xFF9333EA) : const Color(0xFFA855F7))
        : (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: _isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.09),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.80),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLight
                    ? [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.74),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isLight ? Colors.white : accentColor.withValues(alpha: 0.35),
                width: _isLight ? 1.5 : 1.2,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title + Category Badge (ДІТИ / ДОРОСЛІ)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style: TextStyle(
                              color: _themeConfig.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                group.lane.toLowerCase().contains('дитяч') ? LucideIcons.baby : LucideIcons.waves,
                                size: 13,
                                color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                group.lane.isNotEmpty ? group.lane : 'Спортивний басейн',
                                style: TextStyle(
                                  color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: _isLight ? 0.10 : 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: _isLight ? 0.35 : 0.45),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: _isLight ? 0.10 : 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdult ? LucideIcons.user : LucideIcons.users,
                            size: 11,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAdult ? 'ДОРОСЛІ' : 'ДІТИ',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 2: Coach & Time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _isLight ? const Color(0xFFF1F5F9).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.userCheck,
                              size: 13,
                              color: _isLight ? const Color(0xFF64748B) : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                group.coachName.isNotEmpty ? group.coachName : 'Тренер клубу',
                                style: TextStyle(
                                  color: _themeConfig.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock3,
                            size: 13,
                            color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${DateFormat('HH:mm').format(group.startTime)} \u2013 ${DateFormat('HH:mm').format(group.endTime)}',
                            style: TextStyle(
                              color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Row 3: Fill rate & Capacity Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Заповненість: $enrolledCount з $capacity місць',
                      style: TextStyle(
                        color: _themeConfig.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(fillRatio * 100).toInt()}%',
                      style: TextStyle(
                        color: fillRatio >= 1.0
                            ? const Color(0xFFF43F5E)
                            : (_isLight ? const Color(0xFF059669) : const Color(0xFF10B981)),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.08),
                      ),
                      FractionallySizedBox(
                        widthFactor: fillRatio,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: fillRatio >= 1.0
                                  ? [const Color(0xFFF43F5E), const Color(0xFFFB7185)]
                                  : [const Color(0xFF00E5FF), const Color(0xFF10B981)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (fillRatio >= 1.0 ? const Color(0xFFF43F5E) : const Color(0xFF00E5FF)).withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Row 4: Action button - Open Group Attendees Sheet (Option A: Royal Sapphire Azure Gradient)
                InkWell(
                  onTap: () => showCoachClassAttendeesSheet(context, group),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLight
                            ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                            : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: 0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.users, size: 15, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Склад групи ($enrolledCount)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
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
    ).animate().fadeIn(delay: (index * 40).ms);
  }

  // ==========================================
  // TAB 1: ALL SWIMMERS & ADULT CLIENTS
  // ==========================================
  Widget _buildSwimmersSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('children').snapshots(),
      builder: (context, childSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').snapshots(),
          builder: (context, userSnap) {
            if (childSnap.connectionState == ConnectionState.waiting && !childSnap.hasData) {
              return SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                  ),
                ),
              );
            }

            final childDocs = childSnap.data?.docs ?? [];
            final userDocs = userSnap.data?.docs ?? [];

            final List<Map<String, dynamic>> allSwimmers = [];

            // Add children
            for (final d in childDocs) {
              final data = Map<String, dynamic>.from(d.data() as Map);
              data['id'] = d.id;
              final child = Child.fromJson(data);
              allSwimmers.add({
                'id': d.id,
                'name': child.name,
                'isAdult': false,
                'child': child,
                'age': child.age,
              });
            }

            // Add adult clients
            for (final d in userDocs) {
              final data = Map<String, dynamic>.from(d.data() as Map);
              final name = (data['name'] as String? ?? '').trim();
              if (name.isNotEmpty) {
                allSwimmers.add({
                  'id': d.id,
                  'name': name,
                  'isAdult': true,
                  'child': null,
                  'age': data['age'] as int?,
                });
              }
            }

            // Filter by category: 0: All, 1: Kids, 2: Adults
            var filtered = allSwimmers.where((s) {
              if (_categoryFilter == 1 && s['isAdult'] == true) return false;
              if (_categoryFilter == 2 && s['isAdult'] == false) return false;
              if (_searchQuery.isNotEmpty && !(s['name'] as String).toLowerCase().contains(_searchQuery)) {
                return false;
              }
              return true;
            }).toList();

            // Sort alphabetically by name
            filtered.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

            if (filtered.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.userX,
                          color: _isLight ? const Color(0xFF94A3B8) : Colors.white30,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Плавців за вашим запитом не знайдено',
                          style: TextStyle(
                            color: _themeConfig.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 180),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    final bool isAdult = item['isAdult'] as bool;
                    if (!isAdult && item['child'] != null) {
                      return _buildSwimmerDirectoryCard(item['child'] as Child, index);
                    } else {
                      return _buildAdultSwimmerCard(item['name'] as String, item['age'] as int?, index);
                    }
                  },
                  childCount: filtered.length,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdultSwimmerCard(String name, int? age, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.80),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLight
                    ? [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.74),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isLight ? Colors.white : const Color(0xFFA855F7).withValues(alpha: 0.35),
                width: _isLight ? 1.5 : 1.2,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: _themeConfig.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7).withValues(alpha: _isLight ? 0.10 : 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFA855F7).withValues(alpha: _isLight ? 0.30 : 0.45),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.user, size: 10, color: Color(0xFFA855F7)),
                                SizedBox(width: 4),
                                Text(
                                  'ДОРОСЛИЙ ПЛАВЕЦЬ',
                                  style: TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          if (age != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '$age р.',
                              style: TextStyle(
                                color: _themeConfig.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms);
  }

  Widget _buildSwimmerDirectoryCard(Child child, int index) {
    final progress = child.maxXp > 0 ? (child.xp / child.maxXp).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: _isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.09),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.80),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLight
                    ? [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.74),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isLight ? Colors.white : const Color(0xFF00E5FF).withValues(alpha: 0.40),
                width: _isLight ? 1.5 : 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => showSwimmerDetailsSheet(context, child),
                splashColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                highlightColor: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Header (Avatar + Name & Level/XP + Chevron)
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: TextStyle(
                                    color: _themeConfig.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _isLight
                                              ? const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)]
                                              : [
                                                  const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                                  const Color(0xFF0284C7).withValues(alpha: 0.12),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _isLight
                                              ? const Color(0xFF7DD3FC)
                                              : const Color(0xFF00E5FF).withValues(alpha: 0.50),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        '${_coachTr('coach.level_label', 'Рівень')} ${child.level}',
                                        style: TextStyle(
                                          color: _isLight ? const Color(0xFF0369A1) : const Color(0xFF38BDF8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.zap,
                                          size: 12,
                                          color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${child.xp}/${child.maxXp} XP',
                                          style: TextStyle(
                                            color: _themeConfig.textSecondary,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.14),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.chevronRight,
                              color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                              size: 17,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Illuminated mini XP progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _isLight ? const Color(0xFFE2E8F0) : Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _isLight ? Colors.white : Colors.white.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress > 0 ? progress : 0.02,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Row 2: Actions
                      Row(
                        children: [
                          // Medal Award button - Championship Gold Jewel Button
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showAwardMedalSheet(context, child),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFC107),
                                      Color(0xFFF59E0B),
                                      Color(0xFFD97706),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    width: 1.1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🏅', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          child.achievements.isEmpty
                                              ? _coachTr('coach.award_btn_short', 'Нагородити')
                                              : '${_coachTr('coach.award_btn_short', 'Нагородити')} (${child.achievements.length})',
                                          style: const TextStyle(
                                            color: Color(0xFF381A00),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // +25 XP quick bonus button
                          GestureDetector(
                            onTap: () => quickAddChildXp(context, child, 25),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9.5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLight
                                      ? const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)]
                                      : [
                                          const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                          const Color(0xFF0284C7).withValues(alpha: 0.15),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isLight
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFF00E5FF).withValues(alpha: 0.60),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.zap,
                                    size: 14,
                                    color: _isLight ? const Color(0xFF0369A1) : const Color(0xFF00E5FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+25 XP',
                                    style: TextStyle(
                                      color: _isLight ? const Color(0xFF0369A1) : const Color(0xFF00E5FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Note button
                          GestureDetector(
                            onTap: () => showCoachNoteDialog(context, child),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9.5),
                              decoration: BoxDecoration(
                                color: _isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isLight ? const Color(0xFFCBD5E1) : Colors.white.withValues(alpha: 0.20),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isLight
                                        ? const Color(0xFF0284C7).withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.20),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                LucideIcons.fileText,
                                color: _isLight ? const Color(0xFF475569) : Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (child.achievements.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: child.achievements.take(4).map((a) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: _isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(a.iconType, style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 5),
                                  Text(
                                    a.name,
                                    style: TextStyle(
                                      color: _themeConfig.textPrimary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms);
  }
}

void _confirmCoachLogout(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      backgroundColor: const Color(0xFF09182B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.2),
      ),
      title: Text('coach.end_shift'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(
        'coach.end_shift_confirm'.tr(),
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('coach.btn_cancel'.tr(), style: const TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            ref.read(authControllerProvider.notifier).logout();
            context.go('/');
          },
          child: Text('coach.btn_logout'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// ============================================================================
// TAB 4: COACH PROFILE & TELEMETRY (Кабінет Тренера)
// ============================================================================

class CoachProfileTab extends ConsumerStatefulWidget {
  const CoachProfileTab({super.key});

  @override
  ConsumerState<CoachProfileTab> createState() => _CoachProfileTabState();
}

class _CoachProfileTabState extends ConsumerState<CoachProfileTab> {
  bool _isIncomeHidden = false;
  int _selectedPeriod = 0; // 0: Цей місяць, 1: Минулий місяць, 2: Всі
  late AppThemeConfig _themeConfig;
  late bool _isLight;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();

    _themeConfig = ref.watch(appThemeControllerProvider);
    _isLight = !_themeConfig.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.id).snapshots(),
        builder: (context, userDocSnap) {
          final userData = userDocSnap.data?.data() as Map<String, dynamic>? ?? {};
          final int rateGroup = (userData['rateGroup'] as num?)?.toInt() ?? 400;
          final int rateIndividual = (userData['rateIndividual'] as num?)?.toInt() ?? 450;
          final int rateSplit = (userData['rateSplit'] as num?)?.toInt() ?? 600;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').snapshots(),
            builder: (context, classSnap) {
              final classDocs = classSnap.data?.docs ?? [];
              final List<GroupClass> coachClasses = [];

              for (final d in classDocs) {
                final data = Map<String, dynamic>.from(d.data() as Map);
                data['id'] = d.id;
                try {
                  final gc = GroupClass.fromJson(data);
                  final matchesId = gc.coachId == user.id;
                  final matchesName = gc.coachName.isNotEmpty &&
                      (gc.coachName.toLowerCase().contains(user.name.toLowerCase()) ||
                       user.name.toLowerCase().contains(gc.coachName.toLowerCase()));
                  if (matchesId || matchesName) {
                    coachClasses.add(gc);
                  }
                } catch (_) {}
              }

              // Period Filter
              final now = DateTime.now();
              final filteredClasses = coachClasses.where((c) {
                if (_selectedPeriod == 0) {
                  return c.startTime.year == now.year && c.startTime.month == now.month;
                } else if (_selectedPeriod == 1) {
                  final prev = DateTime(now.year, now.month - 1, 1);
                  return c.startTime.year == prev.year && c.startTime.month == prev.month;
                }
                return true;
              }).toList();

              // Sort by startTime descending
              filteredClasses.sort((a, b) => b.startTime.compareTo(a.startTime));

              int conductedGroup = 0;
              int conductedIndividual = 0;
              int conductedSplit = 0;

              int scheduledGroup = 0;
              int scheduledIndividual = 0;
              int scheduledSplit = 0;

              for (final c in filteredClasses) {
                final isConducted = c.startTime.isBefore(now) || c.attendedChildIds.isNotEmpty;
                final tLower = c.title.toLowerCase();
                final cLower = c.category.toLowerCase();
                final isSplit = tLower.contains('спліт') || tLower.contains('split') || (cLower.contains('індивідуал') && c.maxCapacity == 2);
                final isIndividual = !isSplit && (cLower.contains('індивідуал') || tLower.contains('індивідуал') || c.maxCapacity == 1);

                if (isConducted) {
                  if (isSplit) {
                    conductedSplit++;
                  } else if (isIndividual) {
                    conductedIndividual++;
                  } else {
                    conductedGroup++;
                  }
                } else {
                  if (isSplit) {
                    scheduledSplit++;
                  } else if (isIndividual) {
                    scheduledIndividual++;
                  } else {
                    scheduledGroup++;
                  }
                }
              }

              final conductedGroupSum = conductedGroup * rateGroup;
              final conductedIndividualSum = conductedIndividual * rateIndividual;
              final conductedSplitSum = conductedSplit * rateSplit;
              final totalEarned = conductedGroupSum + conductedIndividualSum + conductedSplitSum;
              final totalConducted = conductedGroup + conductedIndividual + conductedSplit;

              final scheduledSum = (scheduledGroup * rateGroup) + (scheduledIndividual * rateIndividual) + (scheduledSplit * rateSplit);
              final totalScheduled = scheduledGroup + scheduledIndividual + scheduledSplit;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 85),
                child: Column(
                  children: [
                    // 1. Coach Identity Card
                    _buildIdentityCard(user),

                    const SizedBox(height: 8),

                    // 2. Interactive Salary Card (VisionOS Glassmorphism Compact)
                    _buildSalaryCard(
                      totalEarned: totalEarned,
                      totalConducted: totalConducted,
                      scheduledSum: scheduledSum,
                      totalScheduled: totalScheduled,
                      conductedGroup: conductedGroup,
                      conductedGroupSum: conductedGroupSum,
                      rateGroup: rateGroup,
                      conductedIndividual: conductedIndividual,
                      conductedIndividualSum: conductedIndividualSum,
                      rateIndividual: rateIndividual,
                      conductedSplit: conductedSplit,
                      conductedSplitSum: conductedSplitSum,
                      rateSplit: rateSplit,
                      allFilteredClasses: filteredClasses,
                    ),

                    const SizedBox(height: 8),

                    // 3. Full-Width VIP Support Chat Card (Above KPI Cards)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _isLight
                                ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                                : const Color(0xFF00E5FF).withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: _isLight
                                ? const Color(0xFF0F172A).withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLight
                                    ? [
                                        Colors.white.withValues(alpha: 0.94),
                                        Colors.white.withValues(alpha: 0.78),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.12),
                                        Colors.white.withValues(alpha: 0.04),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isLight
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.22)
                                    : Colors.white.withValues(alpha: 0.16),
                                width: 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ParentChatScreen(
                                        title: 'Чат з Адміністратором',
                                        subtitle: 'Онлайн',
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7.5),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: _isLight
                                                ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                                                : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_isLight
                                                      ? const Color(0xFF0284C7)
                                                      : const Color(0xFF00E5FF))
                                                  .withValues(alpha: _isLight ? 0.30 : 0.40),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 15),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'coach.chat_admin'.tr(),
                                                  style: TextStyle(
                                                    color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF10B981).withValues(alpha: 0.70),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'coach.chat_admin_desc'.tr(),
                                              style: TextStyle(
                                                color: _isLight ? const Color(0xFF475569) : Colors.white60,
                                                fontSize: 10.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                        size: 16,
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

                    const SizedBox(height: 8),

                    // 4. Performance KPI Grid (2x2)
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            '$totalConducted',
                            'coach.kpi_classes_month'.tr(),
                            LucideIcons.calendarCheck,
                            _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildKpiCard(
                            '96%',
                            'coach.kpi_avg_attendance'.tr(),
                            LucideIcons.trendingUp,
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            '34',
                            'coach.kpi_active_swimmers'.tr(),
                            LucideIcons.users,
                            _isLight ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildKpiCard(
                            '5.0 ★',
                            'coach.kpi_coach_rating'.tr(),
                            LucideIcons.award,
                            _isLight ? const Color(0xFFDB2777) : const Color(0xFFEC4899),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 5. Logout Action Panel (At the Very Bottom)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: _isLight ? 0.08 : 0.14),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: _isLight
                                ? const Color(0xFF0F172A).withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLight
                                    ? [
                                        const Color(0xFFFFF1F2).withValues(alpha: 0.95),
                                        const Color(0xFFFFE4E6).withValues(alpha: 0.85),
                                      ]
                                    : [
                                        Colors.redAccent.withValues(alpha: 0.16),
                                        Colors.red.withValues(alpha: 0.05),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isLight
                                    ? const Color(0xFFFECDD3)
                                    : Colors.redAccent.withValues(alpha: 0.38),
                                width: 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _confirmCoachLogout(context, ref),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.5),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626).withValues(alpha: _isLight ? 0.12 : 0.18),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFDC2626).withValues(alpha: _isLight ? 0.25 : 0.35),
                                            width: 0.8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFDC2626).withValues(alpha: _isLight ? 0.12 : 0.25),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          LucideIcons.logOut,
                                          color: _isLight ? const Color(0xFFDC2626) : Colors.redAccent,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Text(
                                        'coach.end_shift_btn'.tr(),
                                        style: TextStyle(
                                          color: _isLight ? const Color(0xFFDC2626) : Colors.redAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                          shadows: _isLight
                                              ? null
                                              : [
                                                  Shadow(
                                                    color: Colors.redAccent.withValues(alpha: 0.40),
                                                    blurRadius: 8,
                                                  ),
                                                ],
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatConductedClassesCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return '$count проведених занять';
    if (mod10 == 1) return '$count проведене заняття';
    if (mod10 >= 2 && mod10 <= 4) return '$count проведені заняття';
    return '$count проведених занять';
  }

  String _formatClassesCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return '$count занять';
    if (mod10 == 1) return '$count заняття';
    if (mod10 >= 2 && mod10 <= 4) return '$count заняття';
    return '$count занять';
  }

  Widget _buildIdentityCard(AppUser user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isLight
                ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                : const Color(0xFF00E5FF).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _isLight
                ? const Color(0xFF0F172A).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLight
                    ? [
                        Colors.white.withValues(alpha: 0.94),
                        Colors.white.withValues(alpha: 0.78),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isLight
                    ? Colors.white.withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.16),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                // Concentric Glowing Avatar
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isLight
                          ? const [Color(0xFF0284C7), Color(0xFF00E5FF)]
                          : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                            .withValues(alpha: _isLight ? 0.25 : 0.38),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLight ? Colors.white : const Color(0xFF05172A),
                    ),
                    child: const AvatarPicker(
                      heroTag: 'hero_avatar_Тренерам_profile',
                      radius: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 11),

                // Coach Name, Pro Badge & Credentials in compact column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name.isNotEmpty ? user.name : 'coach.title'.tr(),
                              style: TextStyle(
                                color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Certified Coach Pro Rank Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLight
                                    ? [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)]
                                    : [
                                        const Color(0xFF00E5FF).withValues(alpha: 0.20),
                                        const Color(0xFF0284C7).withValues(alpha: 0.12),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: _isLight
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                width: 0.85,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                                      .withValues(alpha: _isLight ? 0.12 : 0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.shieldCheck,
                                  color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'coach.pro_rank'.tr(),
                                  style: TextStyle(
                                    color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Sleek Credentials Micro-Capsule
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isLight ? const Color(0xFFF1F5F9) : Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.user,
                              size: 9.5,
                              color: _isLight ? const Color(0xFF64748B) : Colors.white54,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              user.loginId ?? 'coach',
                              style: TextStyle(
                                color: _isLight ? const Color(0xFF334155) : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: _isLight ? const Color(0xFFCBD5E1) : Colors.white38,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.phone,
                              size: 9.5,
                              color: _isLight ? const Color(0xFF64748B) : Colors.white54,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              user.phone ?? '+380 (50) 123-45-67',
                              style: TextStyle(
                                color: _isLight ? const Color(0xFF334155) : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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

  Widget _buildSalaryCard({
    required int totalEarned,
    required int totalConducted,
    required int scheduledSum,
    required int totalScheduled,
    required int conductedGroup,
    required int conductedGroupSum,
    required int rateGroup,
    required int conductedIndividual,
    required int conductedIndividualSum,
    required int rateIndividual,
    required int conductedSplit,
    required int conductedSplitSum,
    required int rateSplit,
    required List<GroupClass> allFilteredClasses,
  }) {
    final currencyFormat = NumberFormat('#,###', 'uk_UA');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isLight
                ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                : const Color(0xFF00E5FF).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _isLight
                ? const Color(0xFF0F172A).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLight
                    ? [
                        Colors.white.withValues(alpha: 0.94),
                        Colors.white.withValues(alpha: 0.80),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isLight
                    ? Colors.white.withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.16),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Period Switcher [ Цей місяць | Минулий | Всі ] (Apple VisionOS Segmented Control)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _isLight ? const Color(0xFFF1F5F9) : Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodPill(label: 'Цей місяць', index: 0),
                      _buildPeriodPill(label: 'Минулий', index: 1),
                      _buildPeriodPill(label: 'Всі заняття', index: 2),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Header Row: Wallet Icon + "Заробітна плата" + Eye Privacy Toggle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isLight
                              ? const Color(0xFF10B981).withValues(alpha: 0.30)
                              : Colors.white.withValues(alpha: 0.30),
                          width: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: _isLight ? 0.30 : 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.wallet, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Заробітна плата',
                            style: TextStyle(
                              color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Container(
                                width: 4.5,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4.5),
                              Text(
                                _getPeriodSubtitle(),
                                style: TextStyle(
                                  color: _isLight ? const Color(0xFF475569) : Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _isIncomeHidden = !_isIncomeHidden),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isLight ? const Color(0xFFE2E8F0) : const Color(0xFF00E5FF).withValues(alpha: 0.25),
                              width: 0.9,
                            ),
                          ),
                          child: Icon(
                            _isIncomeHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                            color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Big Total Display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _isIncomeHidden ? '••••••••' : currencyFormat.format(totalEarned),
                      style: TextStyle(
                        color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 5),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: _isLight
                            ? const [Color(0xFF0284C7), Color(0xFF10B981)]
                            : const [Color(0xFF00E5FF), Color(0xFF10B981)],
                      ).createShader(bounds),
                      child: const Text(
                        'грн',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 12,
                      color: const Color(0xFF10B981).withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Нараховано за ${_formatConductedClassesCount(totalConducted)}',
                      style: TextStyle(
                        color: _isLight ? const Color(0xFF475569) : Colors.white.withValues(alpha: 0.75),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Scheduled projection banner (if any scheduled classes in this period)
                if (totalScheduled > 0 && _selectedPeriod == 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isLight ? const Color(0xFFFEF3C7) : const Color(0xFFF59E0B).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isLight ? const Color(0xFFFDE68A) : const Color(0xFFF59E0B).withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: _isLight ? 0.08 : 0.12),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.hourglass,
                          size: 13,
                          color: _isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Заплановано до кінця місяця: $totalScheduled занять (+${_isIncomeHidden ? '•••' : currencyFormat.format(scheduledSum)} грн)',
                            style: TextStyle(
                              color: _isLight ? const Color(0xFF92400E) : const Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 9),

                // 3 Category Triptych (VisionOS Glass Tri-Column)
                _buildCategoryTriptych(
                  conductedGroup: conductedGroup,
                  conductedGroupSum: conductedGroupSum,
                  rateGroup: rateGroup,
                  conductedIndividual: conductedIndividual,
                  conductedIndividualSum: conductedIndividualSum,
                  rateIndividual: rateIndividual,
                  conductedSplit: conductedSplit,
                  conductedSplitSum: conductedSplitSum,
                  rateSplit: rateSplit,
                  currencyFormat: currencyFormat,
                ),

                const SizedBox(height: 9),

                // Details Button (Option A - Royal Sapphire Gradient in Light Mode)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showSalaryDetailsSheet(
                      context,
                      allFilteredClasses,
                      rateGroup,
                      rateIndividual,
                      rateSplit,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isLight
                              ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                              : [
                                  const Color(0xFF00E5FF).withValues(alpha: 0.16),
                                  const Color(0xFF0284C7).withValues(alpha: 0.08),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isLight
                              ? const Color(0xFF0284C7).withValues(alpha: 0.60)
                              : const Color(0xFF00E5FF).withValues(alpha: 0.35),
                          width: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: _isLight ? 0.35 : 0.10),
                            blurRadius: _isLight ? 12 : 10,
                            offset: _isLight ? const Offset(0, 3) : Offset.zero,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: _isLight
                                  ? Colors.white.withValues(alpha: 0.20)
                                  : const Color(0xFF00E5FF).withValues(alpha: 0.20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.receipt,
                              size: 12.5,
                              color: _isLight ? Colors.white : const Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Деталізація проведених занять ($totalConducted)',
                            style: TextStyle(
                              color: _isLight ? Colors.white : const Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: _isLight ? Colors.white : const Color(0xFF00E5FF),
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

  Widget _buildPeriodPill({required String label, required int index}) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 5.5),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: _isLight
                        ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                        : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: _isLight
                        ? Colors.white.withValues(alpha: 0.60)
                        : Colors.white.withValues(alpha: 0.85),
                    width: 0.8,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: _isLight ? 0.30 : 0.40),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (_isLight ? const Color(0xFF475569) : Colors.white.withValues(alpha: 0.70)),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPeriodSubtitle() {
    final now = DateTime.now();
    if (_selectedPeriod == 0) {
      return DateFormat('LLLL yyyy', 'uk_UA').format(now).toUpperCase();
    } else if (_selectedPeriod == 1) {
      final prev = DateTime(now.year, now.month - 1, 1);
      return DateFormat('LLLL yyyy', 'uk_UA').format(prev).toUpperCase();
    }
    return 'ЗА ВЕСЬ ЧАС';
  }

  Widget _buildCategoryTriptych({
    required int conductedGroup,
    required int conductedGroupSum,
    required int rateGroup,
    required int conductedIndividual,
    required int conductedIndividualSum,
    required int rateIndividual,
    required int conductedSplit,
    required int conductedSplitSum,
    required int rateSplit,
    required NumberFormat currencyFormat,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isLight ? const Color(0xFFF8FAFC) : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.10),
          width: 0.9,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: _buildTriptychCol(
              title: 'Групові',
              icon: LucideIcons.users,
              count: conductedGroup,
              sum: conductedGroupSum,
              color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
              currencyFormat: currencyFormat,
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.10),
          ),
          Expanded(
            child: _buildTriptychCol(
              title: 'Індивід.',
              icon: LucideIcons.user,
              count: conductedIndividual,
              sum: conductedIndividualSum,
              color: _isLight ? const Color(0xFF9333EA) : const Color(0xFFA855F7),
              currencyFormat: currencyFormat,
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.10),
          ),
          Expanded(
            child: _buildTriptychCol(
              title: 'Спліт',
              icon: LucideIcons.userCheck,
              count: conductedSplit,
              sum: conductedSplitSum,
              color: _isLight ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
              currencyFormat: currencyFormat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriptychCol({
    required String title,
    required IconData icon,
    required int count,
    required int sum,
    required Color color,
    required NumberFormat currencyFormat,
  }) {
    final hasEarnings = sum > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
      decoration: BoxDecoration(
        color: hasEarnings
            ? color.withValues(alpha: _isLight ? 0.08 : 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: hasEarnings
            ? Border.all(
                color: color.withValues(alpha: _isLight ? 0.20 : 0.28),
                width: 0.8,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 11.5,
                color: hasEarnings ? color : (_isLight ? const Color(0xFF94A3B8) : Colors.white54),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: hasEarnings
                      ? (_isLight ? const Color(0xFF0F172A) : Colors.white)
                      : (_isLight ? const Color(0xFF94A3B8) : Colors.white60),
                  fontSize: 11,
                  fontWeight: hasEarnings ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _isIncomeHidden ? '••••' : '${currencyFormat.format(sum)} ₴',
            style: TextStyle(
              color: hasEarnings ? color : (_isLight ? const Color(0xFFCBD5E1) : Colors.white38),
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              shadows: (hasEarnings && !_isLight)
                  ? [
                      Shadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _formatClassesCount(count),
            style: TextStyle(
              color: hasEarnings
                  ? (_isLight ? const Color(0xFF475569) : Colors.white70)
                  : (_isLight ? const Color(0xFF94A3B8) : Colors.white38),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showSalaryDetailsSheet(
    BuildContext context,
    List<GroupClass> classes,
    int rateGroup,
    int rateIndividual,
    int rateSplit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final now = DateTime.now();

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: _isLight ? const Color(0xFFF8FAFC) : const Color(0xFF030D1B).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: _isLight ? const Color(0xFFE2E8F0) : const Color(0xFF00E5FF).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isLight
                    ? const Color(0xFF0F172A).withValues(alpha: 0.12)
                    : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            children: [
              // Sheet Handle & Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _isLight ? const Color(0xFFCBD5E1) : Colors.white38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.receipt,
                              color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Деталізація нарахувань',
                              style: TextStyle(
                                color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: _isLight ? const Color(0xFF64748B) : Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(
                color: _isLight ? const Color(0xFFE2E8F0) : Colors.white12,
                height: 1,
              ),

              // Class List
              Expanded(
                child: classes.isEmpty
                    ? Center(
                        child: Text(
                          'Занять у цьому періоді не знайдено',
                          style: TextStyle(
                            color: _isLight ? const Color(0xFF64748B) : Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final c = classes[index];
                          final isConducted = c.startTime.isBefore(now) || c.attendedChildIds.isNotEmpty;
                          final tLower = c.title.toLowerCase();
                          final cLower = c.category.toLowerCase();
                          final isSplit = tLower.contains('спліт') || tLower.contains('split') || (cLower.contains('індивідуал') && c.maxCapacity == 2);
                          final isIndividual = !isSplit && (cLower.contains('індивідуал') || tLower.contains('індивідуал') || c.maxCapacity == 1);

                          final String typeLabel;
                          final int earned;
                          final Color typeColor;

                          if (isSplit) {
                            typeLabel = 'Спліт';
                            earned = rateSplit;
                            typeColor = _isLight ? const Color(0xFFD97706) : const Color(0xFFF59E0B);
                          } else if (isIndividual) {
                            typeLabel = 'Індивідуальне';
                            earned = rateIndividual;
                            typeColor = _isLight ? const Color(0xFF9333EA) : const Color(0xFFA855F7);
                          } else {
                            typeLabel = 'Групове';
                            earned = rateGroup;
                            typeColor = _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLight
                                    ? [Colors.white, const Color(0xFFF8FAFC)]
                                    : [
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.03),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isConducted
                                    ? typeColor.withValues(alpha: _isLight ? 0.35 : 0.35)
                                    : (_isLight ? const Color(0xFFE2E8F0) : Colors.white12),
                                width: 1.1,
                              ),
                              boxShadow: _isLight
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: _isLight ? 0.12 : 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: typeColor.withValues(alpha: _isLight ? 0.30 : 0.40)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: typeColor.withValues(alpha: _isLight ? 0.10 : 0.20),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isSplit ? LucideIcons.userCheck : (isIndividual ? LucideIcons.user : LucideIcons.users),
                                      color: typeColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.title,
                                        style: TextStyle(
                                          color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            DateFormat('d MMM, HH:mm', 'uk_UA').format(c.startTime),
                                            style: TextStyle(
                                              color: _isLight ? const Color(0xFF64748B) : Colors.white60,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(alpha: _isLight ? 0.12 : 0.18),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: typeColor.withValues(alpha: _isLight ? 0.25 : 0.35)),
                                            ),
                                            child: Text(
                                              typeLabel,
                                              style: TextStyle(
                                                color: typeColor,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isConducted ? '+$earned ₴' : '0 ₴',
                                      style: TextStyle(
                                        color: isConducted
                                            ? const Color(0xFF10B981)
                                            : (_isLight ? const Color(0xFF94A3B8) : Colors.white38),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isConducted ? 'Проведено' : 'Заплановано',
                                      style: TextStyle(
                                        color: isConducted
                                            ? (_isLight ? const Color(0xFF475569) : Colors.white60)
                                            : (_isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24)),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: _isLight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.94),
                  Colors.white.withValues(alpha: 0.82),
                ],
              )
            : RadialGradient(
                center: Alignment.topLeft,
                radius: 1.3,
                colors: [
                  color.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLight ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.32),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isLight ? color.withValues(alpha: 0.10) : color.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: _isLight ? const Color(0xFF0F172A).withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLight
                        ? [color.withValues(alpha: 0.22), color.withValues(alpha: 0.10)]
                        : [color.withValues(alpha: 0.32), color.withValues(alpha: 0.16)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isLight ? color.withValues(alpha: 0.35) : color.withValues(alpha: 0.50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: _isLight ? 0.18 : 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              Icon(LucideIcons.sparkles, color: color.withValues(alpha: _isLight ? 0.60 : 0.50), size: 12),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                shadows: _isLight
                    ? null
                    : [Shadow(color: color.withValues(alpha: 0.65), blurRadius: 10)],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _isLight ? const Color(0xFF475569) : Colors.white70,
              fontSize: 10,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
