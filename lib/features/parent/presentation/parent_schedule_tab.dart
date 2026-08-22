import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dart:ui';

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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected ? [const Color(0xFF00B4DB), const Color(0xFF0083B0)] : [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.02)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1), width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  _filters[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
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
          
          const SizedBox(height: 64),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5),
              ],
            ),
            child: Row(
              children: [
                // Glowing Date Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF00B4DB).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Text(day.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.5)),
                      Text(date, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(LucideIcons.clock, size: 12, color: Colors.cyanAccent),
                          ),
                          const SizedBox(width: 8),
                          Text(time, style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(LucideIcons.user, size: 12, color: Colors.amberAccent),
                          ),
                          const SizedBox(width: 8),
                          Text(coachName, style: const TextStyle(fontSize: 13, color: Colors.amberAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.chevronRight, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, {required String date, required String status, required String grade, required String comment}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.tealAccent, Colors.teal]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.tealAccent.withValues(alpha: 0.4), blurRadius: 8)],
                      ),
                      child: const Icon(LucideIcons.check, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('Юніори (Плавання)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16, letterSpacing: 0.5)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: grade == 'Відмінно' ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: grade == 'Відмінно' ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.orangeAccent.withValues(alpha: 0.5)),
                      ),
                      child: Text(grade.toUpperCase(), style: TextStyle(color: grade == 'Відмінно' ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, color: Colors.white54, size: 14),
                    const SizedBox(width: 8),
                    Text(date, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.quote, color: Colors.cyanAccent, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          comment, 
                          style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 14, height: 1.4)
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
