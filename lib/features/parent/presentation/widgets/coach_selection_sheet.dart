import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';

void showCoachSelectionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const CoachSelectionSheet(),
  );
}

class CoachSelectionSheet extends ConsumerStatefulWidget {
  const CoachSelectionSheet({super.key});

  @override
  ConsumerState<CoachSelectionSheet> createState() => _CoachSelectionSheetState();
}

class _CoachSelectionSheetState extends ConsumerState<CoachSelectionSheet> {
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year && now.month == time.month && now.day == time.day) {
      return DateFormat('HH:mm').format(time);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == time.year && yesterday.month == time.month && yesterday.day == time.day) {
      return 'Вчора';
    }
    return DateFormat('dd.MM').format(time);
  }

  String _formatClassDate(DateTime time) {
    return DateFormat('dd.MM \'о\' HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    final isLight = !isDark;
    final user = ref.watch(authControllerProvider);
    final clientId = user?.id ?? '';

    final children = ref.watch(childrenControllerProvider).value ?? [];
    final family = ref.watch(familyStreamProvider).value;
    final schedule = ref.watch(scheduleControllerProvider).value ?? [];

    final myFamilyIds = <String>{
      if (user != null) user.id,
      if (family != null) ...family.parentIds,
      ...children.map((c) => c.id),
    };

    final now = DateTime.now();

    // 1. Strict filter: Only classes that have NOT ended yet (future or ongoing)
    final futureClasses = schedule.where((c) {
      final isFutureOrOngoing = c.endTime.isAfter(now) || c.startTime.isAfter(now);
      if (!isFutureOrOngoing) return false;
      return c.enrolledChildIds.any((id) => myFamilyIds.contains(id));
    }).toList();

    // 2. Extract valid assigned coaches from future classes
    final Map<String, (String coachName, String classTitle, DateTime startTime)> futureCoachesMap = {};
    for (final c in futureClasses) {
      if (c.coachId.isNotEmpty &&
          c.coachName.isNotEmpty &&
          c.coachName != 'Тренер не призначений' &&
          !c.coachName.toLowerCase().contains('не призначен')) {
        if (!futureCoachesMap.containsKey(c.coachId) || c.startTime.isBefore(futureCoachesMap[c.coachId]!.$3)) {
          futureCoachesMap[c.coachId] = (c.coachName, c.title, c.startTime);
        }
      }
    }

    final futureCoachIds = futureCoachesMap.keys.toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.40,
      maxChildSize: 0.90,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLight
                      ? [
                          Colors.white.withValues(alpha: 0.98),
                          const Color(0xFFF0F9FF).withValues(alpha: 0.96),
                        ]
                      : [
                          const Color(0xFF0F2E52).withValues(alpha: 0.96),
                          const Color(0xFF07192F).withValues(alpha: 0.98),
                        ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isLight
                      ? Colors.white
                      : const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                        .withValues(alpha: 0.20),
                    blurRadius: 30,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFCBD5E1)
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.userCheck, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Вибір тренера',
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Чати за майбутніми тренуваннями',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF64748B) : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            LucideIcons.x,
                            color: isLight ? const Color(0xFF64748B) : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Content: Dialogs or Empty State
                  Expanded(
                    child: clientId.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : StreamBuilder<List<ChatDialog>>(
                            stream: ref.watch(chatRepositoryProvider).streamClientDialogs(clientId),
                            builder: (context, snapshot) {
                              final activeDialogs = snapshot.data ?? [];

                              // Rule: If classes with a coach already passed and no future class exists,
                              // that coach's dialogue MUST disappear.
                              // Therefore, we only keep coach dialogs where d.coachId is in futureCoachIds!
                              final validCoachDialogs = activeDialogs.where((d) {
                                return d.type == 'coach_client' &&
                                    d.coachId != null &&
                                    futureCoachIds.contains(d.coachId);
                              }).toList();

                              final existingDialogCoachIds = validCoachDialogs
                                  .map((d) => d.coachId!)
                                  .toSet();

                              // Coaches with future classes who don't have an active dialog yet
                              final coachesWithoutDialog = futureCoachesMap.entries
                                  .where((e) => !existingDialogCoachIds.contains(e.key))
                                  .toList();

                              // Empty state: no future booked classes with assigned coaches
                              if (futureCoachIds.isEmpty) {
                                return _buildNoFutureCoachesState(context, isLight, themeConfig);
                              }

                              return ListView(
                                controller: scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                    child: Text(
                                      'Тренери ваших занять (${futureCoachIds.length})',
                                      style: TextStyle(
                                        color: isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Existing active dialogs with future coaches
                                  ...validCoachDialogs.map((dialog) => _buildActiveCoachDialogTile(
                                        context: context,
                                        dialog: dialog,
                                        user: user,
                                        isLight: isLight,
                                        themeConfig: themeConfig,
                                        futureInfo: futureCoachesMap[dialog.coachId],
                                      )),

                                  // Coaches with future classes who haven't started a chat yet
                                  ...coachesWithoutDialog.map((entry) => _buildNewCoachContactTile(
                                        context: context,
                                        coachId: entry.key,
                                        coachName: entry.value.$1,
                                        classTitle: entry.value.$2,
                                        classTime: entry.value.$3,
                                        user: user,
                                        isLight: isLight,
                                        themeConfig: themeConfig,
                                      )),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveCoachDialogTile({
    required BuildContext context,
    required ChatDialog dialog,
    required AppUser? user,
    required bool isLight,
    required AppThemeConfig themeConfig,
    required (String coachName, String classTitle, DateTime startTime)? futureInfo,
  }) {
    final hasUnread = dialog.unreadClientCount > 0;
    final displayName = dialog.coachName ?? futureInfo?.$1 ?? 'Тренер';
    final classSubtitle = futureInfo != null
        ? '${futureInfo.$2} • ${_formatClassDate(futureInfo.$3)}'
        : (dialog.childName != null ? 'Пловець: ${dialog.childName}' : 'Заплановане заняття');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                .withValues(alpha: isLight ? 0.06 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLight
                  ? [Colors.white, const Color(0xFFF8FAFC)]
                  : [const Color(0xFF0F2E52), const Color(0xFF07192F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUnread
                  ? const Color(0xFF00E5FF)
                  : (isLight ? const Color(0xFFBAE6FD) : const Color(0xFF00E5FF).withValues(alpha: 0.22)),
              width: hasUnread ? 1.5 : 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParentChatScreen(
                      dialogId: dialog.id,
                      recipientId: dialog.coachId ?? '',
                      recipientName: displayName,
                      coachId: dialog.coachId,
                      coachName: displayName,
                      coachAvatar: dialog.coachAvatar,
                      clientId: user?.id,
                      clientName: user?.name,
                      childName: dialog.childName,
                      type: 'coach_client',
                      title: displayName,
                      subtitle: futureInfo != null ? 'Тренер • ${futureInfo.$2}' : 'Тренер басейну',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
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
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    color: themeConfig.textPrimary,
                                    fontWeight: hasUnread ? FontWeight.w900 : FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatTime(dialog.lastMessageTime),
                                style: TextStyle(
                                  color: hasUnread
                                      ? (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                                      : (isLight ? const Color(0xFF94A3B8) : Colors.white54),
                                  fontSize: 11,
                                  fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            classSubtitle,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dialog.lastMessage.isNotEmpty
                                ? dialog.lastMessage
                                : 'Розпочати діалог...',
                            style: TextStyle(
                              color: hasUnread
                                  ? themeConfig.textPrimary
                                  : (isLight ? const Color(0xFF64748B) : Colors.white60),
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          '${dialog.unreadClientCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewCoachContactTile({
    required BuildContext context,
    required String coachId,
    required String coachName,
    required String classTitle,
    required DateTime classTime,
    required AppUser? user,
    required bool isLight,
    required AppThemeConfig themeConfig,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                .withValues(alpha: isLight ? 0.05 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLight
                  ? [Colors.white, const Color(0xFFF8FAFC)]
                  : [const Color(0xFF0F2E52), const Color(0xFF07192F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLight ? const Color(0xFFBAE6FD) : const Color(0xFF00E5FF).withValues(alpha: 0.20),
              width: 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                final dialogId = 'coach_${coachId}_client_${user?.id}';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParentChatScreen(
                      dialogId: dialogId,
                      recipientId: coachId,
                      recipientName: coachName,
                      coachId: coachId,
                      coachName: coachName,
                      clientId: user?.id,
                      clientName: user?.name,
                      type: 'coach_client',
                      title: coachName,
                      subtitle: 'Тренер • $classTitle',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF00E5FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          coachName.isNotEmpty ? coachName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coachName,
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$classTitle • ${_formatClassDate(classTime)}',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: 0.35),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.messageCircle,
                            size: 13,
                            color: isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Написати',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }

  Widget _buildNoFutureCoachesState(BuildContext context, bool isLight, AppThemeConfig themeConfig) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.85)
            : const Color(0xFF0A223D).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight
              ? const Color(0xFFBAE6FD)
              : const Color(0xFF00E5FF).withValues(alpha: 0.22),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                .withValues(alpha: isLight ? 0.06 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight
                    ? [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)]
                    : [
                        const Color(0xFF0E3D64),
                        const Color(0xFF082038),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: isLight ? 0.40 : 0.50),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                LucideIcons.calendarClock,
                size: 24,
                color: isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Немає запланованих занять',
            style: TextStyle(
              color: themeConfig.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Чат із тренером стає доступним після бронювання заняття. Якщо всі ваші заняття з тренером уже відбулися, доступ до листування закривається автоматично.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ref.read(parentTabProvider.notifier).setTab(1); // Open Schedule
            },
            child: Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.calendar, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Перейти до розкладу',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
