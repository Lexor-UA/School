import 'dart:ui';
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
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF061426).withValues(alpha: 0.94)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
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
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Філії CitySwim',
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Керування філією або перегляд всієї мережі',
                          style: TextStyle(
                            color: currentTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: currentTheme.accentPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'Owner Mode',
                        style: TextStyle(
                          color: currentTheme.accentPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
                  subtitle: 'HappyLand Klosterneuburg • EUR (€) • Europe/Vienna',
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
                  subtitle: 'CitySwim Kyiv Center • UAH (₴) • Europe/Kyiv',
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
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
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
                ? currentTheme.accentPrimary.withValues(alpha: isDark ? 0.18 : 0.12)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? currentTheme.accentPrimary.withValues(alpha: 0.6)
                  : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2640) : const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? currentTheme.accentPrimary.withValues(alpha: 0.4)
                        : Colors.transparent,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            branch.currencySymbol,
                            style: TextStyle(
                              color: currentTheme.accentPrimary,
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
                        color: currentTheme.textSecondary,
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
                        color: currentTheme.accentPrimary.withValues(alpha: 0.4),
                        blurRadius: 8,
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
                ? currentTheme.accentPrimary.withValues(alpha: isDark ? 0.18 : 0.12)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? currentTheme.accentPrimary.withValues(alpha: 0.6)
                  : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '₴ / €',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
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
                        color: currentTheme.textSecondary,
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
                        color: currentTheme.accentPrimary.withValues(alpha: 0.4),
                        blurRadius: 8,
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
    final isOwner = user?.role == UserRole.owner;

    // Підготовка даних активної філії
    final String flag;
    final String label;
    final String badge;

    if (tenancyState.isAllLocations) {
      flag = '🌐';
      label = 'Всі філії';
      badge = '₴ / €';
    } else {
      final b = tenancyState.effectiveBranch;
      flag = b.flagEmoji;
      label = b.id == 'vienna' ? 'CitySwim Vienna' : 'CitySwim Kyiv';
      badge = b.currencySymbol;
    }

    // Для звичайних співробітників (Admin, Coach) показуємо статичний бейдж
    if (!isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: currentTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '($badge)',
              style: TextStyle(
                color: currentTheme.accentPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? (tenancyState.isAllLocations
                          ? const Color(0xFF6366F1).withValues(alpha: 0.20)
                          : currentTheme.accentPrimary.withValues(alpha: 0.16))
                      : Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tenancyState.isAllLocations
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                        : currentTheme.accentPrimary.withValues(alpha: isDark ? 0.45 : 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (tenancyState.isAllLocations
                              ? const Color(0xFF6366F1)
                              : currentTheme.accentPrimary)
                          .withValues(alpha: _isHovered ? 0.35 : 0.18),
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
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: tenancyState.isAllLocations
                              ? const Color(0xFF8B5CF6)
                              : currentTheme.accentPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronDown,
                      color: currentTheme.textSecondary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
