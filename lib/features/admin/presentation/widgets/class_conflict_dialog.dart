import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/schedule/models/class_conflict.dart';

/// Модальне вікно попередження про конфлікти у розкладі (зайнята доріжка, тренер або час).
class ClassConflictDialog extends StatelessWidget {
  final ClassConflict conflict;
  final bool isDark;
  final String? extraInfo;

  const ClassConflictDialog({
    super.key,
    required this.conflict,
    required this.isDark,
    this.extraInfo,
  });

  static Future<void> show(
    BuildContext context, {
    required ClassConflict conflict,
    required bool isDark,
    String? extraInfo,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ClassConflictDialog(
        conflict: conflict,
        isDark: isDark,
        extraInfo: extraInfo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.amberAccent.withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.2,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: isDark ? 0.2 : 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.triangleAlert, color: Colors.amberAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              conflict.type == ClassConflictType.laneConflict
                  ? 'Конфлікт доріжки'
                  : (conflict.type == ClassConflictType.coachConflict
                      ? 'Конфлікт тренера'
                      : 'Конфлікт у розкладі'),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conflict.message,
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          if (extraInfo != null) ...[
            const SizedBox(height: 10),
            Text(
              extraInfo!,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 16, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Будь ласка, оберіть іншу вільну доріжку, змініть час або призначте іншого тренера.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'admin.close'.tr(),
            style: TextStyle(
              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
