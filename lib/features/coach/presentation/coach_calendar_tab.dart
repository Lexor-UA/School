import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'coach_class_attendees_sheet.dart';

class CoachCalendarTab extends ConsumerStatefulWidget {
  const CoachCalendarTab({super.key});

  @override
  ConsumerState<CoachCalendarTab> createState() => _CoachCalendarTabState();
}

class _CoachCalendarTabState extends ConsumerState<CoachCalendarTab> {
  DateTime _selectedDate = DateTime.now();
  bool _onlyMyClasses = true; // Default to coach's own classes as user requested

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    final coachBranch = user?.branchId ?? 'kyiv';
    final coachBranches = user?.branchIds ?? [coachBranch];
    final branchClasses = user != null
        ? allClasses.where((c) => c.branchId == coachBranch || coachBranches.contains(c.branchId)).toList()
        : allClasses;

    // Filter classes for selected day
    final dayClassesAll = branchClasses.where((c) =>
      c.startTime.year == _selectedDate.year &&
      c.startTime.month == _selectedDate.month &&
      c.startTime.day == _selectedDate.day
    ).toList();
    dayClassesAll.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Filter by coach if toggle active
    final dayClasses = _onlyMyClasses && user != null
        ? dayClassesAll.where((c) {
            final matchesId = c.coachId == user.id;
            final matchesName = user.name.isNotEmpty &&
                c.coachName.toLowerCase().contains(user.name.toLowerCase());
            final isMock = user.id == 'mock_coach';
            return matchesId || matchesName || isMock;
          }).toList()
        : dayClassesAll;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Header & Calendar Card
          _buildCalendarCard(branchClasses, themeConfig),
          const SizedBox(height: 14),

          // Selected Day Schedule Section
          _buildDayScheduleSection(dayClasses, dayClassesAll.length, themeConfig),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(List<GroupClass> allClasses, AppThemeConfig themeConfig) {
    final user = ref.watch(authControllerProvider);
    final monthName = DateFormat('LLLL yyyy', context.locale.languageCode).format(_selectedDate);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final firstDayOffset = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday - 1;
    final totalCells = ((daysInMonth + firstDayOffset) / 7).ceil() * 7;
    final prevMonthDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonthDate.year, prevMonthDate.month);
    final nextMonthDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    final daysOfWeek = [
      'admin.wd_mon'.tr(),
      'admin.wd_tue'.tr(),
      'admin.wd_wed'.tr(),
      'admin.wd_thu'.tr(),
      'admin.wd_fri'.tr(),
      'admin.wd_sat'.tr(),
      'admin.wd_sun'.tr(),
    ];

    return ClipRRect(
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Month Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: themeConfig.isDark ? 0.35 : 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.calendar, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        capitalizedMonth,
                        style: TextStyle(
                          color: themeConfig.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildMonthNavButton(
                        icon: LucideIcons.chevronLeft,
                        themeConfig: themeConfig,
                        onTap: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1)),
                      ),
                      const SizedBox(width: 8),
                      _buildMonthNavButton(
                        icon: LucideIcons.chevronRight,
                        themeConfig: themeConfig,
                        onTap: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Days of week header
              Row(
                children: daysOfWeek.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final d = entry.value;
                  final isWeekend = idx == 5 || idx == 6;
                  return Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: isWeekend
                              ? (themeConfig.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                              : (themeConfig.isDark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF64748B)),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Grid of days
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.20,
                ),
                itemBuilder: (context, index) {
                  DateTime cellDate;
                  int day;
                  bool isCurrentMonth = true;

                  if (index < firstDayOffset) {
                    isCurrentMonth = false;
                    day = daysInPrevMonth - firstDayOffset + index + 1;
                    cellDate = DateTime(prevMonthDate.year, prevMonthDate.month, day);
                  } else if (index < firstDayOffset + daysInMonth) {
                    isCurrentMonth = true;
                    day = index - firstDayOffset + 1;
                    cellDate = DateTime(_selectedDate.year, _selectedDate.month, day);
                  } else {
                    isCurrentMonth = false;
                    day = index - (firstDayOffset + daysInMonth) + 1;
                    cellDate = DateTime(nextMonthDate.year, nextMonthDate.month, day);
                  }

                  final isSelected = cellDate.year == _selectedDate.year &&
                      cellDate.month == _selectedDate.month &&
                      cellDate.day == _selectedDate.day;

                  final now = DateTime.now();
                  final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;

                  // Check if classes exist on this day
                  final dayClasses = allClasses.where((c) =>
                      c.startTime.year == cellDate.year &&
                      c.startTime.month == cellDate.month &&
                      c.startTime.day == cellDate.day).toList();
                  final hasClasses = dayClasses.isNotEmpty;
                  final hasMyClasses = user != null && dayClasses.any((c) =>
                      c.coachId == user.id ||
                      (user.name.isNotEmpty && c.coachName.toLowerCase().contains(user.name.toLowerCase())) ||
                      user.id == 'mock_coach');

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = cellDate;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : (isToday
                                ? LinearGradient(
                                    colors: themeConfig.isDark
                                        ? [
                                            const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                            const Color(0xFF0284C7).withValues(alpha: 0.10),
                                          ]
                                        : [
                                            const Color(0xFFBAE6FD).withValues(alpha: 0.60),
                                            const Color(0xFFE0F2FE).withValues(alpha: 0.30),
                                          ],
                                  )
                                : null),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.90)
                              : (isToday
                                  ? (themeConfig.isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.65) : const Color(0xFF0284C7).withValues(alpha: 0.50))
                                  : Colors.transparent),
                          width: isSelected ? 1.5 : 1.1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: themeConfig.isDark ? 0.50 : 0.35),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isToday
                                      ? (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      : (isCurrentMonth
                                          ? themeConfig.textPrimary
                                          : (themeConfig.isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF94A3B8).withValues(alpha: 0.55)))),
                              fontWeight: (isSelected || isToday)
                                  ? FontWeight.w800
                                  : (isCurrentMonth ? FontWeight.w600 : FontWeight.w400),
                              fontSize: 13,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (hasClasses && isCurrentMonth) ...[
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : (hasMyClasses
                                        ? (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                        : (themeConfig.isDark ? const Color(0xFF10B981) : const Color(0xFF059669))),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : (hasMyClasses
                                            ? (themeConfig.isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.8) : const Color(0xFF0284C7).withValues(alpha: 0.6))
                                            : (themeConfig.isDark ? const Color(0xFF10B981).withValues(alpha: 0.8) : const Color(0xFF059669).withValues(alpha: 0.6))),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 5),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required AppThemeConfig themeConfig,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: themeConfig.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: themeConfig.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFF0284C7).withValues(alpha: 0.30),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (themeConfig.isDark ? Colors.black : const Color(0xFF0284C7)).withValues(alpha: themeConfig.isDark ? 0.12 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: themeConfig.isDark ? Colors.white : const Color(0xFF0284C7),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayScheduleSection(List<GroupClass> dayClasses, int totalDayClassesCount, AppThemeConfig themeConfig) {
    final user = ref.watch(authControllerProvider);
    final dateStr = DateFormat('d MMMM', context.locale.languageCode).format(_selectedDate);

    final int totalKidsInDay = dayClasses.fold<int>(0, (sum, c) => sum + c.enrolledChildIds.length);
    final int totalCapInDay = dayClasses.fold<int>(0, (sum, c) => sum + (c.maxCapacity > 0 ? c.maxCapacity : 8));
    final int totalFreeInDay = (totalCapInDay - totalKidsInDay).clamp(0, 9999);

    return ClipRRect(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: themeConfig.isDark ? 0.35 : 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.calendarClock, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'admin.cal_classes_for_date'.tr(args: [dateStr]),
                        style: TextStyle(
                          color: themeConfig.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeConfig.isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                          : const Color(0xFFE0F2FE).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: themeConfig.isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                            : const Color(0xFF38BDF8).withValues(alpha: 0.50),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: themeConfig.isDark ? 0.15 : 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '${dayClasses.length}',
                      style: TextStyle(
                        color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Pill: Мої заняття vs Весь басейн
              Row(
                children: [
                  _buildClassFilterPill(
                    label: 'coach.my_classes'.tr(),
                    isSelected: _onlyMyClasses,
                    themeConfig: themeConfig,
                    onTap: () => setState(() => _onlyMyClasses = true),
                  ),
                  const SizedBox(width: 8),
                  _buildClassFilterPill(
                    label: 'coach.all_pool_classes'.tr(),
                    isSelected: !_onlyMyClasses,
                    themeConfig: themeConfig,
                    onTap: () => setState(() => _onlyMyClasses = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Daily Headcount Summary
              if (dayClasses.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: themeConfig.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeConfig.isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : const Color(0xFFBAE6FD).withValues(alpha: 0.70),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 15,
                        color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Загалом на день: $totalKidsInDay учнів • ${totalFreeInDay > 0 ? "Вільних місць: $totalFreeInDay з $totalCapInDay" : "Всі місця зайняті"}',
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // List of Classes
              dayClasses.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
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
                                      LucideIcons.calendarOff,
                                      color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'admin.cal_no_classes'.tr(),
                              style: TextStyle(
                                color: themeConfig.textPrimary,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _onlyMyClasses && totalDayClassesCount > 0
                                  ? 'coach.has_other_classes_pool'.tr()
                                  : 'coach.no_classes_created_yet'.tr(),
                              style: TextStyle(
                                color: themeConfig.textSecondary,
                                fontSize: 13,
                                height: 1.45,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: dayClasses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final gClass = dayClasses[index];
                        final isMyClass = user != null &&
                            (gClass.coachId == user.id ||
                                (user.name.isNotEmpty && gClass.coachName.toLowerCase().contains(user.name.toLowerCase())) ||
                                user.id == 'mock_coach');
                        final startTimeStr = '${gClass.startTime.hour.toString().padLeft(2, '0')}:${gClass.startTime.minute.toString().padLeft(2, '0')}';
                        final endTimeStr = '${gClass.endTime.hour.toString().padLeft(2, '0')}:${gClass.endTime.minute.toString().padLeft(2, '0')}';
                        final enrolledCount = gClass.enrolledChildIds.length;
                        final maxCap = gClass.maxCapacity > 0 ? gClass.maxCapacity : 8;
                        final freeSlots = (maxCap - enrolledCount).clamp(0, maxCap);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: themeConfig.isDark
                                ? Colors.white.withValues(alpha: isMyClass ? 0.08 : 0.05)
                                : Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeConfig.isDark
                                  ? (isMyClass
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.14))
                                  : (isMyClass
                                      ? const Color(0xFF0284C7).withValues(alpha: 0.40)
                                      : const Color(0xFFBAE6FD).withValues(alpha: 0.70)),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: themeConfig.isDark ? (isMyClass ? 0.08 : 0.0) : 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Time, lane, free slots, and category
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: themeConfig.isDark
                                              ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                                              : const Color(0xFFE0F2FE).withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$startTimeStr - $endTimeStr',
                                          style: TextStyle(
                                            color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (gClass.lane.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: themeConfig.isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            gClass.lane,
                                            style: TextStyle(
                                              color: themeConfig.isDark ? Colors.white70 : const Color(0xFF475569),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      // Free slots badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                          borderRadius: BorderRadius.circular(8),
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
                                                  ? const Color(0xFFE11D48).withValues(alpha: 0.35)
                                                  : (freeSlots <= 2
                                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.30)
                                                      : const Color(0xFF10B981).withValues(alpha: 0.25)),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1.5),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              freeSlots == 0 ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
                                              size: 10.5,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 3.5),
                                            Text(
                                              freeSlots == 0 ? 'Заповнено' : 'Вільно: $freeSlots',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isMyClass)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.20),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        'coach.my_badge'.tr(),
                                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Class title
                              Text(
                                gClass.title,
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Coach and enrolled count
                              Row(
                                children: [
                                  Icon(LucideIcons.user, color: themeConfig.textMuted, size: 12),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      gClass.coachName.isNotEmpty ? gClass.coachName : 'coach.no_coach_assigned'.tr(),
                                      style: TextStyle(color: themeConfig.textSecondary, fontSize: 11.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(LucideIcons.users, color: themeConfig.textMuted, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Записано: $enrolledCount/$maxCap',
                                    style: TextStyle(color: themeConfig.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Action Button: Attendee Roster (Option A)
                              GestureDetector(
                                onTap: () => showCoachClassAttendeesSheet(context, gClass),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 1.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: themeConfig.isDark ? 0.30 : 0.22),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.users, color: Colors.white, size: 15),
                                      const SizedBox(width: 7),
                                      Text(
                                        'Склад ($enrolledCount)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
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
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeConfig themeConfig,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                : (themeConfig.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.40)
                  : (themeConfig.isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFF0284C7).withValues(alpha: 0.30)),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: themeConfig.isDark ? 0.35 : 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    if (!themeConfig.isDark)
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (themeConfig.isDark ? Colors.white70 : const Color(0xFF0284C7)),
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
