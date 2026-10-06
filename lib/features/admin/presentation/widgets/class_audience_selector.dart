import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ClassAudience {
  adult,
  child,
  split,
}

/// Віджет вибору цільової аудиторії заняття (Для дорослих / Для дітей / Спліт)
class ClassAudienceSelector extends StatelessWidget {
  final ClassAudience selectedAudience;
  final ValueChanged<ClassAudience> onAudienceSelected;
  final bool isDark;
  final bool isBabyPool;

  const ClassAudienceSelector({
    super.key,
    required this.selectedAudience,
    required this.onAudienceSelected,
    required this.isDark,
    this.isBabyPool = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        audience: ClassAudience.adult,
        label: 'Для дорослих',
        icon: LucideIcons.user,
        disabled: isBabyPool,
      ),
      (
        audience: ClassAudience.child,
        label: 'Для дітей',
        icon: LucideIcons.baby,
        disabled: false,
      ),
      (
        audience: ClassAudience.split,
        label: 'Спліт',
        icon: LucideIcons.users,
        disabled: isBabyPool,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1625) : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selectedAudience == opt.audience;
          final flex = switch (opt.audience) {
            ClassAudience.adult => 13,
            ClassAudience.child => 11,
            ClassAudience.split => 9,
          };
          return Expanded(
            flex: flex,
            child: GestureDetector(
              onTap: opt.disabled
                  ? () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Дитячий басейн призначений лише для дитячих тренувань.'),
                          backgroundColor: Colors.orangeAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  : () {
                      HapticFeedback.selectionClick();
                      onAudienceSelected(opt.audience);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF00E5FF), width: 1.3)
                      : Border.all(color: Colors.transparent, width: 1.3),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: 14,
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : (opt.disabled
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (opt.disabled
                                    ? (isDark ? Colors.white24 : Colors.black26)
                                    : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B))),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
