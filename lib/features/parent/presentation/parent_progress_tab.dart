import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'dart:ui';
import 'package:swimming_school_app/features/parent/presentation/anatomy_progress_screen.dart';

class ParentProgressTab extends ConsumerWidget {
  const ParentProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = isDark ? Colors.cyanAccent : AppTheme.primaryBlue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Мій прогрес', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. STYLE HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Кроль', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('Основний стиль', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. METRICS
          _buildMetricBar('Техніка', 82, isDark, accentColor),
          _buildMetricBar('Швидкість', 74, isDark, Colors.orangeAccent),
          _buildMetricBar('Робота ніг', 68, isDark, Colors.pinkAccent),
          _buildMetricBar('Положення тіла', 81, isDark, Colors.greenAccent),

          const SizedBox(height: 32),

          // 3. IMPROVEMENTS CARD
          Text('Що покращити', style: TextStyle(color: textSubColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.lightbulb, color: Colors.amber, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'На наступному тренуванні попрацюємо над положенням тіла та роботою ніг. Зверніть увагу на розслаблення під час вдиху.',
                    style: TextStyle(color: textColor, height: 1.5, fontSize: 15),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          // 4. ANATOMY VIEW LINK
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnatomyProgressScreen())),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.activity, color: accentColor, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Анатомія прогресу', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Переглянути розвиток м\'язів у 3D', style: TextStyle(color: textSubColor, fontSize: 14)),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, color: accentColor),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, int percentage, bool isDark, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 12,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
