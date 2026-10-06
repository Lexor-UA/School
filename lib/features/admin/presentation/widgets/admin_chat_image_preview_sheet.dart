import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class AdminChatImagePreviewSheet extends StatefulWidget {
  final Uint8List bytes;
  final AppThemeConfig theme;
  final Future<void> Function(Uint8List bytes, String caption) onSend;

  const AdminChatImagePreviewSheet({
    super.key,
    required this.bytes,
    required this.theme,
    required this.onSend,
  });

  static Future<void> show({
    required BuildContext context,
    required Uint8List bytes,
    required AppThemeConfig theme,
    required Future<void> Function(Uint8List bytes, String caption) onSend,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AdminChatImagePreviewSheet(
        bytes: bytes,
        theme: theme,
        onSend: onSend,
      ),
    );
  }

  @override
  State<AdminChatImagePreviewSheet> createState() => _AdminChatImagePreviewSheetState();
}

class _AdminChatImagePreviewSheetState extends State<AdminChatImagePreviewSheet> {
  final TextEditingController _captionController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.isDark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF0F2E52).withValues(alpha: 0.96),
                        const Color(0xFF07192F).withValues(alpha: 0.98),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.97),
                        const Color(0xFFF0F9FF).withValues(alpha: 0.95),
                      ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                    : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Попередній перегляд',
                      style: TextStyle(
                        color: widget.theme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: widget.theme.textPrimary, size: 20),
                      onPressed: _isSending ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image.memory(
                      widget.bytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: TextField(
                    controller: _captionController,
                    style: TextStyle(color: widget.theme.textPrimary),
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: 'Додати підпис до фото...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : widget.theme.textMuted,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        onPressed: _isSending ? null : () => Navigator.pop(context),
                        child: Text(
                          'Скасувати',
                          style: TextStyle(
                            color: widget.theme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(LucideIcons.send, color: Colors.white, size: 18),
                          label: Text(
                            _isSending ? 'Надсилання...' : 'Надіслати',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: _isSending
                              ? null
                              : () async {
                                  setState(() => _isSending = true);
                                  final caption = _captionController.text.trim();
                                  await widget.onSend(widget.bytes, caption);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
