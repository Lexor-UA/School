import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme.dart';

class ParentScheduleTab extends StatefulWidget {
  const ParentScheduleTab({super.key});

  @override
  State<ParentScheduleTab> createState() => _ParentScheduleTabState();
}

class _ParentScheduleTabState extends State<ParentScheduleTab> {
  final ValueNotifier<int> _selectedFilterNotifier = ValueNotifier<int>(0);
  final List<String> _filters = ['Усі', 'Плавання', 'Стрибки', 'Змагання'];

  @override
  void dispose() {
    _selectedFilterNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Розклад та Історія', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Filters
          SizedBox(
            height: 40,
            child: ValueListenableBuilder<int>(
              valueListenable: _selectedFilterNotifier,
              builder: (context, selectedFilter, _) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedFilter == index;
                    return GestureDetector(
                      onTap: () => _selectedFilterNotifier.value = index,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 24),

          Text(
            'Майбутні Заняття',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          _buildScheduleCard(
            context,
            day: 'Сгд',
            date: '10',
            time: '16:00 - 17:00',
            className: 'Юніори (Батерфляй)',
            coachName: 'Тренер Алекс',
          ).animate().slideX(begin: 0.2, end: 0, delay: 100.ms).fadeIn(),
          const SizedBox(height: 12),
          _buildScheduleCard(
            context,
            day: 'Чтв',
            date: '12',
            time: '17:30 - 18:30',
            className: 'Стрибки у воду',
            coachName: 'Тренер Олена',
          ).animate().slideX(begin: 0.2, end: 0, delay: 200.ms).fadeIn(),
          const SizedBox(height: 12),
          _buildScheduleCard(
            context,
            day: 'Сбт',
            date: '14',
            time: '10:00 - 12:00',
            className: 'Підготовка до змагань',
            coachName: 'Тренер Марк',
          ).animate().slideX(begin: 0.2, end: 0, delay: 300.ms).fadeIn(),
          
          const SizedBox(height: 32),
          Text(
            'Історія Відвідувань',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          _buildHistoryCard(context, date: '5 Грудня, 16:00', status: 'Відвідано', grade: 'Відмінно', comment: 'Чудова робота ногами!').animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 12),
          _buildHistoryCard(context, date: '3 Грудня, 16:00', status: 'Відвідано', grade: 'Добре', comment: 'Потрібно попрацювати над диханням.').animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 80), // Padding for floating nav bar
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, {required String day, required String date, required String time, required String className, required String coachName}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(day, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white70)),
                    Text(date, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(time, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.user, size: 16, color: Colors.cyanAccent),
                        const SizedBox(width: 4),
                        Text(coachName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.cyanAccent)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.white54),
            ],
          ),
        ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, {required String date, required String status, required String grade, required String comment}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.accentTeal,
                    radius: 16,
                    child: Icon(LucideIcons.check, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Юніори (Плавання)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: grade == 'Відмінно' ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.orangeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: grade == 'Відмінно' ? Colors.greenAccent : Colors.orangeAccent),
                    ),
                    child: Text(grade, style: TextStyle(color: grade == 'Відмінно' ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(date, style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.messageSquare, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('"$comment"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
