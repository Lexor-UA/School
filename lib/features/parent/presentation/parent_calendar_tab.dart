import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/create_individual_class_sheet.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';

class ParentCalendarTab extends ConsumerStatefulWidget {
  const ParentCalendarTab({super.key});

  @override
  ConsumerState<ParentCalendarTab> createState() => _ParentCalendarTabState();
}

class _ParentCalendarTabState extends ConsumerState<ParentCalendarTab> {
  String? selectedChildId;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    if (selectedChildId == null && user != null) {
      selectedChildId = user.id;
    }

    final currentTheme = ref.watch(appThemeControllerProvider);
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];
    final allClasses = scheduleAsync.value ?? [];

    final targetChildId = (selectedChildId == null || selectedChildId == 'all')
        ? (user?.id ?? '')
        : selectedChildId!;

    final dayClasses = allClasses.where((c) {
      return c.startTime.year == selectedDate.year &&
          c.startTime.month == selectedDate.month &&
          c.startTime.day == selectedDate.day;
    }).toList();
    dayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'parent.calendar'.tr(),
          style: TextStyle(
            color: currentTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: ThemeHeaderButton(size: 38),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),

            // 1. Sleek Frosted Glass Child / Parent Selector
            _buildChildSelector(currentTheme, user?.id ?? '', user?.name ?? 'Я'),
            const SizedBox(height: 12),

            // 2. VisionOS Frosted Glass Calendar Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCalendarCard(allClasses, currentTheme, targetChildId),
            ),
            const SizedBox(height: 14),

            // 3. On-Screen Live Day Schedule Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDayScheduleSection(
                dayClasses,
                targetChildId,
                currentTheme,
                user,
                children,
              ),
            ),
            const SizedBox(height: 120), // Clearance for floating bottom nav bar
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    if (selectedChildId == null) return;

    final user = ref.read(authControllerProvider);
    final isAdult = selectedChildId == user?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateIndividualClassSheet(
        selectedDate: selectedDate,
        selectedUserId: selectedChildId!,
        isAdult: isAdult,
      ),
    );
  }

  // ===========================================================================
  // 1. CHILD SELECTOR BAR
  // ===========================================================================
  Widget _buildChildSelector(AppThemeConfig currentTheme, String parentId, String parentName) {
    final childrenAsync = ref.watch(childrenControllerProvider);

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChildChip(
              id: parentId,
              name: parentName,
              color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
              isSelected: selectedChildId == parentId,
              currentTheme: currentTheme,
              isParent: true,
            ),
            ...childrenAsync.when(
              data: (children) => children.map((c) => _buildChildChip(
                id: c.id,
                name: c.name,
                color: Color(int.tryParse(c.colorHex) ?? 0xFF10B981),
                isSelected: selectedChildId == c.id,
                currentTheme: currentTheme,
                isParent: false,
              )).toList(),
              loading: () => [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              ],
              error: (_, _) => const [],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildChip({
    required String id,
    required String name,
    required Color color,
    required bool isSelected,
    required AppThemeConfig currentTheme,
    required bool isParent,
  }) {
    final isDark = currentTheme.isDark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => selectedChildId = id),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: isDark
                          ? [
                              color.withValues(alpha: 0.35),
                              color.withValues(alpha: 0.18),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.95),
                              const Color(0xFFF0F9FF).withValues(alpha: 0.92),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.80)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (isDark ? const Color(0xFF00E5FF) : color)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : const Color(0xFFBAE6FD)),
                width: isSelected ? 1.4 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF00E5FF) : color).withValues(alpha: isDark ? 0.30 : 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? (isDark
                            ? LinearGradient(colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.2)])
                            : const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0284C7)]))
                        : null,
                    color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE0F2FE)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isParent ? LucideIcons.user : LucideIcons.baby,
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF0284C7)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.white70 : currentTheme.textSecondary),
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. VISIONOS FROSTED GLASS CALENDAR CARD
  // ===========================================================================
  Widget _buildCalendarCard(
    List<GroupClass> allClasses,
    AppThemeConfig currentTheme,
    String targetChildId,
  ) {
    final monthName = DateFormat('LLLL yyyy', context.locale.languageCode).format(selectedDate);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final daysInMonth = DateUtils.getDaysInMonth(selectedDate.year, selectedDate.month);
    final firstDayOffset = DateTime(selectedDate.year, selectedDate.month, 1).weekday - 1;
    final totalCells = ((daysInMonth + firstDayOffset) / 7).ceil() * 7;
    final daysOfWeek = [
      'parent.mon'.tr(),
      'parent.tue'.tr(),
      'parent.wed'.tr(),
      'parent.thu'.tr(),
      'parent.fri'.tr(),
      'parent.sat'.tr(),
      'parent.sun'.tr(),
    ];

    final isDark = currentTheme.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0E3D64).withValues(alpha: 0.60),
                      const Color(0xFF092842).withValues(alpha: 0.72),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF003B73).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                // Month Switcher Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: currentTheme.accentGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.calendar, color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          capitalizedMonth,
                          style: TextStyle(
                            color: currentTheme.textPrimary,
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
                          onTap: () => setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1)),
                          currentTheme: currentTheme,
                        ),
                        const SizedBox(width: 8),
                        _buildMonthNavButton(
                          icon: LucideIcons.chevronRight,
                          onTap: () => setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1)),
                          currentTheme: currentTheme,
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
                            color: (idx == 5 || idx == 6)
                                ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                : (isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),

                // Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.18,
                  ),
                  itemBuilder: (context, index) {
                    if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
                      return const SizedBox();
                    }

                    final day = index - firstDayOffset + 1;
                    final cellDate = DateTime(selectedDate.year, selectedDate.month, day);
                    final isSelected = cellDate.year == selectedDate.year &&
                        cellDate.month == selectedDate.month &&
                        cellDate.day == selectedDate.day;

                    final now = DateTime.now();
                    final isToday = cellDate.year == now.year &&
                        cellDate.month == now.month &&
                        cellDate.day == now.day;

                    // Enrolled vs Available logic
                    final hasEnrolledClasses = allClasses.any((c) =>
                        c.startTime.year == cellDate.year &&
                        c.startTime.month == cellDate.month &&
                        c.startTime.day == cellDate.day &&
                        c.enrolledChildIds.contains(targetChildId));

                    final hasAvailableClasses = allClasses.any((c) =>
                        c.startTime.year == cellDate.year &&
                        c.startTime.month == cellDate.month &&
                        c.startTime.day == cellDate.day &&
                        !c.enrolledChildIds.contains(targetChildId) &&
                        c.enrolledChildIds.length < c.maxCapacity);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => selectedDate = cellDate),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.all(2),
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
                                : (isToday
                                    ? (isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                                        : currentTheme.accentPrimary.withValues(alpha: 0.12))
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : (isToday
                                      ? (isDark
                                          ? const Color(0xFF00E5FF).withValues(alpha: 0.75)
                                          : currentTheme.accentPrimary.withValues(alpha: 0.7))
                                      : Colors.transparent),
                              width: (isSelected || isToday) ? 1.2 : 0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isToday
                                          ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                          : (isDark ? Colors.white : currentTheme.textPrimary)),
                                  fontWeight: (isSelected || isToday) ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              if (hasEnrolledClasses && hasAvailableClasses && !isSelected)
                                Positioned(
                                  bottom: 4,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 4.5,
                                        height: 4.5,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)).withValues(alpha: 0.7),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Container(
                                        width: 4.5,
                                        height: 4.5,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.7),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (hasEnrolledClasses || hasAvailableClasses)
                                Positioned(
                                  bottom: 4,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : (hasEnrolledClasses
                                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                              : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.8)
                                              : (hasEnrolledClasses
                                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                                  : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)))
                                                .withValues(alpha: 0.6),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
    required AppThemeConfig currentTheme,
  }) {
    final isDark = currentTheme.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                  : const Color(0xFFBAE6FD),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: isDark ? const Color(0xFF00E5FF) : currentTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ON-SCREEN SELECTED DAY SCHEDULE SECTION
  // ===========================================================================
  Widget _buildDayScheduleSection(
    List<GroupClass> dayClasses,
    String targetChildId,
    AppThemeConfig currentTheme,
    AppUser? user,
    List<Child> children,
  ) {
    final isDark = currentTheme.isDark;

    final enrolledClasses = dayClasses.where((c) {
      return c.enrolledChildIds.contains(targetChildId);
    }).toList();

    final availableClasses = dayClasses.where((c) {
      return !c.enrolledChildIds.contains(targetChildId) &&
          c.enrolledChildIds.length < c.maxCapacity;
    }).toList();

    final dateFormatted = DateFormat('d MMMM', context.locale.languageCode).format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Розклад на $dateFormatted',
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showBookingSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                        : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.45),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Записатись',
                      style: TextStyle(
                        color: Colors.white,
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
        const SizedBox(height: 10),

        if (enrolledClasses.isEmpty && availableClasses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildEmptyDayState(currentTheme),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (enrolledClasses.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF10B981).withValues(alpha: 0.40)
                          : const Color(0xFFBAE6FD),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF10B981) : const Color(0xFF0284C7)).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Ваші заплановані заняття (${enrolledClasses.length})',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : currentTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...enrolledClasses.map((c) => _buildEnrolledClassCard(c, targetChildId, currentTheme)),
                const SizedBox(height: 12),
              ],
              if (availableClasses.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.40)
                          : const Color(0xFFBAE6FD),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Доступні для запису (${availableClasses.length})',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : currentTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...availableClasses.map((c) => _buildAvailableClassCard(c, targetChildId, currentTheme)),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyDayState(AppThemeConfig currentTheme) {
    final isDark = currentTheme.isDark;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF0E3D64).withValues(alpha: 0.55),
                        const Color(0xFF092842).withValues(alpha: 0.70),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: const Color(0xFF003B73).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                        : currentTheme.accentPrimary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                          : currentTheme.accentPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.calendarCheck,
                      color: isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'parent.no_classes_this_day_calendar'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Бажаєте провести тренування у цей день?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : currentTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _showBookingSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                            : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.50),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Забронювати тренування',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
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
    );
  }

  Widget _buildEnrolledClassCard(GroupClass c, String targetChildId, AppThemeConfig currentTheme) {
    final isDark = currentTheme.isDark;
    final timeFormatted =
        "${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF0E3D64).withValues(alpha: 0.60),
                        const Color(0xFF092842).withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: const Color(0xFF003B73).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Time pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFBAE6FD),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormatted,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Confirmation badge (Emerald)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF10B981).withValues(alpha: 0.16)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.45)
                              : const Color(0xFFA7F3D0),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.checkCircle2,
                            size: 12,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'parent.booking_confirmed'.tr(),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Action menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        LucideIcons.moreHorizontal,
                        color: isDark ? Colors.white70 : currentTheme.textSecondary,
                        size: 18,
                      ),
                      color: isDark ? const Color(0xFF0F1E32) : Colors.white,
                      onSelected: (value) async {
                        if (value == 'cancel') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
                              title: Text(
                                'Скасувати запис?',
                                style: TextStyle(color: currentTheme.textPrimary),
                              ),
                              content: Text(
                                'Ви впевнені, що хочете скасувати запис на заняття "${c.title}"?',
                                style: TextStyle(color: isDark ? Colors.white70 : currentTheme.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Назад'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Скасувати', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(scheduleControllerProvider.notifier).cancelClass(c.id, targetChildId);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                              SizedBox(width: 8),
                              Text('Скасувати запис', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  c.title,
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),

                // Meta row: Coach and lane
                Row(
                  children: [
                    if (c.coachName.isNotEmpty) ...[
                      Icon(
                        (c.coachName == 'Тренер не призначений' || c.coachName.toLowerCase().contains('не призначен'))
                            ? LucideIcons.clock
                            : LucideIcons.userCheck,
                        size: 13,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (c.coachName == 'Тренер не призначений' || c.coachName.toLowerCase().contains('не призначен'))
                            ? 'Тренер призначається'
                            : 'Тренер: ${c.coachName}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (c.lane.isNotEmpty && c.lane != 'Будь-яка') ...[
                      Icon(
                        LucideIcons.waves,
                        size: 13,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.lane,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
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
        ),
      ),
    );
  }

  Widget _buildAvailableClassCard(GroupClass c, String targetChildId, AppThemeConfig currentTheme) {
    final isDark = currentTheme.isDark;
    final timeFormatted =
        "${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}";
    final freeSlots = c.maxCapacity - c.enrolledChildIds.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF0E3D64).withValues(alpha: 0.55),
                        const Color(0xFF092842).withValues(alpha: 0.68),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: const Color(0xFF003B73).withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Time pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFBAE6FD),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormatted,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Free slots pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '$freeSlots місць вільно',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Quick booking action
                    GestureDetector(
                      onTap: () async {
                        await ref.read(scheduleControllerProvider.notifier).bookClass(c.id, targetChildId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ви успішно записалися на заняття!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                                : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.45),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Записатись',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  c.title,
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),

                // Meta row: Coach and lane
                Row(
                  children: [
                    if (c.coachName.isNotEmpty) ...[
                      Icon(
                        (c.coachName == 'Тренер не призначений' || c.coachName.toLowerCase().contains('не призначен'))
                            ? LucideIcons.clock
                            : LucideIcons.user,
                        size: 13,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (c.coachName == 'Тренер не призначений' || c.coachName.toLowerCase().contains('не призначен'))
                            ? 'Тренер призначається'
                            : 'Тренер: ${c.coachName}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (c.lane.isNotEmpty && c.lane != 'Будь-яка') ...[
                      Icon(
                        LucideIcons.waves,
                        size: 13,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.lane,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
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
        ),
      ),
    );
  }
}
