import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/create_individual_class_sheet.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:flutter/services.dart';
import 'package:swimming_school_app/features/parent/presentation/edit_child_sheet.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:collection/collection.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/parent_calendar_card.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/parent_class_cards.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swimming_school_app/shared/utils/app_snack_bar.dart';

class ParentCalendarTab extends ConsumerStatefulWidget {
  const ParentCalendarTab({super.key});

  @override
  ConsumerState<ParentCalendarTab> createState() => _ParentCalendarTabState();
}

class _ParentCalendarTabState extends ConsumerState<ParentCalendarTab> {
  String selectedChildId = 'all';
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final currentTheme = ref.watch(appThemeControllerProvider);
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];
    final allClasses = scheduleAsync.value ?? [];

    final familyAsync = ref.watch(familyStreamProvider);
    final family = familyAsync.value;
    final parentIds = (family != null && (family.parentIds.isNotEmpty || family.parentNames.isNotEmpty))
        ? {...family.parentIds, ...family.parentNames.keys}.toList()
        : (user != null ? [user.id] : <String>[]);

    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
    final partnerName = user != null
        ? (family?.getOtherParentName(user.id) ?? (partnerId != null ? family?.parentNames[partnerId] : null) ?? 'Партнер')
        : null;

    final allFamilyIds = [...parentIds, ...children.map((c) => c.id)];
    final targetChildId = selectedChildId;

    final Map<String, GroupClass> uniqueDayClasses = {};
    for (final c in allClasses) {
      if (c.startTime.year == selectedDate.year &&
          c.startTime.month == selectedDate.month &&
          c.startTime.day == selectedDate.day) {
        uniqueDayClasses[c.id] = c;
      }
    }
    final dayClasses = uniqueDayClasses.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final fbUser = FirebaseAuth.instance.currentUser;
    final parentDisplayName = (user?.name != null && user!.name.trim().isNotEmpty && user.name != 'New User')
        ? user.name.trim()
        : (fbUser?.displayName?.trim().isNotEmpty == true
            ? fbUser!.displayName!.trim()
            : 'Мій розклад');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 46,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'parent.calendar'.tr(),
          style: TextStyle(
            color: currentTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: ThemeHeaderButton(size: 38),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 2),

            // 1. Sleek Frosted Glass Child / Parent Selector
            _buildChildSelector(
              currentTheme,
              user?.id ?? fbUser?.uid ?? '',
              parentDisplayName,
              partnerId,
              partnerName,
            ),
            const SizedBox(height: 8),

            // 2. VisionOS Frosted Glass Calendar Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ParentCalendarCard(
                selectedDate: selectedDate,
                onDateSelected: (newDate) => setState(() => selectedDate = newDate),
                allClasses: allClasses,
                currentTheme: currentTheme,
                targetChildId: targetChildId,
                allFamilyIds: allFamilyIds,
              ),
            ),
            const SizedBox(height: 8),

            // 3. On-Screen Live Day Schedule Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDayScheduleSection(
                dayClasses,
                targetChildId,
                currentTheme,
                user,
                children,
                allFamilyIds,
                family,
              ),
            ),
            const SizedBox(height: 120), // Clearance for floating bottom nav bar
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    if (selectedDateOnly.isBefore(todayDate)) {
      AppSnackBar.showWarning(context, 'Неможливо записатися на тренування у минулому');
      return;
    }

    final user = ref.read(authControllerProvider);
    final children = ref.read(childrenControllerProvider).value ?? [];
    final family = ref.read(familyStreamProvider).value;
    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;

    if (selectedChildId == 'all') {
      _showChildPickerForBooking(context, user, children);
      return;
    }

    final isAdult = selectedChildId == user?.id || (partnerId != null && selectedChildId == partnerId);
    String memberName = (user?.name != null && user!.name.trim().isNotEmpty && user.name != 'New User')
        ? user.name.trim()
        : (FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
            ? FirebaseAuth.instance.currentUser!.displayName!.trim()
            : 'Мій розклад');
    if (!isAdult) {
      final ch = children.firstWhereOrNull((c) => c.id == selectedChildId);
      if (ch != null) memberName = ch.name;
    } else if (selectedChildId == partnerId) {
      memberName = family?.getOtherParentName(user?.id ?? '') ?? 'Партнер';
    }

    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final familyParentIds = (family != null && family.parentIds.isNotEmpty) ? family.parentIds : [if (user != null) user.id];
    var sub = subscriptionController.getSubscriptionForOwner(selectedChildId, memberName, isAdult: isAdult, isSplit: false, familyUserIds: familyParentIds);
    sub ??= subscriptionController.getSubscriptionForOwner(user?.id ?? '', memberName, isAdult: isAdult, isSplit: false, familyUserIds: familyParentIds);

    if (sub?.expiryDate != null) {
      final endOfExpiryDay = DateTime(sub!.expiryDate!.year, sub.expiryDate!.month, sub.expiryDate!.day, 23, 59, 59);
      if (selectedDateOnly.isAfter(endOfExpiryDay)) {
        final expiryStr = DateFormat('dd.MM.yyyy').format(sub.expiryDate!);
        final selDateStr = DateFormat('dd.MM.yyyy').format(selectedDate);
        AppSnackBar.showError(
          context,
          'Термін дії абонемента для $memberName закінчується $expiryStr (до обраної дати $selDateStr). Оберіть дату в межах дії абонемента.',
        );
        return;
      }
    }

    _openIndividualClassSheet(selectedChildId, isAdult);
  }

  void _openIndividualClassSheet(String targetId, bool isAdult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateIndividualClassSheet(
        selectedDate: selectedDate,
        selectedUserId: targetId,
        isAdult: isAdult,
      ),
    );
  }

  void _showChildPickerForBooking(
    BuildContext context,
    AppUser? user,
    List<Child> children,
  ) {
    final isDark = ref.read(appThemeControllerProvider).isDark;
    final currentTheme = ref.read(appThemeControllerProvider);

    final family = ref.read(familyStreamProvider).value;
    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
    final partnerName = user != null ? family?.getOtherParentName(user.id) : null;

    final allMembers = [
      if (user != null)
        (id: user.id, name: '${user.name} (Я)', isParent: true, color: currentTheme.accentPrimary),
      if (partnerId != null && partnerName != null)
        (id: partnerId, name: partnerName, isParent: true, color: const Color(0xFFA78BFA)),
      ...children.map((ch) => (
            id: ch.id,
            name: ch.name,
            isParent: false,
            color: Color(int.tryParse(ch.colorHex) ?? 0xFF10B981),
          )),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.45) : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Для кого забронювати тренування?',
                style: TextStyle(
                  color: isDark ? Colors.white : currentTheme.textPrimary,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Оберіть члена сім\'ї для створення індивідуального розкладу',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : currentTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              ...allMembers.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final isAdult = m.isParent;
                      final memberId = m.id;
                      final memberName = m.name;
                      final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                      final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
                      final familyParentIds = (family != null && family.parentIds.isNotEmpty) ? family.parentIds : [if (user != null) user.id];
                      var sub = subscriptionController.getSubscriptionForOwner(memberId, memberName, isAdult: isAdult, isSplit: false, familyUserIds: familyParentIds);
                      sub ??= subscriptionController.getSubscriptionForOwner(user?.id ?? '', memberName, isAdult: isAdult, isSplit: false, familyUserIds: familyParentIds);
                      if (sub?.expiryDate != null) {
                        final endOfExpiryDay = DateTime(sub!.expiryDate!.year, sub.expiryDate!.month, sub.expiryDate!.day, 23, 59, 59);
                        if (selectedDateOnly.isAfter(endOfExpiryDay)) {
                          final expiryStr = DateFormat('dd.MM.yyyy').format(sub.expiryDate!);
                          final selDateStr = DateFormat('dd.MM.yyyy').format(selectedDate);
                          AppSnackBar.showError(
                            context,
                            'Термін дії абонемента для $memberName закінчується $expiryStr (до обраної дати $selDateStr).',
                          );
                          return;
                        }
                      }
                      Navigator.pop(ctx);
                      _openIndividualClassSheet(m.id, m.isParent);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0A243D) : const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : m.color.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: m.color.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: m.color.withValues(alpha: 0.60),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: m.color.withValues(alpha: 0.30),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              m.isParent ? LucideIcons.user : LucideIcons.baby,
                              color: isDark ? Colors.white : m.color,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : currentTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (m.isParent)
                                  Text(
                                    'Батьки / Дорослий',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF94A3B8) : currentTheme.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            color: isDark ? const Color(0xFF00E5FF) : currentTheme.textSecondary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. CHILD SELECTOR BAR
  // ===========================================================================
  Widget _buildChildSelector(
    AppThemeConfig currentTheme,
    String parentId,
    String parentName, [
    String? partnerId,
    String? partnerName,
  ]) {
    final childrenAsync = ref.watch(childrenControllerProvider);

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "✨ Всі" chip for family-wide view
            _buildChildChip(
              id: 'all',
              name: '✨ Всі',
              color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
              isSelected: selectedChildId == 'all',
              currentTheme: currentTheme,
              isParent: false,
              customIcon: LucideIcons.users,
            ),
            _buildChildChip(
              id: parentId,
              name: parentName,
              color: currentTheme.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
              isSelected: selectedChildId == parentId,
              currentTheme: currentTheme,
              isParent: true,
              customIcon: LucideIcons.user,
            ),
            if (partnerId != null && partnerName != null)
              _buildChildChip(
                id: partnerId,
                name: partnerName,
                color: const Color(0xFFA78BFA),
                isSelected: selectedChildId == partnerId,
                currentTheme: currentTheme,
                isParent: true,
                customIcon: LucideIcons.user,
              ),
            ...childrenAsync.when(
              data: (children) => children.map((c) => _buildChildChip(
                id: c.id,
                name: c.currentAge != null ? '${c.name} (${c.currentAge})' : c.name,
                color: Color(int.tryParse(c.colorHex) ?? 0xFF10B981),
                isSelected: selectedChildId == c.id,
                currentTheme: currentTheme,
                isParent: false,
                customIcon: LucideIcons.baby,
                childData: c,
              )).toList(),
              loading: () => [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              ],
              error: (_, _) => const [],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildChip({
    required String id,
    required String name,
    required Color color,
    required bool isSelected,
    required AppThemeConfig currentTheme,
    required bool isParent,
    IconData? customIcon,
    Child? childData,
  }) {
    final isDark = currentTheme.isDark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => selectedChildId = id),
          onLongPress: childData != null
              ? () {
                  HapticFeedback.mediumImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => EditChildSheet(
                      child: childData,
                      isDark: currentTheme.isDark,
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5.5),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: isDark
                          ? [
                              color.withValues(alpha: 0.35),
                              color.withValues(alpha: 0.18),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.95),
                              const Color(0xFFF0F9FF).withValues(alpha: 0.92),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                      ? const Color(0xFF0B2540)
                      : Colors.white.withValues(alpha: 0.80)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (isDark ? const Color(0xFF00E5FF) : color)
                    : (isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                        : const Color(0xFFBAE6FD)),
                width: isSelected ? 1.4 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF00E5FF) : color).withValues(alpha: isDark ? 0.30 : 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? (isDark
                            ? LinearGradient(colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.2)])
                            : const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0284C7)]))
                        : null,
                    color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE0F2FE)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      customIcon ?? (isParent ? LucideIcons.user : LucideIcons.baby),
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF0284C7)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.white70 : currentTheme.textSecondary),
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (childData != null && isSelected) ...[
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => EditChildSheet(
                          child: childData,
                          isDark: currentTheme.isDark,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.20 : 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.pencil,
                        size: 10,
                        color: isDark ? Colors.white70 : color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. VISIONOS FROSTED GLASS CALENDAR CARD
  // ===========================================================================
  // ===========================================================================
  // 3. ON-SCREEN SELECTED DAY SCHEDULE SECTION
  // ===========================================================================
  Widget _buildDayScheduleSection(
    List<GroupClass> dayClasses,
    String targetChildId,
    AppThemeConfig currentTheme,
    AppUser? user,
    List<Child> children,
    List<String> allFamilyIds, [
    Family? family,
  ]) {
    final isDark = currentTheme.isDark;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isPastDay = selectedDateOnly.isBefore(todayDate);

    final List<GroupClass> enrolledClasses;
    final List<GroupClass> availableClasses;
    final List<GroupClass> pastUnenrolledClasses;

    if (targetChildId == 'all') {
      enrolledClasses = dayClasses.where((c) {
        return c.enrolledChildIds.any((id) => allFamilyIds.contains(id));
      }).toList();

      availableClasses = dayClasses.where((c) {
        return !c.enrolledChildIds.any((id) => allFamilyIds.contains(id)) &&
            c.enrolledChildIds.length < c.maxCapacity &&
            c.startTime.isAfter(now);
      }).toList();

      pastUnenrolledClasses = dayClasses.where((c) {
        return !c.enrolledChildIds.any((id) => allFamilyIds.contains(id)) &&
            c.startTime.isBefore(now);
      }).toList();
    } else {
      enrolledClasses = dayClasses.where((c) {
        return c.enrolledChildIds.contains(targetChildId);
      }).toList();

      availableClasses = dayClasses.where((c) {
        return !c.enrolledChildIds.contains(targetChildId) &&
            c.enrolledChildIds.length < c.maxCapacity &&
            c.startTime.isAfter(now);
      }).toList();

      pastUnenrolledClasses = dayClasses.where((c) {
        return !c.enrolledChildIds.contains(targetChildId) &&
            c.startTime.isBefore(now);
      }).toList();
    }

    final dateFormatted = DateFormat('d MMMM', context.locale.languageCode).format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Розклад на $dateFormatted',
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            if (!isPastDay)
              GestureDetector(
                onTap: () => _showBookingSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF0E2E50), Color(0xFF081C32)]
                          : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.35),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.30 : 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, color: isDark ? const Color(0xFF00E5FF) : Colors.white, size: 13),
                      const SizedBox(width: 4.5),
                      const Text(
                        'Записатись',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        if (enrolledClasses.isEmpty && availableClasses.isEmpty && pastUnenrolledClasses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _buildEmptyDayState(currentTheme, isPastDay: isPastDay),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (enrolledClasses.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF10B981).withValues(alpha: 0.40)
                          : const Color(0xFFBAE6FD),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF10B981) : const Color(0xFF0284C7)).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Ваші заплановані заняття (${enrolledClasses.length})',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : currentTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...enrolledClasses.map((c) => ParentEnrolledClassCard(c: c, targetChildId: targetChildId, currentTheme: currentTheme, user: user, children: children, family: family)),
                const SizedBox(height: 12),
              ],
              if (availableClasses.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.40)
                          : const Color(0xFFBAE6FD),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Доступні для запису (${availableClasses.length})',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : currentTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...availableClasses.map((c) => ParentAvailableClassCard(c: c, targetChildId: targetChildId, currentTheme: currentTheme, user: user, children: children, family: family)),
                const SizedBox(height: 12),
              ],
              if (pastUnenrolledClasses.isNotEmpty) ...[
                _buildPastClassesSection(pastUnenrolledClasses, currentTheme),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyDayState(AppThemeConfig currentTheme, {bool isPastDay = false}) {
    final isDark = currentTheme.isDark;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.32) : const Color(0xFFBAE6FD),
              width: 1.3,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isPastDay
                      ? null
                      : (isDark
                          ? const LinearGradient(
                              colors: [Color(0xFF0E3152), Color(0xFF082038)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null),
                  color: isPastDay
                      ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                      : (isDark ? null : currentTheme.accentPrimary.withValues(alpha: 0.12)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPastDay
                        ? (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1))
                        : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.65) : currentTheme.accentPrimary),
                    width: 1.2,
                  ),
                  boxShadow: !isPastDay && isDark
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    isPastDay ? LucideIcons.calendarX2 : LucideIcons.calendarCheck,
                    color: isPastDay
                        ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                        : (isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isPastDay ? 'Занять у цей день не було' : 'parent.no_classes_this_day_calendar'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : currentTheme.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isPastDay
                    ? 'На обрану дату не було заплановано тренувань'
                    : 'Бажаєте провести тренування у цей день?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? const Color(0xFFCBD5E1) : currentTheme.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isPastDay) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showBookingSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF0E2E50), Color(0xFF081C32)]
                            : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.35),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.30 : 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, color: isDark ? const Color(0xFF00E5FF) : Colors.white, size: 15),
                        const SizedBox(width: 6),
                        const Text(
                          'Забронювати тренування',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastClassesSection(List<GroupClass> pastClasses, AppThemeConfig currentTheme) {
    final isDark = currentTheme.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.50)
                : const Color(0xFFF1F5F9).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF475569).withValues(alpha: 0.40)
                  : const Color(0xFFCBD5E1),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Завершені тренування (${pastClasses.length})',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...pastClasses.map((c) => ParentPastClassCard(classItem: c, currentTheme: currentTheme)),
      ],
    );
  }

}