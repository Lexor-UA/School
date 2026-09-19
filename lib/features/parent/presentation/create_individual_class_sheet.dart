import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_subscription_tab.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';

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
  final Set<String> _selectedParticipantIds = {};

  late List<String> _availableServices;
  final List<int> _allHours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]; // 09:00 - 20:00

  bool get _isSplit => _selectedService?.contains('Спліт') == true;

  @override
  void initState() {
    super.initState();
    if (widget.isAdult) {
      _availableServices = [
        'Індивідуальні тренування для дорослих',
        'Групові заняття для дорослих',
        'Спліт тренування ( 2 особи ) діти/ дорослі',
        'Аквааеробіка',
      ];
    } else {
      _availableServices = [
        'Індивідуальні тренування для дітей',
        'Групові заняття для дітей (старша група 9-15 років)',
        'Групові заняття для дітей (молодша група 6-8 років)',
        'Спліт тренування ( 2 особи ) діти/ дорослі',
      ];
    }
    _selectedService = _availableServices.first;
    _initSplitParticipants();
  }

  void _initSplitParticipants() {
    _selectedParticipantIds.clear();
    _selectedParticipantIds.add(widget.selectedUserId);

    final user = ref.read(authControllerProvider);
    final children = ref.read(childrenControllerProvider).value ?? [];

    if (widget.selectedUserId == user?.id) {
      // Current profile is parent -> auto-add first child if available
      if (children.isNotEmpty) {
        _selectedParticipantIds.add(children.first.id);
      }
    } else {
      // Current profile is child -> auto-add parent
      if (user != null) {
        _selectedParticipantIds.add(user.id);
      }
    }
  }

  void _toggleParticipant(String id) {
    setState(() {
      if (_selectedParticipantIds.contains(id)) {
        _selectedParticipantIds.remove(id);
      } else {
        if (_selectedParticipantIds.length < 2) {
          _selectedParticipantIds.add(id);
        } else {
          // Already have 2 participants selected.
          // Smooth swap: replace the member who isn't widget.selectedUserId,
          // or replace the first member if both differ.
          final toReplace = _selectedParticipantIds.firstWhere(
            (item) => item != widget.selectedUserId,
            orElse: () => _selectedParticipantIds.first,
          );
          _selectedParticipantIds.remove(toReplace);
          _selectedParticipantIds.add(id);
        }
      }
    });
  }

  void _createBooking() async {
    if (_selectedService == null || _selectedHour == null) return;

    if (_isSplit && _selectedParticipantIds.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, оберіть двох учасників для спліт-тренування'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final currentTheme = ref.read(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final userSubs = subscriptionController.getSubscriptionsForUser(user.id);

    Subscription? activeSub;

    if (_isSplit) {
      // 1. Check for dedicated split subscription
      activeSub = userSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
        (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
      );

      // 2. If no split subscription, check if any participant has an active subscription
      if (activeSub == null) {
        final children = ref.read(childrenControllerProvider).value ?? [];
        for (final pId in _selectedParticipantIds) {
          final isPAdult = pId == user.id;
          final pName = isPAdult ? user.name : (children.firstWhereOrNull((c) => c.id == pId)?.name ?? user.name);
          final sub = subscriptionController.getSubscriptionForOwner(user.id, pName, isAdult: isPAdult);
          if (sub != null && sub.remainingClasses > 0) {
            activeSub = sub;
            break;
          }
        }
      }

      // 3. Fallback to any active subscription with remaining classes
      activeSub ??= userSubs.firstWhereOrNull((s) => s.isActive && s.remainingClasses > 0);

      if (activeSub == null) {
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
                'Для запису на спліт-тренування необхідно мати активний абонемент (Спліт або стандартний). Бажаєте придбати його у розділі "Абонемент"?',
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
    } else {
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
      
      final subscription = subscriptionController.getSubscriptionForOwner(user.id, ownerName, isAdult: widget.isAdult);
      
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
                widget.isAdult
                    ? 'Для запису необхідно мати оплачений дорослий абонемент для $ownerName. Бажаєте придбати його у розділі "Абонемент"?'
                    : 'Для запису необхідно мати оплачений дитячий абонемент для $ownerName. Бажаєте придбати його у розділі "Абонемент"?',
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
      setState(() => _isLoading = false);
      return;
    }

    final endTime = startTime.add(const Duration(hours: 1));

    final enrolledIds = _isSplit
        ? _selectedParticipantIds.toList()
        : [widget.selectedUserId];

    try {
      final success = await ref.read(scheduleControllerProvider.notifier).createClass(
        title: _selectedService!,
        startTime: startTime,
        endTime: endTime,
        coachId: 'unassigned',
        coachName: 'Тренер не призначений',
        maxCapacity: _isSplit ? 2 : 1,
        category: 'Індивідуальне',
        lane: 'Будь-яка',
        enrolledChildIds: enrolledIds,
        isCustomBooking: true,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isSplit
                  ? 'Спліт-заняття для 2 осіб успішно заплановано!'
                  : 'Заняття успішно заплановано!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не вдалося запланувати: учасник вже має заняття на цей час або відсутній активний абонемент.'),
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

  Widget _buildParticipantSelector(bool isDark, AppThemeConfig currentTheme) {
    final user = ref.watch(authControllerProvider);
    final children = ref.watch(childrenControllerProvider).value ?? [];
    final family = ref.watch(familyStreamProvider).value;
    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
    final partnerName = user != null ? family?.getOtherParentName(user.id) : null;

    final List<({String id, String name, bool isAdult})> allMembers = [
      if (user != null) (id: user.id, name: '${user.name} (Я)', isAdult: true),
      if (family != null && family.isPaired && partnerId != null && partnerName != null)
        (id: partnerId, name: partnerName, isAdult: true),
      ...children.map((c) => (id: c.id, name: c.name, isAdult: false)),
    ];

    final count = _selectedParticipantIds.length;
    final isReady = count == 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF00E5FF).withValues(alpha: 0.10),
                  const Color(0xFF0284C7).withValues(alpha: 0.05),
                ]
              : [
                  const Color(0xFFF0F9FF),
                  Colors.white.withValues(alpha: 0.9),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady
              ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : const Color(0xFF0284C7).withValues(alpha: 0.4))
              : (isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD)),
          width: 1.2,
        ),
        boxShadow: isReady && isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.users,
                  size: 16,
                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Учасники спліт-тренування',
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.15)
                      : (isDark ? Colors.orangeAccent.withValues(alpha: 0.20) : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isReady
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : (isDark ? Colors.orangeAccent.withValues(alpha: 0.5) : const Color(0xFFF59E0B)),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReady ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 13,
                      color: isReady
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.orangeAccent : const Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isReady ? '2 з 2 обрано' : 'Обрано $count з 2',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isReady
                            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                            : (isDark ? Colors.orangeAccent : const Color(0xFFD97706)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Оберіть двох членів сім\'ї для спільного заняття:',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white60 : currentTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allMembers.map((member) {
              final isSelected = _selectedParticipantIds.contains(member.id);

              return InkWell(
                onTap: () => _toggleParticipant(member.id),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                    const Color(0xFF0284C7).withValues(alpha: 0.15),
                                  ]
                                : [
                                    const Color(0xFFE0F2FE),
                                    const Color(0xFFBAE6FD).withValues(alpha: 0.6),
                                  ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                          : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.20),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: member.isAdult
                                ? (isDark ? const [Color(0xFF6366F1), Color(0xFF38BDF8)] : const [Color(0xFF4F46E5), Color(0xFF0284C7)])
                                : (isDark ? const [Color(0xFF10B981), Color(0xFF06B6D4)] : const [Color(0xFF059669), Color(0xFF0891B2)]),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            member.isAdult ? LucideIcons.user : LucideIcons.baby,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0369A1))
                                  : currentTheme.textPrimary,
                            ),
                          ),
                          Text(
                            member.isAdult ? 'Дорослий' : 'Дитина',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: member.isAdult
                                  ? (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1))
                                  : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (allMembers.length < 2)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Увага: у сім\'ї додано лише 1 профіль. Для спліт-тренування додайте дитину або запросіть другого учасника.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.orangeAccent : const Color(0xFFD97706),
                ),
              ),
            ),
        ],
      ),
    );
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
           if (_isSplit) {
             for (final pId in _selectedParticipantIds) {
               if (c.enrolledChildIds.contains(pId)) return true;
             }
           } else {
             if (c.enrolledChildIds.contains(widget.selectedUserId)) return true;
           }
           
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

    final bool canSubmit = !_isLoading &&
        _selectedService != null &&
        _selectedHour != null &&
        (!_isSplit || _selectedParticipantIds.length == 2);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                        if (selected) {
                          setState(() {
                            _selectedService = service;
                            if (_isSplit && _selectedParticipantIds.length < 2) {
                              _initSplitParticipants();
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),

                // Dynamic Split training participants selector
                if (_isSplit) _buildParticipantSelector(isDark, currentTheme),

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
                    gradient: !canSubmit
                        ? null
                        : LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                                : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: !canSubmit
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
                    onPressed: !canSubmit ? null : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !canSubmit
                          ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12)
                          : Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isSplit && _selectedParticipantIds.length != 2
                                ? 'Оберіть 2 учасників (${_selectedParticipantIds.length}/2)'
                                : 'Підтвердити',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.25),
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
