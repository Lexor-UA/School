import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_home_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_calendar_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_progress_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_profile_tab.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';

class ParentTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

final parentTabProvider = NotifierProvider<ParentTabNotifier, int>(ParentTabNotifier.new);

class ParentMain extends ConsumerStatefulWidget {
  const ParentMain({super.key});

  @override
  ConsumerState<ParentMain> createState() => _ParentMainState();
}

class _ParentMainState extends ConsumerState<ParentMain> {
  final List<Widget> _tabs = const [
    ParentHomeTab(),
    ParentCalendarTab(),
    ParentProgressTab(),
    ParentProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(parentTabProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),
          // Fluid transition overlay
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00B4DB).withValues(alpha: 0.2), 
                    const Color(0xFF0F172A).withValues(alpha: 0.75)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(bottom: false, child: _tabs[selectedIndex]),
        ],
      ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentTeal.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: GNav(
                    rippleColor: Colors.white.withValues(alpha: 0.1),
                    hoverColor: Colors.white.withValues(alpha: 0.1),
                    gap: 8,
                    activeColor: Colors.white,
                    iconSize: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    duration: const Duration(milliseconds: 400),
                    tabBackgroundColor: AppTheme.accentTeal.withValues(alpha: 0.4),
                    color: Colors.white70,
                    tabs: [
                      GButton(icon: LucideIcons.home, text: 'parent.tab_home'.tr()),
                      GButton(icon: LucideIcons.calendarDays, text: 'Календар'),
                      GButton(icon: LucideIcons.trendingUp, text: 'Прогрес'),
                      GButton(icon: LucideIcons.user, text: 'parent.tab_profile'.tr()),
                    ],
                    selectedIndex: selectedIndex,
                    onTabChange: (i) {
                      ref.read(parentTabProvider.notifier).setTab(i);
                    },
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
