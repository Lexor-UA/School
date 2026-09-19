import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/controllers/parent_notifications_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';

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
            clipBehavior: Clip.antiAlias,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20, tileMode: TileMode.decal),
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
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
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
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                                              'Всі прочитані',
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? const Color(0xFF34D399)
                                                    : const Color(0xFF059669),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (notifications.isNotEmpty) ...[
                                Tooltip(
                                  message: 'Очистити сповіщення',
                                  child: InkWell(
                                    onTap: () => _confirmClearAll(context, ref, isDarkMode),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? const Color(0xFFEF4444).withValues(alpha: 0.14)
                                            : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDarkMode
                                              ? const Color(0xFFEF4444).withValues(alpha: 0.40)
                                              : const Color(0xFFFCA5A5),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.trash2,
                                            color: isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Очистити',
                                            style: TextStyle(
                                              color: isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
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
                                      return Dismissible(
                                        key: ValueKey(notif.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withValues(alpha: isDarkMode ? 0.25 : 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFFEF4444).withValues(alpha: isDarkMode ? 0.50 : 0.35),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 22),
                                        ),
                                        onDismissed: (_) {
                                          ref.read(parentNotificationsControllerProvider.notifier).deleteNotification(notif.id);
                                        },
                                        child: _buildNotificationCard(
                                          context: context,
                                          ref: ref,
                                          notif: notif,
                                          isDark: isDarkMode,
                                          textColor: textColor,
                                          textSubColor: textSubColor,
                                        ),
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

    if (notif.actionType == 'family_invite' || lowerTitle.contains('сім')) {
      badgeColors = const [Color(0xFF10B981), Color(0xFF06B6D4)];
      badgeGlow = const Color(0xFF10B981);
    } else if (notif.actionType == 'calendar' || lowerTitle.contains('тренуван') || lowerTitle.contains('розклад')) {
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

    final isFamilyInvite = notif.actionType == 'family_invite';

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

                // If Family Invite, render interactive accept/decline buttons
                if (isFamilyInvite)
                  _buildFamilyInviteActions(context, ref, notif, isDark),

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
                    if (!isFamilyInvite && notif.actionType != null)
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

  Widget _buildFamilyInviteActions(BuildContext context, WidgetRef ref, ParentNotification notif, bool isDark) {
    if (notif.inviteStatus == 'accepted') {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.45 : 0.35),
            width: 0.9,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 14),
            SizedBox(width: 6),
            Text(
              'Запрошення прийнято • Сім\'ю об\'єднано',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (notif.inviteStatus == 'declined') {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.xCircle, color: isDark ? Colors.white54 : Colors.black45, size: 14),
            const SizedBox(width: 6),
            Text(
              'Запрошення відхилено',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // Pending: Action Buttons
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          // Accept Button
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final error = await ref.read(familyControllerProvider).respondToInvite(
                        notif.id,
                        notif.inviteCode ?? '',
                        true,
                      );
                  if (context.mounted) {
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                      );
                    } else {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(LucideIcons.heartHandshake, color: Colors.greenAccent, size: 20),
                              SizedBox(width: 8),
                              Text('Вітаємо! Акаунти успішно об\'єднано в сім\'ю!'),
                            ],
                          ),
                          backgroundColor: Color(0xFF064E3B),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.check, size: 15),
                label: const Text(
                  'Прийняти',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Decline Button
          Expanded(
            child: SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFE11D48),
                  side: BorderSide(
                    color: isDark ? const Color(0xFFFDA4AF).withValues(alpha: 0.5) : const Color(0xFFE11D48).withValues(alpha: 0.4),
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await ref.read(familyControllerProvider).respondToInvite(
                        notif.id,
                        notif.inviteCode ?? '',
                        false,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Запрошення відхилено'),
                        backgroundColor: Color(0xFF1E293B),
                      ),
                    );
                  }
                },
                icon: const Icon(LucideIcons.x, size: 15),
                label: const Text(
                  'Відхилити',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
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

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref, bool isDark) async {
    final themeConfig = ref.read(appThemeControllerProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F2643) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.20 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.45 : 0.30),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: Color(0xFFEF4444),
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Очистити всі сповіщення?',
              style: TextStyle(
                color: themeConfig.textPrimary,
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ви впевнені, що хочете видалити всі сповіщення? Список сповіщень стане порожнім.',
              style: TextStyle(
                color: themeConfig.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Скасувати',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.trash2, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Очистити',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
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
    );

    if (confirm == true) {
      await ref.read(parentNotificationsControllerProvider.notifier).clearAll();
    }
  }
}
