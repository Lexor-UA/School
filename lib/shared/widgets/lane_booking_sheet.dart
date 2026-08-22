import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LaneBookingSheet extends StatefulWidget {
  final int laneIndex;
  const LaneBookingSheet({super.key, required this.laneIndex});

  @override
  State<LaneBookingSheet> createState() => _LaneBookingSheetState();
}

class _LaneBookingSheetState extends State<LaneBookingSheet> {
  String _selectedTime = '16:00';
  bool _isBooked = false;

  final List<String> _times = ['14:00', '15:00', '16:00', '18:00', '19:30'];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF001524).withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 2),
            ),
          ),
          child: _isBooked ? _buildSuccess() : _buildBookingForm(),
        ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 40),
            ]
          ),
          child: const Icon(LucideIcons.checkCircle, color: Colors.greenAccent, size: 64),
        ).animate().scale(curve: Curves.elasticOut, duration: 1.seconds),
        const SizedBox(height: 24),
        const Text(
          'Доріжку заброньовано!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ).animate().fade().slideY(),
        const SizedBox(height: 8),
        Text(
          'Доріжка ${widget.laneIndex + 1} о $_selectedTime',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 18),
        ).animate().fade(delay: 200.ms).slideY(),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Готово', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBookingForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Бронювання', style: TextStyle(color: Colors.white70, fontSize: 16)),
                Text(
                  'Доріжка ${widget.laneIndex + 1}',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.waves, color: Colors.blueAccent, size: 32),
            )
          ],
        ),
        const SizedBox(height: 32),
        const Text('Доступний час на сьогодні:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _times.map((time) => _buildTimeChip(time)).toList(),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
              ]
            ),
            child: ElevatedButton(
              onPressed: () {
                setState(() { _isBooked = true; });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Підтвердити', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTimeChip(String time) {
    final isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white24),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
