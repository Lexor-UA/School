import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/class_session.dart';
import 'package:intl/intl.dart';

class AdminBookingSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final List<String> availableIds;
  final List<String> availableNames;

  const AdminBookingSheet({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.availableIds,
    required this.availableNames,
  });

  @override
  ConsumerState<AdminBookingSheet> createState() => _AdminBookingSheetState();
}

class _AdminBookingSheetState extends ConsumerState<AdminBookingSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;
  String? _selectedChildId;
  bool _isBooking = false;

  void _book() async {
    if (_selectedClassId == null || _selectedChildId == null) return;
    
    setState(() => _isBooking = true);
    
    try {
      final success = await ref.read(scheduleControllerProvider.notifier).bookClass(_selectedClassId!, _selectedChildId!);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Успішно записано!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не вдалося записати (можливо, немає місць або абонемента)'), backgroundColor: Colors.redAccent));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.availableIds.isNotEmpty) {
      _selectedChildId = widget.availableIds.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Записати на заняття', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          const Text('Оберіть дату:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = date;
                    _selectedClassId = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        Text(DateFormat('E', 'uk').format(date).toUpperCase(), style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('${date.day}', style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Оберіть клієнта/дитину:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF1E293B),
                value: _selectedChildId,
                isExpanded: true,
                icon: const Icon(LucideIcons.chevronDown, color: Colors.cyanAccent),
                items: List.generate(widget.availableIds.length, (index) {
                  return DropdownMenuItem(
                    value: widget.availableIds[index],
                    child: Text(widget.availableNames[index], style: const TextStyle(color: Colors.white)),
                  );
                }),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedChildId = val);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Доступні заняття:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final classes = snapshot.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return ClassSession.fromJson(data);
                }).where((c) {
                  final d1 = c.date;
                  final d2 = _selectedDate;
                  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
                }).toList();
                
                classes.sort((a, b) => a.date.compareTo(b.date));
                
                if (classes.isEmpty) {
                  return const Center(child: Text('Немає занять на цей день', style: TextStyle(color: Colors.white54)));
                }
                
                return ListView.builder(
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final c = classes[index];
                    final isFull = c.enrolledChildIds.length >= c.maxCapacity;
                    final isSelected = _selectedClassId == c.id;
                    
                    return GestureDetector(
                      onTap: isFull ? null : () => setState(() => _selectedClassId = c.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? Colors.cyanAccent : (isFull ? Colors.redAccent.withValues(alpha: 0.3) : Colors.transparent)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c.time} - ${c.category}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(c.lane.isNotEmpty ? c.lane : 'Основний басейн', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            Text('${c.enrolledChildIds.length} / ${c.maxCapacity}', style: TextStyle(color: isFull ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedClassId != null && _selectedChildId != null && !_isBooking ? _book : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isBooking
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3))
                  : const Text('Записати', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
