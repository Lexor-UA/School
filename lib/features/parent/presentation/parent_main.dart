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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: themeConfig.isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, -3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: themeConfig.isDark
                    ? const Color(0xFF071E36).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.93),
                border: Border(
                  top: BorderSide(
                    color: themeConfig.isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                        : const Color(0xFFBAE6FD),
                    width: 1.2,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                  child: GNav(
                    rippleColor: themeConfig.accentPrimary.withValues(alpha: 0.1),
                    hoverColor: themeConfig.accentPrimary.withValues(alpha: 0.1),
                    gap: 8,
                    activeColor: themeConfig.isDark ? Colors.white : const Color(0xFF0284C7),
                    iconSize: 21,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: themeConfig.isDark ? Colors.white : const Color(0xFF0284C7),
                      letterSpacing: 0.2,
                    ),
                    tabBorderRadius: 18,
                    tabActiveBorder: Border.all(
                      color: themeConfig.isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                          : const Color(0xFFBAE6FD),
                      width: 1.0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    duration: const Duration(milliseconds: 300),
                    tabBackgroundColor: themeConfig.isDark
                        ? themeConfig.accentPrimary.withValues(alpha: 0.35)
                        : const Color(0xFF0284C7).withValues(alpha: 0.12),
                    color: themeConfig.isDark ? Colors.white70 : const Color(0xFF64748B),
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
