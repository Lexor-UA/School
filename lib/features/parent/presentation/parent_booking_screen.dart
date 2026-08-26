import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class ParentBookingScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const ParentBookingScreen({super.key, required this.date});

  @override
  ConsumerState<ParentBookingScreen> createState() => _ParentBookingScreenState();
}

class _ParentBookingScreenState extends ConsumerState<ParentBookingScreen> {
  GroupClass? selectedClass;
  Child? selectedChild;
  bool isBooking = false;
  bool showSuccess = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (showSuccess) {
      return _buildSuccessScreen(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkTheme.scaffoldBackgroundColor : AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Запис на заняття', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (selectedClass == null) ...[
                  Text(
                    'Доступні заняття на ${_formatDate(widget.date)}',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAvailableClasses(isDark),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Обране заняття', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => setState(() { selectedClass = null; selectedChild = null; }),
                        child: const Text('Змінити', style: TextStyle(color: Colors.cyanAccent)),
                      ),
                    ],
                  ),
                  _buildSelectedClassCard(selectedClass!, isDark),
                  const SizedBox(height: 32),
                  
                  // Step 2: Select Child (Real data from Firebase)
                  Text('Для кого?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildChildSelectionList(isDark),
                ]
              ],
            ),
          ),

          // Step 3: Confirm Button
          if (selectedClass != null && selectedChild != null)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isBooking ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isBooking
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3))
                      : const Text('Підтвердити запис', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ).animate().slideY(begin: 0.2, end: 0).fadeIn(),
            )
        ],
      ),
    );
  }

  Widget _buildAvailableClasses(bool isDark) {
    return ref.watch(scheduleControllerProvider).when(
      data: (classes) {
        final available = classes.where((c) => c.startTime.year == widget.date.year && c.startTime.month == widget.date.month && c.startTime.day == widget.date.day).toList();
        
        if (available.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(LucideIcons.calendarOff, size: 48, color: isDark ? Colors.white54 : Colors.black54),
                  const SizedBox(height: 16),
                  Text('На цей день немає вільних занять', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: available.map((c) => _buildClassOptionCard(c, isDark)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Помилка: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }

  Widget _buildClassOptionCard(GroupClass c, bool isDark) {
    final bool isFull = c.enrolledChildIds.length >= c.maxCapacity;

    return GestureDetector(
      onTap: isFull ? null : () => setState(() => selectedClass = c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Opacity(
          opacity: isFull ? 0.5 : 1.0,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: isDark ? Colors.cyanAccent : AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${c.maxCapacity - c.enrolledChildIds.length} місць вільних · ${c.lane.isNotEmpty ? c.lane : 'Басейн'}',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isFull)
                const Text('Заповнено', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12))
              else
                Icon(LucideIcons.chevronRight, color: isDark ? Colors.cyanAccent : AppTheme.primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedClassCard(GroupClass c, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.cyanAccent.withValues(alpha: 0.05) : Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.cyan.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.checkCircle2, color: isDark ? Colors.cyanAccent : AppTheme.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')} · ${c.title}',
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.user, color: isDark ? Colors.white54 : Colors.black54, size: 16),
              const SizedBox(width: 8),
              Text('Тренер: ${c.coachName}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(LucideIcons.mapPin, color: isDark ? Colors.white54 : Colors.black54, size: 16),
              const SizedBox(width: 8),
              Text(c.lane.isNotEmpty ? c.lane : 'Основний басейн', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildChildSelectionList(bool isDark) {
    return ref.watch(childrenControllerProvider).when(
      data: (children) {
        if (children.isEmpty) {
          return const Text('У вашому профілі ще немає доданих дітей.', style: TextStyle(color: Colors.redAccent));
        }
        return Column(
          children: children.map((child) => _buildChildSelectionCard(child, isDark)).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Помилка: $e', style: const TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildChildSelectionCard(Child child, bool isDark) {
    final bool isSelected = selectedChild?.id == child.id;
    final color = Color(int.tryParse(child.colorHex) ?? 0xFF000000);

    return GestureDetector(
      onTap: () => setState(() => selectedChild = child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.8), shape: BoxShape.circle),
              child: Center(child: Text(child.name.isNotEmpty ? child.name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            ),
            const SizedBox(width: 16),
            Text(child.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: color)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white54 : Colors.black54),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Future<void> _confirmBooking() async {
    setState(() => isBooking = true);
    
    // Use the real schedule controller method to book
    bool success = await ref.read(scheduleControllerProvider.notifier).bookClass(selectedClass!.id, selectedChild!.id);
    
    if (mounted) {
      if (success) {
        setState(() {
          isBooking = false;
          showSuccess = true;
        });
      } else {
        setState(() => isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка запису. Можливо немає місць або абонемент неактивний.')),
        );
      }
    }
  }

  Widget _buildSuccessScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkTheme.scaffoldBackgroundColor : AppTheme.backgroundGrey,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.check, color: Colors.greenAccent, size: 64),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                'Готово!',
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                '${selectedChild?.name ?? 'Дитину'} записано на тренування ${_formatDate(widget.date)} о ${selectedClass?.startTime.hour.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16, height: 1.5),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 64),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    foregroundColor: isDark ? Colors.cyanAccent : AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Добре', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}
