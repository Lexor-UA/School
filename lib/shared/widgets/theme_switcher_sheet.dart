import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class ThemeSwitcherSheet extends ConsumerWidget {
  const ThemeSwitcherSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSwitcherSheet(),
    );
  }

  String _t(String key, String fallback) {
    try {
      final res = key.tr();
      return (res.isNotEmpty && res != key) ? res : fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final presets = AppThemeConfig.allPresets;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: currentTheme.isDark
              ? const Color(0xFF09182B).withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border.all(
            color: currentTheme.isDark
                ? Colors.white.withValues(alpha: 0.16)
                : currentTheme.accentPrimary.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: currentTheme.isDark ? 0.6 : 0.16),
              blurRadius: 36,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 14, bottom: 10),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: currentTheme.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 18, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentTheme.accentGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: currentTheme.accentPrimary.withValues(alpha: 0.40),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.palette, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('theme_title', 'Вибір теми додатку'),
                            style: TextStyle(
                              color: currentTheme.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _t('theme_subtitle', 'Оберіть темну або світлу океанічну тему'),
                            style: TextStyle(
                              color: currentTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: currentTheme.textSecondary, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: currentTheme.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 1,
                color: currentTheme.dividerColor,
              ),

              // List of 2 themes with live UI mockup cards
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  itemCount: presets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final theme = presets[index];
                    final isSelected = currentTheme.id == theme.id;

                    return _ThemeCard(
                      theme: theme,
                      isSelected: isSelected,
                      currentTheme: currentTheme,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(appThemeControllerProvider.notifier).setTheme(theme.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final AppThemeConfig theme;
  final bool isSelected;
  final AppThemeConfig currentTheme;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.currentTheme,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  String _t(String key, String fallback) {
    try {
      final res = key.tr();
      return (res.isNotEmpty && res != key) ? res : fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isSelected = widget.isSelected;
    final currentTheme = widget.currentTheme;

    IconData themeIcon;
    switch (theme.id) {
      case AppThemeMode.darkOcean:
        themeIcon = LucideIcons.moon;
        break;
      case AppThemeMode.lightAzure:
      default:
        themeIcon = LucideIcons.waves;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? (theme.isDark
                      ? const Color(0xFF10233B)
                      : Colors.white)
                  : (currentTheme.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.70)),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? theme.accentPrimary
                    : (_isHovered
                        ? theme.accentPrimary.withValues(alpha: 0.5)
                        : (currentTheme.isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08))),
                width: isSelected ? 2.2 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.accentPrimary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03),
                        blurRadius: _isHovered ? 10 : 4,
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Live Miniature UI Mockup Box
                Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: theme.bgGradient,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.cardBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accentPrimary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mini app bar in mockup
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: theme.accentPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.textPrimary.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Icon(themeIcon, size: 11, color: theme.accentPrimary),
                        ],
                      ),
                      // Mini card mockup with accent button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.cardBorder, width: 0.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 18,
                              height: 5,
                              decoration: BoxDecoration(
                                color: theme.textSecondary.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: theme.actionCardGradients.first),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Title, Subtitle, Badge, Swatches
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _t(theme.titleKey, theme.title),
                              style: TextStyle(
                                color: currentTheme.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: theme.statusActiveBadgeBg,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: theme.accentPrimary.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _t(theme.badgeKey, theme.badgeText),
                              style: TextStyle(
                                color: theme.statusActiveBadgeText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _t(theme.subKey, theme.subtitle),
                        style: TextStyle(
                          color: currentTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Swatch dots
                      Row(
                        children: theme.previewColors.map((col) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: currentTheme.isDark ? Colors.white24 : Colors.black12,
                                width: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Selection checkmark or radio
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? LinearGradient(colors: theme.accentGradient)
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? theme.accentPrimary
                          : currentTheme.textMuted.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.accentPrimary.withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(LucideIcons.check, color: Colors.white, size: 16),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
