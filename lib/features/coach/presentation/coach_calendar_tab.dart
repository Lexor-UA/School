import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    // Filter classes for selected day
    final dayClassesAll = allClasses.where((c) =>
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
          _buildCalendarCard(allClasses),
          const SizedBox(height: 14),

          // Selected Day Schedule Section
          _buildDayScheduleSection(dayClasses, dayClassesAll.length),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(List<GroupClass> allClasses) {
    final user = ref.watch(authControllerProvider);
    final monthName = DateFormat('LLLL yyyy', context.locale.languageCode).format(_selectedDate);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final firstDayOffset = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday - 1;
    final totalCells = ((daysInMonth + firstDayOffset) / 7).ceil() * 7;
    final daysOfWeek = [
      'admin.wd_mon'.tr(),
      'admin.wd_tue'.tr(),
      'admin.wd_wed'.tr(),
      'admin.wd_thu'.tr(),
      'admin.wd_fri'.tr(),
      'admin.wd_sat'.tr(),
      'admin.wd_sun'.tr(),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1E33),
            Color(0xFF091422),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.calendar, color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          capitalizedMonth,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
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
                          onTap: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1)),
                        ),
                        const SizedBox(width: 8),
                        _buildMonthNavButton(
                          icon: LucideIcons.chevronRight,
                          onTap: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Days of week header
                Row(
                  children: daysOfWeek.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final d = entry.value;
                    return Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: (idx == 5 || idx == 6) ? const Color(0xFF38BDF8) : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),

                // Grid of days
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (context, index) {
                    if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
                      return const SizedBox();
                    }

                    final day = index - firstDayOffset + 1;
                    final cellDate = DateTime(_selectedDate.year, _selectedDate.month, day);
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
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : (isToday
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF38BDF8).withValues(alpha: 0.22),
                                        const Color(0xFF0077B6).withValues(alpha: 0.12),
                                      ],
                                    )
                                  : null),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : (isToday
                                    ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                                    : Colors.transparent),
                            width: isSelected ? 1.4 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00D2FF).withValues(alpha: 0.45),
                                    blurRadius: 10,
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
                                    : (isToday ? const Color(0xFF38BDF8) : Colors.white),
                                fontWeight: (isSelected || isToday) ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 13,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: hasClasses
                                    ? (isSelected
                                        ? Colors.white
                                        : (hasMyClasses ? const Color(0xFF00E5FF) : const Color(0xFF10B981)))
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
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

  Widget _buildMonthNavButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDayScheduleSection(List<GroupClass> dayClasses, int totalDayClassesCount) {
    final user = ref.watch(authControllerProvider);
    final dateStr = DateFormat('d MMMM', context.locale.languageCode).format(_selectedDate);

    final int totalKidsInDay = dayClasses.fold<int>(0, (sum, c) => sum + c.enrolledChildIds.length);
    final int totalCapInDay = dayClasses.fold<int>(0, (sum, c) => sum + (c.maxCapacity > 0 ? c.maxCapacity : 8));
    final int totalFreeInDay = (totalCapInDay - totalKidsInDay).clamp(0, 9999);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1E33),
            Color(0xFF091422),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.calendarClock, color: Colors.white, size: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'admin.cal_classes_for_date'.tr(args: [dateStr]),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${dayClasses.length}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Filter Pill: Мої заняття vs Весь басейн
                Row(
                  children: [
                    _buildClassFilterPill(
                      label: 'coach.my_classes'.tr(),
                      isSelected: _onlyMyClasses,
                      onTap: () => setState(() => _onlyMyClasses = true),
                    ),
                    const SizedBox(width: 6),
                    _buildClassFilterPill(
                      label: 'coach.all_pool_classes'.tr(),
                      isSelected: !_onlyMyClasses,
                      onTap: () => setState(() => _onlyMyClasses = false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Daily Headcount Summary
                if (dayClasses.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.users, size: 15, color: Color(0xFF00E5FF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Загалом на день: $totalKidsInDay учнів • ${totalFreeInDay > 0 ? "Вільних місць: $totalFreeInDay з $totalCapInDay" : "Всі місця зайняті"}',
                            style: const TextStyle(
                              color: Colors.white,
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
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.calendarOff, color: Colors.white30, size: 36),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'admin.cal_no_classes'.tr(),
                                style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _onlyMyClasses && totalDayClassesCount > 0
                                    ? 'coach.has_other_classes_pool'.tr()
                                    : 'coach.no_classes_created_yet'.tr(),
                                style: const TextStyle(color: Colors.white38, fontSize: 11.5),
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: isMyClass ? 0.07 : 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMyClass
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.10),
                                ),
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
                                              color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '$startTimeStr - $endTimeStr',
                                              style: const TextStyle(
                                                color: Color(0xFF00E5FF),
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
                                                color: Colors.white.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                gClass.lane,
                                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                              ),
                                            ),
                                          const SizedBox(width: 6),
                                          // Free slots badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: freeSlots == 0
                                                  ? const Color(0xFFEF4444).withValues(alpha: 0.16)
                                                  : (freeSlots <= 2
                                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.16)
                                                      : const Color(0xFF10B981).withValues(alpha: 0.16)),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: freeSlots == 0
                                                    ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                                                    : (freeSlots <= 2
                                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                                                        : const Color(0xFF10B981).withValues(alpha: 0.45)),
                                              ),
                                            ),
                                            child: Text(
                                              freeSlots == 0 ? 'Заповнено' : 'Вільно: $freeSlots',
                                              style: TextStyle(
                                                color: freeSlots == 0
                                                    ? const Color(0xFFEF4444)
                                                    : (freeSlots <= 2 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
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
                                      const Icon(LucideIcons.user, color: Colors.white54, size: 12),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          gClass.coachName.isNotEmpty ? gClass.coachName : 'coach.no_coach_assigned'.tr(),
                                          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(LucideIcons.users, color: Colors.white54, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Записано: $enrolledCount/$maxCap',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Action Button: Attendee Roster (Option A)
                                  GestureDetector(
                                    onTap: () => showCoachClassAttendeesSheet(context, gClass),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(LucideIcons.users, color: Colors.white, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Склад ($enrolledCount)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E5FF).withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
