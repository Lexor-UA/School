import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'dart:ui';
import 'package:swimming_school_app/features/parent/presentation/pool_map_screen.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/shared/widgets/subscription_front_card.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_progress_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/parent/controllers/parent_notifications_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/parent_notifications_sheet.dart';

class ParentHomeTab extends ConsumerStatefulWidget {
  const ParentHomeTab({super.key});

  @override
  ConsumerState<ParentHomeTab> createState() => _ParentHomeTabState();
}

class _ParentHomeTabState extends ConsumerState<ParentHomeTab> {



  void _showNotifications(BuildContext context, bool isDark) {
    ParentNotificationsSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    ref.watch(subscriptionControllerProvider);
    final notifState = ref.watch(parentNotificationsControllerProvider);

    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    
    final textColor = themeConfig.textPrimary;
    final textSubColor = themeConfig.textSecondary;
    final accentColor = isDark ? Colors.cyanAccent : const Color(0xFF0284C7);

    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    
    final allEnrolledIds = [
      if (user != null) user.id,
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
                            color: textSubColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('👋', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.name ?? 'Гість',
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
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                                blurRadius: 10,
                                spreadRadius: 1,
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
              child: _buildNextClassCard(context, isDark, accentColor, textColor, textSubColor, c, user, children),
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

          // 4. AQUAPRO PROGRESS CARD
          _buildProgressCard(
            context: context,
            isDark: isDark,
            accentColor: accentColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ParentProgressTab()),
              );
            },
          ),
          const SizedBox(height: 12),

          // 5. 3D POOL MAP CARD
          _build3DPoolCard(context, isDark, accentColor),

          const SizedBox(height: 120), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildNextClassCard(BuildContext context, bool isDark, Color accentColor, Color textColor, Color textSubColor, GroupClass nextClass, AppUser? user, List<Child> children) {
    String enrolledChildId = '';
    try {
      enrolledChildId = nextClass.enrolledChildIds.firstWhere((id) => (user != null && id == user.id) || children.any((ch) => ch.id == id));
    } catch (e) {
      // Ignore
    }
    
    final isParent = user != null && enrolledChildId == user.id;
    
    String personName = 'Unknown';
    if (isParent) {
      personName = user.name;
    } else {
      try {
        personName = children.firstWhere((ch) => ch.id == enrolledChildId).name;
      } catch (e) {
        // Ignore
      }
    }
    
    final iconData = isParent ? LucideIcons.user : LucideIcons.baby;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0E3D64).withValues(alpha: 0.60),
                          const Color(0xFF092842).withValues(alpha: 0.72),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF003B73).withValues(alpha: 0.35)
                        : const Color(0xFF0284C7).withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                                children: [
                                  Container(
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
                                        Text(
                                          personName.toUpperCase(),
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
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
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
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
                                      color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (nextClass.coachName.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Icon(
                                      (nextClass.coachName == 'Тренер не призначений' || nextClass.coachName.toLowerCase().contains('не призначен'))
                                          ? LucideIcons.clock
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
                                        color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Деталі заняття будуть доступні незабаром")),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F9FF).withValues(alpha: 0.85),
                          border: Border(
                            top: BorderSide(
                              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.16) : const Color(0xFFBAE6FD),
                              width: 0.9,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'parent.open_class'.tr(),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            Icon(
                              LucideIcons.arrowRight,
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms).fadeIn();
  }

  Widget _buildEmptyStateCard(BuildContext context, WidgetRef ref, bool isDark, Color accentColor, Color textColor) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0E3D64).withValues(alpha: 0.60),
                          const Color(0xFF092842).withValues(alpha: 0.72),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0xFF003B73).withValues(alpha: 0.35) : const Color(0xFF0284C7).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
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
                      color: textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
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
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildProgressCard({
    required BuildContext context,
    required bool isDark,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final cardBgColors = isDark
        ? [
            const Color(0xFF0E3D64).withValues(alpha: 0.60),
            const Color(0xFF092842).withValues(alpha: 0.72),
          ]
        : [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF0F9FF).withValues(alpha: 0.90),
          ];

    final borderColor = isDark
        ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
        : const Color(0xFFBAE6FD);

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cardBgColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF003B73).withValues(alpha: 0.35)
                            : const Color(0xFF0284C7).withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      if (isDark)
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Glowing Activity Badge
                      Container(
                        width: 44,
                        height: 44,
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
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.activity,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'parent.progress'.tr() == 'parent.progress'
                                  ? 'Мій прогрес'
                                  : 'parent.progress'.tr(),
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'parent.progress_subtitle'.tr() == 'parent.progress_subtitle'
                                  ? 'Особисті досягнення та активність'
                                  : 'parent.progress_subtitle'.tr(),
                              style: TextStyle(
                                color: subColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron Right
                      Icon(
                        LucideIcons.chevronRight,
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.75) : const Color(0xFF0284C7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _build3DPoolCard(BuildContext context, bool isDark, Color accentColor) {
    final cardBgColors = isDark
        ? [
            const Color(0xFF0E3D64).withValues(alpha: 0.60),
            const Color(0xFF092842).withValues(alpha: 0.72),
          ]
        : [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF0F9FF).withValues(alpha: 0.90),
          ];

    final borderColor = isDark
        ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
        : const Color(0xFFBAE6FD);

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PoolMapScreen())),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cardBgColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF003B73).withValues(alpha: 0.35)
                            : const Color(0xFF0284C7).withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      if (isDark)
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Glowing 3D Pool Badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.box,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'parent.pool_map'.tr() == 'parent.pool_map'
                                  ? '3D Карта Басейну'
                                  : 'parent.pool_map'.tr(),
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Інтерактивний план комплексу та доріжок',
                              style: TextStyle(
                                color: subColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron Right
                      Icon(
                        LucideIcons.chevronRight,
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.75) : const Color(0xFF0284C7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuart);
  }
}
