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
import 'package:go_router/go_router.dart';

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
                                style: const TextStyle(
                                  color: Colors.white,
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
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF10B981),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'coach.on_shift'.tr(),
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Quick QR Scanner Action Button (Icon-only cyber-luxe badge)
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Logout button
                      Tooltip(
                        message: 'Вийти з кабінету',
                        child: GestureDetector(
                          onTap: () => _confirmCoachLogout(context, ref),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1.2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.logOut, color: Colors.white70, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 20),

                  // Shift telemetry card
                  _buildShiftTelemetryCard(),

                  const SizedBox(height: 14),

                  // Changes & Activity Feed Banner
                  const CoachChangesBanner(),

                  const SizedBox(height: 14),

                  // Daily Headcount & Capacity Summary
                  if (todayClasses.isNotEmpty) ...[
                    _buildDailyHeadcountCard(
                      totalKidsToday,
                      todayClasses.length,
                      totalFreeToday,
                      totalCapToday,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Quick Attendance Journal Action Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachJournalScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF).withValues(alpha: 0.18),
                            const Color(0xFF0077B6).withValues(alpha: 0.22),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
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
                                colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.clipboardCheck, color: Colors.white, size: 19),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'coach.quick_attendance'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'coach.quick_attendance_sub'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, color: Color(0xFF00E5FF), size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section title & Today Date Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'coach.schedule_today'.tr(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 5),
                            Text(
                              DateFormat('d MMMM', context.locale.languageCode).format(DateTime.now()),
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
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

          // Schedule list content (Today's classes only)
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
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 140),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Icon(LucideIcons.calendarCheck2, color: Color(0xFF00E5FF), size: 44),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'coach.no_classes_today_title'.tr(),
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'coach.no_classes_today_desc'.tr(),
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                              foregroundColor: const Color(0xFF00E5FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                            ),
                            onPressed: () {
                              ref.read(coachTabProvider.notifier).setTab(1);
                            },
                            icon: const Icon(LucideIcons.calendarDays, size: 16),
                            label: Text(
                              'coach.open_calendar'.tr(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildClassCard(displayClasses[index], index);
                    },
                    childCount: displayClasses.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('coach.load_error'.tr(args: ['$e']), style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTelemetryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Row(
            children: [
              _buildTelemetryMetric(
                icon: LucideIcons.waves,
                iconColor: const Color(0xFF00E5FF),
                label: 'coach.telemetry_water_temp'.tr(),
                value: '27.8°C',
              ),
              Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.12)),
              _buildTelemetryMetric(
                icon: LucideIcons.clock3,
                iconColor: const Color(0xFF10B981),
                label: 'coach.telemetry_duty'.tr(),
                value: '08:00 - 20:00',
              ),
              Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.12)),
              _buildTelemetryMetric(
                icon: LucideIcons.shieldCheck,
                iconColor: const Color(0xFFF59E0B),
                label: 'coach.telemetry_shift_status'.tr(),
                value: 'coach.status_active'.tr(),
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
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildDailyHeadcountCard(int totalKids, int totalClasses, int freeSlots, int totalCapacity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
          width: 1.1,
        ),
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
                    const Text(
                      'НА СЬОГОДНІ: ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$totalKids дітей у $totalClasses ${totalClasses == 1 ? "групі" : "групах"}',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
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
                    color: freeSlots > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(GroupClass gClass, int index) {
    final startTimeStr = '${gClass.startTime.hour.toString().padLeft(2, '0')}:${gClass.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${gClass.endTime.hour.toString().padLeft(2, '0')}:${gClass.endTime.minute.toString().padLeft(2, '0')}';
    final enrolledCount = gClass.enrolledChildIds.length;
    final attendedCount = gClass.attendedChildIds.length;
    final maxCap = gClass.maxCapacity > 0 ? gClass.maxCapacity : 8;
    final freeSlots = (maxCap - enrolledCount).clamp(0, maxCap);
    final fillFraction = (enrolledCount / maxCap).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
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
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              gClass.category.isNotEmpty ? gClass.category : 'parent.swimming'.tr(),
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (gClass.lane.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                gClass.lane,
                                style: const TextStyle(
                                  color: Colors.white70,
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
                                        : (freeSlots <= 2 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
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
                        const Icon(LucideIcons.clock, color: Colors.white54, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '$startTimeStr - $endTimeStr',
                          style: const TextStyle(
                            color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
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
                    const Icon(LucideIcons.user, color: Colors.white54, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'coach.assigned_coach'.tr(args: [gClass.coachName.isNotEmpty ? gClass.coachName : 'coach.title'.tr()]),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(fillFraction * 100).toInt()}%',
                      style: TextStyle(
                        color: fillFraction > 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
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
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fillFraction > 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF00E5FF),
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
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
        trailing: const Icon(LucideIcons.chevronRight, color: Color(0xFF00E5FF), size: 18),
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
          color: const Color(0xFF09182B).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
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
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where(FieldPath.documentId, whereIn: childIds.take(20).toList())
          .get();

      final children = snapshot.docs.map((doc) => Child.fromJson({'id': doc.id, ...doc.data()})).toList();
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
// TAB 3: COACH SWIMMERS DIRECTORY (Мої Вихованці)
// ============================================================================

class CoachSwimmersTab extends StatefulWidget {
  const CoachSwimmersTab({super.key});

  @override
  State<CoachSwimmersTab> createState() => _CoachSwimmersTabState();
}

class _CoachSwimmersTabState extends State<CoachSwimmersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                              blurRadius: 12,
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
                              'coach.swimmers_heading'.tr() == 'Мої учні'
                                  ? 'Мої плавці'
                                  : ('coach.swimmers_heading'.tr() == 'Мои ученики'
                                      ? 'Мои пловцы'
                                      : 'coach.swimmers_heading'.tr()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'coach.swimmers_subheading'.tr().replaceAll('юних плавців', 'плавців'),
                              style: const TextStyle(
                                color: Colors.white60,
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

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'coach.swimmers_search'.tr().replaceAll('учня', 'плавця').replaceAll('ученика', 'пловца'),
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5),
                        prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF00E5FF), size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Swimmers Stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('children').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final swimmers = docs
                  .map((d) => Child.fromJson({'id': d.id, ...d.data() as Map<String, dynamic>}))
                  .where((c) => _searchQuery.isEmpty || c.name.toLowerCase().contains(_searchQuery))
                  .toList();

              if (swimmers.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'coach.no_swimmers_found'.tr().replaceAll('Вихованців', 'Плавців').replaceAll('Учнів', 'Плавців'),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 140),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final child = swimmers[index];
                      return _buildSwimmerDirectoryCard(child, index);
                    },
                    childCount: swimmers.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwimmerDirectoryCard(Child child, int index) {
    final progress = child.maxXp > 0 ? (child.xp / child.maxXp).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showSwimmerDetailsSheet(context, child),
          splashColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
          highlightColor: const Color(0xFF00E5FF).withValues(alpha: 0.08),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Header (Avatar + Name & Level/XP + Chevron)
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.name,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '${_coachTr('coach.level_label', 'Рівень')} ${child.level}',
                                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${child.xp}/${child.maxXp} XP',
                                    style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.chevronRight, color: Color(0xFF00E5FF), size: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Full-width mini progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 4,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.08),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Row 2: Actions - 100% responsive, never overflows
                    Row(
                      children: [
                        // Medal Award button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showAwardMedalSheet(context, child),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                    const Color(0xFFD97706).withValues(alpha: 0.18),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🏅', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        child.achievements.isEmpty
                                            ? _coachTr('coach.award_btn_short', 'Нагородити')
                                            : '${_coachTr('coach.award_btn_short', 'Нагородити')} (${child.achievements.length})',
                                        style: const TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.zap, size: 13, color: Color(0xFF00E5FF)),
                                SizedBox(width: 4),
                                Text(
                                  '+25 XP',
                                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11.5, fontWeight: FontWeight.w800),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: const Icon(LucideIcons.fileText, color: Colors.white70, size: 15),
                          ),
                        ),
                      ],
                    ),
                    if (child.achievements.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: child.achievements.take(4).map((a) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(a.iconType, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(a.name, style: const TextStyle(color: Colors.white70, fontSize: 10)),
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

class CoachProfileTab extends ConsumerWidget {
  const CoachProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
        child: Column(
          children: [
            // Coach Identity Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Column(
                    children: [
                      // Avatar with glowing ring
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const AvatarPicker(
                          heroTag: 'hero_avatar_Тренерам_profile',
                          radius: 46,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user?.name ?? 'coach.title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'coach.pro_rank'.tr(),
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'coach.login_prefix'.tr(args: [user?.loginId ?? 'coach', user?.phone ?? '+380 (50) 123-45-67']),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Performance KPI Grid
            Row(
              children: [
                Expanded(child: _buildKpiCard('48', 'coach.kpi_classes_month'.tr(), LucideIcons.calendarCheck, const Color(0xFF00E5FF))),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('96%', 'coach.kpi_avg_attendance'.tr(), LucideIcons.trendingUp, const Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildKpiCard('34', 'coach.kpi_active_swimmers'.tr(), LucideIcons.users, const Color(0xFFF59E0B))),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('5.0 ★', 'coach.kpi_coach_rating'.tr(), LucideIcons.award, const Color(0xFFEC4899))),
              ],
            ),

            const SizedBox(height: 24),

            // Support Action Card (Чат з Адміністратором)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.messageSquare, color: Color(0xFF00E5FF), size: 20),
                  ),
                  title: Text(
                    'coach.chat_admin'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    'coach.chat_admin_desc'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 18),
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
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Logout Button
            GestureDetector(
              onTap: () => _confirmCoachLogout(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'coach.end_shift_btn'.tr(),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String value, String label, IconData icon, Color color) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(LucideIcons.sparkles, color: color.withValues(alpha: 0.5), size: 14),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}
