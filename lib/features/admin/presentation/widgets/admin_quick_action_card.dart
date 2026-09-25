import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class AdminQuickActionCard extends ConsumerStatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color accentColor;
  final List<Color>? gradientColors;
  final VoidCallback onTap;

  const AdminQuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.accentColor,
    this.gradientColors,
    required this.onTap,
  });

  @override
  ConsumerState<AdminQuickActionCard> createState() => AdminQuickActionCardState();
}

class AdminQuickActionCardState extends ConsumerState<AdminQuickActionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final effectiveGradient = widget.gradientColors ?? [
      widget.accentColor,
      widget.accentColor.withValues(alpha: 0.8),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.lightImpact();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.025 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isHovered ? -2.5 : 0, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(20),
                    splashColor: widget.accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    highlightColor: widget.accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: _isHovered ? 0.30 : 0.22),
                                  widget.accentColor.withValues(alpha: _isHovered ? 0.15 : 0.07),
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFF8FAFC),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isHovered
                              ? (isDark
                                  ? widget.accentColor.withValues(alpha: 0.85)
                                  : widget.accentColor.withValues(alpha: 0.65))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.28)
                                  : const Color(0xFFBAE6FD)),
                          width: _isHovered ? 1.2 : 1.15,
                        ),
                        boxShadow: [
                          if (isDark) ...[
                            // Layer 1: Deep colored base shadow
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isHovered ? 0.30 : 0.18),
                              blurRadius: _isHovered ? 20 : 14,
                              offset: const Offset(0, 6),
                            ),
                            // Layer 2: Medium elevation shadow
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: _isHovered ? 0.32 : 0.14),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ] else ...[
                            // Layer 1: Ambient Jewel Bloom (colored reflection on the water)
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: _isHovered ? 0.28 : 0.12),
                              blurRadius: _isHovered ? 16 : 10,
                              offset: Offset(0, _isHovered ? 4 : 2),
                            ),
                            // Layer 2: Deep grounding shadow
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        ],
                      ),
                      child: Row(
                        children: [
                          // Vibrant Glowing Jewel Emblem — 3D gemstone badge
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: effectiveGradient,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: isDark ? 0.50 : 0.65),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: effectiveGradient.first.withValues(alpha: _isHovered ? 0.65 : (isDark ? 0.42 : 0.36)),
                                  blurRadius: _isHovered ? 16 : (isDark ? 10 : 8),
                                  offset: Offset(0, isDark ? 3 : 2),
                                ),
                                if (!isDark)
                                  BoxShadow(
                                    color: effectiveGradient.last.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    spreadRadius: -1,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Icon(widget.icon, color: Colors.white, size: isDark ? 20 : 22),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Titles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.label,
                                    style: TextStyle(
                                      color: currentTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.sublabel,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFB0D4EC)
                                        : const Color(0xFF64748B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Chevron capsule with accent tint for light theme
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: _isHovered ? 0.16 : 0.08)
                                  : (_isHovered
                                      ? widget.accentColor.withValues(alpha: 0.18)
                                      : const Color(0xFFF0F9FF)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : (_isHovered
                                        ? widget.accentColor.withValues(alpha: 0.45)
                                        : const Color(0xFFBAE6FD)),
                                width: 1.0,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: widget.accentColor.withValues(alpha: 0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.chevronRight,
                                size: 12,
                                color: _isHovered
                                    ? widget.accentColor
                                    : (isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.75)
                                        : widget.accentColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

