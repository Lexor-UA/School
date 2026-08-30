import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';

class ParentChatScreen extends ConsumerStatefulWidget {
  const ParentChatScreen({super.key});

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
      clientAvatar: '', // Or appropriate avatar
      senderId: user.id,
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
    final dialogId = user?.id ?? '';
    final messagesAsync = ref.watch(chatMessagesStreamProvider(dialogId));
    final isDark = true; // Match admin UI for consistency, or we could pass it

    return Scaffold(
      backgroundColor: const Color(0xFF030D1B),
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Немає повідомлень.\nНапишіть нам, і ми обов\'язково допоможемо!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 16),
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
                          return _buildMessageBubble(msg.text, isMe, timeString, index);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                    error: (err, stack) => Center(child: Text('Помилка завантаження: $err', style: const TextStyle(color: Colors.white))),
                  ),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
            child: const Icon(LucideIcons.headset, color: Colors.cyanAccent),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Підтримка CitySwim',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                    SizedBox(width: 4),
                    Text('Онлайн', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, int index) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe 
              ? [Colors.cyanAccent.withValues(alpha: 0.8), Colors.blueAccent.withValues(alpha: 0.8)]
              : [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: isMe 
            ? [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 10)]
            : [],
          border: Border.all(
            color: isMe ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.black87 : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.white54,
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

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.paperclip, color: Colors.white54),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Повідомлення...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 10)],
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.black87, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
