import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';

void showCoachDialogsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const CoachDialogsSheet(),
  );
}

class CoachDialogsSheet extends ConsumerStatefulWidget {
  const CoachDialogsSheet({super.key});

  @override
  ConsumerState<CoachDialogsSheet> createState() => _CoachDialogsSheetState();
}

class _CoachDialogsSheetState extends ConsumerState<CoachDialogsSheet> {
  int _selectedFilter = 0; // 0: Усі, 1: Клієнти, 2: Адміністрація

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
    final isLight = !themeConfig.isDark;
    final coach = ref.watch(authControllerProvider);
    final coachId = coach?.id ?? '';

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
                              colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
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
                            child: Icon(LucideIcons.messageCircle, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Повідомлення та чати',
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                'Спілкування з учнями та адміністрацією',
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

                  // Filter Chips Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildFilterPill('Всі чати', 0, isLight),
                        const SizedBox(width: 8),
                        _buildFilterPill('Клієнти', 1, isLight),
                        const SizedBox(width: 8),
                        _buildFilterPill('Адміністрація', 2, isLight),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // List of Dialogs
                  Expanded(
                    child: coachId.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : StreamBuilder<List<ChatDialog>>(
                            stream: ref.watch(chatRepositoryProvider).streamCoachDialogs(coachId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                  ),
                                );
                              }

                              final allDialogs = snapshot.data ?? [];
                              final clientDialogs = allDialogs.where((d) => d.type == 'coach_client').toList();

                              return ListView(
                                controller: scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                                children: [
                                  // 1. Direct Admin Chat Button (if filter is 0 or 2)
                                  if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                                    _buildAdminChatTile(context, isLight, themeConfig),
                                    const SizedBox(height: 12),
                                  ],

                                  // Header for client dialogs
                                  if (_selectedFilter != 2) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Діалоги з клієнтами (${clientDialogs.length})',
                                            style: TextStyle(
                                              color: themeConfig.textSecondary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (clientDialogs.isEmpty)
                                      _buildEmptyClientDialogsState(isLight, themeConfig)
                                    else
                                      ...clientDialogs.map((dialog) => _buildClientDialogCard(
                                            context: context,
                                            dialog: dialog,
                                            coachId: coachId,
                                            coach: coach,
                                            isLight: isLight,
                                            themeConfig: themeConfig,
                                          )),
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

  Widget _buildFilterPill(String label, int index, bool isLight) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isLight ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF0E2746)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF00E5FF).withValues(alpha: 0.22)),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isLight ? const Color(0xFF032238) : Colors.white)
                : (isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminChatTile(BuildContext context, bool isLight, AppThemeConfig themeConfig) {
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
                  MaterialPageRoute(
                    builder: (_) => const ParentChatScreen(
                      title: 'Чат з Адміністратором',
                      subtitle: 'Рецепція басейну • Онлайн',
                    ),
                  ),
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
                            'Швидкий зв\'язок з рецепцією та черговим адміном',
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

  Widget _buildEmptyClientDialogsState(bool isLight, AppThemeConfig themeConfig) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
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
            LucideIcons.messageSquareDashed,
            size: 38,
            color: isLight ? const Color(0xFF94A3B8) : Colors.white38,
          ),
          const SizedBox(height: 10),
          Text(
            'Немає активних діалогів з клієнтами',
            style: TextStyle(
              color: themeConfig.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ви можете написати клієнту безпосередньо зі списку груп або бази плавців',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeConfig.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDialogCard({
    required BuildContext context,
    required ChatDialog dialog,
    required String coachId,
    required dynamic coach,
    required bool isLight,
    required AppThemeConfig themeConfig,
  }) {
    final hasUnread = dialog.unreadCoachCount > 0;

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
                      recipientId: dialog.clientId,
                      recipientName: dialog.clientName,
                      coachId: coachId,
                      coachName: coach?.name,
                      coachAvatar: coach?.avatarUrl,
                      clientId: dialog.clientId,
                      clientName: dialog.clientName,
                      childName: dialog.childName,
                      type: 'coach_client',
                      title: dialog.clientName,
                      subtitle: dialog.childName != null
                          ? 'Батьки (${dialog.childName})'
                          : 'Клієнт • Онлайн',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF),
                            dialog.childName != null ? const Color(0xFF0284C7) : const Color(0xFFA855F7),
                          ],
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
                          dialog.clientName.isNotEmpty ? dialog.clientName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Client details & last message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  dialog.clientName,
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
                          if (dialog.childName != null && dialog.childName!.isNotEmpty) ...[
                            Text(
                              'Батьки учня: ${dialog.childName}',
                              style: TextStyle(
                                color: isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
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

                    // Unread badge
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
                          '${dialog.unreadCoachCount}',
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
}
