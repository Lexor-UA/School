import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    IconData icon;
    
    switch (achievement.iconType) {
      case 'gold_cup':
        baseColor = Colors.amber;
        icon = LucideIcons.trophy;
        break;
      case 'silver_medal':
        baseColor = Colors.grey.shade400;
        icon = LucideIcons.medal;
        break;
      case 'diamond_cup':
        baseColor = Colors.cyanAccent;
        icon = LucideIcons.diamond;
        break;
      case 'bronze_medal':
      default:
        baseColor = Colors.orange.shade700;
        icon = LucideIcons.award;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = achievement.isUnlocked ? baseColor : (isDark ? Colors.white24 : Colors.black26);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: achievement.isUnlocked ? 2 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D Model placeholder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [displayColor.withValues(alpha: 0.8), displayColor.withValues(alpha: 0.2)],
                radius: 0.8,
              ),
              boxShadow: achievement.isUnlocked
                  ? [BoxShadow(color: displayColor.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)]
                  : [],
            ),
            child: Icon(icon, color: achievement.isUnlocked ? Colors.white : (isDark ? Colors.white38 : Colors.black38), size: 40),
          ).animate(onPlay: achievement.isUnlocked ? (c) => c.repeat() : null).shimmer(duration: 2.seconds, color: Colors.white54).shake(hz: 2, curve: Curves.easeInOutCubic, duration: 3.seconds),
          const SizedBox(height: 16),
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: achievement.isUnlocked ? (isDark ? Colors.white : const Color(0xFF0A2540)) : (isDark ? Colors.white54 : Colors.black45),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : const Color(0xFF4A6572),
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
