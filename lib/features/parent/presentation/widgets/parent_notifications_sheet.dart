import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/controllers/parent_notifications_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';

class ParentNotificationsSheet extends ConsumerStatefulWidget {
  const ParentNotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      isScrollControlled: true,
      useSafeArea: false,
      builder: (_) => const ParentNotificationsSheet(),
    );
  }

  @override
  ConsumerState<ParentNotificationsSheet> createState() => _ParentNotificationsSheetState();
}

class _ParentNotificationsSheetState extends ConsumerState<ParentNotificationsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(parentNotificationsControllerProvider.notifier).markAllAsRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(parentNotificationsControllerProvider);
    final notifications = notifState.notifications;
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDarkMode = themeConfig.isDark;
    final textColor = themeConfig.textPrimary;
    final textSubColor = themeConfig.textSecondary;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? const [
                      Color(0xFF0F3258), // Luminous rich sapphire oceanic at top
                      Color(0xFF091F38), // Oceanic depth tone
                      Color(0xFF061527), // Deep ocean at bottom
                    ]
                  : const [
                      Color(0xFFFFFFFF),
                      Color(0xFFF1F8FF),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                    : const Color(0xFF0284C7).withValues(alpha: 0.12),
                blurRadius: 36,
                offset: const Offset(0, -6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.80 : 0.25),
                blurRadius: 32,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                children: [
                  // Ambient volumetric radial glow orbs for luminous depth
                  if (isDarkMode) ...[
                    Positioned(
                      top: -20,
                      right: -30,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00E5FF).withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF38BDF8).withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  SafeArea(
                    top: false,
                    bottom: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top drag handle
                          Center(
                            child: Container(
                              width: 44,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : const Color(0xFF94A3B8),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Header row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(LucideIcons.bell, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'parent.notifications'.tr() == 'parent.notifications'
                                          ? 'Сповіщення'
                                          : 'parent.notifications'.tr(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                            : const Color(0xFF10B981).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDarkMode
                                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                              : const Color(0xFF059669).withValues(alpha: 0.25),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.checkCheck,
                                            size: 13,
                                            color: isDarkMode
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFF059669),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Усі сповіщення прочитані',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? const Color(0xFF34D399)
                                                  : const Color(0xFF059669),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Sleek Circular Glass Close Button
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : const Color(0xFFCBD5E1),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.x,
                                      color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Notifications list (wraps content adaptively without empty void)
                          Flexible(
                            child: notifications.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: BoxDecoration(
                                              color: (isDarkMode
                                                      ? const Color(0xFF00E5FF)
                                                      : const Color(0xFF0284C7))
                                                  .withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              LucideIcons.bellOff,
                                              size: 38,
                                              color: isDarkMode
                                                  ? const Color(0xFF00E5FF)
                                                  : const Color(0xFF0284C7),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Сповіщень немає',
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Тут з\'являтимуться нагадування про заняття, абонементи та повідомлення',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: textSubColor, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: notifications.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                    itemBuilder: (ctx, index) {
                                      final notif = notifications[index];
                                      return _buildNotificationCard(
                                        context: context,
                                        ref: ref,
                                        notif: notif,
                                        isDark: isDarkMode,
                                        textColor: textColor,
                                        textSubColor: textSubColor,
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Premium Tactile Close Button
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDarkMode
                                      ? [
                                          const Color(0xFF103358).withValues(alpha: 0.85),
                                          const Color(0xFF0C2440).withValues(alpha: 0.95),
                                        ]
                                      : [
                                          const Color(0xFFF1F5F9),
                                          const Color(0xFFE2E8F0),
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'parent.close'.tr() == 'parent.close' ? 'Закрити' : 'parent.close'.tr(),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
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
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required WidgetRef ref,
    required ParentNotification notif,
    required bool isDark,
    required Color textColor,
    required Color textSubColor,
  }) {
    // Determine category-specific jewel colors for icons
    List<Color> badgeColors;
    Color badgeGlow;

    final lowerTitle = notif.title.toLowerCase();
    final lowerMsg = notif.message.toLowerCase();

    if (notif.actionType == 'calendar' || lowerTitle.contains('тренуван') || lowerTitle.contains('розклад')) {
      badgeColors = const [Color(0xFF00E5FF), Color(0xFF0284C7)];
      badgeGlow = const Color(0xFF00E5FF);
    } else if (lowerTitle.contains('досягнен') || lowerTitle.contains('бейдж') || lowerTitle.contains('нагород') || lowerMsg.contains('акула')) {
      badgeColors = const [Color(0xFFA855F7), Color(0xFF6366F1)];
      badgeGlow = const Color(0xFFA855F7);
    } else if (notif.actionType == 'subscription' || lowerTitle.contains('абонемент') || lowerTitle.contains('оплат')) {
      badgeColors = const [Color(0xFFF59E0B), Color(0xFFD97706)];
      badgeGlow = const Color(0xFFF59E0B);
    } else if (notif.actionType == 'chat' || lowerTitle.contains('чат') || lowerTitle.contains('повідомлен')) {
      badgeColors = const [Color(0xFF10B981), Color(0xFF059669)];
      badgeGlow = const Color(0xFF10B981);
    } else {
      badgeColors = const [Color(0xFF38BDF8), Color(0xFF0284C7)];
      badgeGlow = const Color(0xFF38BDF8);
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? (notif.isRead
                  ? [
                      const Color(0xFF103358).withValues(alpha: 0.72),
                      const Color(0xFF0B213B).withValues(alpha: 0.85),
                    ]
                  : [
                      const Color(0xFF154475).withValues(alpha: 0.85),
                      const Color(0xFF0D2C4E).withValues(alpha: 0.95),
                    ])
              : (notif.isRead
                  ? const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)]
                  : const [Color(0xFFFFFFFF), Color(0xFFF0F9FF)]),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notif.isRead
              ? (isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                  : const Color(0xFFE2E8F0))
              : (isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                  : const Color(0xFFBAE6FD)),
          width: notif.isRead ? 1.1 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeGlow.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vibrant Jewel Gradient Icon Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: badgeColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: badgeGlow.withValues(alpha: isDark ? 0.40 : 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(notif.icon, color: Colors.white, size: 21),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w800,
                          fontSize: 15.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (!notif.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.60),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.message,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : textSubColor,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTimeAgo(notif.timestamp),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (notif.actionType != null)
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          if (notif.actionType == 'chat') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentChatScreen()),
                            );
                          } else if (notif.actionType == 'calendar') {
                            ref.read(parentTabProvider.notifier).setTab(1);
                          } else if (notif.actionType == 'subscription') {
                            ref.read(parentTabProvider.notifier).setTab(2);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                  .withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                notif.actionType == 'chat'
                                    ? 'Перейти в чат'
                                    : (notif.actionType == 'calendar'
                                        ? 'До розкладу'
                                        : (notif.actionType == 'subscription'
                                            ? 'До абонементів'
                                            : 'Детальніше')),
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.arrowRight,
                                size: 13,
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Щойно';
    if (diff.inMinutes < 60) return '${diff.inMinutes} хв тому';
    if (diff.inHours < 24) return '${diff.inHours} год тому';
    if (diff.inDays == 1) return 'Вчора';
    return '${diff.inDays} дн тому';
  }
}
