import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';

/// Преміальний селектор філій для Owner та статичний бейдж для співробітників
class BranchSelectorPill extends ConsumerStatefulWidget {
  const BranchSelectorPill({super.key});

  @override
  ConsumerState<BranchSelectorPill> createState() => _BranchSelectorPillState();
}

class _BranchSelectorPillState extends ConsumerState<BranchSelectorPill> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _showBranchPicker(BuildContext context, TenancyState tenancyState) {
    HapticFeedback.lightImpact();
    final currentTheme = ref.read(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: math.max(MediaQuery.of(ctx).padding.bottom, 16) + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? const Color(0xFF0F1E32).withValues(alpha: 0.96) : Colors.white,
                    isDark ? const Color(0xFF070E1A).withValues(alpha: 0.98) : const Color(0xFFF0F9FF),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0284C7).withValues(alpha: 0.08),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Grab Bar Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFBAE6FD),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Філії CitySwim',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : currentTheme.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? currentTheme.accentPrimary.withValues(alpha: 0.15)
                                        : const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? currentTheme.accentPrimary.withValues(alpha: 0.35)
                                          : const Color(0xFFBAE6FD),
                                    ),
                                  ),
                                  child: Text(
                                    'Owner Mode',
                                    style: TextStyle(
                                      color: isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Керування філією або перегляд всієї мережі',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : currentTheme.textSecondary,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(ctx).pop();
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F9FF),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.x,
                                color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                // Branch 1: Vienna
                _buildBranchOption(
                  context: ctx,
                  branch: Branch.vienna,
                  title: 'CitySwim Vienna',
                  subtitle: 'In der Au 1, Klosterneuburg • EUR (€)',
                  flag: '🇦🇹',
                  isSelected: !tenancyState.isAllLocations && tenancyState.activeBranch?.id == 'vienna',
                  onTap: () {
                    ref.read(tenancyControllerProvider.notifier).switchBranch('vienna');
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 10),

                // Branch 2: Kyiv
                _buildBranchOption(
                  context: ctx,
                  branch: Branch.kyiv,
                  title: 'CitySwim Kyiv',
                  subtitle: 'CitySwim Kyiv Center • UAH (₴)',
                  flag: '🇺🇦',
                  isSelected: !tenancyState.isAllLocations && tenancyState.activeBranch?.id == 'kyiv',
                  onTap: () {
                    ref.read(tenancyControllerProvider.notifier).switchBranch('kyiv');
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 14),

                // Divider
                Divider(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                  height: 1,
                ),
                const SizedBox(height: 14),

                // Option 3: All Locations
                _buildAllLocationsOption(
                  context: ctx,
                  isSelected: tenancyState.isAllLocations,
                  onTap: () {
                    ref.read(tenancyControllerProvider.notifier).switchBranch('all');
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
  }

  Widget _buildBranchOption({
    required BuildContext context,
    required Branch branch,
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final currentTheme = ref.read(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? currentTheme.accentPrimary.withValues(alpha: 0.18) : const Color(0xFFF0F9FF))
                : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isDark ? currentTheme.accentPrimary.withValues(alpha: 0.6) : const Color(0xFF0284C7))
                  : (isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F2640)
                      : (isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF0F9FF)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? (isSelected
                            ? currentTheme.accentPrimary.withValues(alpha: 0.4)
                            : Colors.transparent)
                        : const Color(0xFFBAE6FD),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    flag,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? Colors.transparent : const Color(0xFFBAE6FD),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            branch.currencySymbol,
                            style: TextStyle(
                              color: isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? currentTheme.textSecondary : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: currentTheme.accentGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? currentTheme.accentPrimary.withValues(alpha: 0.4)
                            : const Color(0xFF0284C7).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllLocationsOption({
    required BuildContext context,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final currentTheme = ref.read(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? currentTheme.accentPrimary.withValues(alpha: 0.18) : const Color(0xFFF5F3FF))
                : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFAF5FF)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isDark ? currentTheme.accentPrimary.withValues(alpha: 0.6) : const Color(0xFF8B5CF6))
                  : (isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE9D5FF)),
              width: isSelected ? 1.5 : 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.globe, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Всі філії (All locations)',
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? Colors.transparent : const Color(0xFFDDD6FE),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '₴ / €',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Зведена аналітика та загальні показники мережі',
                      style: TextStyle(
                        color: isDark ? currentTheme.textSecondary : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: currentTheme.accentGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? currentTheme.accentPrimary.withValues(alpha: 0.4)
                            : const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final user = ref.watch(authControllerProvider);
    final tenancyState = ref.watch(tenancyControllerProvider);
    // Підготовка даних активної філії
    final String flag;
    final String label;

    if (tenancyState.isAllLocations) {
      flag = '🌐';
      label = 'Всі філії';
    } else {
      final b = tenancyState.effectiveBranch;
      flag = b.flagEmoji;
      label = b.id == 'vienna' ? 'CitySwim Vienna' : 'CitySwim Kyiv';
    }

    final canSwitchBranch = user?.isOwnerOrSuperAdmin == true;

    // Для адміністратора та тренера показуємо статичний люксовий бейдж
    if (!canSwitchBranch) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.20) : const Color(0xFF0284C7).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: currentTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    // Для Owner показуємо інтерактивну Glassmorphic-капсулу
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _showBranchPicker(context, tenancyState);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? (tenancyState.isAllLocations
                          ? const Color(0xFF6366F1).withValues(alpha: 0.20)
                          : currentTheme.accentPrimary.withValues(alpha: 0.16))
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tenancyState.isAllLocations
                        ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.5 : 0.7)
                        : (isDark
                            ? currentTheme.accentPrimary.withValues(alpha: 0.45)
                            : const Color(0xFFBAE6FD)),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? (tenancyState.isAllLocations
                                  ? const Color(0xFF6366F1)
                                  : currentTheme.accentPrimary)
                              .withValues(alpha: _isHovered ? 0.35 : 0.18)
                          : const Color(0xFF0284C7)
                              .withValues(alpha: _isHovered ? 0.20 : 0.08),
                      blurRadius: _isHovered ? 14 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      flag,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: TextStyle(
                        color: currentTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.chevronDown,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      size: 14,
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
