import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/coach/presentation/qr_scanner_screen.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import '../coach_journal_screen.dart';
import '../coach_changes_banner.dart';
import '../coach_class_attendees_sheet.dart';
import '../coach_dashboard.dart';

String _coachTr(String key, String fallback, {List<String>? args}) => coachTr(key, fallback, args: args);
void _confirmCoachLogout(BuildContext context, WidgetRef ref) => confirmCoachLogout(context, ref);

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
    final coachBranch = user?.branchId ?? 'kyiv';
    final coachBranches = user?.branchIds ?? [coachBranch];

    final todayClasses = allClasses.where((c) {
      final classDate = DateTime(c.startTime.year, c.startTime.month, c.startTime.day);
      if (!classDate.isAtSameMomentAs(today)) return false;
      final isMock = user?.id == 'mock_coach';
      if (!isMock) {
        final matchesBranch = c.branchId == coachBranch || coachBranches.contains(c.branchId);
        if (!matchesBranch) return false;
      }
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
                      // Quick Logout button (Luxury frosted ruby crystal orb)
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
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF7F1D1D).withValues(alpha: 0.60),
                                        const Color(0xFF450A0A).withValues(alpha: 0.80),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.95),
                                        const Color(0xFFFFF1F2).withValues(alpha: 0.85),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: themeConfig.isDark ? 0.55 : 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: themeConfig.isDark ? 0.30 : 0.10),
                                  blurRadius: themeConfig.isDark ? 14 : 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.logOut,
                                color: themeConfig.isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444),
                                size: 18,
                              ),
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
                                      const Color(0xFF0E2A4D),
                                      const Color(0xFF071A31),
                                    ]
                                  : [
                                      Colors.white.withValues(alpha: 0.78),
                                      Colors.white.withValues(alpha: 0.62),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: themeConfig.isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.28)
                                  : Colors.white.withValues(alpha: 0.95),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: themeConfig.isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                    : const Color(0xFF003B73).withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: themeConfig.isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                                        : const Color(0xFF0284C7).withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: themeConfig.isDark
                                          ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                          : const Color(0xFF0284C7).withValues(alpha: 0.20),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: themeConfig.isDark ? 0.30 : 0.12),
                                        blurRadius: 22,
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
                                                  const Color(0xFF00E5FF).withValues(alpha: 0.40),
                                                  const Color(0xFF082B4A).withValues(alpha: 0.92),
                                                ]
                                              : [
                                                  const Color(0xFFBAE6FD).withValues(alpha: 0.65),
                                                  const Color(0xFFE0F2FE).withValues(alpha: 0.30),
                                                ],
                                        ),
                                        border: Border.all(
                                          color: themeConfig.isDark
                                              ? const Color(0xFF00E5FF).withValues(alpha: 0.70)
                                              : const Color(0xFF38BDF8).withValues(alpha: 0.50),
                                          width: 1.4,
                                        ),
                                        boxShadow: themeConfig.isDark
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                                                  blurRadius: 14,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.calendarCheck2,
                                          color: themeConfig.isDark ? Colors.white : const Color(0xFF0284C7),
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
                                          color: Colors.white.withValues(alpha: 0.45),
                                          width: 1.1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00E5FF).withValues(alpha: themeConfig.isDark ? 0.48 : 0.28),
                                            blurRadius: 18,
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
                                        const Color(0xFF0F2D50),
                                        const Color(0xFF081C33),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.78),
                                        Colors.white.withValues(alpha: 0.62),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: themeConfig.isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.32)
                                    : Colors.white.withValues(alpha: 0.95),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeConfig.isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
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
                                      color: Colors.white.withValues(alpha: 0.50),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: themeConfig.isDark ? 0.45 : 0.28),
                                        blurRadius: 14,
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
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                                        : const Color(0xFFE0F2FE).withValues(alpha: 0.85),
                                    border: Border.all(
                                      color: themeConfig.isDark
                                          ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                                          : const Color(0xFF38BDF8).withValues(alpha: 0.50),
                                      width: 1.2,
                                    ),
                                    boxShadow: themeConfig.isDark
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.chevronRight,
                                      color: themeConfig.isDark ? Colors.white : const Color(0xFF0284C7),
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
                      const Color(0xFF0F2C4E).withValues(alpha: 0.85),
                      const Color(0xFF081B32).withValues(alpha: 0.92),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.62),
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: themeConfig.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.95),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: themeConfig.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                    : const Color(0xFF003B73).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildTelemetryMetric(
                icon: LucideIcons.waves,
                iconColor: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                gradientColors: themeConfig.isDark
                    ? [const Color(0xFF00E5FF).withValues(alpha: 0.35), const Color(0xFF0284C7).withValues(alpha: 0.20)]
                    : const [Color(0xFF06B6D4), Color(0xFF0284C7)],
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
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
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
                iconColor: themeConfig.isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                gradientColors: themeConfig.isDark
                    ? [const Color(0xFF38BDF8).withValues(alpha: 0.35), const Color(0xFF0284C7).withValues(alpha: 0.20)]
                    : const [Color(0xFF38BDF8), Color(0xFF2563EB)],
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
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
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
                gradientColors: themeConfig.isDark
                    ? [const Color(0xFF10B981).withValues(alpha: 0.35), const Color(0xFF047857).withValues(alpha: 0.20)]
                    : const [Color(0xFF10B981), Color(0xFF059669)],
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
    List<Color>? gradientColors,
    Color? valueColor,
    bool isLiveBeacon = false,
  }) {
    final colors = gradientColors ??
        (themeConfig.isDark
            ? [
                iconColor.withValues(alpha: 0.35),
                iconColor.withValues(alpha: 0.15),
              ]
            : [
                iconColor,
                iconColor.withValues(alpha: 0.85),
              ]);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: themeConfig.isDark
                    ? iconColor.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.80),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (themeConfig.isDark ? iconColor : colors.last)
                      .withValues(alpha: themeConfig.isDark ? 0.35 : 0.28),
                  blurRadius: themeConfig.isDark ? 12 : 10,
                  offset: themeConfig.isDark ? Offset.zero : const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 17,
                shadows: themeConfig.isDark
                    ? [
                        Shadow(
                          color: iconColor,
                          blurRadius: 8,
                        ),
                      ]
                    : [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
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
                      const Color(0xFF0F2D50),
                      const Color(0xFF081C33),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.62),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeConfig.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.95),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: themeConfig.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.14)
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
                            padding: const EdgeInsets.symmetric(horizontal: 9.5, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: freeSlots == 0
                                  ? const LinearGradient(
                                      colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : (freeSlots <= 2
                                      ? const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: freeSlots == 0
                                    ? const Color(0xFFFDA4AF).withValues(alpha: 0.65)
                                    : (freeSlots <= 2
                                        ? const Color(0xFFFDE68A).withValues(alpha: 0.65)
                                        : const Color(0xFFA7F3D0).withValues(alpha: 0.65)),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: freeSlots == 0
                                      ? const Color(0xFFE11D48).withValues(alpha: 0.40)
                                      : (freeSlots <= 2
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                          : const Color(0xFF10B981).withValues(alpha: 0.30)),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  freeSlots == 0 ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
                                  size: 11.5,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4.5),
                                Text(
                                  freeSlots == 0 ? 'Заповнено' : 'Вільно: $freeSlots',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
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

