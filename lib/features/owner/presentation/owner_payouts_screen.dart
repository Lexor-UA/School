import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';

class OwnerPayoutsScreen extends StatefulWidget {
  const OwnerPayoutsScreen({super.key});

  @override
  State<OwnerPayoutsScreen> createState() => _OwnerPayoutsScreenState();
}

class _OwnerPayoutsScreenState extends State<OwnerPayoutsScreen> {
  void _showDevSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.pinkAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                      _buildBalanceCard().animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      const Text(
                        'ОЧІКУЮТЬ ВИПЛАТИ',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 16),
                      _buildPayoutItem('Олександр Спіян', 'Серпень 2026', '₴ 24,000', 'https://i.pravatar.cc/150?u=a042581f4e29026704d', 300),
                      _buildPayoutItem('Марія Коваленко', 'Серпень 2026', '₴ 18,500', 'https://i.pravatar.cc/150?u=a042581f4e29026704c', 400),
                      
                      const SizedBox(height: 32),
                      const Text(
                        'ІСТОРІЯ ТРАНЗАКЦІЙ',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 16),
                      _buildHistoryItem('Оренда басейну', '1 Серпня', '- ₴ 40,000', Colors.pinkAccent, 600),
                      _buildHistoryItem('Виплата: Іван П.', '31 Липня', '- ₴ 12,000', Colors.pinkAccent, 700),
                      _buildHistoryItem('Зарахування (LiqPay)', '31 Липня', '+ ₴ 85,000', Colors.greenAccent, 800),
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
                'Виплати',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.landmark, color: Colors.pinkAccent, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.pinkAccent.withOpacity(0.1), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ДОСТУПНО ДЛЯ ВИПЛАТ', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Icon(LucideIcons.creditCard, color: Colors.pinkAccent.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('₴ 142,500', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showDevSnackbar('Поповнення рахунку у розробці');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Поповнити', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPayoutItem(String name, String period, String amount, String avatarUrl, int delay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(period, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Text(amount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showDevSnackbar('Виплата для $name виконана успішно!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                foregroundColor: Colors.pinkAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Підтвердити виплату', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }

  Widget _buildHistoryItem(String title, String date, String amount, Color color, int delay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          Text(amount, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }
}
