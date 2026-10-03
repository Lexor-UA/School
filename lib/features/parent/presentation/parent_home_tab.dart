import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/shared/widgets/subscription_front_card.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/parent/controllers/parent_notifications_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/parent_notifications_sheet.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/coach_selection_sheet.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';

class ParentHomeTab extends ConsumerStatefulWidget {
  const ParentHomeTab({super.key});

  @override
  ConsumerState<ParentHomeTab> createState() => _ParentHomeTabState();
}

class _ParentHomeTabState extends ConsumerState<ParentHomeTab> {
  void _openCoachChat(BuildContext context) {
    showCoachSelectionSheet(context);
  }

  void _showNotifications(BuildContext context, bool isDark) {
    ParentNotificationsSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final notifState = ref.watch(parentNotificationsControllerProvider);

    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    
    final textColor = themeConfig.textPrimary;
    final textSubColor = themeConfig.textSecondary;
    final accentColor = isDark ? Colors.cyanAccent : const Color(0xFF0284C7);

    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final family = ref.watch(familyStreamProvider).value;
    
    final allEnrolledIds = [
      if (user != null) user.id,
      if (family != null) ...family.parentIds,
      ...children.map((c) => c.id),
    ];

    List<GroupClass> todaysUpcomingClasses = [];
    if (scheduleAsync.value != null) {
      final now = DateTime.now();
      var upcomingClasses = scheduleAsync.value!.where((c) {
        if (c.startTime.isBefore(now)) return false;
        return c.enrolledChildIds.any((id) => allEnrolledIds.contains(id));
      }).toList();
      
      upcomingClasses.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      if (upcomingClasses.isNotEmpty) {
        final nearestDate = upcomingClasses.first.startTime;
        todaysUpcomingClasses = upcomingClasses.where((c) {
          return c.startTime.year == nearestDate.year &&
                 c.startTime.month == nearestDate.month &&
                 c.startTime.day == nearestDate.day;
        }).toList();
      }
    }

    bool hasClassesToday = todaysUpcomingClasses.isNotEmpty;

    // Fetch active subscription for the main user (or default)
    final allSubs = user != null ? ref.watch(subscriptionControllerProvider.notifier).getSubscriptionsForUser(user.id) : <Subscription>[];
    final activeSubs = allSubs.where((s) => s.isActive).toList();
    
    // Sort so primary user's sub comes first if available, else first active
    activeSubs.sort((a, b) {
      if (user != null) {
        if (a.ownerName == user.name && b.ownerName != user.name) return -1;
        if (a.ownerName != user.name && b.ownerName == user.name) return 1;
      }
      return 0;
    });
    
    final currentSub = activeSubs.isNotEmpty ? activeSubs.first : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 115.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: accentColor.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: -5),
                  ],
                ),
                child: const AvatarPicker(
                  heroTag: 'hero_avatar_Клієнтам_home',
                  radius: 28,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'parent.hello'.tr(),
                          style: TextStyle(
                            color: isDark ? textSubColor : const Color(0xFF0369A1),
                            fontSize: 13.5,
                            fontWeight: isDark ? FontWeight.w600 : FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('👋', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (user?.name != null && user!.name.trim().isNotEmpty && user.name != 'New User')
                          ? user.name
                          : (FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
                              ? FirebaseAuth.instance.currentUser!.displayName!.trim()
                              : 'Гість'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 8),
              const ThemeHeaderButton(size: 38),
              const SizedBox(width: 8),
              Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [Color(0xFF0E2E50), Color(0xFF081C32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isDark ? null : Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.50) : const Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.40),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(LucideIcons.bell, color: isDark ? const Color(0xFF00E5FF) : textColor, size: 19),
                      onPressed: () => _showNotifications(context, isDark),
                    ),
                  ).animate().fade(delay: 200.ms),
                  if (notifState.hasUnread)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.7),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.3,1.3), duration: 1.seconds),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // 2. MAIN CLASS CARDS
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                            : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.calendarCheck, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Найближчі заняття',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          if (hasClassesToday)
            ...todaysUpcomingClasses.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildNextClassCard(context, isDark, accentColor, textColor, textSubColor, c, user, children, family),
            ))
          else
            _buildEmptyStateCard(context, ref, isDark, accentColor, textColor),
          
          const SizedBox(height: 24),

          // 3. SUBSCRIPTION CARD
          SubscriptionFrontCard(
            currentSub: currentSub,
            onTap: () {
              ref.read(parentTabProvider.notifier).setTab(2); // Navigate to Subscription tab
            },
          ),

            const SizedBox(height: 20),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Subscription balance & status pill
                    if (currentSub != null) ...[
                      GestureDetector(
                        onTap: () {
                          ref.read(parentTabProvider.notifier).setTab(2);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? const [Color(0xFF0A2239), Color(0xFF051525)]
                                  : const [Colors.white, Color(0xFFF8FAFC)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.28)
                                  : const Color(0xFFBAE6FD),
                              width: 1.0,
                            ),
                            boxShadow: [
                              if (isDark) ...[
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ] else ...[
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  blurRadius: 1,
                                  offset: const Offset(0, -1),
                                ),
                              ],
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (currentSub.serviceName != null && currentSub.serviceName!.isNotEmpty)
                                          ? currentSub.serviceName!
                                          : 'Абонемент CitySwim',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentSub.remainingClasses > 0
                                          ? 'Залишок: ${currentSub.remainingClasses} ${currentSub.remainingClasses == 1 ? "заняття" : "занять"} • Діє до ${currentSub.expiryDate != null ? DateFormat("dd.MM.yyyy").format(currentSub.expiryDate!) : "безстроково"}'
                                          : 'Активний абонемент',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // B. Quick Action Buttons Row
                    Row(
                      children: [
                        // Quick Action 1: Chat with Coach
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _openCoachChat(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? const [Color(0xFF0A2239), Color(0xFF051525)]
                                      : const [Colors.white, Color(0xFFF8FAFC)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.28)
                                      : const Color(0xFFBAE6FD),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  if (isDark) ...[
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ] else ...[
                                    BoxShadow(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.80),
                                      blurRadius: 1,
                                      offset: const Offset(0, -1),
                                    ),
                                  ],
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(LucideIcons.userCheck, color: Colors.white, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Чат',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'З тренером',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                            fontWeight: isDark ? FontWeight.w500 : FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Quick Action 2: Chat with school / support
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (user != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ParentChatScreen(
                                      dialogId: 'support_admin_${user.id}',
                                      recipientId: 'admin_support',
                                      recipientName: 'Адміністрація CitySwim',
                                      clientId: user.id,
                                      clientName: user.name,
                                      type: 'client_admin',
                                      title: 'Підтримка CitySwim',
                                      subtitle: 'Адміністрація школи',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? const [Color(0xFF0A2239), Color(0xFF051525)]
                                      : const [Colors.white, Color(0xFFF8FAFC)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.28)
                                      : const Color(0xFFBAE6FD),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  if (isDark) ...[
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ] else ...[
                                    BoxShadow(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.80),
                                      blurRadius: 1,
                                      offset: const Offset(0, -1),
                                    ),
                                  ],
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                                            : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(LucideIcons.messageCircle, color: Colors.white, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Чат',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Зі школою',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                            fontWeight: isDark ? FontWeight.w500 : FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 120), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildNextClassCard(
    BuildContext context,
    bool isDark,
    Color accentColor,
    Color textColor,
    Color textSubColor,
    GroupClass nextClass,
    AppUser? user,
    List<Child> children, [
    Family? family,
  ]) {
    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
    final partnerName = user != null
        ? (family?.getOtherParentName(user.id) ?? (partnerId != null ? family?.parentNames[partnerId] : null) ?? 'Партнер')
        : null;

    final enrolledMembers = nextClass.enrolledChildIds.map((id) {
      if (user != null && id == user.id) {
        return (id: user.id, name: user.name, isParent: true);
      }
      final child = children.where((ch) => ch.id == id).firstOrNull;
      if (child != null) {
        return (id: child.id, name: child.name, isParent: false);
      }
      if (family != null && family.parentNames.containsKey(id) && family.parentNames[id]!.trim().isNotEmpty) {
        return (id: id, name: family.parentNames[id]!.trim(), isParent: true);
      }
      if (partnerId != null && id == partnerId && partnerName != null && partnerName.isNotEmpty) {
        return (id: id, name: partnerName, isParent: true);
      }
      if (family != null && family.parentIds.contains(id)) {
        final name = family.getOtherParentName(user?.id ?? '') ?? partnerName ?? 'Партнер';
        return (id: id, name: name, isParent: true);
      }
      if (partnerName != null && partnerName.isNotEmpty && partnerName != 'Партнер') {
        return (id: id, name: partnerName, isParent: true);
      }
      return (id: id, name: 'Партнер', isParent: true);
    }).toList();

    final bool isMultiple = enrolledMembers.length > 1;
    final String personName = enrolledMembers.isNotEmpty
        ? enrolledMembers.map((m) => m.name).join(' + ')
        : 'Запис';
    final bool isParent = enrolledMembers.any((m) => m.isParent);
    final iconData = isMultiple ? LucideIcons.users : (isParent ? LucideIcons.user : LucideIcons.baby);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF0A2239),
                          Color(0xFF051525),
                        ]
                      : const [
                          Colors.white,
                          Color(0xFFF0F9FF),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.32) : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                        : const Color(0xFF0284C7).withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  else
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.90),
                      blurRadius: 2,
                      offset: const Offset(0, -1),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.waves, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                                            : const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                                              : const Color(0xFFBAE6FD),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(iconData, size: 11, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              personName.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.clock,
                                        size: 13,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${DateFormat('HH:mm').format(nextClass.startTime)} – ${DateFormat('HH:mm').format(nextClass.endTime)}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                nextClass.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.mapPin,
                                        size: 12,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        nextClass.lane.isNotEmpty && nextClass.lane != 'Будь-яка'
                                            ? 'HappyLand · ${nextClass.lane}'
                                            : 'HappyLand',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (nextClass.coachName.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          (nextClass.coachName == 'Тренер не призначений' || nextClass.coachName.toLowerCase().contains('не призначен'))
                                              ? LucideIcons.user
                                              : LucideIcons.userCheck,
                                          size: 12,
                                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (nextClass.coachName == 'Тренер не призначений' || nextClass.coachName.toLowerCase().contains('не призначен'))
                                              ? 'Тренер призначається'
                                              : nextClass.coachName,
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.05) : const Color(0xFFF0F9FF).withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : const Color(0xFFBAE6FD),
                          width: 0.9,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (nextClass.coachName.isNotEmpty &&
                            nextClass.coachName != 'Тренер не призначений' &&
                            !nextClass.coachName.toLowerCase().contains('не призначен') &&
                            nextClass.coachId.isNotEmpty &&
                            user != null)
                          GestureDetector(
                            onTap: () {
                              final childEnrolled = enrolledMembers.firstWhereOrNull((m) => !m.isParent);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParentChatScreen(
                                    dialogId: 'coach_${nextClass.coachId}_client_${user.id}',
                                    recipientId: nextClass.coachId,
                                    recipientName: nextClass.coachName,
                                    coachId: nextClass.coachId,
                                    coachName: nextClass.coachName,
                                    clientId: user.id,
                                    clientName: user.name,
                                    childName: childEnrolled?.name,
                                    type: 'coach_client',
                                    title: nextClass.coachName,
                                    subtitle: 'Тренер • ${nextClass.title}',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.messageCircle, color: Colors.white, size: 13),
                                  SizedBox(width: 5),
                                  Text(
                                    'Написати тренеру',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                    : const Color(0xFFBAE6FD),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.calendarCheck2,
                                  size: 11,
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 4.5),
                                Text(
                                  'Заплановано',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        GestureDetector(
                          onTap: () {
                            ref.read(parentTabProvider.notifier).setTab(1); // Schedule
                          },
                          child: Container(
                            padding: isDark
                                ? EdgeInsets.zero
                                : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: isDark
                                ? null
                                : BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFBAE6FD),
                                      width: 0.9,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'В розклад',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.arrowRight,
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms).fadeIn();
  }

  Widget _buildEmptyStateCard(BuildContext context, WidgetRef ref, bool isDark, Color accentColor, Color textColor) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF0A2239),
                          Color(0xFF051525),
                        ]
                      : const [
                          Colors.white,
                          Color(0xFFF0F9FF),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.32) : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.12) : const Color(0xFF0284C7).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  else
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.90),
                      blurRadius: 2,
                      offset: const Offset(0, -1),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.calendarX2, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), size: 34),
                  const SizedBox(height: 12),
                  Text(
                    'У вас немає запланованих занять.\nДодайте заняття в календарі!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF1F5F9) : textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => ref.read(parentTabProvider.notifier).setTab(1),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                              : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.45),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Відкрити календар',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ).animate().fadeIn();
  }
}
