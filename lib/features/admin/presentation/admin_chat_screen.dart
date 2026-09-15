import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  final String clientName;
  final String clientId;
  const AdminChatScreen({super.key, required this.clientName, required this.clientId});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (widget.clientId.isEmpty) return;

    final repo = ref.read(chatRepositoryProvider);
    repo.sendMessage(
      dialogId: widget.clientId, // using clientId as dialogId
      clientId: widget.clientId,
      clientName: widget.clientName,
      clientAvatar: '',
      senderId: 'admin',
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
    // Mark messages as read by admin
    if (widget.clientId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatRepositoryProvider).markMessagesAsRead(widget.clientId, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.clientId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark, currentTheme),
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'Немає повідомлень.',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : currentTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                           _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20.0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == 'admin';
                          final timeString = "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";
                          return _buildMessageBubble(msg.text, isMe, timeString, index, isDark, currentTheme);
                        },
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: isDark ? const Color(0xFF38BDF8) : currentTheme.accentPrimary,
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Помилка: $err',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
                _buildInputArea(isDark, currentTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppThemeConfig currentTheme) {
    final userRoles = ref.watch(usersRoleMapProvider).value ?? {};

    String role = 'parent';
    final idLower = widget.clientId.toLowerCase();
    final nameLower = widget.clientName.toLowerCase();
    if (idLower.startsWith('recovery_') || nameLower.contains('відновлення') || nameLower.contains('🔑')) {
      role = 'recovery';
    } else if (userRoles[widget.clientId] == 'coach' ||
               userRoles['name_${widget.clientName}'] == 'coach' ||
               nameLower.contains('антон') ||
               nameLower.contains('тренер')) {
      role = 'coach';
    }

    final isRecovery = role == 'recovery';
    final isCoach = role == 'coach';

    String displayName = widget.clientName;
    if (isRecovery && displayName.startsWith('🔑')) {
      displayName = displayName.replaceFirst('🔑', '').trim();
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: isRecovery
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                    : (isCoach
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : (isDark ? Colors.white.withValues(alpha: 0.25) : currentTheme.cardBorder)),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.20) : currentTheme.cardBorder,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    color: isDark ? Colors.white : currentTheme.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              // Role-specific avatar
              if (isRecovery)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🔑', style: TextStyle(fontSize: 20)),
                  ),
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCoach
                          ? const Color(0xFF10B981).withValues(alpha: 0.8)
                          : (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.8) : currentTheme.accentPrimary),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCoach
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF38BDF8) : currentTheme.accentPrimary))
                            .withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.clientId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() as Map<String, dynamic>?;
                      final avatarUrl = data?['avatarUrl'] as String?;
                      if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(avatarUrl),
                          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        );
                      }

                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isCoach
                                  ? const [Color(0xFF10B981), Color(0xFF0284C7)]
                                  : const [Color(0xFF00D2FF), Color(0xFF0077B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: isDark ? Colors.white : currentTheme.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role Badge
                        if (isRecovery)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🔑 ', style: TextStyle(fontSize: 8.5)),
                                Text(
                                  'ВІДНОВЛЕННЯ',
                                  style: TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isCoach)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🏊 ', style: TextStyle(fontSize: 8.5)),
                                Text(
                                  'ТРЕНЕР',
                                  style: TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👤 ', style: TextStyle(fontSize: 8.5)),
                                Text(
                                  'КЛІЄНТ',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isRecovery ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isRecovery ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isRecovery
                              ? 'Запит на відновлення доступу'
                              : (isCoach ? 'В мережі • Тренер школи' : 'В мережі'),
                          style: TextStyle(
                            color: isRecovery
                                ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                                : (isDark ? Colors.white70 : currentTheme.textSecondary),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.phone,
                  color: isDark ? const Color(0xFF38BDF8) : currentTheme.accentPrimary,
                  size: 20,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    String text,
    bool isMe,
    String time,
    int index,
    bool isDark,
    AppThemeConfig currentTheme,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe 
              ? [const Color(0xFF00E5FF).withValues(alpha: 0.90), const Color(0xFF0077B6).withValues(alpha: 0.90)]
              : (isDark
                  ? [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.12)]
                  : [Colors.white.withValues(alpha: 0.95), const Color(0xFFF1F5F9).withValues(alpha: 0.95)]),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: isMe 
            ? [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 2))]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
          border: Border.all(
            color: isMe
                ? Colors.white.withValues(alpha: 0.6)
                : (isDark ? Colors.white.withValues(alpha: 0.30) : currentTheme.cardBorder),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : (isDark ? Colors.white : currentTheme.textPrimary),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : (isDark ? Colors.white60 : currentTheme.textMuted),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: (20 * index).ms).slideY(begin: 0.1),
    );
  }

  Widget _buildInputArea(bool isDark, AppThemeConfig currentTheme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.22) : currentTheme.cardBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.paperclip,
                  color: isDark ? Colors.white70 : currentTheme.textSecondary,
                ),
                onPressed: () {},
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.28)
                          : currentTheme.cardBorder,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: isDark ? Colors.white : currentTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Повідомлення...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : currentTheme.textMuted,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                      blurRadius: 10,
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
