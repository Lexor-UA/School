import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';

class OwnerReportsScreen extends StatefulWidget {
  const OwnerReportsScreen({super.key});

  @override
  State<OwnerReportsScreen> createState() => _OwnerReportsScreenState();
}

class _OwnerReportsScreenState extends State<OwnerReportsScreen> {
  String _selectedTimeframe = 'Місяць';

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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalRevenueCard().animate().fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildTimeframeSelector().animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 24),
                        const Text(
                          'СТРУКТУРА ДОХОДІВ',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 16),
                        _buildRevenueBreakdown().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 32),
                        const Text(
                          'КЛЮЧОВІ МЕТРИКИ',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 16),
                        _buildMetricRow(
                          LucideIcons.users, 'Клієнтська база', '412', '+12%', Colors.cyanAccent,
                          LucideIcons.userMinus, 'Відтік (Churn)', '2.4%', '-0.5%', Colors.greenAccent,
                        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                        const SizedBox(height: 16),
                        _buildMetricRow(
                          LucideIcons.trendingUp, 'LTV Клієнта', '₴ 12,400', '+8%', Colors.orangeAccent,
                          LucideIcons.shoppingCart, 'Нові абонементи', '84', '+15%', Colors.purpleAccent,
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
                        const SizedBox(height: 40),
                      ],
                    ),
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
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Фінансові Звіти',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ЧИСТИЙ ПРИБУТОК', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('+12.5%', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('₴ 84,200', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1)),
          const SizedBox(height: 8),
          const Text('Витрати: ₴ 40,300', style: TextStyle(color: Colors.pinkAccent, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['Тиждень', 'Місяць', 'Квартал', 'Рік'].map((period) {
        final isSelected = _selectedTimeframe == period;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimeframe = period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              period,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevenueBreakdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildBreakdownItem('Групові тренування', 65, Colors.cyanAccent),
          const SizedBox(height: 16),
          _buildBreakdownItem('Індивідуальні тренування', 25, Colors.purpleAccent),
          const SizedBox(height: 16),
          _buildBreakdownItem('Разові візити', 10, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int percentage, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
        Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(IconData icon1, String label1, String val1, String change1, Color color1, IconData icon2, String label2, String val2, String change2, Color color2) {
    return Row(
      children: [
        Expanded(child: _buildSmallMetricCard(icon1, label1, val1, change1, color1)),
        const SizedBox(width: 16),
        Expanded(child: _buildSmallMetricCard(icon2, label2, val2, change2, color2)),
      ],
    );
  }

  Widget _buildSmallMetricCard(IconData icon, String label, String value, String change, Color color) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(change, style: TextStyle(color: isPositive ? Colors.greenAccent : Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
