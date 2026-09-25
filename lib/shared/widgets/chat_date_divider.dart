import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatDateDivider extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const ChatDateDivider({
    super.key,
    required this.date,
    required this.isDark,
  });

  /// Check whether two dates belong to the same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Format date for chat divider: "Сьогодні", "Вчора", "24 вересня", "22 листопада 2025 р."
  static String formatChatDate(DateTime date, {String? locale}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Сьогодні';
    if (diff == 1) return 'Вчора';

    final loc = locale ?? 'uk';
    try {
      if (date.year == now.year) {
        return DateFormat('d MMMM', loc).format(date);
      } else {
        return DateFormat('d MMMM yyyy', loc).format(date);
      }
    } catch (_) {
      // Reliable Ukrainian fallback when Intl data is not initialized in raw environments
      const monthsUk = [
        '',
        'січня',
        'лютого',
        'березня',
        'квітня',
        'травня',
        'червня',
        'липня',
        'серпня',
        'вересня',
        'жовтня',
        'листопада',
        'грудня'
      ];
      final m = (date.month >= 1 && date.month <= 12) ? monthsUk[date.month] : '${date.month}';
      if (date.year == now.year) {
        return '${date.day} $m';
      }
      return '${date.day} $m ${date.year} р.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = formatChatDate(date);

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 14, bottom: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F1E32).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                      : const Color(0xFFBAE6FD),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                        .withValues(alpha: isDark ? 0.20 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 13,
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
