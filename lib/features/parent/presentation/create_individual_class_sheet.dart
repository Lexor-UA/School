import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';

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
      'Групові заняття з плавання для дітей старша група',
      'Групові заняття з плавання для дітей молодша група',
      'Групові заняття з плавання для дорослих',
      'Індивідуальні тренування з плавання для дітей',
      'Індивідуальні тренування з плавання для дорослих',
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
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Зрозуміло', style: TextStyle(color: Colors.cyanAccent)),
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
              backgroundColor: Colors.greenAccent,
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
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Запланувати заняття',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Оберіть заняття',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableServices.map((service) {
              final isSelected = _selectedService == service;
              return ChoiceChip(
                label: Text(service),
                selected: isSelected,
                selectedColor: AppTheme.accentTeal.withValues(alpha: 0.2),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.accentTeal : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(color: isSelected ? AppTheme.accentTeal : Colors.transparent),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedService = service);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Оберіть час',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allHours.map((hour) {
              final isOccupied = occupiedHours.contains(hour);
              final isSelected = _selectedHour == hour;
              
              return InkWell(
                onTap: isOccupied ? null : () => setState(() => _selectedHour = hour),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isOccupied 
                        ? Colors.redAccent.withValues(alpha: 0.1) 
                        : (isSelected ? AppTheme.primaryBlue : Colors.white.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      color: isOccupied 
                          ? Colors.redAccent.withValues(alpha: 0.5) 
                          : (isSelected ? Colors.white : Colors.white70),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      decoration: isOccupied ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isLoading || _selectedService == null || _selectedHour == null)
                  ? null
                  : _createBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentTeal,
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
          const SizedBox(height: 24), // SafeArea margin equivalent
        ],
      ),
    );
  }
}
