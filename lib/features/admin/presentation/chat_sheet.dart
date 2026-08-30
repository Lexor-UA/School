import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';

class ChatSheet extends ConsumerStatefulWidget {
  const ChatSheet({super.key});

  @override
  ConsumerState<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<ChatSheet> {

  @override
  Widget build(BuildContext context) {
    final dialogsAsync = ref.watch(adminChatDialogsStreamProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF030D1B).withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: dialogsAsync.when(
              data: (dialogs) {
                final unreadCount = dialogs.where((d) => d.unreadAdminCount > 0).length;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(LucideIcons.messageCircle, color: Colors.orangeAccent),
                        const SizedBox(width: 12),
                        const Text('Вхідні повідомлення', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$unreadCount нових', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (dialogs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Text('Немає активних діалогів', style: TextStyle(color: Colors.white54, fontSize: 16)),
                        ),
                      )
                    else
                      ...List.generate(dialogs.length, (index) => _buildChatItem(index, dialogs[index])),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('Помилка: $err', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(int index, ChatDialog dialog) {
    bool isUnread = dialog.unreadAdminCount > 0;
    final timeString = "${dialog.lastMessageTime.hour.toString().padLeft(2, '0')}:${dialog.lastMessageTime.minute.toString().padLeft(2, '0')}";
    
    return GestureDetector(
      onTap: () {
        context.go('/admin/chat?clientName=${Uri.encodeComponent(dialog.clientName)}&clientId=${dialog.clientId}');
        // Close the bottom sheet
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isUnread ? Colors.orangeAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: Text(dialog.clientName.isNotEmpty ? dialog.clientName[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF030D1B), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dialog.clientName,
                        style: TextStyle(
                          color: isUnread ? Colors.white : Colors.white70,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        timeString,
                        style: TextStyle(color: isUnread ? Colors.orangeAccent : Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dialog.lastMessage,
                    style: TextStyle(
                      color: isUnread ? Colors.white70 : Colors.white54,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
  }
}
