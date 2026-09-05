import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/admin/presentation/create_class_sheet.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class AdminCalendarScreen extends ConsumerStatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  ConsumerState<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends ConsumerState<AdminCalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    final dayClasses = allClasses.where((c) => 
      c.startTime.year == _selectedDate.year && 
      c.startTime.month == _selectedDate.month && 
      c.startTime.day == _selectedDate.day
    ).toList();
    dayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: const Color(0xFF09182B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Розклад та Календар',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
            letterSpacing: 0.3,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Full-vibrancy animated water
          const RepaintBoundary(child: AnimatedWaterBackground()),
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),

          // 2. Liquid gradient atmosphere overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00B4DB).withValues(alpha: 0.15),
                    const Color(0xFF0284C7).withValues(alpha: 0.10),
                    const Color(0xFF09182B).withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. Screen content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 6),
                // Month Header & Calendar Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCalendarCard(allClasses),
                ),
                const SizedBox(height: 14),

                // Selected Day Schedule Section (Directly on screen!)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildDayScheduleSection(dayClasses),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(List<GroupClass> allClasses) {
    final monthName = DateFormat('LLLL yyyy', context.locale.languageCode).format(_selectedDate);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final firstDayOffset = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday - 1;
    final totalCells = ((daysInMonth + firstDayOffset) / 7).ceil() * 7;
    final daysOfWeek = ['Пн', 'Вв', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF13233C).withValues(alpha: 0.90),
            const Color(0xFF0A1422).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
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
              const SizedBox(height: 12),

              // Days of week header
              Row(
                children: daysOfWeek.map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: (d == 'Сб' || d == 'Нд') ? const Color(0xFF38BDF8) : Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )).toList(),
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
                        borderRadius: BorderRadius.circular(12),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDayScheduleSection(List<GroupClass> dayClasses) {
    final dateStr = DateFormat('d MMMM', context.locale.languageCode).format(_selectedDate);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF13233C).withValues(alpha: 0.90),
            const Color(0xFF0A1422).withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
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
                            child: Text(
                              'Заняття: $dateStr',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                            builder: (context) => CreateClassSheet(initialDate: _selectedDate),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.plus, color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Додати',
                                style: TextStyle(
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
                      ? _buildEmptyDayState(dateStr)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 10),
                          physics: const BouncingScrollPhysics(),
                          itemCount: dayClasses.length,
                          itemBuilder: (context, index) {
                            return _buildAdminClassCard(dayClasses[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDayState(String dateStr) {
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
                      const Color(0xFF38BDF8).withValues(alpha: 0.22),
                      const Color(0xFF0077B6).withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.calendarX2, color: Color(0xFF38BDF8), size: 26),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Немає запланованих занять',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'На $dateStr ще не призначено жодних тренувань',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Quick template time chips
              Text(
                'Швидке створення за шаблоном часу:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
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
                  ),
                  _buildQuickTimeChip(
                    icon: LucideIcons.sun,
                    iconColor: const Color(0xFFF59E0B),
                    label: '14:00',
                    time: const TimeOfDay(hour: 14, minute: 0),
                  ),
                  _buildQuickTimeChip(
                    icon: LucideIcons.moon,
                    iconColor: const Color(0xFF818CF8),
                    label: '18:00',
                    time: const TimeOfDay(hour: 18, minute: 0),
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Створити заняття на цю дату',
                          style: TextStyle(
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
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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

  Widget _buildAdminClassCard(GroupClass c) {
    final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${c.endTime.hour.toString().padLeft(2, '0')}:${c.endTime.minute.toString().padLeft(2, '0')}';
    final enrolledCount = c.enrolledChildIds.length;
    final progress = c.maxCapacity > 0 ? (enrolledCount / c.maxCapacity).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
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
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.waves, color: Color(0xFF38BDF8), size: 11),
                      const SizedBox(width: 4),
                      Text(
                        c.lane,
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreHorizontal, color: Colors.white70, size: 18),
                color: const Color(0xFF13233C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Видалити заняття?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text('Ви впевнені, що хочете скасувати "${c.title}"?', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false), 
                            child: const Text('Ні', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF43F5E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context, true), 
                            child: const Text('Так, видалити', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 16, color: Color(0xFFFF3B30)),
                        SizedBox(width: 8),
                        Text('Скасувати заняття', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 13, fontWeight: FontWeight.w600)),
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
            style: const TextStyle(
              color: Colors.white,
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
                const Icon(LucideIcons.award, color: Color(0xFF00E5FF), size: 13),
                const SizedBox(width: 4),
                Text(
                  c.coachName,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 14),
              ],
              const Icon(LucideIcons.users, color: Colors.white60, size: 13),
              const SizedBox(width: 4),
              Text(
                '$enrolledCount / ${c.maxCapacity} місць',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? const Color(0xFFF43F5E) : const Color(0xFF00E5FF),
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
