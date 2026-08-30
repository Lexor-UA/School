import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'dart:ui';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/parent/presentation/anatomy_progress_screen.dart';

class ParentProgressTab extends ConsumerWidget {
  const ParentProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force dark colors because we use a dark background
    final bool isDark = true;
    final textColor = isDark ? Colors.white : const Color(0xFF0A2540);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A6572);
    final accentColor = Colors.cyanAccent;

    return Scaffold(
      backgroundColor: Colors.black, // Base background color
      appBar: AppBar(
        title: const Text('Мій прогрес', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
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
                      const Color(0xFF0F172A).withValues(alpha: 0.75)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
        children: [
          // 1. STYLE HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Кроль', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('Основний стиль', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. METRICS
          _buildMetricBar('Техніка', 82, isDark, accentColor),
          _buildMetricBar('Швидкість', 74, isDark, Colors.orangeAccent),
          _buildMetricBar('Робота ніг', 68, isDark, Colors.pinkAccent),
          _buildMetricBar('Положення тіла', 81, isDark, Colors.greenAccent),

          const SizedBox(height: 24),

          // 3. IMPROVEMENTS CARD
          Text('Що покращити', style: TextStyle(color: textSubColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.lightbulb, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'На наступному тренуванні попрацюємо над положенням тіла та роботою ніг. Зверніть увагу на розслаблення під час вдиху.',
                    style: TextStyle(color: textColor, height: 1.4, fontSize: 13),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          // 4. ANATOMY VIEW LINK
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnatomyProgressScreen())),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.activity, color: accentColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Анатомія прогресу', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Переглянути розвиток м\'язів у 3D', style: TextStyle(color: textSubColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, color: accentColor, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 100),
        ],
      ),
      ),
      ],
      ),
      ),
    );
  }

  Widget _buildMetricBar(String label, int percentage, bool isDark, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
