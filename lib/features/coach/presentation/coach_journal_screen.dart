import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'coach_dashboard.dart';

class CoachJournalScreen extends ConsumerWidget {
  const CoachJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Color(0xFF09182B),
      body: Stack(
        children: [
          // 1. Water animation background
          Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),
          Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),

          // 2. Liquid gradient atmosphere overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x1F0369A1),
                    Color(0x0F0284C7),
                    Color(0xEB09182B),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. Journal Tab Content
          SafeArea(
            child: CoachJournalTab(),
          ),
        ],
      ),
    );
  }
}
