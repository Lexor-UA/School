import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    final dayClasses = allClasses.where((c) {
      final matchesDate = c.startTime.year == _selectedDate.year && 
        c.startTime.month == _selectedDate.month && 
        c.startTime.day == _selectedDate.day;
      if (!matchesDate) return false;

      if (_selectedCoachId != null && _selectedCoachId!.isNotEmpty) {
        final matchesId = c.coachId == _selectedCoachId;
        final matchesName = _selectedCoachName != null && c.coachName.isNotEmpty &&
            (c.coachName.toLowerCase().contains(_selectedCoachName!.toLowerCase()) ||
             _selectedCoachName!.toLowerCase().contains(c.coachName.toLowerCase()));
        return matchesId || matchesName;
      }
      return true;
    }).toList();
    dayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: currentTheme.glassCardBg,
            shape: BoxShape.circle,
            border: Border.all(color: currentTheme.cardBorder),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(LucideIcons.arrowLeft, color: currentTheme.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'admin.cal_title'.tr(),
          style: TextStyle(
            color: currentTheme.textPrimary,
            fontWeight: FontWeight.bold,
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
            child: Column(
              children: [
                const SizedBox(height: 6),
                // Month Header & Calendar Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCalendarCard(allClasses, currentTheme),
                ),
                const SizedBox(height: 10),

                // Coach Filter Bar (Allows Admin to manage specific coach's schedule)
                _buildCoachFilterBar(currentTheme),

                const SizedBox(height: 10),

                // Selected Day Schedule Section (Directly on screen!)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildDayScheduleSection(dayClasses, currentTheme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(List<GroupClass> allClasses, AppThemeConfig currentTheme) {
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
        color: currentTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: currentTheme.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: currentTheme.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
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
                        onTap: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1)),
                        currentTheme: currentTheme,
                      ),
                      const SizedBox(width: 8),
                      _buildMonthNavButton(
                        icon: LucideIcons.chevronRight,
                        onTap: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1)),
                        currentTheme: currentTheme,
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
                  return Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: (idx == 5 || idx == 6) ? currentTheme.accentPrimary : currentTheme.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
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
                      setState(() {
                        _selectedDate = cellDate;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: currentTheme.accentGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : (isToday
                                ? LinearGradient(
                                    colors: [
                                      currentTheme.accentPrimary.withValues(alpha: 0.22),
                                      currentTheme.accentPrimary.withValues(alpha: 0.08),
                                    ],
                                  )
                                : null),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? currentTheme.accentPrimary
                              : (isToday
                                  ? currentTheme.accentPrimary.withValues(alpha: 0.6)
                                  : Colors.transparent),
                          width: isSelected ? 1.2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
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
                                  : (isToday ? currentTheme.accentPrimary : currentTheme.textPrimary),
                              fontWeight: (isSelected || isToday) ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 13.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: hasClasses
                                  ? (isSelected ? Colors.white : const Color(0xFF10B981))
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              boxShadow: hasClasses
                                  ? [
                                      BoxShadow(
                                        color: (isSelected ? Colors.white : const Color(0xFF10B981))
                                            .withValues(alpha: 0.8),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
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
            color: currentTheme.glassCardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: currentTheme.cardBorder),
          ),
          child: Center(
            child: Icon(icon, color: currentTheme.textPrimary, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachFilterBar(AppThemeConfig currentTheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final coachDocs = snapshot.data!.docs;

        return SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // All coaches chip
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCoachId = null;
                    _selectedCoachName = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _selectedCoachId == null
                        ? currentTheme.accentPrimary.withValues(alpha: 0.20)
                        : currentTheme.chipBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedCoachId == null
                          ? currentTheme.accentPrimary
                          : currentTheme.chipBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 13,
                        color: _selectedCoachId == null ? currentTheme.accentPrimary : currentTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Всі тренери',
                        style: TextStyle(
                          color: _selectedCoachId == null ? currentTheme.accentPrimary : currentTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: _selectedCoachId == null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Individual coach chips
              ...coachDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final cId = doc.id;
                final cName = (data['name'] as String?) ?? 'Тренер';
                final isSelected = _selectedCoachId == cId ||
                    (_selectedCoachName != null && _selectedCoachName!.toLowerCase() == cName.toLowerCase());

                return GestureDetector(
                  onTap: () {
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? currentTheme.accentPrimary.withValues(alpha: 0.20)
                          : currentTheme.chipBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? currentTheme.accentPrimary
                            : currentTheme.chipBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.waves,
                          size: 13,
                          color: isSelected ? currentTheme.accentPrimary : currentTheme.accentSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cName,
                          style: TextStyle(
                            color: isSelected ? currentTheme.accentPrimary : currentTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(LucideIcons.x, size: 12, color: currentTheme.accentPrimary),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayScheduleSection(List<GroupClass> dayClasses, AppThemeConfig currentTheme) {
    final dateStr = DateFormat('d MMMM', context.locale.languageCode).format(_selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: currentTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: currentTheme.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: currentTheme.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
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
                            child: const Center(
                              child: Icon(LucideIcons.calendarClock, color: Colors.white, size: 16),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'admin.cal_classes_for_date'.tr(args: [dateStr]),
                                style: TextStyle(
                                  color: currentTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: currentTheme.accentPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '${dayClasses.length}',
                              style: TextStyle(
                                color: currentTheme.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_selectedCoachName != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCoachId = null;
                                  _selectedCoachName = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: currentTheme.accentPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: currentTheme.accentPrimary.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.userCheck, color: currentTheme.accentPrimary, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedCoachName!,
                                      style: TextStyle(color: currentTheme.accentPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.x, color: currentTheme.accentPrimary, size: 11),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // + Додати заняття
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: currentTheme.accentGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.plus, color: Colors.white, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'admin.cal_add_btn'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Classes List or Empty State
                Expanded(
                  child: dayClasses.isEmpty
                      ? _buildEmptyDayState(dateStr, currentTheme)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 10),
                          physics: const BouncingScrollPhysics(),
                          itemCount: dayClasses.length,
                          itemBuilder: (context, index) {
                            return _buildAdminClassCard(dayClasses[index], currentTheme);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildEmptyDayState(String dateStr, AppThemeConfig currentTheme) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing luminous icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentTheme.accentPrimary.withValues(alpha: 0.22),
                      currentTheme.accentSecondary.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentTheme.accentPrimary.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentTheme.accentPrimary.withValues(alpha: 0.20),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(LucideIcons.calendarX2, color: currentTheme.accentPrimary, size: 26),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'admin.cal_no_classes'.tr(),
                style: TextStyle(
                  color: currentTheme.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'admin.cal_no_classes_desc'.tr(args: [dateStr]),
                style: TextStyle(
                  color: currentTheme.textSecondary,
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Quick template time chips
              Text(
                'admin.cal_quick_templates'.tr(),
                style: TextStyle(
                  color: currentTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
                    time: const TimeOfDay(hour: 9, minute: 0),
                    currentTheme: currentTheme,
                  ),
                  _buildQuickTimeChip(
                    icon: LucideIcons.sun,
                    iconColor: const Color(0xFFF59E0B),
                    label: '14:00',
                    time: const TimeOfDay(hour: 14, minute: 0),
                    currentTheme: currentTheme,
                  ),
                  _buildQuickTimeChip(
                    icon: LucideIcons.moon,
                    iconColor: const Color(0xFF818CF8),
                    label: '18:00',
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
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CreateClassSheet(initialDate: _selectedDate),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentTheme.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'admin.cal_create_for_date'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _buildQuickTimeChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TimeOfDay time,
    required AppThemeConfig currentTheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
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
            builder: (context) => CreateClassSheet(initialDate: targetDate),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: currentTheme.chipBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: currentTheme.chipBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: currentTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminClassCard(GroupClass c, AppThemeConfig currentTheme) {
    final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${c.endTime.hour.toString().padLeft(2, '0')}:${c.endTime.minute.toString().padLeft(2, '0')}';
    final enrolledCount = c.enrolledChildIds.length;
    final progress = c.maxCapacity > 0 ? (enrolledCount / c.maxCapacity).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: currentTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: currentTheme.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: currentTheme.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: currentTheme.accentGradient,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$timeStr - $endTimeStr',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (c.lane.isNotEmpty && c.lane != 'Будь-яка')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: currentTheme.glassCardBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: currentTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.waves, color: currentTheme.accentPrimary, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        c.lane,
                        style: TextStyle(color: currentTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(LucideIcons.moreHorizontal, color: currentTheme.textSecondary, size: 18),
                color: currentTheme.dialogBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: currentTheme.dialogBorder),
                ),
                onSelected: (value) async {
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
                        backgroundColor: currentTheme.dialogBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('admin.cal_delete_title'.tr(), style: TextStyle(color: currentTheme.textPrimary, fontWeight: FontWeight.bold)),
                        content: Text('admin.cal_delete_confirm'.tr(args: [c.title]), style: TextStyle(color: currentTheme.textSecondary)),
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
                            child: Text('admin.yes_delete'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        Text('admin.cal_cancel_class'.tr(), style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.title,
            style: TextStyle(
              color: currentTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Coach & Capacity
          Row(
            children: [
              if (c.coachName.isNotEmpty) ...[
                Icon(LucideIcons.award, color: currentTheme.accentPrimary, size: 13),
                const SizedBox(width: 4),
                Text(
                  c.coachName,
                  style: TextStyle(color: currentTheme.accentPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 14),
              ],
              Icon(LucideIcons.users, color: currentTheme.textMuted, size: 13),
              const SizedBox(width: 4),
              Text(
                '$enrolledCount / ${c.maxCapacity} ${'admin.spots_label'.tr()}',
                style: TextStyle(color: currentTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: currentTheme.chipBg,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? const Color(0xFFF43F5E) : currentTheme.accentPrimary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
