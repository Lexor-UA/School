import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/admin/presentation/create_class_sheet.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

class AdminCalendarScreen extends ConsumerStatefulWidget {
  final String? initialCoachId;
  final String? initialCoachName;

  const AdminCalendarScreen({
    super.key,
    this.initialCoachId,
    this.initialCoachName,
  });

  @override
  ConsumerState<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends ConsumerState<AdminCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedCoachId;
  String? _selectedCoachName;


  @override
  void initState() {
    super.initState();
    _selectedCoachId = widget.initialCoachId;
    _selectedCoachName = widget.initialCoachName;

    // Automatically check and clean up any duplicate ghost classes from the database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(scheduleControllerProvider.notifier).cleanupDuplicateClasses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    final tenancyState = ref.watch(tenancyControllerProvider);
    final activeBranchId = tenancyState.activeBranchId;
    final isAllLocations = tenancyState.isAllLocationsSelected;

    final branchClasses = isAllLocations
        ? allClasses
        : allClasses.where((c) => c.branchId == activeBranchId).toList();

    final Map<String, GroupClass> uniqueDayClasses = {};
    for (final c in branchClasses) {
      final matchesDate = c.startTime.year == _selectedDate.year && 
        c.startTime.month == _selectedDate.month && 
        c.startTime.day == _selectedDate.day;
      if (!matchesDate) continue;

      if (_selectedCoachId != null && _selectedCoachId!.isNotEmpty) {
        final matchesId = c.coachId == _selectedCoachId;
        final matchesName = _selectedCoachName != null && c.coachName.isNotEmpty &&
            (c.coachName.toLowerCase().contains(_selectedCoachName!.toLowerCase()) ||
             _selectedCoachName!.toLowerCase().contains(c.coachName.toLowerCase()));
        if (!matchesId && !matchesName) continue;
      }
      uniqueDayClasses[c.id] = c;
    }
    final dayClasses = uniqueDayClasses.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentTheme.isDark
                  ? const Color(0xFF0C2238).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.90),
              border: Border.all(
                color: currentTheme.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                    : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                      .withValues(alpha: currentTheme.isDark ? 0.20 : 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Center(
                  child: Icon(LucideIcons.chevronLeft, color: currentTheme.textPrimary, size: 20),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'admin.cal_title'.tr(),
          style: TextStyle(
            color: currentTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 19,
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Full-fidelity animated water ripples
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),

          // 2. Fluid aquatic gradient overlay
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

          // 3. Screen content
          SafeArea(
            child: RepaintBoundary(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    // Month Header & Calendar Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCalendarCard(branchClasses, currentTheme),
                    ),
                    const SizedBox(height: 10),

                    // Coach Filter Bar (Allows Admin to manage specific coach's schedule)
                    _buildCoachFilterBar(currentTheme),

                    const SizedBox(height: 10),

                    // Selected Day Schedule Section (Directly on screen!)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildDayScheduleSection(dayClasses, currentTheme),
                    ),

                    // Comfortable bottom breathing room
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(List<GroupClass> allClasses, AppThemeConfig currentTheme) {
    final monthName = DateFormat('LLLL yyyy', context.locale.languageCode).format(_selectedDate);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);
    final now = DateTime.now();
    final isCurrentDateSelected = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

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

    return RepaintBoundary(
      child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: currentTheme.isDark
                  ? [
                      const Color(0xFF0C2238).withValues(alpha: 0.90),
                      const Color(0xFF061424).withValues(alpha: 0.95),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF0F9FF),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: currentTheme.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: currentTheme.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                    : const Color(0xFF0284C7).withValues(alpha: 0.08),
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
              if (currentTheme.isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
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
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.calendar, color: Colors.white, size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                capitalizedMonth,
                                style: TextStyle(
                                  color: currentTheme.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCurrentDateSelected) ...[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedDate = DateTime.now());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: currentTheme.isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                                      : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: currentTheme.isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                                        : const Color(0xFFBAE6FD),
                                    width: 1.1,
                                  ),
                                  boxShadow: currentTheme.isDark
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.calendarDays,
                                      size: 11.5,
                                      color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Сьогодні',
                                      style: TextStyle(
                                        color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        _buildMonthNavButton(
                          icon: LucideIcons.chevronLeft,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1));
                          },
                          currentTheme: currentTheme,
                        ),
                        const SizedBox(width: 6),
                        _buildMonthNavButton(
                          icon: LucideIcons.chevronRight,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1));
                          },
                          currentTheme: currentTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 14),

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
                              ? (currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                              : (currentTheme.isDark ? const Color(0xFFBAE6FD) : const Color(0xFF64748B)),
                          fontSize: 12.5,
                          fontWeight: isWeekend ? FontWeight.w800 : FontWeight.w700,
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
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.15,
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

                  final hasClasses = allClasses.any((c) =>
                      c.startTime.year == cellDate.year &&
                      c.startTime.month == cellDate.month &&
                      c.startTime.day == cellDate.day);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
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
                                    colors: currentTheme.isDark
                                        ? [
                                            const Color(0xFF0B2138).withValues(alpha: 0.85),
                                            const Color(0xFF061424).withValues(alpha: 0.85),
                                          ]
                                        : [
                                            const Color(0xFFE0F2FE),
                                            Colors.white,
                                          ],
                                  )
                                : null),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.55)
                              : (isToday
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.65)
                                  : Colors.transparent),
                          width: isSelected ? 1.4 : 1.1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                  blurRadius: 12,
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
                                      ? (currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      : (currentTheme.isDark
                                          ? Colors.white.withValues(alpha: 0.92)
                                          : currentTheme.textPrimary)),
                              fontWeight: (isSelected || isToday) ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: isSelected ? 5 : 4.5,
                            height: isSelected ? 5 : 4.5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : (hasClasses ? const Color(0xFF10B981) : Colors.transparent),
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [
                                      const BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : (hasClasses
                                      ? [
                                          const BoxShadow(
                                            color: Color(0xFF10B981),
                                            blurRadius: 6,
                                            spreadRadius: 0.8,
                                          ),
                                        ]
                                      : null),
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

  Widget _buildMonthNavButton({required IconData icon, required VoidCallback onTap, required AppThemeConfig currentTheme}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: currentTheme.isDark
                ? const Color(0xFF0B2138).withValues(alpha: 0.85)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: currentTheme.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                  : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: (currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                    .withValues(alpha: currentTheme.isDark ? 0.15 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: currentTheme.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              size: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachFilterBar(AppThemeConfig currentTheme) {
    final coaches = ref.watch(coachesProvider).value ?? [];
    if (coaches.isEmpty) {
      return const SizedBox.shrink();
    }

    final tenancyState = ref.watch(tenancyControllerProvider);
    final activeBranchId = tenancyState.activeBranchId;
    final isAllLocations = tenancyState.isAllLocationsSelected;

    final coachDocs = isAllLocations
        ? coaches
        : coaches.where((c) {
            final bId = c.branchId;
            final bIds = c.branchIds.isNotEmpty ? c.branchIds : [bId];
            return bId == activeBranchId || bIds.contains(activeBranchId);
          }).toList();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All coaches chip
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCoachId = null;
                _selectedCoachName = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: _selectedCoachId == null
                    ? const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _selectedCoachId == null
                    ? null
                    : (currentTheme.isDark ? const Color(0xFF0C2238).withValues(alpha: 0.85) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedCoachId == null
                      ? Colors.white.withValues(alpha: 0.50)
                      : (currentTheme.isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD)),
                  width: 1.1,
                ),
                boxShadow: _selectedCoachId == null
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: (currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF003B73))
                              .withValues(alpha: currentTheme.isDark ? 0.08 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.users,
                    size: 13.5,
                    color: _selectedCoachId == null
                        ? Colors.white
                        : (currentTheme.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Всі тренери',
                    style: TextStyle(
                      color: _selectedCoachId == null
                          ? Colors.white
                          : (currentTheme.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A)),
                      fontSize: 12,
                      fontWeight: _selectedCoachId == null ? FontWeight.w800 : FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Individual coach chips
          ...coachDocs.map((coach) {
            final cId = coach.id;
            final cName = coach.name.isNotEmpty ? coach.name : 'Тренер';
            final isSelected = _selectedCoachId == cId ||
                (_selectedCoachName != null && _selectedCoachName!.toLowerCase() == cName.toLowerCase());

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedCoachId = null;
                    _selectedCoachName = null;
                  } else {
                    _selectedCoachId = cId;
                    _selectedCoachName = cName;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
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
                      : (currentTheme.isDark ? const Color(0xFF0C2238).withValues(alpha: 0.85) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.50)
                        : (currentTheme.isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD)),
                    width: 1.1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: (currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF003B73))
                                .withValues(alpha: currentTheme.isDark ? 0.08 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.waves,
                      size: 13.5,
                      color: isSelected
                          ? Colors.white
                          : (currentTheme.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (currentTheme.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A)),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.x, size: 12, color: Colors.white),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayScheduleSection(List<GroupClass> dayClasses, AppThemeConfig currentTheme) {
    final dateStr = DateFormat('d MMMM', context.locale.languageCode).format(_selectedDate);

    return RepaintBoundary(
      child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: currentTheme.isDark
                  ? [
                      const Color(0xFF0C2238).withValues(alpha: 0.90),
                      const Color(0xFF061424).withValues(alpha: 0.95),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF0F9FF),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: currentTheme.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: currentTheme.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                    : const Color(0xFF0284C7).withValues(alpha: 0.08),
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
              if (currentTheme.isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Section Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.50),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.calendarClock, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: currentTheme.isDark ? Colors.white : currentTheme.textPrimary,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: currentTheme.isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                                      : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: currentTheme.isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                                        : const Color(0xFFBAE6FD),
                                    width: 1.1,
                                  ),
                                ),
                                child: Text(
                                  '${dayClasses.length}',
                                  style: TextStyle(
                                    color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // + Додати заняття Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CreateClassSheet(
                            initialDate: _selectedDate,
                            initialCoachId: _selectedCoachId,
                            initialCoachName: _selectedCoachName,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(13),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.50),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.plus, color: Colors.white, size: 14.5),
                            const SizedBox(width: 5.5),
                            Text(
                              'admin.cal_add_btn'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Active coach filter banner (renders below header so date never shrinks)
              if (_selectedCoachName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: currentTheme.isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentTheme.isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                          : const Color(0xFFBAE6FD),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.userCheck,
                        size: 14,
                        color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Фільтр: тренер $_selectedCoachName',
                          style: TextStyle(
                            color: currentTheme.isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedCoachId = null;
                            _selectedCoachName = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentTheme.isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: currentTheme.isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                  : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Скинути',
                                style: TextStyle(
                                  color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.x,
                                size: 11,
                                color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Classes List or Empty State
              if (dayClasses.isEmpty)
                _buildEmptyDayState(dateStr, currentTheme)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: dayClasses.length,
                  itemBuilder: (context, index) {
                    return _buildAdminClassCard(dayClasses[index], currentTheme, dayClasses);
                  },
                ),
            ],
          ),
        ),
      );
  }

  Widget _buildEmptyDayState(String dateStr, AppThemeConfig currentTheme) {
    final hasCoachFilter = _selectedCoachName != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Concentric Water Ripples
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.05 : 0.03),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.18 : 0.10),
                      width: 1.2,
                    ),
                  ),
                ),
                // Middle ring
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.12 : 0.06),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.35 : 0.20),
                      width: 1.2,
                    ),
                  ),
                ),
                // Inner Jewel Circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.50),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.45 : 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      hasCoachFilter ? LucideIcons.userX : LucideIcons.calendarCheck2,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              hasCoachFilter
                  ? 'У тренера $_selectedCoachName немає занять'
                  : 'admin.cal_no_classes'.tr(),
              style: TextStyle(
                color: currentTheme.isDark ? Colors.white : currentTheme.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                hasCoachFilter
                    ? 'На $dateStr ще не призначено жодних тренувань'
                    : 'admin.cal_no_classes_desc'.tr(args: [dateStr]),
                style: TextStyle(
                  color: currentTheme.isDark ? const Color(0xFF94A3B8) : currentTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (hasCoachFilter) ...[
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedCoachId = null;
                      _selectedCoachName = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: currentTheme.isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: currentTheme.isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                            : const Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 14,
                          color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Показати всі заняття дня',
                          style: TextStyle(
                            color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Quick template time chips with sparkles header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 13,
                  color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 5),
                Text(
                  'admin.cal_quick_templates'.tr(),
                  style: TextStyle(
                    color: currentTheme.isDark ? const Color(0xFF94A3B8) : currentTheme.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickTimeChip(
                  icon: LucideIcons.sunrise,
                  iconColor: const Color(0xFFFBBF24),
                  label: '09:00',
                  subLabel: 'Ранок',
                  time: const TimeOfDay(hour: 9, minute: 0),
                  currentTheme: currentTheme,
                ),
                _buildQuickTimeChip(
                  icon: LucideIcons.sun,
                  iconColor: const Color(0xFFF59E0B),
                  label: '14:00',
                  subLabel: 'День',
                  time: const TimeOfDay(hour: 14, minute: 0),
                  currentTheme: currentTheme,
                ),
                _buildQuickTimeChip(
                  icon: LucideIcons.moon,
                  iconColor: const Color(0xFF818CF8),
                  label: '18:00',
                  subLabel: 'Вечір',
                  time: const TimeOfDay(hour: 18, minute: 0),
                  currentTheme: currentTheme,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Primary creation button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CreateClassSheet(
                      initialDate: _selectedDate,
                      initialCoachId: _selectedCoachId,
                      initialCoachName: _selectedCoachName,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.50),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        hasCoachFilter
                            ? '+ Створити заняття для $_selectedCoachName'
                            : 'admin.cal_create_for_date'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
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
    );
  }

  Widget _buildQuickTimeChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? subLabel,
    required TimeOfDay time,
    required AppThemeConfig currentTheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          final targetDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            time.hour,
            time.minute,
          );
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CreateClassSheet(
              initialDate: targetDate,
              initialCoachId: _selectedCoachId,
              initialCoachName: _selectedCoachName,
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: currentTheme.isDark
                ? const Color(0xFF0C2238).withValues(alpha: 0.85)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: currentTheme.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.28)
                  : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: currentTheme.isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: currentTheme.isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subLabel != null) ...[
                const SizedBox(width: 5),
                Text(
                  subLabel,
                  style: TextStyle(
                    color: currentTheme.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminClassCard(GroupClass c, AppThemeConfig currentTheme, [List<GroupClass>? siblingClasses]) {
    final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${c.endTime.hour.toString().padLeft(2, '0')}:${c.endTime.minute.toString().padLeft(2, '0')}';
    final enrolledCount = c.enrolledChildIds.length;
    final progress = c.maxCapacity > 0 ? (enrolledCount / c.maxCapacity).clamp(0.0, 1.0) : 0.0;
    final spotsLeft = (c.maxCapacity - enrolledCount).clamp(0, c.maxCapacity);
    final isUnassigned = c.coachId == 'unassigned' ||
        c.coachId.isEmpty ||
        c.coachName.isEmpty ||
        c.coachName == 'Тренер не призначений' ||
        c.coachName.toLowerCase().contains('не призначен');

    // Conflict detection against sibling classes on the same day
    GroupClass? conflictingLaneClass;
    GroupClass? conflictingCoachClass;

    if (siblingClasses != null) {
      for (final other in siblingClasses) {
        if (other.id == c.id) continue;
        final overlaps = other.startTime.isBefore(c.endTime) && other.endTime.isAfter(c.startTime);
        if (!overlaps) continue;

        // Lane conflict check
        if (c.lane.isNotEmpty && other.lane.isNotEmpty && c.lane != 'Будь-яка') {
          final isSameLane = c.lane == other.lane;
          final wholePoolConflict = (c.lane == 'Весь басейн' && other.lane.startsWith('Доріжка')) ||
              (other.lane == 'Весь басейн' && c.lane.startsWith('Доріжка'));
          if (isSameLane || wholePoolConflict) {
            conflictingLaneClass ??= other;
          }
        }

        // Coach conflict check
        if (!isUnassigned && c.coachId.isNotEmpty && other.coachId.isNotEmpty && c.coachId == other.coachId) {
          conflictingCoachClass ??= other;
        }
      }
    }

    final hasConflict = conflictingLaneClass != null || conflictingCoachClass != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: currentTheme.isDark
            ? null
            : (hasConflict
                ? null
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )),
        color: currentTheme.isDark
            ? (hasConflict
                ? const Color(0xFF1E1424).withValues(alpha: 0.95)
                : const Color(0xFF0F2642).withValues(alpha: 0.85))
            : (hasConflict ? const Color(0xFFFFFBEB) : null),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasConflict
              ? const Color(0xFFF59E0B)
              : (currentTheme.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                  : const Color(0xFFBAE6FD)),
          width: hasConflict ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasConflict
                ? const Color(0xFFF59E0B).withValues(alpha: currentTheme.isDark ? 0.30 : 0.15)
                : (currentTheme.isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF0284C7).withValues(alpha: 0.07)),
            blurRadius: hasConflict ? 14 : 12,
            offset: const Offset(0, 3),
          ),
          if (currentTheme.isDark && !hasConflict)
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
              blurRadius: 16,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CreateClassSheet(
                classToEdit: c,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Time Badge - Jewel Cyan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.40),
                          width: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.clock, size: 11.5, color: Colors.white),
                          const SizedBox(width: 4.5),
                          Text(
                            '$timeStr - $endTimeStr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (c.lane.isNotEmpty && c.lane != 'Будь-яка')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: conflictingLaneClass != null
                              ? const Color(0xFFEF4444).withValues(alpha: currentTheme.isDark ? 0.25 : 0.12)
                              : (currentTheme.isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                                  : const Color(0xFFE0F2FE)),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: conflictingLaneClass != null
                                ? const Color(0xFFEF4444).withValues(alpha: currentTheme.isDark ? 0.60 : 0.45)
                                : (currentTheme.isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                    : const Color(0xFFBAE6FD)),
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              conflictingLaneClass != null ? LucideIcons.triangleAlert : LucideIcons.waves,
                              color: conflictingLaneClass != null
                                  ? const Color(0xFFEF4444)
                                  : (currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                              size: 11,
                            ),
                            const SizedBox(width: 4.5),
                            Text(
                              conflictingLaneClass != null ? '${c.lane} (ДУБЛЬ)' : c.lane,
                              style: TextStyle(
                                color: conflictingLaneClass != null
                                    ? const Color(0xFFEF4444)
                                    : (currentTheme.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (conflictingCoachClass != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: currentTheme.isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: currentTheme.isDark ? 0.60 : 0.45),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.triangleAlert, color: Color(0xFFF59E0B), size: 11),
                            SizedBox(width: 4),
                            Text(
                              'ДУБЛЬ ТРЕНЕРА',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: currentTheme.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: currentTheme.isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                : const Color(0xFFBAE6FD),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.moreHorizontal,
                          color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF0284C7),
                          size: 16,
                        ),
                      ),
                      color: currentTheme.isDark ? const Color(0xFF0C2238) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: currentTheme.isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                              : const Color(0xFFBAE6FD),
                          width: 1.1,
                        ),
                      ),
                      onSelected: (value) async {
                        HapticFeedback.lightImpact();
                        if (value == 'edit') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => CreateClassSheet(
                              classToEdit: c,
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: currentTheme.isDark ? const Color(0xFF0C2238) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: currentTheme.isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              title: Text(
                                'admin.cal_delete_title'.tr(),
                                style: TextStyle(color: currentTheme.textPrimary, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                'admin.cal_delete_confirm'.tr(args: [c.title]),
                                style: TextStyle(color: currentTheme.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('admin.no'.tr(), style: TextStyle(color: currentTheme.textMuted)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF43F5E),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'admin.yes_delete'.tr(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final success = await ref.read(scheduleControllerProvider.notifier).deleteClass(c.id);
                            if (success) {
                              final admin = ref.read(authControllerProvider);
                              if (admin != null) {
                                await logAdminAction('Скасовано заняття "${c.title}" (${c.startTime.day}.${c.startTime.month})', admin.id);
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(LucideIcons.pencil, size: 16, color: currentTheme.accentPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Редагувати заняття',
                                style: TextStyle(
                                  color: currentTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFFF3B30)),
                              const SizedBox(width: 8),
                              Text(
                                'admin.cal_cancel_class'.tr(),
                                style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  c.title,
                  style: TextStyle(
                    color: currentTheme.isDark ? Colors.white : currentTheme.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                if (hasConflict) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: currentTheme.isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: currentTheme.isDark ? 0.45 : 0.30),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1.5),
                              child: Icon(LucideIcons.triangleAlert, color: Color(0xFFEF4444), size: 15),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                conflictingLaneClass != null
                                    ? 'Накладка: доріжка «${c.lane}» вже зайнята заняттям «${conflictingLaneClass.title}» (${conflictingLaneClass.coachName.isNotEmpty ? conflictingLaneClass.coachName : "без тренера"})'
                                    : 'Накладка: тренер ${c.coachName} вже веде заняття «${conflictingCoachClass?.title}» в цей самий час',
                                style: TextStyle(
                                  color: currentTheme.isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: currentTheme.isDark ? const Color(0xFF0F1E32) : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Text('Видалити дублікат?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      'Видалити це дублююче заняття «${c.title}» (${c.coachName.isNotEmpty ? c.coachName : "без тренера"}, ${c.lane})?',
                                      style: TextStyle(fontSize: 14, color: currentTheme.textSecondary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text('admin.cancel'.tr(), style: TextStyle(color: currentTheme.textSecondary)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFEF4444),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Видалити', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final success = await ref.read(scheduleControllerProvider.notifier).deleteClass(c.id);
                                  if (success) {
                                    final admin = ref.read(authControllerProvider);
                                    if (admin != null) {
                                      await logAdminAction('Видалено дублікат заняття "${c.title}" (${c.lane})', admin.id);
                                    }
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: currentTheme.isDark ? 0.30 : 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.55),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 13),
                                    SizedBox(width: 5),
                                    Text(
                                      'Видалити цей дублікат',
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 9),

                // Coach & Capacity Row
                Row(
                  children: [
                    if (isUnassigned) ...[
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CreateClassSheet(
                                classToEdit: c,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: currentTheme.isDark ? 0.22 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: currentTheme.isDark ? 0.55 : 0.35),
                                width: 1.1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.userX, color: Color(0xFFF59E0B), size: 12),
                                SizedBox(width: 4.5),
                                Text(
                                  'Без тренера ✎',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else if (c.coachName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: currentTheme.isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.14)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: currentTheme.isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                : const Color(0xFFBAE6FD),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.award,
                              color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.45,
                              ),
                              child: Text(
                                c.coachName.replaceFirst(RegExp(r'^Тренер\s+', caseSensitive: false), ''),
                                style: TextStyle(
                                  color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.users,
                          color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          size: 13,
                        ),
                        const SizedBox(width: 4.5),
                        Text(
                          '$enrolledCount/${c.maxCapacity} • ${spotsLeft > 0 ? "вільно $spotsLeft" : "повний"}',
                          style: TextStyle(
                            color: spotsLeft == 0
                                ? const Color(0xFFF43F5E)
                                : (currentTheme.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A)),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Neon progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(
                        height: 5,
                        width: double.infinity,
                        color: currentTheme.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE0F2FE),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: progress >= 1.0
                                  ? const [Color(0xFFF43F5E), Color(0xFFE11D48)]
                                  : progress >= 0.75
                                      ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
                                      : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (progress >= 1.0
                                        ? const Color(0xFFF43F5E)
                                        : (progress >= 0.75
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF00E5FF)))
                                    .withValues(alpha: currentTheme.isDark ? 0.45 : 0.25),
                                blurRadius: 4,
                              ),
                            ],
                          ),
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
}
