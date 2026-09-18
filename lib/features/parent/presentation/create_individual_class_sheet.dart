import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_subscription_tab.dart';

class CreateIndividualClassSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final String selectedUserId;
  final bool isAdult;

  const CreateIndividualClassSheet({
    super.key,
    required this.selectedDate,
    required this.selectedUserId,
    required this.isAdult,
  });

  @override
  ConsumerState<CreateIndividualClassSheet> createState() => _CreateIndividualClassSheetState();
}

class _CreateIndividualClassSheetState extends ConsumerState<CreateIndividualClassSheet> {
  String? _selectedService;
  int? _selectedHour;
  bool _isLoading = false;

  late List<String> _availableServices;
  final List<int> _allHours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]; // 09:00 - 20:00

  @override
  void initState() {
    super.initState();
    _availableServices = [
      'Групові заняття для дітей (старша група 9-15 років)',
      'Групові заняття для дітей (молодша група 6-8 років)',
      'Групові заняття для дорослих',
      'Індивідуальні тренування для дітей',
      'Індивідуальні тренування для дорослих',
      'Спліт тренування ( 2 особи ) діти/ дорослі',
      'Аквааеробіка',
    ];
    _selectedService = _availableServices.first;
  }

  void _createBooking() async {
    if (_selectedService == null || _selectedHour == null) return;
    
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    
    String ownerName = user.name;
    if (widget.selectedUserId != user.id) {
       final childrenAsync = ref.read(childrenControllerProvider);
       final children = childrenAsync.value ?? [];
       try {
         ownerName = children.firstWhere((c) => c.id == widget.selectedUserId).name;
       } catch (_) {
         // Fallback to parent name if child not found
       }
    }
    
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final subscription = subscriptionController.getSubscriptionForOwner(user.id, ownerName);
    final currentTheme = ref.read(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    
    if (subscription == null || subscription.remainingClasses <= 0) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : currentTheme.cardBorder,
              ),
            ),
            title: Text('Немає абонемента', style: TextStyle(color: currentTheme.textPrimary, fontWeight: FontWeight.bold)),
            content: Text(
              'Для запису необхідно мати оплачений абонемент для $ownerName. Бажаєте придбати його у розділі "Абонемент"?',
              style: TextStyle(color: isDark ? Colors.white70 : currentTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Скасувати', style: TextStyle(color: isDark ? Colors.white54 : currentTheme.textMuted)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close bottom sheet
                  ref.read(selectedSubscriptionOwnerProvider.notifier).setSelectedOwner(ownerName);
                  ref.read(parentTabProvider.notifier).setTab(2); // Switch to Subscriptions tab
                },
                child: Text(
                  'Придбати абонемент',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final startTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedHour!,
    );

    if (startTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неможливо обрати минулий час для тренування'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final endTime = startTime.add(const Duration(hours: 1));

    try {
      final success = await ref.read(scheduleControllerProvider.notifier).createClass(
        title: _selectedService!,
        startTime: startTime,
        endTime: endTime,
        coachId: 'unassigned',
        coachName: 'Тренер не призначений',
        maxCapacity: _selectedService!.contains('Спліт') ? 2 : 1,
        category: 'Індивідуальне',
        lane: 'Будь-яка',
        enrolledChildIds: [widget.selectedUserId],
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заняття успішно заплановано!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не вдалося запланувати заняття.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    // Determine occupied hours for the selected date
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final classesOnDate = scheduleAsync.value?.where((c) {
      return c.startTime.year == widget.selectedDate.year &&
             c.startTime.month == widget.selectedDate.month &&
             c.startTime.day == widget.selectedDate.day;
    }).toList() ?? [];

    final occupiedHours = classesOnDate
        .where((c) => c.enrolledChildIds.isNotEmpty || c.maxCapacity > 2)
        .where((c) {
           if (c.enrolledChildIds.contains(widget.selectedUserId)) return true;
           
           final title = c.title.toLowerCase();
           final isAdultClass = title.contains('дорослих') || title.contains('аквааеробіка'); 
           final isChildClass = title.contains('діт');
           final isSplit = title.contains('спліт');
           
           if (isSplit) return true;
           if (widget.isAdult) return isAdultClass;
           return isChildClass;
        })
        .map((c) => c.startTime.hour)
        .toSet();

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  const Color(0xFF0284C7).withValues(alpha: 0.26),
                  const Color(0xFF0A223D).withValues(alpha: 0.55),
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.96),
                  const Color(0xFFF0F9FF).withValues(alpha: 0.92),
                ],
              ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.35) : currentTheme.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
          if (isDark)
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
              blurRadius: 36,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Запланувати заняття',
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(
                  'Оберіть послугу',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : currentTheme.textSecondary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableServices.map((service) {
                    final isSelected = _selectedService == service;
                    return ChoiceChip(
                      label: Text(service),
                      selected: isSelected,
                      selectedColor: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                          : const Color(0xFF0284C7).withValues(alpha: 0.15),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.85),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                            : (isDark ? Colors.white70 : currentTheme.textSecondary),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                            : (isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFBAE6FD)),
                        width: isSelected ? 1.2 : 1.0,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedService = service);
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                Text(
                  'Оберіть час',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : currentTheme.textSecondary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final todayDate = DateTime(now.year, now.month, now.day);
                    final selectedDateOnly = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
                    final isPastDay = selectedDateOnly.isBefore(todayDate);
                    final isToday = selectedDateOnly.isAtSameMomentAs(todayDate);

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allHours.map((hour) {
                        final isPastHour = isPastDay || (isToday && hour <= now.hour);
                        final isOccupied = occupiedHours.contains(hour);
                        final isDisabled = isOccupied || isPastHour;
                        final isSelected = _selectedHour == hour;
                        
                        return InkWell(
                          onTap: isDisabled ? null : () => setState(() => _selectedHour = hour),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isOccupied 
                                  ? (isDark ? Colors.redAccent.withValues(alpha: 0.12) : const Color(0xFFFEE2E2)) 
                                  : isPastHour
                                      ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04))
                                      : (isSelected
                                          ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                          : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.85))),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : isOccupied
                                        ? (isDark ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFFFECACA))
                                        : isPastHour
                                            ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08))
                                            : (isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD)),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                color: isOccupied 
                                    ? Colors.redAccent.withValues(alpha: 0.6) 
                                    : isPastHour
                                        ? (isDark ? Colors.white30 : Colors.black38)
                                        : (isSelected ? Colors.white : currentTheme.textPrimary),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                                decoration: isDisabled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: (_isLoading || _selectedService == null || _selectedHour == null)
                        ? null
                        : LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                                : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: (_isLoading || _selectedService == null || _selectedHour == null)
                        ? null
                        : [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: (_isLoading || _selectedService == null || _selectedHour == null)
                        ? null
                        : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isLoading || _selectedService == null || _selectedHour == null)
                          ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12)
                          : Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Підтвердити',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
