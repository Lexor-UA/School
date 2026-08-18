import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme.dart';
import 'parent_home_tab.dart';
import 'parent_schedule_tab.dart';
import 'parent_profile_tab.dart';
import '../widgets/animated_water_background.dart';
import '../widgets/water_particles.dart';
import '../controllers/theme_controller.dart';

class ParentMain extends ConsumerStatefulWidget {
  const ParentMain({super.key});

  @override
  ConsumerState<ParentMain> createState() => _ParentMainState();
}

class _ParentMainState extends ConsumerState<ParentMain> {
  final ValueNotifier<int> _selectedIndexNotifier = ValueNotifier<int>(0);

  final List<Widget> _tabs = const [
    ParentHomeTab(),
    ParentScheduleTab(),
    ParentProfileTab(),
  ];

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeControllerProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: isDarkMode ? Colors.black : Colors.lightBlue.shade100,
      body: Stack(
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
                  colors: isDarkMode 
                    ? [AppTheme.primaryBlue.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.85)]
                    : [Colors.lightBlueAccent.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _selectedIndexNotifier,
            builder: (context, index, child) {
              return SafeArea(bottom: false, child: _tabs[index]);
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? AppTheme.accentTeal.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.blue.shade100.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: ValueListenableBuilder<int>(
                  valueListenable: _selectedIndexNotifier,
                  builder: (context, index, child) {
                    return GNav(
                      rippleColor: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.2),
                      hoverColor: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      gap: 8,
                      activeColor: isDarkMode ? Colors.white : Colors.blue.shade900,
                      iconSize: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      duration: const Duration(milliseconds: 400),
                      tabBackgroundColor: isDarkMode ? AppTheme.accentTeal.withValues(alpha: 0.4) : Colors.blue.shade200.withValues(alpha: 0.5),
                      color: isDarkMode ? Colors.white70 : Colors.blue.shade800.withValues(alpha: 0.7),
                      tabs: const [
                        GButton(icon: LucideIcons.home, text: 'Головна'),
                        GButton(icon: LucideIcons.calendarDays, text: 'Розклад'),
                        GButton(icon: LucideIcons.user, text: 'Профіль'),
                      ],
                      selectedIndex: index,
                      onTabChange: (i) {
                        _selectedIndexNotifier.value = i;
                      },
                    );
                  }
                ),
              ),
            ),
        ),
      ),
    );
  }
}
