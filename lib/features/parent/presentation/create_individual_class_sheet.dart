import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_subscription_tab.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/tenancy/utils/branch_timezone_helper.dart';
import 'package:intl/intl.dart';

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
  bool get _isGroup =>
      _selectedService?.toLowerCase().contains('групов') == true ||
      _selectedService?.toLowerCase().contains('аквааеробіка') == true;
  bool get _isAdultGroup => _isGroup && widget.isAdult;
  bool get _isChildGroup => _isGroup && !widget.isAdult;

  @override
  void initState() {
    super.initState();
    if (widget.isAdult) {
      _availableServices = [
        'Індивідуальні тренування для дорослих',
      ];
    } else {
      _availableServices = [
        'Індивідуальні тренування для дітей',
      ];
    }
    _selectedService = _availableServices.first;
    _initParticipantsForService(_selectedService!);
  }

  void _initParticipantsForService(String service) {
    _selectedParticipantIds.clear();
    _selectedParticipantIds.add(widget.selectedUserId);

    final isSplit = service.contains('Спліт');
    if (isSplit) {
      final user = ref.read(authControllerProvider);
      final children = ref.read(childrenControllerProvider).value ?? [];

      if (widget.selectedUserId == user?.id) {
        // Current profile is parent -> auto-add first eligible child (age >= 6) if available
        final eligibleChildren = children.where((c) => (c.currentAge ?? 0) >= 6).toList();
        if (eligibleChildren.isNotEmpty) {
          _selectedParticipantIds.add(eligibleChildren.first.id);
        }
      } else {
        // Current profile is child -> auto-add parent
        if (user != null) {
          _selectedParticipantIds.add(user.id);
        }
      }
    }
  }

  void _toggleParticipant(String id) {
    setState(() {
      if (_selectedParticipantIds.contains(id)) {
        if (_isGroup && _selectedParticipantIds.length == 1) {
          // Keep at least 1 participant selected in a group class
          return;
        }
        _selectedParticipantIds.remove(id);
      } else {
        if (_isGroup) {
          _selectedParticipantIds.add(id);
        } else if (_isSplit) {
          if (_selectedParticipantIds.length < 2) {
            _selectedParticipantIds.add(id);
          } else {
            // Smooth swap for split: replace member who isn't widget.selectedUserId,
            // or replace the first member if both differ.
            final toReplace = _selectedParticipantIds.firstWhere(
              (item) => item != widget.selectedUserId,
              orElse: () => _selectedParticipantIds.first,
            );
            _selectedParticipantIds.remove(toReplace);
            _selectedParticipantIds.add(id);
          }
        } else {
          _selectedParticipantIds.clear();
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

    if (_selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, оберіть хоча б одного учасника'),
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
    final family = ref.read(familyStreamProvider).value;
    final children = ref.read(childrenControllerProvider).value ?? [];
    final familyParentIds = (family != null && family.parentIds.isNotEmpty) ? family.parentIds : [user.id];

    if (_isSplit) {
      final userSubs = subscriptionController.getSubscriptionsForUser(user.id);
      Subscription? activeSub = userSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
        (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
      );

      // Check if partner holds a split subscription
      if (activeSub == null && family != null) {
        for (final pId in family.parentIds) {
          if (pId != user.id) {
            final partnerSubs = subscriptionController.getSubscriptionsForUser(pId);
            activeSub = partnerSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
              (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
            );
            if (activeSub != null) break;
          }
        }
      }

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
              title: Text('Немає спліт-абонемента', style: TextStyle(color: currentTheme.textPrimary, fontWeight: FontWeight.bold)),
              content: Text(
                'Для запису на спліт-тренування необхідно мати активний спліт-абонемент (на 2 особи). Бажаєте придбати його у розділі "Абонемент"?',
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

      final startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _selectedHour!,
      );

      if (activeSub.expiryDate != null) {
        final endOfExpiryDay = DateTime(
          activeSub.expiryDate!.year,
          activeSub.expiryDate!.month,
          activeSub.expiryDate!.day,
          23, 59, 59,
        );
        if (startTime.isAfter(endOfExpiryDay)) {
          final expiryStr = DateFormat('dd.MM.yyyy').format(activeSub.expiryDate!);
          final dateStr = DateFormat('dd.MM.yyyy').format(startTime);
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
                title: Text('Термін дії абонемента закінчився', style: TextStyle(color: currentTheme.textPrimary, fontWeight: FontWeight.bold)),
                content: Text(
                  'Термін дії вашого спліт-абонемента закінчується $expiryStr, що передує даті тренування ($dateStr). Будь ласка, оберіть дату в межах дії абонемента або оформіть новий абонемент.',
                  style: TextStyle(color: isDark ? Colors.white70 : currentTheme.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Зрозуміло', style: TextStyle(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
    } else {
      // Validate subscription for EACH selected participant
      final Map<String, int> usedSubClasses = {};

      for (final pId in _selectedParticipantIds) {
        final pIsAdult = pId == user.id || familyParentIds.contains(pId);
        String ownerName = user.name;
        if (!pIsAdult) {
          final ch = children.firstWhereOrNull((c) => c.id == pId);
          if (ch != null) ownerName = ch.name;
        } else if (pId != user.id && family != null && family.parentNames.containsKey(pId)) {
          ownerName = family.parentNames[pId]!;
        }

        // Check age compatibility for child service
        if (!pIsAdult) {
          final ch = children.firstWhereOrNull((c) => c.id == pId);
          final age = ch?.currentAge;
          if (age != null && !isServiceAgeCompatible(_selectedService!, age)) {
            final range = parseAgeRange(_selectedService!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Вік дитини $ownerName ($age р.) не відповідає віковій групі (${range!.$1}-${range.$2} р.)'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
        }

        Subscription? subscription = subscriptionController.getSubscriptionForOwner(
          pId,
          ownerName,
          isAdult: pIsAdult,
          isSplit: false,
          familyUserIds: familyParentIds,
        );
        subscription ??= subscriptionController.getSubscriptionForOwner(
          user.id,
          ownerName,
          isAdult: pIsAdult,
          isSplit: false,
          familyUserIds: familyParentIds,
        );

        final alreadyUsed = subscription != null ? (usedSubClasses[subscription.id] ?? 0) : 0;

        if (subscription == null ||
            (subscription.remainingClasses - alreadyUsed) <= 0 ||
            subscription.isSplitSubscription) {
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
                  pIsAdult
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

        if (!pIsAdult) {
          final ch = children.firstWhereOrNull((c) => c.id == pId);
          final age = ch?.currentAge;
          if (age != null && !subscription.isAgeCompatible(age)) {
            final subRange = subscription.ageRange;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Абонемент для $ownerName призначений для віку ${subRange?.$1}-${subRange?.$2} р. (вік дитини: $age р.).'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
        }

        final startTime = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          _selectedHour!,
        );

        if (subscription.expiryDate != null) {
          final endOfExpiryDay = DateTime(
            subscription.expiryDate!.year,
            subscription.expiryDate!.month,
            subscription.expiryDate!.day,
            23, 59, 59,
          );
          if (startTime.isAfter(endOfExpiryDay)) {
            final expiryStr = DateFormat('dd.MM.yyyy').format(subscription.expiryDate!);
            final dateStr = DateFormat('dd.MM.yyyy').format(startTime);
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
                  title: Text('Термін дії абонемента закінчився', style: TextStyle(color: currentTheme.textPrimary, fontWeight: FontWeight.bold)),
                  content: Text(
                    'Термін дії абонемента для $ownerName закінчується $expiryStr, що передує даті тренування ($dateStr). Будь ласка, оберіть дату в межах дії абонемента або оформіть новий абонемент.',
                    style: TextStyle(color: isDark ? Colors.white70 : currentTheme.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Зрозуміло', style: TextStyle(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))),
                    ),
                  ],
                ),
              );
            }
            return;
          }
        }

        usedSubClasses[subscription.id] = alreadyUsed + 1;
      }
    }

    setState(() => _isLoading = true);

    final activeBranch = ref.read(effectiveBranchProvider);
    final branchNow = BranchTimezoneHelper.toBranchLocalTime(DateTime.now(), activeBranch.id);

    final startTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedHour!,
    );

    if (startTime.isBefore(branchNow)) {
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

    final int capacity = _isGroup ? 10 : (_isSplit ? 2 : 1);
    final String category = _isGroup
        ? (_selectedService!.toLowerCase().contains('аквааеробіка') ? 'Аквааеробіка' : 'Групове')
        : (_isSplit ? 'Спліт' : 'Індивідуальне');

    final enrolledIds = _isSplit || _isGroup
        ? _selectedParticipantIds.toList()
        : [widget.selectedUserId];

    try {
      final success = await ref.read(scheduleControllerProvider.notifier).createClass(
        title: _selectedService!,
        startTime: startTime,
        endTime: endTime,
        coachId: 'unassigned',
        coachName: 'Тренер не призначений',
        maxCapacity: capacity,
        category: category,
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
                  : (_isGroup
                      ? 'Групове тренування успішно заплановано (учасників: ${enrolledIds.length})!'
                      : 'Заняття успішно заплановано!')),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          final conflict = ref.read(scheduleControllerProvider.notifier).lastConflict;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(conflict?.message ?? 'Не вдалося запланувати: обраний час недоступний або відсутній активний абонемент.'),
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
    final partnerName = user != null
        ? (family?.getOtherParentName(user.id) ?? (partnerId != null ? family?.parentNames[partnerId] : null) ?? 'Партнер')
        : null;

    final List<({String id, String name, bool isAdult})> eligibleMembers = [];

    if (_isSplit) {
      if (user != null) eligibleMembers.add((id: user.id, name: '${user.name} (Я)', isAdult: true));
      if (partnerId != null && partnerName != null) {
        eligibleMembers.add((id: partnerId, name: partnerName, isAdult: true));
      }
      eligibleMembers.addAll(
        children.where((c) => (c.currentAge ?? 0) >= 6).map((c) => (id: c.id, name: c.name, isAdult: false)),
      );
    } else if (_isAdultGroup) {
      if (user != null) eligibleMembers.add((id: user.id, name: '${user.name} (Я)', isAdult: true));
      if (partnerId != null && partnerName != null) {
        eligibleMembers.add((id: partnerId, name: partnerName, isAdult: true));
      }
    } else if (_isChildGroup) {
      final range = _selectedService != null ? parseAgeRange(_selectedService!) : null;
      final matchedChildren = children.where((c) {
        final age = c.currentAge;
        if (age == null) return false;
        if (range != null) {
          return age >= range.$1 && age <= range.$2;
        }
        return age >= 6;
      }).toList();

      eligibleMembers.addAll(
        matchedChildren.map((c) => (id: c.id, name: '${c.name}${c.currentAge != null ? " (${c.currentAge} р.)" : ""}', isAdult: false)),
      );
    }

    if (eligibleMembers.isEmpty) return const SizedBox.shrink();

    final count = _selectedParticipantIds.length;
    final isReady = _isSplit ? (count == 2) : (count >= 1);

    final title = _isSplit
        ? 'Учасники спліт-тренування'
        : (_isAdultGroup ? 'Учасники групового заняття' : 'Діти на групове заняття');

    final badgeText = _isSplit
        ? (isReady ? '2 з 2 обрано' : 'Обрано $count з 2')
        : 'Обрано: $count';

    final subtitle = _isSplit
        ? 'Оберіть двох членів сім\'ї для спільного заняття:'
        : (_isAdultGroup
            ? 'Оберіть дорослих членів сім\'ї, які братимуть участь:'
            : 'Оберіть дітей, які братимуть участь у групі:');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF0B2238),
                  Color(0xFF07192C),
                  Color(0xFF04101D),
                ]
              : const [
                  Color(0xFFF0F9FF),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady
              ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.50) : const Color(0xFF0284C7).withValues(alpha: 0.4))
              : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.28) : const Color(0xFFBAE6FD)),
          width: 1.2,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: isReady
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  LucideIcons.users,
                  size: 15,
                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : currentTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.15)
                      : (isDark ? Colors.orangeAccent.withValues(alpha: 0.20) : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isReady
                        ? const Color(0xFF10B981).withValues(alpha: 0.6)
                        : (isDark ? Colors.orangeAccent.withValues(alpha: 0.6) : const Color(0xFFF59E0B)),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReady ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 12.5,
                      color: isReady
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.orangeAccent : const Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
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
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : currentTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: eligibleMembers.map((member) {
              final isSelected = _selectedParticipantIds.contains(member.id);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _toggleParticipant(member.id);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: isDark
                                  ? const [Color(0xFF0E2E50), Color(0xFF081C32)]
                                  : const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? const Color(0xFF0B2540) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.85) : const Color(0xFF0284C7))
                            : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : const Color(0xFFCBD5E1)),
                        width: isSelected ? 1.4 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.30 : 0.18),
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
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.40) : Colors.transparent,
                              width: 1.0,
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
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? Colors.white : const Color(0xFF0369A1))
                                    : (isDark ? const Color(0xFFE2E8F0) : currentTheme.textPrimary),
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
                          duration: const Duration(milliseconds: 180),
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
                                  : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFF94A3B8)),
                              width: 1.5,
                            ),
                            boxShadow: isSelected && isDark
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 13, color: isDark ? const Color(0xFF081C32) : Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_isSplit && eligibleMembers.length < 2)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1C0A) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.50) : const Color(0xFFF59E0B),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.triangleAlert, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Увага: для спліт-тренування додайте дитину або запросіть другого учасника.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
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
      final cStart = c.branchStartTime;
      return cStart.year == widget.selectedDate.year &&
             cStart.month == widget.selectedDate.month &&
             cStart.day == widget.selectedDate.day;
    }).toList() ?? [];

    final occupiedHours = <int>{};
    for (final hour in _allHours) {
      final classesAtHour = classesOnDate.where((c) => c.branchStartTime.hour == hour).toList();
      if (classesAtHour.isEmpty) continue;

      // 1. Participant conflict: Are any of the currently selected participants already busy at this hour?
      final isParticipantBusy = classesAtHour.any((c) =>
          c.enrolledChildIds.any((id) => _selectedParticipantIds.contains(id)));
      if (isParticipantBusy) {
        occupiedHours.add(hour);
        continue;
      }

      // 2. Whole pool booked: If any class occupies the entire pool ('Весь басейн')
      final isWholePoolBooked = classesAtHour.any((c) {
        final l = c.lane.trim().toLowerCase();
        return l.contains('весь') || l.contains('всі');
      });
      if (isWholePoolBooked) {
        occupiedHours.add(hour);
        continue;
      }

      // 3. Pool capacity: Maximum 4 simultaneous classes in the 4-lane pool
      if (classesAtHour.length >= 4) {
        occupiedHours.add(hour);
        continue;
      }
    }

    final subscriptionController = ref.watch(subscriptionControllerProvider.notifier);
    final user = ref.watch(authControllerProvider);
    final family = ref.watch(familyStreamProvider).value;
    final familyParentIds = (family != null && family.parentIds.isNotEmpty) ? family.parentIds : [if (user != null) user.id];

    DateTime? earliestExpiryForSelected;
    if (user != null) {
      if (_isSplit) {
        final userSubs = subscriptionController.getSubscriptionsForUser(user.id);
        var activeSub = userSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
          (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
        );
        if (activeSub == null && family != null) {
          for (final pId in family.parentIds) {
            if (pId != user.id) {
              final partnerSubs = subscriptionController.getSubscriptionsForUser(pId);
              activeSub = partnerSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
                (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
              );
              if (activeSub != null) break;
            }
          }
        }
        earliestExpiryForSelected = activeSub?.expiryDate;
      } else {
        for (final pId in _selectedParticipantIds) {
          final pIsAdult = pId == user.id || familyParentIds.contains(pId);
          String ownerName = user.name;
          if (!pIsAdult) {
            final children = ref.watch(childrenControllerProvider).value ?? [];
            final ch = children.firstWhereOrNull((c) => c.id == pId);
            if (ch != null) ownerName = ch.name;
          } else if (pId != user.id && family != null && family.parentNames.containsKey(pId)) {
            ownerName = family.parentNames[pId]!;
          }

          var sub = subscriptionController.getSubscriptionForOwner(pId, ownerName, isAdult: pIsAdult, isSplit: false, familyUserIds: familyParentIds);
          sub ??= subscriptionController.getSubscriptionForOwner(user.id, ownerName, isAdult: pIsAdult, isSplit: false, familyUserIds: familyParentIds);
          if (sub?.expiryDate != null) {
            final expiry = sub!.expiryDate!;
            if (earliestExpiryForSelected == null || expiry.isBefore(earliestExpiryForSelected)) {
              earliestExpiryForSelected = expiry;
            }
          }
        }
      }
    }

    final endOfSelectedDate = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, 23, 59, 59);
    final bool isDateAfterSubscriptionExpiry = earliestExpiryForSelected != null &&
        endOfSelectedDate.isAfter(DateTime(earliestExpiryForSelected.year, earliestExpiryForSelected.month, earliestExpiryForSelected.day, 23, 59, 59));

    final bool canSubmit = !_isLoading &&
        !isDateAfterSubscriptionExpiry &&
        _selectedService != null &&
        _selectedHour != null &&
        !occupiedHours.contains(_selectedHour) &&
        (_isSplit ? _selectedParticipantIds.length == 2 : _selectedParticipantIds.isNotEmpty);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF0B2238),
                  Color(0xFF07192C),
                  Color(0xFF04101D),
                ]
              : const [
                  Colors.white,
                  Color(0xFFF0F9FF),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : currentTheme.cardBorder,
          width: 1.3,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Interactive Drag Handle Bar (Pull down or tap to dismiss)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! > 5) {
                  Navigator.of(context).pop();
                }
              },
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.50)
                          : Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            // Pinned Header: Title
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Запланувати заняття',
                  style: TextStyle(
                    color: isDark ? Colors.white : currentTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

              // Scrollable Body with Clamping physics so downward scroll at top dismisses
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 2,
                    bottom: math.max(MediaQuery.of(context).padding.bottom, 18.0) + 14.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                if (isDateAfterSubscriptionExpiry) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: isDark ? 0.45 : 0.50),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.triangleAlert, size: 18, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Термін дії абонемента закінчується ${DateFormat('dd.MM.yyyy').format(earliestExpiryForSelected)}. Запис на обрану дату (${DateFormat('dd.MM.yyyy').format(widget.selectedDate)}) неможливий.',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFFECACA) : const Color(0xFFB91C1C),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!widget.isAdult)
                  Builder(
                    builder: (context) {
                      final children = ref.watch(childrenControllerProvider).value ?? [];
                      final currentChild = children.firstWhereOrNull((c) => c.id == widget.selectedUserId);
                      if (currentChild == null) return const SizedBox.shrink();
                      final age = currentChild.currentAge;
                      final isUnder6 = age != null && age <= 5;
                      final ageGroup = isUnder6
                          ? 'Тільки індивідуальні заняття (до 6 р.)'
                          : ((age != null && age >= 9) ? 'Старша група (9-15 р.)' : 'Молодша група (6-8 р.)');
                      return Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0A243D) : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFF0284C7).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.20),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isUnder6 ? LucideIcons.sparkles : LucideIcons.baby, size: 15, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                            const SizedBox(width: 8),
                            Text(
                              '${currentChild.name}${age != null ? " ($age р.)" : ""} • $ageGroup',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 10),
                
                Text(
                  'Оберіть послугу',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : currentTheme.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableServices.map((service) {
                    final isSelected = _selectedService == service;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedService = service;
                            _initParticipantsForService(service);
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: isDark
                                        ? const [Color(0xFF0E2E50), Color(0xFF081C32)]
                                        : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : (isDark ? const Color(0xFF0B2540) : Colors.white.withValues(alpha: 0.90)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.85)
                                      : Colors.white.withValues(alpha: 0.85))
                                  : (isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                                      : const Color(0xFFBAE6FD)),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.22),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(
                                  LucideIcons.check,
                                  size: 15,
                                  color: isDark ? const Color(0xFF00E5FF) : Colors.white,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                service,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF00E5FF) : Colors.white)
                                      : (isDark ? const Color(0xFFE2E8F0) : currentTheme.textPrimary),
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13.5,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 10),

                // Dynamic Split or Group training participants selector
                if (_isSplit || _isGroup) _buildParticipantSelector(isDark, currentTheme),

                Text(
                  'Оберіть час',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : currentTheme.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final activeBranch = ref.watch(effectiveBranchProvider);
                    final now = BranchTimezoneHelper.toBranchLocalTime(DateTime.now(), activeBranch.id);
                    final todayDate = DateTime(now.year, now.month, now.day);
                    final selectedDateOnly = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
                    final isPastDay = selectedDateOnly.isBefore(todayDate);
                    final isToday = selectedDateOnly.isAtSameMomentAs(todayDate);

                    return Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: _allHours.map((hour) {
                        final isPastHour = isPastDay || (isToday && hour <= now.hour);
                        final isOccupied = occupiedHours.contains(hour);
                        final isDisabled = isOccupied || isPastHour;
                        final isSelected = _selectedHour == hour;
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isDisabled ? null : () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedHour = hour);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: isDark
                                            ? const [Color(0xFF0E2E50), Color(0xFF081C32)]
                                            : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isOccupied 
                                    ? (isDark ? const Color(0xFF1E1418) : const Color(0xFFFEE2E2)) 
                                    : isPastHour
                                        ? (isDark ? const Color(0xFF081522).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.04))
                                        : (isSelected
                                            ? null
                                            : (isDark ? const Color(0xFF0B2540) : Colors.white.withValues(alpha: 0.88))),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.90) : Colors.white.withValues(alpha: 0.90))
                                      : isOccupied
                                          ? (isDark ? Colors.redAccent.withValues(alpha: 0.35) : const Color(0xFFFECACA))
                                          : isPastHour
                                              ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08))
                                              : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : const Color(0xFFBAE6FD)),
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.22),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  color: isOccupied 
                                      ? (isDark ? const Color(0xFFF87171).withValues(alpha: 0.70) : Colors.redAccent.withValues(alpha: 0.6))
                                      : isPastHour
                                          ? (isDark ? Colors.white30 : Colors.black38)
                                          : (isSelected
                                              ? (isDark ? const Color(0xFF00E5FF) : Colors.white)
                                              : (isDark ? const Color(0xFFE2E8F0) : currentTheme.textPrimary)),
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                  decoration: isDisabled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: canSubmit
                        ? LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF0E2E50), Color(0xFF081C32)]
                                : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canSubmit
                        ? null
                        : (isDark ? const Color(0xFF0A2035) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: canSubmit
                          ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.40))
                          : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
                      width: canSubmit ? 1.4 : 1.0,
                    ),
                    boxShadow: canSubmit
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.20),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: !canSubmit ? null : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (canSubmit) ...[
                                Icon(
                                  LucideIcons.calendarCheck,
                                  size: 17,
                                  color: isDark ? const Color(0xFF00E5FF) : Colors.white,
                                ),
                                const SizedBox(width: 8),
                              ],
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _isSplit && _selectedParticipantIds.length != 2
                                      ? 'Оберіть 2 учасників (${_selectedParticipantIds.length}/2)'
                                      : (_isGroup && _selectedParticipantIds.length > 1
                                          ? 'Записати (${_selectedParticipantIds.length} ос.)'
                                          : 'Підтвердити'),
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: canSubmit
                                        ? Colors.white
                                        : (isDark ? const Color(0xFF64748B) : Colors.black38),
                                    letterSpacing: 0.2,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
