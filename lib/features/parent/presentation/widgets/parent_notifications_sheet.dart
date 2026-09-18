import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/controllers/parent_notifications_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';

class ParentNotificationsSheet extends ConsumerWidget {
  const ParentNotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ParentNotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(parentNotificationsControllerProvider);
    final notifications = notifState.notifications;
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDarkMode = themeConfig.isDark;
    final textColor = themeConfig.textPrimary;
    final textSubColor = themeConfig.textSecondary;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF09182B).withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.6 : 0.2),
                blurRadius: 32,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.bell, color: Colors.white, size: 18),
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
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                notifState.hasUnread
                                    ? 'Непрочитаних: ${notifState.unreadCount}'
                                    : 'Усі сповіщення прочитані',
                                style: TextStyle(
                                  color: notifState.hasUnread
                                      ? (isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                                      : textSubColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (notifications.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              ref.read(parentNotificationsControllerProvider.notifier).markAllAsRead();
                            },
                            icon: const Icon(LucideIcons.checkCheck, size: 15),
                            label: const Text('Прочитати все', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: isDarkMode ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: textSubColor, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notifications list
                    Expanded(
                      child: notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: (isDarkMode ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.bellOff,
                                      size: 38,
                                      color: isDarkMode ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: notifications.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                    const SizedBox(height: 12),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          side: BorderSide(
                            color: isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'parent.close'.tr() == 'parent.close' ? 'Закрити' : 'parent.close'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
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
    final iconColor = notif.iconColor ?? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? (notif.isRead ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.09))
            : (notif.isRead ? Colors.white : const Color(0xFFF0F9FF)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: notif.isRead
              ? (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0))
              : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFFBAE6FD)),
          width: notif.isRead ? 1 : 1.3,
        ),
        boxShadow: notif.isRead
            ? null
            : [
                BoxShadow(
                  color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.18 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: isDark ? 0.4 : 0.25),
                width: 1,
              ),
            ),
            child: Icon(notif.icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
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
                          fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (!notif.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E5FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notif.message,
                  style: TextStyle(
                    color: textSubColor,
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTimeAgo(notif.timestamp),
                      style: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                              const SizedBox(width: 2),
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
