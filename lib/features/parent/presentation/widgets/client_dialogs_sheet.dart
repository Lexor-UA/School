import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';

void showClientDialogsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const ClientDialogsSheet(),
  );
}

class ClientDialogsSheet extends ConsumerStatefulWidget {
  const ClientDialogsSheet({super.key});

  @override
  ConsumerState<ClientDialogsSheet> createState() => _ClientDialogsSheetState();
}

class _ClientDialogsSheetState extends ConsumerState<ClientDialogsSheet> {
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

    // Find coaches from enrolled classes
    final Map<String, (String coachName, String classTitle)> myCoachesMap = {};
    for (final c in schedule) {
      final isEnrolled = c.enrolledChildIds.any((id) => myFamilyIds.contains(id));
      if (isEnrolled &&
          c.coachId.isNotEmpty &&
          c.coachName.isNotEmpty &&
          c.coachName != 'Тренер не призначений' &&
          !c.coachName.toLowerCase().contains('не призначен')) {
        myCoachesMap[c.coachId] = (c.coachName, c.title);
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
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
                          const Color(0xFFF0F9FF).withValues(alpha: 0.95),
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
                            child: Icon(LucideIcons.messageSquare, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Чати та повідомлення',
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                'Зв\'язок з адміністратором та тренерами',
                                style: TextStyle(
                                  color: themeConfig.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            LucideIcons.x,
                            color: isLight ? const Color(0xFF64748B) : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Dialogs stream
                  Expanded(
                    child: clientId.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : StreamBuilder<List<ChatDialog>>(
                            stream: ref.watch(chatRepositoryProvider).streamClientDialogs(clientId),
                            builder: (context, snapshot) {
                              final activeDialogs = snapshot.data ?? [];
                              final existingCoachIds = <String>{};

                              final coachDialogs = activeDialogs.where((d) {
                                if (d.type == 'coach_client' && d.coachId != null) {
                                  existingCoachIds.add(d.coachId!);
                                  return true;
                                }
                                return false;
                              }).toList();

                              // Coaches with whom no dialog exists yet
                              final availableCoaches = myCoachesMap.entries
                                  .where((entry) => !existingCoachIds.contains(entry.key))
                                  .toList();

                              return ListView(
                                controller: scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                                children: [
                                  // 1. Admin Support Dialog Tile
                                  _buildAdminSupportTile(context, isLight, themeConfig),
                                  const SizedBox(height: 16),

                                  // 2. Active Coach Chats
                                  if (coachDialogs.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Text(
                                        'Діалоги з тренерами (${coachDialogs.length})',
                                        style: TextStyle(
                                          color: themeConfig.textSecondary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...coachDialogs.map((dialog) => _buildActiveCoachDialogTile(
                                          context: context,
                                          dialog: dialog,
                                          user: user,
                                          isLight: isLight,
                                          themeConfig: themeConfig,
                                        )),
                                    const SizedBox(height: 14),
                                  ],

                                  // 3. Available Coaches from Enrolled Classes
                                  if (availableCoaches.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Text(
                                        'Тренери ваших занять (${availableCoaches.length})',
                                        style: TextStyle(
                                          color: themeConfig.textSecondary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...availableCoaches.map((entry) => _buildNewCoachContactTile(
                                          context: context,
                                          coachId: entry.key,
                                          coachName: entry.value.$1,
                                          classTitle: entry.value.$2,
                                          user: user,
                                          isLight: isLight,
                                          themeConfig: themeConfig,
                                        )),
                                  ] else if (coachDialogs.isEmpty) ...[
                                    _buildNoCoachesYetState(isLight, themeConfig),
                                  ],
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

  Widget _buildAdminSupportTile(BuildContext context, bool isLight, AppThemeConfig themeConfig) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                .withValues(alpha: isLight ? 0.08 : 0.12),
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
              color: isLight
                  ? const Color(0xFF0284C7).withValues(alpha: 0.30)
                  : const Color(0xFF00E5FF).withValues(alpha: 0.35),
              width: 1.1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ParentChatScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Адміністрація школи',
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Підтримка, абонементи та питання розкладу',
                            style: TextStyle(
                              color: themeConfig.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: isLight ? const Color(0xFF94A3B8) : Colors.white60,
                      size: 18,
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

  Widget _buildActiveCoachDialogTile({
    required BuildContext context,
    required ChatDialog dialog,
    required dynamic user,
    required bool isLight,
    required AppThemeConfig themeConfig,
  }) {
    final hasUnread = dialog.unreadClientCount > 0;
    final displayName = dialog.coachName ?? 'Тренер';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: hasUnread
                ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                : (isLight ? const Color(0xFF0284C7).withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.20)),
            blurRadius: 10,
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
                  : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF00E5FF).withValues(alpha: 0.20)),
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
                      subtitle: 'Тренер басейну',
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
                          const SizedBox(height: 3),
                          Text(
                            dialog.lastMessage.isNotEmpty ? dialog.lastMessage : 'Діалог створено',
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
    required dynamic user,
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
                .withValues(alpha: isLight ? 0.05 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF0B213B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF00E5FF).withValues(alpha: 0.18),
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
                            classTitle,
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

  Widget _buildNoCoachesYetState(bool isLight, AppThemeConfig themeConfig) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF081C33).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF00E5FF).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.userCheck,
            size: 34,
            color: isLight ? const Color(0xFF94A3B8) : Colors.white38,
          ),
          const SizedBox(height: 8),
          Text(
            'Запишіться на заняття',
            style: TextStyle(
              color: themeConfig.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Після запису на тренування тут з\'явиться можливість прямого зв\'язку з вашим тренером',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeConfig.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
