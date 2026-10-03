import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ClientBranchSelector extends StatelessWidget {
  final String selectedBranchId;
  final ValueChanged<String> onBranchChanged;
  final bool isDark;

  const ClientBranchSelector({
    super.key,
    required this.selectedBranchId,
    required this.onBranchChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
              : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF003B73).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF0284C7,
                  ).withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    width: 0.9,
                  ),
                ),
                child: const Icon(
                  LucideIcons.building2,
                  size: 16,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Закріплена філія клієнта',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      'Визначає валюту (₴/€), доступні пакети та локації',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.50)
                            : const Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildBranchOption(
                  branchId: 'kyiv',
                  title: 'Київ',
                  flag: '🇺🇦',
                  subtitle: 'Гривня (₴)',
                  isSelected: selectedBranchId == 'kyiv',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBranchOption(
                  branchId: 'vienna',
                  title: 'Відень',
                  flag: '🇦🇹',
                  subtitle: 'Euro (€)',
                  isSelected: selectedBranchId == 'vienna',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchOption({
    required String branchId,
    required String title,
    required String flag,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
  }) {
    final isVienna = branchId == 'vienna';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onBranchChanged(branchId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: isVienna
                      ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                      : [const Color(0xFF00E5FF), const Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isVienna ? const Color(0xFFFCA5A5) : const Color(0xFFBAE6FD))
                : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        (isVienna
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF00E5FF))
                            .withValues(alpha: isDark ? 0.35 : 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.50)
                          : const Color(0xFF64748B)),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
