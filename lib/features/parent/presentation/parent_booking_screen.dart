import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';

class ParentBookingScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const ParentBookingScreen({super.key, required this.date});

  @override
  ConsumerState<ParentBookingScreen> createState() => _ParentBookingScreenState();
}

class _ParentBookingScreenState extends ConsumerState<ParentBookingScreen> {
  GroupClass? selectedClass;
  String? selectedUserId;
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
        title: Text('parent.class_booking'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    'parent.available_classes_for'.tr(args: [_formatDate(widget.date)]),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAvailableClasses(isDark),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('parent.selected_class'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => setState(() { selectedClass = null; selectedUserId = null; }),
                        child: Text('parent.change'.tr(), style: const TextStyle(color: Colors.cyanAccent)),
                      ),
                    ],
                  ),
                  _buildSelectedClassCard(selectedClass!, isDark),
                  const SizedBox(height: 32),
                  
                  // Step 2: Select Child (Real data from Firebase)
                  Text('parent.for_whom'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildChildSelectionList(isDark),
                ]
              ],
            ),
          ),

          // Step 3: Confirm Button
          if (selectedClass != null && selectedUserId != null)
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
                      : Text('parent.confirm_record'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Text('parent.no_classes_this_day'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
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
                      'parent.places_left'.tr(args: [(c.maxCapacity - c.enrolledChildIds.length).toString()]) + ' · ' + (c.lane.isNotEmpty ? c.lane : 'parent.main_pool'.tr()),
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isFull)
                Text('parent.full'.tr(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12))
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
              Text(c.lane.isNotEmpty ? c.lane : 'parent.main_pool'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildChildSelectionList(bool isDark) {
    final user = ref.watch(authControllerProvider);
    
    return ref.watch(childrenControllerProvider).when(
      data: (children) {
        return Column(
          children: [
            if (user != null)
              _buildSelectionCard(user.id, user.name, Colors.blue, isDark, true),
            ...children.map((child) => _buildSelectionCard(child.id, child.name, Color(int.tryParse(child.colorHex) ?? 0xFF000000), isDark, false)),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Помилка: $e', style: const TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildSelectionCard(String id, String name, Color color, bool isDark, bool isParent) {
    final bool isSelected = selectedUserId == id;

    return GestureDetector(
      onTap: () => setState(() => selectedUserId = id),
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
            if (!isParent) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold))),
              ),
            ] else ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(LucideIcons.user, color: Colors.blue, size: 24)),
              ),
            ],
            const SizedBox(width: 16),
            Expanded(
              child: Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ),const Spacer(),
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
    if (selectedClass == null || selectedUserId == null) return;
    
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    
    String ownerName = user.name;
    if (selectedUserId != user.id) {
       final childrenAsync = ref.read(childrenControllerProvider);
       final children = childrenAsync.value ?? [];
       try {
         ownerName = children.firstWhere((c) => c.id == selectedUserId).name;
       } catch (e) {}
    }
    
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final subscription = subscriptionController.getSubscriptionForOwner(user.id, ownerName);
    
    if (subscription == null || subscription.remainingClasses <= 0) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Немає абонемента', style: TextStyle(color: Colors.white)),
            content: Text('Для запису необхідно мати оплачений абонемент для $ownerName. Бажаєте придбати його у розділі "Абонемент"?', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати', style: TextStyle(color: Colors.white54))),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close booking modal
                },
                child: const Text('Зрозуміло', style: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => isBooking = true);
    final success = await ref.read(scheduleControllerProvider.notifier).bookClass(selectedClass!.id, selectedUserId!);
    
    if (mounted) {
      if (success) {
        setState(() {
          isBooking = false;
          showSuccess = true;
        });
      } else {
        setState(() => isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('parent.booking_error_msg'.tr())),
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
                'parent.done'.tr(),
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                'parent.child_enrolled_time'.tr(args: ['Запис', _formatDate(widget.date), selectedClass?.startTime.hour.toString().padLeft(2, '0') ?? '']),
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
                  child: Text('parent.ok'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
