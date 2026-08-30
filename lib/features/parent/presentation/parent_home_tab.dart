import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'dart:ui';
import 'package:swimming_school_app/features/parent/presentation/pool_map_screen.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/shared/widgets/subscription_front_card.dart';
import 'package:swimming_school_app/shared/widgets/subscription_qr_card.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_progress_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';

class ParentHomeTab extends ConsumerStatefulWidget {
  const ParentHomeTab({super.key});

  @override
  ConsumerState<ParentHomeTab> createState() => _ParentHomeTabState();
}

class _ParentHomeTabState extends ConsumerState<ParentHomeTab> {

  void _showNotifications(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('parent.notifications'.tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildNotificationItem('parent.notif_rescheduled_title'.tr(), '${'parent.today_capitalized'.tr()} · 16:15', LucideIcons.clock, isDark),
                  _buildNotificationItem('parent.notif_badge_title'.tr(), 'parent.notif_badge_desc'.tr(), LucideIcons.award, isDark),
                  _buildNotificationItem('parent.notif_sub_title'.tr(), 'parent.notif_sub_desc'.tr(), LucideIcons.creditCard, isDark),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('parent.close'.tr(), style: TextStyle(color: isDark ? Colors.cyanAccent : AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String desc, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isDark ? Colors.cyanAccent : AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    ref.watch(subscriptionControllerProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = isDark ? Colors.cyanAccent : AppTheme.primaryBlue;

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
      padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
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
                child: Text(
                  '${'parent.hello'.tr()}, ${user?.name ?? 'Гість'} 👋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 16),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.bell, color: textColor, size: 24),
                      onPressed: () => _showNotifications(context, isDark),
                    ),
                  ).animate().fade(delay: 200.ms),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.3,1.3), duration: 1.seconds),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // 2. MAIN CLASS CARDS
          Text('Найближчі заняття', style: TextStyle(color: textSubColor, fontSize: 16, fontWeight: FontWeight.w600)),
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
          
          const SizedBox(height: 32),

          // 5. PROGRESS ROW
          _buildActionRow(
            context: context,
            title: 'parent.progress'.tr(),
            subtitle: '24 тренування · 15 км',
            icon: LucideIcons.trendingUp,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ParentProgressTab()),
              );
            }
          ),
          const SizedBox(height: 24),

          // 6. 3D POOL SIMPLIFIED BUTTON
          _build3DPoolButton(context, isDark, accentColor),

          const SizedBox(height: 140), // Space for bottom nav
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), width: 1.5),
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
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(LucideIcons.waves, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(iconData, size: 10, color: accentColor),
                                    const SizedBox(width: 4),
                                    Text(personName.toUpperCase(), style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text('${DateFormat('HH:mm').format(nextClass.startTime)} - ${DateFormat('HH:mm').format(nextClass.endTime)}', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('🏊 ${nextClass.title}', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(nextClass.lane.isNotEmpty && nextClass.lane != 'Будь-яка' ? 'HappyLand · ${nextClass.lane}' : 'HappyLand', style: TextStyle(color: textSubColor, fontSize: 12)),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Деталі заняття будуть доступні незабаром")));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade100,
                      border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('parent.open_class'.tr(), style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        Icon(LucideIcons.arrowRight, color: accentColor, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms).fadeIn();
  }

  Widget _buildEmptyStateCard(BuildContext context, WidgetRef ref, bool isDark, Color accentColor, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), width: 1.5),
            // Dashed border effect could be cool here but standard border is safer
          ),
          child: Column(
            children: [
              Icon(LucideIcons.calendarX2, color: Colors.white54, size: 32),
              const SizedBox(height: 12),
              Text('У вас немає запланованих занять.\nДодайте заняття в календарі!', textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 14)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref.read(parentTabProvider.notifier).setTab(1), // Go to calendar tab
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Відкрити календар', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildActionRow({required BuildContext context, required String title, required String subtitle, required IconData icon, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: isDark ? Colors.white54 : Colors.black54, size: 18),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _build3DPoolButton(BuildContext context, bool isDark, Color accentColor) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PoolMapScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.box, size: 20, color: accentColor),
              const SizedBox(width: 12),
              Text('parent.pool_map'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
