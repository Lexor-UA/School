import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class AdminChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final AppThemeConfig currentTheme;
  final bool isRecovery;
  final bool isUploadingAttachment;
  final VoidCallback onSendMessage;
  final VoidCallback onPickGallery;

  const AdminChatInputBar({
    super.key,
    required this.controller,
    required this.isDark,
    required this.currentTheme,
    required this.isRecovery,
    required this.isUploadingAttachment,
    required this.onSendMessage,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isUploadingAttachment) _buildUploadingBanner(),
        _buildQuickRepliesBar(),
        _buildInputArea(context),
      ],
    );
  }

  Widget _buildUploadingBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF092842) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
          ),
          SizedBox(width: 8),
          Text(
            'Надсилання фотографії...',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildQuickRepliesBar() {
    final recoveryChips = [
      '✅ Доступ відновлено!',
      '🔑 Тимчасовий пароль: 1',
      '📞 Надішліть ваш контактний телефон',
      '📩 Інструкцію надіслано на пошту',
    ];

    final defaultChips = [
      '👋 Вітаємо у CitySwim!',
      '📅 Нагадуємо про розклад',
      '🏊 Чекаємо на тренуванні!',
      '💳 Інформація про оплату',
      '👌 Домовились!',
    ];

    final chips = isRecovery ? recoveryChips : defaultChips;

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                controller.text = chip;
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: chip.length),
                );
              },
              borderRadius: BorderRadius.circular(19),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isRecovery
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.12))
                      : (isRecovery
                          ? const Color(0xFFFEF3C7)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: isDark
                        ? (isRecovery
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.22))
                        : (isRecovery
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFFBAE6FD)),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isRecovery ? const Color(0xFFD97706) : const Color(0xFF0284C7))
                          .withValues(alpha: isDark ? 0.15 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRecovery ? LucideIcons.keyRound : LucideIcons.sparkles,
                      size: 13,
                      color: isRecovery
                          ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                          : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip,
                      style: TextStyle(
                        color: isRecovery
                            ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
                            : (isDark ? Colors.white : const Color(0xFF334155)),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                    width: 1.15,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.image,
                    color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                    size: 20,
                  ),
                  tooltip: 'Обрати фото з медіатеки',
                  onPressed: onPickGallery,
                  constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.28) : const Color(0xFFBAE6FD),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.10 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Повідомлення...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => onSendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                        : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.white, size: 19),
                  onPressed: onSendMessage,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
