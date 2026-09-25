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

      // 5. Floating Apple VisionOS Frosted Dock (Luminous Liquid Glass)
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: themeConfig.isDark
                ? [
                    // Ambient ocean cyan aura dispelling any black look
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                      blurRadius: 32,
                      spreadRadius: -1,
                      offset: const Offset(0, 6),
                    ),
                    // Luminous royal ocean lift (rich deep sapphire depth)
                    BoxShadow(
                      color: const Color(0xFF001529).withValues(alpha: 0.70),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: themeConfig.isDark
                        ? [
                            const Color(0xFF0F2E52).withValues(alpha: 0.88),
                            const Color(0xFF07192F).withValues(alpha: 0.94),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.96),
                            const Color(0xFFF8FAFC).withValues(alpha: 0.92),
                          ],
                  ),
                  border: Border.all(
                    color: themeConfig.isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.95),
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
                      label: 'Мої учні',
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
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeConfig.isDark
                      ? const [
                          Color(0xFF00E5FF),
                          Color(0xFF0284C7),
                        ]
                      : const [
                          Color(0xFF0EA5E9),
                          Color(0xFF0284C7),
                        ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? (themeConfig.isDark
                    ? Colors.white.withValues(alpha: 0.50)
                    : Colors.white.withValues(alpha: 0.55))
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                        .withValues(alpha: themeConfig.isDark ? 0.50 : 0.30),
                    blurRadius: 18,
                    spreadRadius: themeConfig.isDark ? 1 : 0,
                    offset: const Offset(0, 3),
                  ),
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
                  ? Colors.white
                  : (themeConfig.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.3,
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
