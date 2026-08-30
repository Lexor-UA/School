import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/create_individual_class_sheet.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('parent.calendar'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildChildSelector(isDark, user?.id ?? '', user?.name ?? 'Я'),
          const SizedBox(height: 16),
          
          _buildCalendarHeader(isDark),
          _buildCalendarGrid(isDark),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: const [
                // Classes are now shown in a bottom sheet
              ],
            ),
          ),
        ],
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



  Widget _buildChildSelector(bool isDark, String parentId, String parentName) {
    final childrenAsync = ref.watch(childrenControllerProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildChildChip(parentId, parentName, Colors.blue, selectedChildId == parentId, isDark, true),
          ...childrenAsync.when(
            data: (children) => children.map((c) => _buildChildChip(
              c.id, 
              c.name, 
              Color(int.parse(c.colorHex)), 
              selectedChildId == c.id, 
              isDark,
              false
            )).toList(),
            loading: () => [const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))],
            error: (_, __) => [const Text('Error loading children')],
          ),
        ],
      ),
    );
  }

  Widget _buildChildChip(String id, String name, Color color, bool isSelected, bool isDark, bool isParent) {
    return GestureDetector(
      onTap: () => setState(() => selectedChildId = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isParent) ...[
              Icon(LucideIcons.baby, size: 14, color: color),
              const SizedBox(width: 8),
            ] else ...[
              Icon(LucideIcons.user, size: 14, color: isDark ? Colors.white : Colors.black),
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
    final monthName = DateFormat('MMMM yyyy', context.locale.languageCode).format(selectedDate);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(capitalizedMonth, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white54 : Colors.black54),
                onPressed: () => setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1)),
              ),
              IconButton(
                icon: Icon(LucideIcons.chevronRight, color: isDark ? Colors.white54 : Colors.black54),
                onPressed: () => setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final daysInMonth = DateUtils.getDaysInMonth(selectedDate.year, selectedDate.month);
    final firstDayOffset = DateTime(selectedDate.year, selectedDate.month, 1).weekday - 1;
    final totalCells = ((daysInMonth + firstDayOffset) / 7).ceil() * 7;
    
    final daysOfWeek = ['parent.mon'.tr(), 'parent.tue'.tr(), 'parent.wed'.tr(), 'parent.thu'.tr(), 'parent.fri'.tr(), 'parent.sat'.tr(), 'parent.sun'.tr()];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek.map((d) => SizedBox(
              width: 32,
              child: Center(child: Text(d, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Grid
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
              final isSelected = selectedDate.day == day;
              final isToday = DateTime.now().year == selectedDate.year && DateTime.now().month == selectedDate.month && DateTime.now().day == day;

              return GestureDetector(
                onTap: () {
                  setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month, day));
                  _showDayClassesSheet(context, isDark);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (isDark ? Colors.cyanAccent : AppTheme.primaryBlue) 
                        : (isToday ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('$day', style: TextStyle(
                      color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : Colors.black),
                      fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDayClassesSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final scheduleAsync = ref.watch(scheduleControllerProvider);
          final childrenAsync = ref.watch(childrenControllerProvider);
          final user = ref.watch(authControllerProvider);

          if (childrenAsync.isLoading || scheduleAsync.isLoading) {
            return Container(
              height: 200,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final children = childrenAsync.value ?? [];
          final allClasses = scheduleAsync.value ?? [];

          var enrolledClasses = allClasses.where((c) {
            return c.enrolledChildIds.any((enrolledId) => 
              (user != null && user.id == enrolledId) || 
              children.any((child) => child.id == enrolledId)
            );
          }).toList();

          if (selectedChildId != 'all') {
            enrolledClasses = enrolledClasses.where((c) => c.enrolledChildIds.contains(selectedChildId)).toList();
          }

          enrolledClasses = enrolledClasses.where((c) => 
            c.startTime.year == selectedDate.year && 
            c.startTime.month == selectedDate.month && 
            c.startTime.day == selectedDate.day
          ).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(
                  '${selectedDate.day} ${DateFormat('MMMM yyyy', context.locale.languageCode).format(selectedDate)}',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: enrolledClasses.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'parent.no_classes_this_day_calendar'.tr(),
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showBookingSheet(context);
                              },
                              icon: const Icon(LucideIcons.plus, color: Colors.black, size: 20),
                              label: Text('parent.schedule_class'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            ...enrolledClasses.map((c) {
                              final enrolledChildId = c.enrolledChildIds.firstWhere((id) => (user != null && id == user.id) || children.any((ch) => ch.id == id), orElse: () => '');
                              final isParent = user != null && enrolledChildId == user.id;
                              final child = isParent ? Child(id: user.id, parentId: '', name: user.name, colorHex: '0xFF00BFFF') : children.firstWhere((ch) => ch.id == enrolledChildId, orElse: () => Child(id: '', parentId: '', name: 'Unknown', colorHex: '0xFFFFFFFF'));
                              final color = isParent ? (isDark ? Colors.cyanAccent : AppTheme.primaryBlue) : Color(int.tryParse(child.colorHex) ?? (isDark ? 0xFFFFFFFF : 0xFF000000));

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
                                        if (!isParent)
                                          Icon(LucideIcons.baby, size: 16, color: color)
                                        else
                                          Icon(LucideIcons.user, size: 16, color: color),
                                        const SizedBox(width: 8),
                                        Text(child.name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                                        const Spacer(),
                                        Text('${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(c.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                                    if (c.lane.isNotEmpty && c.lane != 'Будь-яка')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(c.lane, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 16),
                                        const SizedBox(width: 6),
                                        Text('parent.booking_confirmed'.tr(), style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                          icon: Icon(LucideIcons.moreHorizontal, color: isDark ? Colors.white54 : Colors.black54),
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          onSelected: (value) async {
                                            if (value == 'cancel') {
                                              await ref.read(scheduleControllerProvider.notifier).cancelClass(c.id, enrolledChildId);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'details',
                                              child: Row(children: [Icon(LucideIcons.info, size: 18, color: isDark ? Colors.white : Colors.black), const SizedBox(width: 8), Text('parent.details'.tr())]),
                                            ),
                                            PopupMenuItem(
                                              value: 'cancel',
                                              child: Row(children: [Icon(LucideIcons.xCircle, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text('parent.cancel_class'.tr(), style: const TextStyle(color: Colors.redAccent))]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showBookingSheet(context);
                                },
                                icon: const Icon(LucideIcons.plus, color: Colors.black, size: 20),
                                label: Text('parent.schedule_more'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
