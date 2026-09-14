import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_switcher_sheet.dart';

class ThemeHeaderButton extends ConsumerStatefulWidget {
  final double size;
  const ThemeHeaderButton({super.key, this.size = 40});

  @override
  ConsumerState<ThemeHeaderButton> createState() => _ThemeHeaderButtonState();
}

class _ThemeHeaderButtonState extends ConsumerState<ThemeHeaderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.lightImpact();
          ThemeSwitcherSheet.show(context);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : (_isHovered ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = _pulseController.value;
              final glowSpread = _isHovered ? 4.0 : (pulse * 2.0);
              final glowAlpha = _isHovered ? 0.40 : (0.15 + pulse * 0.18);

              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: _isHovered ? 0.22 : 0.12)
                      : Colors.white.withValues(alpha: _isHovered ? 0.95 : 0.85),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.20)
                        : currentTheme.accentPrimary.withValues(alpha: 0.30),
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: currentTheme.accentPrimary.withValues(alpha: glowAlpha),
                            blurRadius: _isHovered ? 14 : (8 + pulse * 6),
                            spreadRadius: glowSpread,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Palette Icon with vibrant theme accent
                      Icon(
                        LucideIcons.palette,
                        color: currentTheme.accentPrimary,
                        size: widget.size * 0.48,
                      ),
                      // Micro jewel shine dot in corner of the button
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: currentTheme.accentSecondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: currentTheme.accentSecondary.withValues(alpha: 0.8),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
