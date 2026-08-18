import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/animated_water_background.dart';
import '../widgets/water_particles.dart';
import '../controllers/auth_controller.dart';
import 'role_selection_screen.dart';

class AdminMain extends ConsumerStatefulWidget {
  const AdminMain({super.key});

  @override
  ConsumerState<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends ConsumerState<AdminMain> {
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
                
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: _buildSearchBar().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      
                      // Live Status Banner
                      _buildLiveStatusBanner().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      
                      const Text(
                        'ШВИДКІ ДІЇ',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 16),
                      
                      // Quick Actions Grid
                      Row(
                        children: [
                          Expanded(child: _buildActionCard(LucideIcons.userPlus, 'Новий Клієнт', Colors.cyanAccent, 400)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildActionCard(LucideIcons.calendarPlus, 'Запис', Colors.greenAccent, 500)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildActionCard(LucideIcons.messageCircle, 'Чат (3 нові)', Colors.orangeAccent, 600)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildActionCard(LucideIcons.wallet, 'Оплата', Colors.purpleAccent, 700)),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      const Text(
                        'ЗАВДАННЯ НА СЬОГОДНІ',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(height: 16),
                      
                      _buildTaskItem('Підтвердити оплату', 'Клієнт: Марія, Група Юніори', true).animate().fadeIn(delay: 900.ms).slideX(begin: 0.1),
                      const SizedBox(height: 12),
                      _buildTaskItem('Зателефонувати новеньким', '3 пропущених дзвінка', false, isUrgent: true).animate().fadeIn(delay: 1000.ms).slideX(begin: 0.1),
                      const SizedBox(height: 12),
                      _buildTaskItem('Оновити розклад', 'Тренер Алекс захворів', false).animate().fadeIn(delay: 1100.ms).slideX(begin: 0.1),
                      
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
                    tag: 'hero_avatar_Адміністраторам',
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вітаємо, ${user?.name ?? "Адмін"}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('CitySwim CRM', style: TextStyle(color: Colors.cyanAccent, fontSize: 13, letterSpacing: 1)),
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: const TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Пошук клієнта, групи, або транзакції...',
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(LucideIcons.search, color: Colors.cyanAccent),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
    );
  }

  Widget _buildLiveStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withValues(alpha: 0.2), Colors.cyanAccent.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.activity, color: Colors.cyanAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Зараз у басейні', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('24 клієнта', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 16, color: Colors.white24),
                    const SizedBox(width: 12),
                    const Text('3 тренери', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color accentColor, int delay) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 10)],
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
          ),
        ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }

  Widget _buildTaskItem(String title, String subtitle, bool isCompleted, {bool isUrgent = false}) {
    Color statusColor = isCompleted ? Colors.greenAccent : (isUrgent ? Colors.orangeAccent : Colors.cyanAccent);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUrgent ? Colors.orangeAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isCompleted ? LucideIcons.check : LucideIcons.clock, 
              color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white54),
        ],
      ),
    );
  }
}
