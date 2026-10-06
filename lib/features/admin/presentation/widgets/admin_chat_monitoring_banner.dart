import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class AdminChatMonitoringBanner extends StatelessWidget {
  final bool isDark;
  final AppThemeConfig currentTheme;

  const AdminChatMonitoringBanner({
    super.key,
    required this.isDark,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF1E1035).withValues(alpha: 0.95),
                      const Color(0xFF0F0A1E).withValues(alpha: 0.98),
                    ]
                  : [
                      const Color(0xFFFAF5FF),
                      const Color(0xFFF3E8FF),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFA855F7).withValues(alpha: isDark ? 0.45 : 0.35),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.40),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.eye, color: Colors.white, size: 19),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Скритний нагляд',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFE9D5FF) : const Color(0xFF581C87),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                          ),
                          child: const Text(
                            '100% STEALTH',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Тільки читання • Учасники не знають про нагляд',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFC084FC).withValues(alpha: 0.90) : const Color(0xFF7E22CE),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.35 : 0.40),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.lock,
                      size: 11.5,
                      color: isDark ? const Color(0xFFE9D5FF) : const Color(0xFF6B21A8),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      'Read-only',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFE9D5FF) : const Color(0xFF6B21A8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
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
}
