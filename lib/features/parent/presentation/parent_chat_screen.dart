import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class ParentChatScreen extends ConsumerStatefulWidget {
  final String? title;
  final String? subtitle;
  const ParentChatScreen({super.key, this.title, this.subtitle});

  @override
  ConsumerState<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends ConsumerState<ParentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final repo = ref.read(chatRepositoryProvider);
    repo.sendMessage(
      dialogId: user.id, // Client ID is used as Dialog ID
      clientId: user.id,
      clientName: user.name,
      clientAvatar: user.avatarUrl,
      senderId: user.id,
      clientRole: user.role == UserRole.coach ? 'coach' : 'parent',
      text: text,
    );

    _messageController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider);
      if (user != null) {
        ref.read(chatRepositoryProvider).markMessagesAsRead(user.id, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final theme = ref.watch(appThemeControllerProvider);
    final dialogId = user?.id ?? '';
    final messagesAsync = ref.watch(chatMessagesStreamProvider(dialogId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, theme),
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'Немає повідомлень.\nНапишіть нам, і ми обов\'язково допоможемо!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.isDark ? Colors.white54 : theme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      
                      // Auto-scroll logic if new message arrives
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                           _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24.0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == user?.id;
                          final timeString = "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";
                          return _buildMessageBubble(msg.text, isMe, timeString, index, theme);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                    error: (err, stack) => Center(child: Text('Помилка завантаження: $err', style: TextStyle(color: theme.textPrimary))),
                  ),
                ),
                _buildInputArea(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeConfig theme) {
    final isDark = theme.isDark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0E3D64).withValues(alpha: 0.85),
                      const Color(0xFF092842).withValues(alpha: 0.90),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.94),
                      const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                    : const Color(0xFFBAE6FD),
                width: 1.1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF003B73) : const Color(0xFF0284C7))
                    .withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                        : const Color(0xFFBAE6FD),
                    width: 1.0,
                  ),
                ),
                child: IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: theme.textPrimary, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.headset, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? 'Підтримка CitySwim',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle ?? 'Служба турботи про клієнтів',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.85)
                            : theme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, int index, AppThemeConfig theme) {
    final isDark = theme.isDark;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isMe ? 22 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 22),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMe
                      ? (isDark
                          ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                          : const [Color(0xFF0284C7), Color(0xFF0369A1)])
                      : (isDark
                          ? [
                              const Color(0xFF0E3D64).withValues(alpha: 0.75),
                              const Color(0xFF092842).withValues(alpha: 0.85),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.95),
                              const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                            ]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 22),
                ),
                border: Border.all(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.35)
                      : (isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                          : const Color(0xFFBAE6FD)),
                  width: 1.1,
                ),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                              .withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF003B73) : const Color(0xFF0284C7))
                              .withValues(alpha: isDark ? 0.30 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : theme.textPrimary,
                      fontSize: 15,
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : (isDark ? Colors.white60 : theme.textSecondary),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: (20 * index).ms).slideY(begin: 0.08),
    );
  }

  Widget _buildInputArea(AppThemeConfig theme) {
    final isDark = theme.isDark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0E3D64).withValues(alpha: 0.85),
                      const Color(0xFF092842).withValues(alpha: 0.92),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.94),
                      const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                    : const Color(0xFFBAE6FD),
                width: 1.1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF003B73) : const Color(0xFF0284C7))
                    .withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.paperclip,
                  color: isDark ? const Color(0xFF00E5FF) : theme.accentPrimary,
                ),
                onPressed: () {},
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: theme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Повідомлення...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : theme.textMuted,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                        : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                          .withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.white, size: 19),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
