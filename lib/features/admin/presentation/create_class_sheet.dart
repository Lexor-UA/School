import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';

class CreateClassSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final AppUser? defaultCoach;
  
  const CreateClassSheet({super.key, this.initialDate, this.defaultCoach});

  @override
  ConsumerState<CreateClassSheet> createState() => _CreateClassSheetState();
}

class _CreateClassSheetState extends ConsumerState<CreateClassSheet> {
  final _titleController = TextEditingController(text: 'Junior Pro');
  
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 0);
  
  int _maxCapacity = 8;
  String _selectedLane = 'Доріжка 1';
  final List<String> _lanes = ['Доріжка 1', 'Доріжка 2', 'Доріжка 3', 'Басейн', 'Дитячий басейн'];

  AppUser? _selectedCoach;

  String _selectedCategory = 'Плавання';
  final List<String> _categories = ['Плавання', 'Стрибки', 'Аквааеробіка'];

  bool _isSaving = false;

  String _getLaneLabel(String lane) {
    switch (lane) {
      case 'Доріжка 1':
        return 'admin.lane_1'.tr();
      case 'Доріжка 2':
        return 'admin.lane_2'.tr();
      case 'Доріжка 3':
        return 'admin.lane_3'.tr();
      case 'Басейн':
        return 'admin.lane_pool'.tr();
      case 'Дитячий басейн':
        return 'admin.lane_kids_pool'.tr();
      default:
        return lane;
    }
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'Плавання':
        return 'admin.cat_swimming'.tr();
      case 'Стрибки':
        return 'admin.cat_diving'.tr();
      case 'Аквааеробіка':
        return 'admin.cat_aqua'.tr();
      default:
        return cat;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E5FF),
              onPrimary: Colors.black,
              surface: Color(0xFF13233C),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF13233C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E5FF),
              onPrimary: Colors.black,
              surface: Color(0xFF13233C),
              onSurface: Colors.white,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Color(0xFF13233C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _selectedCoach == null) return;

    setState(() => _isSaving = true);

    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    final endTime = startTime.add(const Duration(hours: 1));

    final success = await ref.read(scheduleControllerProvider.notifier).createClass(
      title: _titleController.text.trim(),
      startTime: startTime,
      endTime: endTime,
      coachId: _selectedCoach!.id,
      coachName: _selectedCoach!.name,
      maxCapacity: _maxCapacity,
      category: _selectedCategory,
      lane: _selectedLane,
    );

    if (success) {
      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction('Створено заняття "${_titleController.text.trim()}"', admin.id);
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachesAsync = ref.watch(coachesProvider);
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.92,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF13233C).withValues(alpha: 0.98),
            const Color(0xFF091424).withValues(alpha: 0.99),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              mediaQuery.viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header with Jewel Squircle
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF10B981), Color(0xFF047857)],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.calendarPlus, color: Colors.white, size: 21),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'admin.class_create_title'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'admin.class_create_subtitle'.tr(),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(LucideIcons.x, color: Colors.white70, size: 17),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Title input
                  _buildLabel('admin.class_name'.tr()),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: _inputDecoration(hint: 'admin.class_name_hint'.tr()),
                  ),
                  const SizedBox(height: 16),

                  // Category & Coach
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('admin.class_category'.tr()),
                            _buildDropdown(_selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('admin.class_coach'.tr()),
                            coachesAsync.when(
                              data: (coachesList) {
                                if (coachesList.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                                    ),
                                    child: Text('admin.class_no_coaches'.tr(), style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 13)),
                                  );
                                }
                                if (_selectedCoach == null) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      final matched = widget.defaultCoach != null
                                          ? coachesList.firstWhere(
                                              (c) => c.id == widget.defaultCoach!.id || c.name.toLowerCase() == widget.defaultCoach!.name.toLowerCase(),
                                              orElse: () => coachesList.first,
                                            )
                                          : coachesList.first;
                                      setState(() => _selectedCoach = matched);
                                    }
                                  });
                                }
                                return _buildCoachDropdown(_selectedCoach, coachesList, (v) => setState(() => _selectedCoach = v!));
                              },
                              loading: () => Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)))),
                              ),
                              error: (err, stack) => Text('admin.class_error'.tr(), style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date & Time Interactive Cards
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('admin.class_date'.tr()),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _selectDate,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(LucideIcons.calendar, color: Color(0xFF00E5FF), size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}', 
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('admin.class_start_time'.tr()),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _selectTime,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(LucideIcons.clock, color: Color(0xFF00E5FF), size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', 
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lane selection chips
                  _buildLabel('admin.class_lane_place'.tr()),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _lanes.map((lane) {
                        final isSelected = _selectedLane == lane;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _selectedLane = lane),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8.5),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00E5FF)
                                        : Colors.white.withValues(alpha: 0.16),
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00B4D8).withValues(alpha: 0.45),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  _getLaneLabel(lane),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Capacity Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('admin.class_students_limit'.tr()),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.40)),
                        ),
                        child: Text(
                          'admin.class_spots_count'.tr(args: ['$_maxCapacity']),
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00E5FF),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                      thumbColor: const Color(0xFF00E5FF),
                      overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _maxCapacity.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (val) => setState(() => _maxCapacity = val.toInt()),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button (VisionOS Gradient)
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B4D8).withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSaving ? null : _save,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'admin.class_create_btn'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7.0, left: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13.5),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF13233C),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          icon: Icon(LucideIcons.chevronDown, color: Colors.white.withValues(alpha: 0.60), size: 18),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(_getCategoryLabel(i)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCoachDropdown(AppUser? value, List<AppUser> items, ValueChanged<AppUser?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppUser>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF13233C),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          icon: Icon(LucideIcons.chevronDown, color: Colors.white.withValues(alpha: 0.60), size: 18),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.name))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
