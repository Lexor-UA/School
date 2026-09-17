import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

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
        onTapUp: (_) async {
          setState(() => _isPressed = false);
          HapticFeedback.mediumImpact();
          // Instant direct toggle between Oceanic Night (dark) and Oceanic Pearl (light)
          final nextMode = isDark ? AppThemeMode.lightAzure : AppThemeMode.darkOcean;
          await ref.read(appThemeControllerProvider.notifier).setTheme(nextMode);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : (_isHovered ? 1.08 : 1.0),
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
                        : currentTheme.accentPrimary.withValues(alpha: 0.35),
                    width: 1.2,
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
                            color: const Color(0xFF0284C7).withValues(alpha: _isHovered ? 0.20 : 0.10),
                            blurRadius: _isHovered ? 12 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: child.key == const ValueKey('moon')
                            ? Tween<double>(begin: -0.20, end: 0.0).animate(animation)
                            : Tween<double>(begin: 0.20, end: 0.0).animate(animation),
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isDark ? LucideIcons.moon : LucideIcons.sun,
                      key: ValueKey(isDark ? 'moon' : 'sun'),
                      color: isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                      size: widget.size * 0.50,
                    ),
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
