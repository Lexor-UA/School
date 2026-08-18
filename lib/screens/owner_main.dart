import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/animated_water_background.dart';
import '../widgets/water_particles.dart';
import '../controllers/auth_controller.dart';
import 'role_selection_screen.dart';

class OwnerMain extends ConsumerStatefulWidget {
  const OwnerMain({super.key});

  @override
  ConsumerState<OwnerMain> createState() => _OwnerMainState();
}

class _OwnerMainState extends ConsumerState<OwnerMain> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1B),
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, ref),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        'ОГЛЯД БІЗНЕСУ',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn().slideX(begin: -0.1),
                      const SizedBox(height: 8),
                      const Text(
                        'Фінансові Метрики',
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                      
                      const SizedBox(height: 32),
                      
                      // Hero Metric
                      _buildHeroMetricCard().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      
                      const SizedBox(height: 20),
                      
                      // KPI Grid
                      Row(
                        children: [
                          Expanded(child: _buildGlassMetricCard(LucideIcons.users, '412', 'Клієнти', Colors.cyanAccent, 300)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildGlassMetricCard(LucideIcons.calendarCheck, '84%', 'Завантаження', Colors.orangeAccent, 400)),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Glowing Chart
                      _buildGlowingChart().animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                      
                      const SizedBox(height: 32),
                      
                      // Live Activity Feed
                      const Text(
                        'LIVE СТАТУС',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 16),
                      _buildActivityItem(LucideIcons.arrowDownCircle, 'Нова оплата: Абонемент', '+ ₴ 2,400', Colors.greenAccent, 700),
                      _buildActivityItem(LucideIcons.userPlus, 'Новий клієнт: Олена', 'Сьогодні, 14:30', Colors.cyanAccent, 800),
                      _buildActivityItem(LucideIcons.wallet, 'Виплата зарплати', '- ₴ 12,000', Colors.pinkAccent, 900),
                      
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 15)],
                  ),
                  child: const Hero(
                    tag: 'hero_avatar_Власникам',
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вітаємо, ${user?.name ?? "Власник"}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('CitySwim CEO', style: TextStyle(color: Colors.cyanAccent, fontSize: 13, letterSpacing: 1)),
                  ],
                ),
              ],
            ).animate().fadeIn(),
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: Colors.white70),
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMetricCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withValues(alpha: 0.2), Colors.cyanAccent.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trendingUp, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 4),
                        const Text('+12.5%', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.wallet, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 24),
              const Text('ЗАГАЛЬНИЙ ДОХІД (МІСЯЦЬ)', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('₴ 124,500', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1)),
            ],
          ),
        ),
    );
  }

  Widget _buildGlassMetricCard(IconData icon, String value, String label, Color accentColor, int delay) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accentColor, size: 28),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }

  Widget _buildActivityItem(IconData icon, String title, String subtitle, Color color, int delay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }

  Widget _buildGlowingChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ДИНАМІКА ПРИБУТКУ', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const Spacer(),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: SplineChartPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class SplineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final path = Path();
    
    // Smooth curve points
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(size.width * 0.2, size.height * 0.8, size.width * 0.2, size.height * 0.3, size.width * 0.4, size.height * 0.4);
    path.cubicTo(size.width * 0.6, size.height * 0.5, size.width * 0.7, size.height * 0.1, size.width * 0.8, size.height * 0.2);
    path.cubicTo(size.width * 0.9, size.height * 0.3, size.width * 0.95, size.height * 0.1, size.width, 0);

    // Glow effect
    canvas.drawShadow(path, Colors.cyanAccent, 15, true);
    
    // Draw gradient fill below line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.cyanAccent.withValues(alpha: 0.3), Colors.cyanAccent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw dots
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.4), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, 0), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
