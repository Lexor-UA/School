import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RewardPopup extends StatelessWidget {
  final String title;
  final String description;

  const RewardPopup({super.key, required this.title, required this.description});

  static void show(BuildContext context, {required String title, required String description}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => RewardPopup(title: title, description: description),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'НОВЕ ДОСЯГНЕННЯ!',
                    style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
                  const SizedBox(height: 24),
                  // 3D Trophy
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.amber.shade300, Colors.amber.shade900],
                        radius: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.amber.withValues(alpha: 0.6), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.trophy, color: Colors.white, size: 60),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds, color: Colors.white)
                      .shake(hz: 3, curve: Curves.easeInOutCubic, duration: 4.seconds),
                  
                  const SizedBox(height: 32),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 400.ms).scale(),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Забрати', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),
                ],
              ),
            ),
        ),
      ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
    );
  }
}
