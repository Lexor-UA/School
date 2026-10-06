import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class AdminChatEmptyState extends StatelessWidget {
  final bool isMonitoring;
  final String? coachName;
  final String clientName;
  final String displayName;
  final bool isDark;
  final AppThemeConfig currentTheme;
  final ValueChanged<String>? onTemplateSelected;

  const AdminChatEmptyState({
    super.key,
    required this.isMonitoring,
    this.coachName,
    required this.clientName,
    required this.displayName,
    required this.isDark,
    required this.currentTheme,
    this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isMonitoring) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) : const Color(0xFFEDE9FE),
                  border: Border.all(
                    color: isDark ? const Color(0xFFA78BFA).withValues(alpha: 0.40) : const Color(0xFFC4B5FD),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.eye,
                  size: 40,
                  color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Скритний нагляд активний',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Повідомлень між тренером (${coachName ?? 'Тренер'}) та клієнтом ($clientName) поки немає.\nУсі нові повідомлення з\'являтимуться тут автоматично.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.8) : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final quickTemplates = [
      '👋 Вітаємо у школі плавання CitySwim! Чим можемо допомогти?',
      '📅 Нагадуємо про розклад вашого наступного тренування.',
      '🏊 Бажаєте записатись на індивідуальне заняття з тренером?',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE0F2FE),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.12),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.messageSquare,
                size: 40,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Початок діалогу з $displayName',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Напишіть повідомлення або оберіть швидкий шаблон нижче:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ...quickTemplates.map((template) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTemplateSelected?.call(template),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFBAE6FD),
                          width: 1.15,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              template,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF334155),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.arrowUpRight, size: 15, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
