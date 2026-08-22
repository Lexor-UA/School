import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BookingSheet extends StatefulWidget {
  const BookingSheet({super.key});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  String _selectedClient = 'Марія (Юніори)';
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = '16:00';
  bool _isSuccess = false;

  final List<String> _clients = [
    'Марія (Юніори)',
    'Олег (Малюки)',
    'Іван (Дорослі)',
  ];

  String _getWeekday(int weekday) {
    const days = ['Пн', 'Вв', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    return days[weekday - 1];
  }

  List<String> _getTimeSlotsForDate(DateTime date) {
    // Generate some mock available time slots based on the day
    if (date.weekday == DateTime.sunday) {
      return ['10:00', '11:00', '12:00'];
    } else if (date.weekday == DateTime.saturday) {
      return ['10:00', '11:00', '14:00', '15:00'];
    }
    return ['16:00', '17:00', '18:30', '19:30'];
  }

  void _submit() {
    setState(() {
      _isSuccess = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF030D1B).withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: _isSuccess ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.4), blurRadius: 30)],
          ),
          child: const Icon(LucideIcons.check, color: Colors.greenAccent, size: 60),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text(
          'Запис підтверджено!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          '$_selectedClient на ${_selectedDate.day}/${_selectedDate.month}, $_selectedTimeSlot',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFormState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(LucideIcons.calendarPlus, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text('Швидкий Запис', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        
        const Text('Клієнт', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _clients.map((client) {
            final isSelected = client == _selectedClient;
            return GestureDetector(
              onTap: () => setState(() => _selectedClient = client),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  client,
                  style: TextStyle(
                    color: isSelected ? Colors.greenAccent : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        const Text('Дата тренування', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 14,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
              
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = date;
                  _selectedTimeSlot = ''; // Reset time on date change
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getWeekday(date.weekday),
                        style: TextStyle(
                          color: isSelected ? Colors.greenAccent : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.greenAccent : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        const Text('Час тренування', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getTimeSlotsForDate(_selectedDate).map((time) {
            final isSelected = time == _selectedTimeSlot;
            return GestureDetector(
              onTap: () => setState(() => _selectedTimeSlot = time),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? Colors.greenAccent : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 10,
              shadowColor: Colors.greenAccent.withValues(alpha: 0.5),
            ),
            onPressed: _submit,
            child: const Text('Записати', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}
