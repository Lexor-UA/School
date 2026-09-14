import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_home_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_calendar_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_subscription_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_profile_tab.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

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
    ParentSubscriptionTab(),
    ParentProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(parentTabProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: themeConfig.scaffoldBg,
      body: SizedBox.expand(
        child: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(child: AnimatedWaterBackground()),
            ),
            // Fluid transition overlay
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeConfig.bgGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Theme-tailored 3D animated water bubbles
            const Positioned.fill(
              child: RepaintBoundary(child: WaterParticles()),
            ),
          SafeArea(bottom: false, child: _tabs[selectedIndex]),
        ],
      ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: themeConfig.accentPrimary.withValues(alpha: themeConfig.isDark ? 0.3 : 0.15),
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
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    color: themeConfig.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.92),
                    border: Border.all(
                      color: themeConfig.isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : themeConfig.accentPrimary.withValues(alpha: 0.25),
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: GNav(
                    rippleColor: themeConfig.accentPrimary.withValues(alpha: 0.1),
                    hoverColor: themeConfig.accentPrimary.withValues(alpha: 0.1),
                    gap: 6,
                    activeColor: themeConfig.isDark ? Colors.white : themeConfig.accentPrimary,
                    iconSize: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    duration: const Duration(milliseconds: 350),
                    tabBackgroundColor: themeConfig.accentPrimary.withValues(alpha: themeConfig.isDark ? 0.35 : 0.15),
                    color: themeConfig.isDark ? Colors.white70 : themeConfig.textSecondary,
                    tabs: [
                      GButton(icon: LucideIcons.home, text: 'parent.tab_home'.tr()),
                      GButton(icon: LucideIcons.calendarDays, text: 'parent.tab_calendar'.tr()),
                      GButton(icon: LucideIcons.creditCard, text: 'parent.tab_pass'.tr()),
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
