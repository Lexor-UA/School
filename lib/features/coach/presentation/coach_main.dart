import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'coach_dashboard.dart';
import 'coach_calendar_tab.dart';

class CoachMain extends ConsumerStatefulWidget {
  const CoachMain({super.key});

  @override
  ConsumerState<CoachMain> createState() => _CoachMainState();
}

class _CoachMainState extends ConsumerState<CoachMain> {
  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(coachTabProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: themeConfig.scaffoldBg,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // 1. Water animation background
            const Positioned.fill(
              child: RepaintBoundary(child: AnimatedWaterBackground()),
            ),

            // 2. Frosted fluid aquatic gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeConfig.bgGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Theme-tailored 3D animated water bubbles
            const Positioned.fill(
              child: RepaintBoundary(child: WaterParticles()),
            ),

            // 3. Main Tab Body
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: selectedTab,
                children: const [
                  CoachScheduleTab(),
                  CoachCalendarTab(),
                  CoachSwimmersTab(),
                  CoachProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. Floating Apple VisionOS Frosted Dock
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 14, right: 14, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: themeConfig.isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              if (themeConfig.isDark)
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: themeConfig.isDark
                      ? const Color(0xFF0B1B30).withValues(alpha: 0.78)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: themeConfig.isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : themeConfig.cardBorder,
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDockItem(
                      index: 0,
                      icon: LucideIcons.calendarClock,
                      label: 'coach.nav_schedule'.tr(),
                      isSelected: selectedTab == 0,
                      themeConfig: themeConfig,
                    ),
                    _buildDockItem(
                      index: 1,
                      icon: LucideIcons.calendarDays,
                      label: 'coach.nav_calendar'.tr(),
                      isSelected: selectedTab == 1,
                      themeConfig: themeConfig,
                    ),
                    _buildDockItem(
                      index: 2,
                      icon: LucideIcons.users,
                      label: 'Групи',
                      isSelected: selectedTab == 2,
                      themeConfig: themeConfig,
                    ),
                    _buildDockItem(
                      index: 3,
                      icon: LucideIcons.userCheck,
                      label: 'coach.nav_cabinet'.tr(),
                      isSelected: selectedTab == 3,
                      themeConfig: themeConfig,
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

  Widget _buildDockItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required AppThemeConfig themeConfig,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(coachTabProvider.notifier).setTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 15 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (themeConfig.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                  : themeConfig.accentPrimary.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? (themeConfig.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                    : themeConfig.accentPrimary.withValues(alpha: 0.40))
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (themeConfig.isDark ? const Color(0xFF00E5FF) : themeConfig.accentPrimary).withValues(alpha: 0.20),
                    blurRadius: 14,
                    spreadRadius: -2,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (themeConfig.isDark ? const Color(0xFF00E5FF) : themeConfig.accentPrimary)
                  : (themeConfig.isDark ? Colors.white60 : themeConfig.textMuted),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: themeConfig.isDark ? Colors.white : themeConfig.accentPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 180.ms).slideX(begin: -0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
