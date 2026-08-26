import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_booking_screen.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';

class ParentCalendarTab extends ConsumerStatefulWidget {
  const ParentCalendarTab({super.key});

  @override
  ConsumerState<ParentCalendarTab> createState() => _ParentCalendarTabState();
}

class _ParentCalendarTabState extends ConsumerState<ParentCalendarTab> {
  bool isWeekView = false;
  String selectedChildId = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM', 'uk').format(now);
    final capitalizedDate = dateStr[0].toUpperCase() + dateStr.substring(1);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Календар', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _buildViewToggle(isDark),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Child Selector
          _buildChildSelector(isDark),
          const SizedBox(height: 16),
          
          // Calendar UI
          _buildCalendarHeader(isDark),
          _buildCalendarGrid(isDark),
          
          const SizedBox(height: 16),
          
          // Selected Day Classes
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                Text(
                  capitalizedDate, 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 16),
                _buildClassesForSelectedDay(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleBtn('Місяць', !isWeekView, isDark, () => setState(() => isWeekView = false)),
          _buildToggleBtn('Тиждень', isWeekView, isDark, () => setState(() => isWeekView = true)),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool active, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? (isDark ? Colors.cyanAccent.withValues(alpha: 0.2) : AppTheme.primaryBlue.withValues(alpha: 0.1)) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: TextStyle(
          color: active ? (isDark ? Colors.cyanAccent : AppTheme.primaryBlue) : (isDark ? Colors.white54 : Colors.black54),
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }

  Widget _buildChildSelector(bool isDark) {
    final childrenAsync = ref.watch(childrenControllerProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildChildChip('all', 'Усі діти', Colors.white, selectedChildId == 'all', isDark),
          ...childrenAsync.when(
            data: (children) => children.map((c) => _buildChildChip(
              c.id, 
              c.name, 
              Color(int.parse(c.colorHex)), 
              selectedChildId == c.id, 
              isDark
            )).toList(),
            loading: () => [const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))],
            error: (_, __) => [const Text('Error loading children')],
          ),
        ],
      ),
    );
  }

  Widget _buildChildChip(String id, String name, Color color, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => selectedChildId = id),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (id != 'all') ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
            ] else if (id == 'all') ...[
              Icon(LucideIcons.users, size: 14, color: isDark ? Colors.white : Colors.black),
              const SizedBox(width: 8),
            ],
            Text(name, style: TextStyle(
              color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white70 : Colors.black54),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(bool isDark) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'uk').format(now);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(capitalizedMonth, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white54 : Colors.black54),
              const SizedBox(width: 16),
              Icon(LucideIcons.chevronRight, color: isDark ? Colors.white54 : Colors.black54),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1..7
    final monday = now.subtract(Duration(days: currentWeekday - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final isToday = index == (currentWeekday - 1); 
          final dateNumber = monday.add(Duration(days: index)).day;

          return Column(
            children: [
              Text(days[index], style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isToday ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$dateNumber', style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
              ),
              const SizedBox(height: 4),
              // Dots for classes (mocked visually for now, could be dynamic based on ScheduleController)
              if (index == (currentWeekday - 1) || index == currentWeekday)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
                    if (index == (currentWeekday - 1)) ...[
                      const SizedBox(width: 2),
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle)),
                    ]
                  ],
                )
            ],
          );
        }),
      ),
    );
  }

  Widget _buildClassesForSelectedDay(bool isDark) {
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final childrenAsync = ref.watch(childrenControllerProvider);

    if (childrenAsync.isLoading || scheduleAsync.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
    }

    final children = childrenAsync.value ?? [];
    final allClasses = scheduleAsync.value ?? [];

    // Filter classes for the selected day (mocked as today) and where a child is enrolled
    var enrolledClasses = allClasses.where((c) {
      if (c.startTime.day != DateTime.now().day) return false;
      return c.enrolledChildIds.any((enrolledId) => children.any((child) => child.id == enrolledId));
    }).toList();

    // Filter by selected child in UI
    if (selectedChildId != 'all') {
      enrolledClasses = enrolledClasses.where((c) => c.enrolledChildIds.contains(selectedChildId)).toList();
    }

    if (enrolledClasses.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 32),
          Icon(LucideIcons.calendarOff, color: isDark ? Colors.white54 : Colors.black54, size: 40),
          const SizedBox(height: 16),
          Text('На цей день занять немає', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ParentBookingScreen(date: DateTime.now()))),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              foregroundColor: isDark ? Colors.cyanAccent : AppTheme.primaryBlue,
            ),
            child: const Text('Переглянути доступні заняття'),
          )
        ],
      );
    }

    return Column(
      children: enrolledClasses.map((c) {
        // Find which child is enrolled in this class
        final enrolledChildId = c.enrolledChildIds.firstWhere((id) => children.any((ch) => ch.id == id), orElse: () => '');
        final child = children.firstWhere((ch) => ch.id == enrolledChildId, orElse: () => Child(id: '', parentId: '', name: 'Unknown'));
        final color = Color(int.tryParse(child.colorHex) ?? 0xFF000000);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(child.name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Text('${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(c.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(c.lane.isNotEmpty ? c.lane : 'Основний басейн', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 6),
                  const Text('Запис підтверджено', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}
