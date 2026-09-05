import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'coach_dashboard.dart';

class CoachTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

/// Provider for active coach tab
final coachTabProvider = NotifierProvider<CoachTabNotifier, int>(CoachTabNotifier.new);

class CoachMain extends ConsumerStatefulWidget {
  const CoachMain({super.key});

  @override
  ConsumerState<CoachMain> createState() => _CoachMainState();
}

class _CoachMainState extends ConsumerState<CoachMain> {
  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(coachTabProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF09182B),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // 1. Water animation background
            const Positioned.fill(
              child: RepaintBoundary(child: AnimatedWaterBackground()),
            ),
            const Positioned.fill(
              child: RepaintBoundary(child: WaterParticles()),
            ),

            // 2. Frosted fluid aquatic gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00B4DB).withValues(alpha: 0.18),
                      const Color(0xFF0284C7).withValues(alpha: 0.10),
                      const Color(0xFF0F172A).withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Volumetric ambient depth orbs
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00E5FF).withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 320,
              left: -70,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0284C7).withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 4. Main Tab Body
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: selectedTab,
                children: const [
                  CoachScheduleTab(),
                  CoachJournalTab(),
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
          margin: const EdgeInsets.only(left: 18, right: 18, bottom: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
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
                  color: const Color(0xFF0B1B30).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDockItem(
                      index: 0,
                      icon: LucideIcons.calendarClock,
                      label: 'coach.nav_schedule'.tr(),
                      isSelected: selectedTab == 0,
                    ),
                    _buildDockItem(
                      index: 1,
                      icon: LucideIcons.clipboardCheck,
                      label: 'coach.nav_journal'.tr(),
                      isSelected: selectedTab == 1,
                    ),
                    _buildDockItem(
                      index: 2,
                      icon: LucideIcons.users,
                      label: 'coach.nav_swimmers'.tr(),
                      isSelected: selectedTab == 2,
                    ),
                    _buildDockItem(
                      index: 3,
                      icon: LucideIcons.userCheck,
                      label: 'coach.nav_cabinet'.tr(),
                      isSelected: selectedTab == 3,
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
          horizontal: isSelected ? 16 : 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
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
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ).animate().fadeIn(duration: 180.ms).slideX(begin: -0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
