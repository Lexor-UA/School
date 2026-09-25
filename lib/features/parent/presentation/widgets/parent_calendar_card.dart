import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';

class ParentCalendarCard extends ConsumerWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<GroupClass> allClasses;
  final AppThemeConfig currentTheme;
  final String targetChildId;
  final List<String> allFamilyIds;

  const ParentCalendarCard({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.allClasses,
    required this.currentTheme,
    required this.targetChildId,
    required this.allFamilyIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final subscriptions = ref.watch(subscriptionControllerProvider);
    final user = ref.watch(authControllerProvider);
    final family = ref.watch(familyStreamProvider).value;
    final relevantUserIds = {
      if (user != null) user.id,
      if (family != null) ...family.parentIds,
    };
    final activeFamilySubs = subscriptions.where((s) => s.isActive && s.remainingClasses > 0 && relevantUserIds.contains(s.userId)).toList();

    DateTime? maxExpiry;
    for (final s in activeFamilySubs) {
      if (s.expiryDate != null) {
        if (maxExpiry == null || s.expiryDate!.isAfter(maxExpiry)) {
          maxExpiry = s.expiryDate;
        }
      }
    }

    final now = DateTime.now();
    final DateTime maxAllowedDate;
    if (maxExpiry != null) {
      maxAllowedDate = DateTime(maxExpiry.year, maxExpiry.month + 1, 1).subtract(const Duration(seconds: 1));
    } else {
      maxAllowedDate = DateTime(now.year, now.month + 3, 1).subtract(const Duration(seconds: 1));
    }

    final nextMonthFirstDay = DateTime(selectedDate.year, selectedDate.month + 1, 1);
    final bool canGoNextMonth = nextMonthFirstDay.isBefore(maxAllowedDate) ||
        (nextMonthFirstDay.year == maxAllowedDate.year && nextMonthFirstDay.month == maxAllowedDate.month);
    final bool canGoPrevMonth = selectedDate.year > now.year || (selectedDate.year == now.year && selectedDate.month >= now.month);

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
                          onTap: canGoPrevMonth ? () { HapticFeedback.selectionClick(); onDateSelected(DateTime(selectedDate.year, selectedDate.month - 1, 1)); } : null,
                          currentTheme: currentTheme,
                          isEnabled: canGoPrevMonth,
                        ),
                        const SizedBox(width: 8),
                        _buildMonthNavButton(
                          icon: LucideIcons.chevronRight,
                          onTap: canGoNextMonth ? () { HapticFeedback.selectionClick(); onDateSelected(DateTime(selectedDate.year, selectedDate.month + 1, 1)); } : null,
                          currentTheme: currentTheme,
                          isEnabled: canGoNextMonth,
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
                    final bool hasEnrolledClasses;
                    final bool hasAvailableClasses;

                    if (targetChildId == 'all') {
                      hasEnrolledClasses = allClasses.any((c) =>
                          c.startTime.year == cellDate.year &&
                          c.startTime.month == cellDate.month &&
                          c.startTime.day == cellDate.day &&
                          c.enrolledChildIds.any((id) => allFamilyIds.contains(id)));

                      hasAvailableClasses = allClasses.any((c) =>
                          c.startTime.year == cellDate.year &&
                          c.startTime.month == cellDate.month &&
                          c.startTime.day == cellDate.day &&
                          !c.enrolledChildIds.any((id) => allFamilyIds.contains(id)) &&
                          c.enrolledChildIds.length < c.maxCapacity);
                    } else {
                      hasEnrolledClasses = allClasses.any((c) =>
                          c.startTime.year == cellDate.year &&
                          c.startTime.month == cellDate.month &&
                          c.startTime.day == cellDate.day &&
                          c.enrolledChildIds.contains(targetChildId));

                      hasAvailableClasses = allClasses.any((c) =>
                          c.startTime.year == cellDate.year &&
                          c.startTime.month == cellDate.month &&
                          c.startTime.day == cellDate.day &&
                          !c.enrolledChildIds.contains(targetChildId) &&
                          c.enrolledChildIds.length < c.maxCapacity);
                    }

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () { HapticFeedback.selectionClick(); onDateSelected(cellDate); },
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
    required VoidCallback? onTap,
    required AppThemeConfig currentTheme,
    bool isEnabled = true,
  }) {
    final isDark = currentTheme.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isEnabled ? 1.0 : 0.35,
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
                    ? const Color(0xFF00E5FF).withValues(alpha: isEnabled ? 0.25 : 0.10)
                    : const Color(0xFFBAE6FD).withValues(alpha: isEnabled ? 1.0 : 0.4),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 16,
                color: isEnabled
                    ? (isDark ? const Color(0xFF00E5FF) : currentTheme.textPrimary)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
