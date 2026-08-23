import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';

class OwnerStaffScreen extends StatelessWidget {
  const OwnerStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1B),
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    children: [
                      _buildSummaryCard().animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      const Text(
                        'ТРЕНЕРИ',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 16),
                      _buildStaffCard('Олександр Спіян', 'Старший тренер', 92, 4.9, 'https://i.pravatar.cc/150?u=a042581f4e29026704d', 200),
                      _buildStaffCard('Марія Коваленко', 'Тренер', 78, 4.8, 'https://i.pravatar.cc/150?u=a042581f4e29026704c', 300),
                      _buildStaffCard('Іван Петренко', 'Тренер-стажер', 45, 4.5, 'https://i.pravatar.cc/150?u=a042581f4e29026704b', 400),
                      const SizedBox(height: 24),
                      const Text(
                        'АДМІНІСТРАТОРИ',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 16),
                      _buildStaffCard('Анна Бойко', 'Головний адміністратор', 100, 5.0, 'https://i.pravatar.cc/150?u=a042581f4e29026704a', 600, showLoad: false),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Персонал',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.userPlus, color: Colors.cyanAccent, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.05), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryStat('Всього', '12', LucideIcons.users),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
          _buildSummaryStat('Онлайн', '4', LucideIcons.checkCircle2, Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
          _buildSummaryStat('Відпустка', '1', LucideIcons.tent, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String val, IconData icon, [Color color = Colors.white]) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildStaffCard(String name, String role, int load, double rating, String avatarUrl, int delay, {bool showLoad = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(role, style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                if (showLoad) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: load / 100,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              load > 85 ? Colors.orangeAccent : Colors.greenAccent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$load%', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              const Icon(LucideIcons.star, color: Colors.amber, size: 16),
              const SizedBox(height: 4),
              Text(rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }
}
