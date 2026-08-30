import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';

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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', whereIn: ['coach', 'admin'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                      }
                      
                      final staffDocs = snapshot.data?.docs ?? [];
                      final coaches = staffDocs.where((d) => d['role'] == 'coach').toList();
                      final admins = staffDocs.where((d) => d['role'] == 'admin').toList();

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        children: [
                          _buildSummaryCard(staffDocs.length).animate().fadeIn().slideY(begin: 0.1),
                          const SizedBox(height: 32),
                          
                          if (coaches.isNotEmpty) ...[
                            const Text(
                              'ТРЕНЕРИ',
                              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ).animate().fadeIn(delay: 100.ms),
                            const SizedBox(height: 16),
                            ...coaches.map((doc) {
                              final name = doc['name'] ?? 'Без імені';
                              final avatarUrl = doc['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=$name';
                              // In a real app we'd fetch actual class count/rating for the coach. Here we mock some stats for the UI
                              return _buildStaffCard(doc.id, name, 'Тренер', 92, 4.9, avatarUrl, 200);
                            }),
                            const SizedBox(height: 24),
                          ],

                          if (admins.isNotEmpty) ...[
                            const Text(
                              'АДМІНІСТРАТОРИ',
                              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ).animate().fadeIn(delay: 500.ms),
                            const SizedBox(height: 16),
                            ...admins.map((doc) {
                              final name = doc['name'] ?? 'Без імені';
                              final avatarUrl = doc['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=$name';
                              return _buildStaffCard(doc.id, name, 'Адміністратор', 100, 5.0, avatarUrl, 600, showLoad: false);
                            }),
                          ],
                          const SizedBox(height: 40),
                        ],
                      );
                    }
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

  Widget _buildSummaryCard(int staffCount) {
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
          _buildSummaryStat(LucideIcons.users, staffCount.toString(), 'Всього'),
          _buildSummaryStat(LucideIcons.checkCircle2, '98%', 'Явка'),
          _buildSummaryStat(LucideIcons.star, '4.8', 'Рейтинг'),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 28),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildStaffCard(String id, String name, String role, int load, double rating, String avatarUrl, int delay, {bool showLoad = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(avatarUrl),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(role, style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toString(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    if (showLoad) ...[
                      const SizedBox(width: 16),
                      const Icon(LucideIcons.activity, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 4),
                      Text('$load% Навантаження', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, color: Colors.white54),
            onPressed: () {},
          )
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }
}
