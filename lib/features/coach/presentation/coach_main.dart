import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'coach_dashboard.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';

class CoachMain extends StatefulWidget {
  const CoachMain({super.key});

  @override
  State<CoachMain> createState() => _CoachMainState();
}

class _CoachMainState extends State<CoachMain> {
  final ValueNotifier<int> _selectedIndexNotifier = ValueNotifier<int>(0);

  final List<Widget> _tabs = [
    const CoachDashboard(),
    const _CoachProfileTab(),
  ];

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00B4DB).withValues(alpha: 0.2),
                    const Color(0xFF0F172A).withValues(alpha: 0.75),
                  ],
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
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _selectedIndexNotifier,
                    builder: (context, index, child) {
                      return GNav(
                      rippleColor: Colors.white.withValues(alpha: 0.1),
                      hoverColor: Colors.white.withValues(alpha: 0.1),
                      gap: 8,
                      activeColor: Colors.white,
                      iconSize: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      duration: const Duration(milliseconds: 400),
                      tabBackgroundColor: Colors.blueAccent.withValues(alpha: 0.3),
                      color: Colors.white54,
                      tabs: [
                        GButton(icon: LucideIcons.layoutDashboard, text: 'coach.tab_schedule'.tr()),
                        GButton(icon: LucideIcons.user, text: 'coach.tab_profile'.tr()),
                      ],
                      selectedIndex: index,
                        onTabChange: (index) {
                          _selectedIndexNotifier.value = index;
                        },
                      );
                    },
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachProfileTab extends ConsumerWidget {
  const _CoachProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AvatarPicker(
            heroTag: 'hero_avatar_Тренерам',
            radius: 60,
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                    context.go('/');
                  },
                  icon: const Icon(LucideIcons.logOut, color: Colors.redAccent),
                  label: Text('coach.logout'.tr(), style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
