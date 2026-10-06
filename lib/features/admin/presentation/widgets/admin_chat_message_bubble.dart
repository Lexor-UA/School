import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/chat/models/chat_message.dart';

class AdminChatMessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final String time;
  final int index;
  final bool isDark;
  final AppThemeConfig currentTheme;
  final bool isMonitoring;
  final String? coachId;
  final String? coachName;
  final String clientName;

  const AdminChatMessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.time,
    required this.index,
    required this.isDark,
    required this.currentTheme,
    this.isMonitoring = false,
    this.coachId,
    this.coachName,
    required this.clientName,
  });

  static void openFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.90),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.5,
                  child: imageUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(imageUrl.split(',').last),
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00E5FF),
                              ),
                            );
                          },
                        ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 18,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.60),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
    final isCoachSender = isMonitoring &&
        (msg.senderRole == 'coach' || (coachId != null && msg.senderId == coachId));

    final Alignment bubbleAlignment = isMonitoring
        ? (isCoachSender ? Alignment.centerLeft : Alignment.centerRight)
        : (isMe ? Alignment.centerRight : Alignment.centerLeft);

    final BorderRadius bubbleBorderRadius = isMonitoring
        ? BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isCoachSender ? 6 : 20),
            bottomRight: Radius.circular(isCoachSender ? 20 : 6),
          )
        : BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isMe ? 22 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 22),
          );

    final List<Color> bubbleGradientColors = isMonitoring
        ? (isCoachSender
            ? (isDark
                ? [Colors.white.withValues(alpha: 0.22), const Color(0xFF064E3B).withValues(alpha: 0.45)]
                : [Colors.white, const Color(0xFFECFDF5)])
            : (isDark
                ? [Colors.white.withValues(alpha: 0.22), const Color(0xFF0C4A6E).withValues(alpha: 0.45)]
                : [Colors.white, const Color(0xFFF0F9FF)]))
        : (isMe
            ? (isDark
                ? [const Color(0xFF00E5FF), const Color(0xFF0077B6)]
                : [const Color(0xFF0284C7), const Color(0xFF0369A1)])
            : (isDark
                ? [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.12)]
                : [Colors.white, const Color(0xFFF8FAFC)]));

    final Color bubbleBorderColor = isMonitoring
        ? (isCoachSender
            ? const Color(0xFF10B981).withValues(alpha: 0.65)
            : const Color(0xFF0284C7).withValues(alpha: 0.65))
        : (isMe
            ? (isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.35))
            : (isDark
                ? Colors.white.withValues(alpha: 0.30)
                : const Color(0xFFBAE6FD)));

    return Align(
      alignment: bubbleAlignment,
      child: GestureDetector(
        onLongPress: () {
          if (msg.text.isNotEmpty) {
            HapticFeedback.lightImpact();
            Clipboard.setData(ClipboardData(text: msg.text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.copy, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Повідомлення скопійовано: "${msg.text}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0284C7),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bubbleGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: bubbleBorderRadius,
            boxShadow: [
              BoxShadow(
                color: isMonitoring
                    ? (isCoachSender
                        ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12)
                        : const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12))
                    : (isMe
                        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                            .withValues(alpha: isDark ? 0.40 : 0.30)
                        : const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.08)),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: bubbleBorderColor,
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: bubbleBorderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hasImage ? 10 : 16,
                  vertical: hasImage ? 10 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMonitoring) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCoachSender ? LucideIcons.award : LucideIcons.user,
                            size: 11,
                            color: isCoachSender
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCoachSender
                                ? 'Тренер: ${coachName ?? msg.senderName ?? 'Тренер'}'
                                : 'Клієнт: $clientName',
                            style: TextStyle(
                              color: isCoachSender
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                  : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (hasImage) ...[
                      GestureDetector(
                        onTap: () => openFullScreenImage(context, msg.imageUrl!),
                        child: Container(
                          margin: EdgeInsets.only(bottom: msg.text.isNotEmpty ? 8 : 4),
                          constraints: const BoxConstraints(maxHeight: 250, minWidth: 180),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              children: [
                                msg.imageUrl!.startsWith('data:image')
                                    ? Image.memory(
                                        base64Decode(msg.imageUrl!.split(',').last),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Image.network(
                                        msg.imageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            height: 180,
                                            color: isDark ? const Color(0xFF071B2C) : const Color(0xFFE0F2FE),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF00E5FF),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(LucideIcons.maximize2, color: Colors.white, size: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (msg.text.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hasImage ? 6 : 0),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isMonitoring
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isMe
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF0F172A))),
                            fontSize: 15,
                            fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hasImage ? 6 : 0),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: isMonitoring
                                ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                                : (isMe
                                    ? Colors.white.withValues(alpha: 0.82)
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B))),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: (20 * index).ms).slideY(begin: 0.08),
    );
  }
}
