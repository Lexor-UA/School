import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CreateClassSheet extends ConsumerStatefulWidget {
  const CreateClassSheet({super.key});

  @override
  ConsumerState<CreateClassSheet> createState() => _CreateClassSheetState();
}

class _CreateClassSheetState extends ConsumerState<CreateClassSheet> {
  final _titleController = TextEditingController(text: 'Junior Pro');
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 0);
  
  int _maxCapacity = 8;
  String _selectedLane = 'Доріжка 1';
  final List<String> _lanes = ['Доріжка 1', 'Доріжка 2', 'Доріжка 3', 'Басейн', 'Дитячий басейн'];

  String _selectedCoach = 'Ігор (Головний тренер)';
  final List<String> _coaches = ['Ігор (Головний тренер)', 'Анна (Спортивна група)', 'Олег (Початківці)'];

  String _selectedCategory = 'Плавання';
  final List<String> _categories = ['Плавання', 'Стрибки', 'Аквааеробіка'];

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // Default duration 1 hour
    final endTime = startTime.add(const Duration(hours: 1));

    await ref.read(scheduleControllerProvider.notifier).createClass(
      title: _titleController.text.trim(),
      startTime: startTime,
      endTime: endTime,
      coachId: 'mock_coach_id', // Mock for now until coaches are in DB
      coachName: _selectedCoach,
      maxCapacity: _maxCapacity,
      category: _selectedCategory,
      lane: _selectedLane,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkTheme.scaffoldBackgroundColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Створити заняття', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: Icon(LucideIcons.x, color: isDark ? Colors.white54 : Colors.black54), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),

            // Title
            _buildLabel('Назва заняття', isDark),
            TextField(
              controller: _titleController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: _inputDecoration(isDark),
            ),
            const SizedBox(height: 16),

            // Category & Coach
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Категорія', isDark),
                      _buildDropdown(_selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!), isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Тренер', isDark),
                      _buildDropdown(_selectedCoach, _coaches, (v) => setState(() => _selectedCoach = v!), isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Дата', isDark),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.calendar, color: Colors.cyanAccent, size: 20),
                              const SizedBox(width: 8),
                              Text('${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}', 
                                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Час початку', isDark),
                      GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.clock, color: Colors.cyanAccent, size: 20),
                              const SizedBox(width: 8),
                              Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', 
                                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lane
            _buildLabel('Доріжка / Місце', isDark),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _lanes.map((lane) {
                  final isSelected = _selectedLane == lane;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLane = lane),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.transparent),
                      ),
                      child: Text(lane, style: TextStyle(
                        color: isSelected ? (isDark ? Colors.cyanAccent : AppTheme.primaryBlue) : (isDark ? Colors.white70 : Colors.black54),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Capacity
            _buildLabel('Ліміт людей: $_maxCapacity', isDark),
            Slider(
              value: _maxCapacity.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              activeColor: Colors.cyanAccent,
              onChanged: (val) => setState(() => _maxCapacity = val.toInt()),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black))
                    : const Text('Створити', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          icon: Icon(LucideIcons.chevronDown, color: isDark ? Colors.white54 : Colors.black54),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
