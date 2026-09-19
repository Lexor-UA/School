import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_subscription_tab.dart';

class ParentBookingScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const ParentBookingScreen({super.key, required this.date});

  @override
  ConsumerState<ParentBookingScreen> createState() => _ParentBookingScreenState();
}

class _ParentBookingScreenState extends ConsumerState<ParentBookingScreen> {
  GroupClass? selectedClass;
  String? selectedUserId;
  final List<String> _selectedSplitUserIds = [];
  bool isBooking = false;
  bool showSuccess = false;
  String bookedTargetName = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (showSuccess) {
      return _buildSuccessScreen(isDark);
    }

    final bool isSplitEmpty = selectedClass != null && selectedClass!.isSplit && selectedClass!.enrolledChildIds.isEmpty;
    final bool canConfirm = isSplitEmpty
        ? _selectedSplitUserIds.length == 2
        : (selectedClass != null && selectedUserId != null);

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
                        onPressed: () => setState(() {
                          selectedClass = null;
                          selectedUserId = null;
                          _selectedSplitUserIds.clear();
                        }),
                        child: Text('parent.change'.tr(), style: const TextStyle(color: Colors.cyanAccent)),
                      ),
                    ],
                  ),
                  _buildSelectedClassCard(selectedClass!, isDark),
                  const SizedBox(height: 32),
                  
                  // Step 2: Select Child / Participants
                  Text(
                    isSplitEmpty ? 'Оберіть 2-х учасників' : 'parent.for_whom'.tr(),
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildChildSelectionList(isDark),
                ]
              ],
            ),
          ),

          // Step 3: Confirm Button
          if (selectedClass != null && (isSplitEmpty || selectedUserId != null))
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isBooking || !canConfirm) ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canConfirm ? Colors.cyanAccent : (isDark ? Colors.white12 : Colors.black12),
                    foregroundColor: canConfirm ? Colors.black87 : (isDark ? Colors.white38 : Colors.black38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isBooking
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3))
                      : Text(
                          isSplitEmpty
                              ? (_selectedSplitUserIds.length == 2
                                  ? 'Записати на спліт-тренування'
                                  : (_selectedSplitUserIds.isEmpty ? 'Оберіть 2-х учасників' : 'Оберіть 2-го учасника'))
                              : 'parent.confirm_record'.tr(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
        final now = DateTime.now();
        final available = classes.where((c) {
          final isSameDay = c.startTime.year == widget.date.year &&
              c.startTime.month == widget.date.month &&
              c.startTime.day == widget.date.day;
          return isSameDay && c.startTime.isAfter(now);
        }).toList();
        
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
      onTap: isFull ? null : () => setState(() {
        selectedClass = c;
        selectedUserId = null;
        _selectedSplitUserIds.clear();
      }),
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
                      '${'parent.places_left'.tr(args: [(c.maxCapacity - c.enrolledChildIds.length).toString()])} · ${c.lane.isNotEmpty ? c.lane : 'parent.main_pool'.tr()}',
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
    final family = ref.watch(familyStreamProvider).value;
    final isChildClass = selectedClass?.isChildOnly ?? false;
    final isAdultClass = selectedClass?.isAdultOnly ?? false;
    final isSplitEmpty = selectedClass != null && selectedClass!.isSplit && selectedClass!.enrolledChildIds.isEmpty;

    return ref.watch(childrenControllerProvider).when(
      data: (children) {
        final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
        final partnerName = user != null
            ? (family?.getOtherParentName(user.id) ?? (partnerId != null ? family?.parentNames[partnerId] : null) ?? 'Партнер')
            : null;

        final showParent = user != null && !isChildClass;
        final showPartner = family != null && family.isPaired && partnerId != null && partnerName != null && !isChildClass;
        final eligibleChildren = isAdultClass 
            ? <Child>[] 
            : children.where((ch) => selectedClass?.isAgeCompatible(ch.currentAge) ?? true).toList();

        if (!showParent && eligibleChildren.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              selectedClass?.ageRange != null
                  ? 'Вік ваших дітей не відповідає віковій групі цього тренування (${selectedClass!.ageRange!.$1}-${selectedClass!.ageRange!.$2} р.).'
                  : (isChildClass
                      ? 'У вашому профілі ще немає доданих дітей для цього дитячого заняття.'
                      : 'Немає доступних учасників для запису.'),
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSplitEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.16) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFF38BDF8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFF0284C7).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.users, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Спліт-тренування (2 учасники)',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedSplitUserIds.length == 2
                                ? 'Обрано 2 з 2 учасників (готові до запису)'
                                : 'Оберіть 2-х учасників (батько + дитина або двоє дітей): обрано ${_selectedSplitUserIds.length} з 2',
                            style: TextStyle(
                              color: _selectedSplitUserIds.length == 2
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white70 : Colors.black54),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showParent)
              _buildSelectionCard(
                user.id,
                '${user.name} (Я)',
                Colors.blue,
                isDark,
                true,
                isSplitEmpty: isSplitEmpty,
              ),
            if (showPartner)
              _buildSelectionCard(
                partnerId,
                partnerName,
                const Color(0xFFA78BFA),
                isDark,
                true,
                isSplitEmpty: isSplitEmpty,
              ),
            ...eligibleChildren.map((child) {
              final ageStr = child.currentAge != null ? ' (${child.currentAge} р.)' : '';
              return _buildSelectionCard(
                child.id,
                '${child.name}$ageStr',
                Color(int.tryParse(child.colorHex) ?? 0xFF000000),
                isDark,
                false,
                isSplitEmpty: isSplitEmpty,
              );
            }),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Помилка: $e', style: const TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildSelectionCard(
    String id,
    String name,
    Color color,
    bool isDark,
    bool isParent, {
    bool isSplitEmpty = false,
  }) {
    final bool isSelected = isSplitEmpty ? _selectedSplitUserIds.contains(id) : (selectedUserId == id);
    final int splitIndex = isSplitEmpty ? _selectedSplitUserIds.indexOf(id) : -1;
    final String splitBadge = splitIndex == 0 ? '1-й учасник' : (splitIndex == 1 ? '2-й учасник' : '');

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSplitEmpty) {
            if (isSelected) {
              _selectedSplitUserIds.remove(id);
            } else {
              if (_selectedSplitUserIds.length < 2) {
                _selectedSplitUserIds.add(id);
              } else {
                _selectedSplitUserIds[1] = id;
              }
            }
          } else {
            selectedUserId = id;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (isDark ? const Color(0xFF00E5FF) : color) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
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
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(LucideIcons.user, color: color, size: 24)),
              ),
            ],
            const SizedBox(width: 16),
            Expanded(
              child: Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            if (isSplitEmpty && isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (splitIndex == 0 ? Colors.cyanAccent : const Color(0xFF10B981)).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: splitIndex == 0 ? Colors.cyanAccent : const Color(0xFF10B981),
                    width: 1,
                  ),
                ),
                child: Text(
                  splitBadge,
                  style: TextStyle(
                    color: splitIndex == 0 ? (isDark ? Colors.cyanAccent : const Color(0xFF0284C7)) : const Color(0xFF10B981),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isSelected)
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
    if (selectedClass == null) return;
    final isSplitEmpty = selectedClass!.isSplit && selectedClass!.enrolledChildIds.isEmpty;
    if (isSplitEmpty && _selectedSplitUserIds.length < 2) return;
    if (!isSplitEmpty && selectedUserId == null) return;

    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final childrenAsync = ref.read(childrenControllerProvider);
    final children = childrenAsync.value ?? [];

    String getMemberName(String id) {
      if (id == user.id) return user.name;
      final ch = children.where((c) => c.id == id).firstOrNull;
      if (ch != null) return ch.name;
      return id;
    }

    if (selectedClass!.startTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Це тренування вже завершилося.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);

    if (isSplitEmpty) {
      final id1 = _selectedSplitUserIds[0];
      final id2 = _selectedSplitUserIds[1];
      final name1 = getMemberName(id1);
      final name2 = getMemberName(id2);
      final bothNames = '$name1 та $name2';

      // Check split subscription
      final userSubs = subscriptionController.getSubscriptionsForUser(user.id);
      final splitSub = userSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
        (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
      );
      final isAdult1 = id1 == user.id;
      final subscription = splitSub ?? subscriptionController.getSubscriptionForOwner(user.id, name1, isAdult: isAdult1);

      if (subscription == null || subscription.remainingClasses <= 0) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Немає спліт-абонемента', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Для запису необхідно мати оплачений спліт-абонемент на 2 особи. Бажаєте придбати його у розділі "Абонемент"?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати', style: TextStyle(color: Colors.white54))),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ref.read(selectedSubscriptionOwnerProvider.notifier).setSelectedOwner('Всі (Спліт)');
                    ref.read(parentTabProvider.notifier).setTab(2);
                  },
                  child: const Text('Придбати абонемент', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Age compatibility check for both attendees
      for (final uid in [id1, id2]) {
        if (uid != user.id) {
          final child = children.where((c) => c.id == uid).firstOrNull;
          final childAge = child?.currentAge;
          if (childAge != null && !selectedClass!.isAgeCompatible(childAge)) {
            final range = selectedClass!.ageRange;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Вік дитини ${child?.name ?? ''} ($childAge р.) не відповідає віковій групі цього тренування (${range?.$1 ?? 0}-${range?.$2 ?? 0} р.).'),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
      }

      setState(() => isBooking = true);
      final result = await ref.read(scheduleControllerProvider.notifier).bookClass(
        selectedClass!.id,
        id1,
        secondParticipantId: id2,
      );

      if (mounted) {
        if (result.isSuccess) {
          setState(() {
            bookedTargetName = bothNames;
            isBooking = false;
            showSuccess = true;
          });
        } else {
          setState(() => isBooking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    // Standard non-split booking
    String ownerName = getMemberName(selectedUserId!);
    final isAdult = selectedUserId == user.id;
    final subscription = subscriptionController.getSubscriptionForOwner(user.id, ownerName, isAdult: isAdult);

    if (subscription == null || subscription.remainingClasses <= 0) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Немає абонемента', style: TextStyle(color: Colors.white)),
            content: Text(
              isAdult
                  ? 'Для запису необхідно мати оплачений дорослий абонемент для $ownerName. Бажаєте придбати його у розділі "Абонемент"?'
                  : 'Для запису необхідно мати оплачений дитячий абонемент для $ownerName. Бажаєте придбати його у розділі "Абонемент"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати', style: TextStyle(color: Colors.white54))),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ref.read(selectedSubscriptionOwnerProvider.notifier).setSelectedOwner(ownerName);
                  ref.read(parentTabProvider.notifier).setTab(2);
                },
                child: const Text('Придбати абонемент', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (selectedUserId != user.id) {
      final child = children.where((c) => c.id == selectedUserId).firstOrNull;
      final childAge = child?.currentAge;
      if (childAge != null && !selectedClass!.isAgeCompatible(childAge)) {
        final range = selectedClass!.ageRange;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Вік дитини ($childAge р.) не відповідає віковій групі цього тренування (${range?.$1 ?? 0}-${range?.$2 ?? 0} р.).'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => isBooking = true);
    final result = await ref.read(scheduleControllerProvider.notifier).bookClass(selectedClass!.id, selectedUserId!);

    if (mounted) {
      if (result.isSuccess) {
        setState(() {
          bookedTargetName = ownerName;
          isBooking = false;
          showSuccess = true;
        });
      } else {
        setState(() => isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
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
              Builder(builder: (context) {
                final formattedTime = selectedClass != null
                    ? DateFormat('HH:mm').format(selectedClass!.startTime)
                    : '';
                final displayName = bookedTargetName.isNotEmpty ? bookedTargetName : 'Учня';
                return Text(
                  'parent.child_enrolled_time'.tr(args: [displayName, _formatDate(widget.date), formattedTime]),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16, height: 1.5),
                );
              }).animate().fadeIn(delay: 400.ms),
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
