import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets/apple_time_wheel_picker.dart';

class CreateClassSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final GroupClass? classToEdit;
  final String? initialCoachId;
  final String? initialCoachName;
  
  const CreateClassSheet({
    super.key,
    this.initialDate,
    this.classToEdit,
    this.initialCoachId,
    this.initialCoachName,
  });

  @override
  ConsumerState<CreateClassSheet> createState() => _CreateClassSheetState();
}

class _CreateClassSheetState extends ConsumerState<CreateClassSheet> {
  late final TextEditingController _titleController;
  
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 0);
  
  int _maxCapacity = 8;
  String _selectedPoolType = 'Спортивний басейн';
  String _selectedLane = 'Доріжка 1';
  final List<String> _sportLanes = ['Доріжка 1', 'Доріжка 2', 'Доріжка 3', 'Доріжка 4', 'Весь басейн'];

  AppUser? _selectedCoach;

  String _selectedCategory = 'Плавання';
  final List<String> _categories = ['Плавання', 'Стрибки', 'Аквааеробіка'];

  bool _isSaving = false;

  bool get _isEditing => widget.classToEdit != null;

  // Recurring schedule settings (regular group by default)
  bool _isRecurring = true;
  late Set<int> _selectedWeekdays;
  int _durationWeeks = 52; // Default: 1 year (52 weeks)

  int get _calculatedRecurringCount {
    int count = 0;
    final totalDays = _durationWeeks * 7;
    final base = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    for (int i = 0; i < totalDays; i++) {
      final d = base.add(Duration(days: i));
      if (_selectedWeekdays.contains(d.weekday)) {
        count++;
      }
    }
    return count;
  }

  String _getWeekdaysNamesSummary() {
    final Map<int, String> names = {
      1: 'понеділках',
      2: 'вівторках',
      3: 'середах',
      4: 'четвергах',
      5: 'п\'ятницях',
      6: 'суботах',
      7: 'неділях',
    };
    final sorted = _selectedWeekdays.toList()..sort();
    return sorted.map((w) => names[w] ?? '').where((s) => s.isNotEmpty).join(', ');
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
    if (_isEditing) {
      final c = widget.classToEdit!;
      _titleController = TextEditingController(text: c.title);
      _selectedDate = c.startTime;
      _selectedTime = TimeOfDay(hour: c.startTime.hour, minute: c.startTime.minute);
      _maxCapacity = c.maxCapacity;
      _selectedCategory = c.category;
      if (c.lane == 'Дитячий басейн') {
        _selectedPoolType = 'Дитячий басейн';
        _selectedLane = 'Дитячий басейн';
      } else {
        _selectedPoolType = 'Спортивний басейн';
        _selectedLane = c.lane.isNotEmpty ? c.lane : 'Доріжка 1';
      }
      _selectedWeekdays = {c.startTime.weekday};
    } else {
      _titleController = TextEditingController(text: 'Junior Pro');
      _selectedDate = widget.initialDate ?? DateTime.now();
      if (widget.initialDate != null) {
        _selectedTime = TimeOfDay(hour: widget.initialDate!.hour, minute: widget.initialDate!.minute);
      }
      _selectedPoolType = 'Спортивний басейн';
      _selectedLane = 'Доріжка 1';
      _selectedWeekdays = {_selectedDate.weekday};
    }
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
      setState(() {
        _selectedDate = picked;
        _selectedWeekdays.add(picked.weekday);
      });
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

    bool success = false;
    if (_isEditing) {
      success = await ref.read(scheduleControllerProvider.notifier).updateClass(
        classId: widget.classToEdit!.id,
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
          final timeFmt = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
          await logAdminAction('Оновлено заняття "${_titleController.text.trim()}" на $timeFmt', admin.id);
        }
      }
    } else if (_isRecurring) {
      if (_selectedWeekdays.isEmpty) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Оберіть хоча б один день тижня')),
        );
        return;
      }
      final createdCount = await ref.read(scheduleControllerProvider.notifier).createRecurringClasses(
        title: _titleController.text.trim(),
        startDate: _selectedDate,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        durationMinutes: 60,
        weekdays: _selectedWeekdays,
        durationWeeks: _durationWeeks,
        coachId: _selectedCoach!.id,
        coachName: _selectedCoach!.name,
        maxCapacity: _maxCapacity,
        category: _selectedCategory,
        lane: _selectedLane,
      );

      success = createdCount > 0;
      if (success) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Створено регулярну групу "${_titleController.text.trim()}" на $_durationWeeks тиж. ($createdCount занять)', admin.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Групу "${_titleController.text.trim()}" успішно створено! Згенеровано $createdCount занять у розкладі.'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF00B4D8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      }
    } else {
      success = await ref.read(scheduleControllerProvider.notifier).createClass(
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isEditing
                                ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                                : const [Color(0xFF10B981), Color(0xFF047857)],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: (_isEditing ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isEditing
                                ? LucideIcons.pencil
                                : (_isRecurring ? LucideIcons.users : LucideIcons.calendarPlus),
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'Редагувати заняття'
                                  : (_isRecurring
                                      ? 'admin.group_create_title'.tr()
                                      : 'admin.class_single_title'.tr()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEditing
                                  ? 'Зміна часу та параметрів тренування'
                                  : (_isRecurring
                                      ? 'admin.group_create_subtitle'.tr()
                                      : 'admin.class_single_subtitle'.tr()),
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

                  // Title input (Group Name vs Class Title)
                  _buildLabel(_isRecurring ? 'admin.group_name'.tr() : 'admin.class_name'.tr()),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: _inputDecoration(
                      hint: _isRecurring ? 'admin.group_name_hint'.tr() : 'admin.class_name_hint'.tr(),
                    ),
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
                                      if (_isEditing) {
                                        final target = coachesList.firstWhere(
                                          (c) => c.id == widget.classToEdit!.coachId || c.name.toLowerCase() == widget.classToEdit!.coachName.toLowerCase(),
                                          orElse: () => coachesList.first,
                                        );
                                        setState(() => _selectedCoach = target);
                                      } else if (widget.initialCoachId != null || widget.initialCoachName != null) {
                                        final target = coachesList.firstWhere(
                                          (c) => (widget.initialCoachId != null && c.id == widget.initialCoachId) ||
                                                 (widget.initialCoachName != null && c.name.toLowerCase() == widget.initialCoachName!.toLowerCase()),
                                          orElse: () => coachesList.first,
                                        );
                                        setState(() => _selectedCoach = target);
                                      } else {
                                        setState(() => _selectedCoach = coachesList.first);
                                      }
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

                  // Schedule Mode Selector (Single vs Recurring Year-long)
                  if (!_isEditing) ...[
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                  ],

                  // Date Picker Card
                  _buildLabel(_isRecurring ? 'Дата першого тренування (старт)' : 'admin.class_date'.tr()),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
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
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}', 
                              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Recurring Options: Weekdays, Duration, Preview Banner
                  if (_isRecurring && !_isEditing) ...[
                    const SizedBox(height: 16),
                    _buildWeekdaysSelector(),
                    const SizedBox(height: 16),
                    _buildDurationSelector(),
                    const SizedBox(height: 16),
                    _buildRecurringBanner(),
                  ],
                  const SizedBox(height: 16),

                  // Apple Alarm-style Time Drum Wheel Picker
                  AppleTimeWheelPicker(
                    initialTime: _selectedTime,
                    onTimeChanged: (newTime) {
                      setState(() => _selectedTime = newTime);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pool & Lane selection (Sport pool with lanes vs Kids pool)
                  _buildPoolAndLaneSelector(),
                  const SizedBox(height: 16),

                  // Capacity Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel(_isRecurring ? 'Місткість групи (кількість учнів)' : 'admin.class_students_limit'.tr()),
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
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2)),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isRecurring ? 'Створення групи та $_calculatedRecurringCount занять...' : 'Збереження...',
                                      style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_isEditing ? LucideIcons.check : (_isRecurring ? LucideIcons.users : LucideIcons.sparkles), color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEditing
                                          ? 'Зберегти зміни'
                                          : (_isRecurring
                                              ? 'Створити групу ($_calculatedRecurringCount занять)'
                                              : 'admin.class_create_btn'.tr()),
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

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          // 1. Regular Group (Primary default)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isRecurring = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _isRecurring
                      ? const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isRecurring
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 15,
                      color: _isRecurring ? Colors.white : const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '👥 Постійна група',
                      style: TextStyle(
                        color: _isRecurring ? Colors.white : Colors.white,
                        fontSize: 13,
                        fontWeight: _isRecurring ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Single Class (Alternative option)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isRecurring = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: !_isRecurring
                      ? const LinearGradient(
                          colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isRecurring
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 15,
                      color: !_isRecurring ? Colors.white : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '⏱ Разове заняття',
                      style: TextStyle(
                        color: !_isRecurring ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: !_isRecurring ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdaysSelector() {
    final days = [
      {'id': 1, 'label': 'Пн'},
      {'id': 2, 'label': 'Вт'},
      {'id': 3, 'label': 'Ср'},
      {'id': 4, 'label': 'Чт'},
      {'id': 5, 'label': 'Пт'},
      {'id': 6, 'label': 'Сб'},
      {'id': 7, 'label': 'Нд'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Дні тижня для регулярної групи'),
            Text(
              'Обрано: ${_selectedWeekdays.length}',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((d) {
            final id = d['id'] as int;
            final label = d['label'] as String;
            final isSelected = _selectedWeekdays.contains(id);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedWeekdays.length > 1) {
                          _selectedWeekdays.remove(id);
                        }
                      } else {
                        _selectedWeekdays.add(id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : Colors.white.withValues(alpha: 0.16),
                        width: isSelected ? 1.2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00B4D8).withValues(alpha: 0.45),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getDurationPeriodSummary() {
    switch (_durationWeeks) {
      case 52:
        return 'рік (52 тиж.)';
      case 26:
        return 'пів року (26 тиж.)';
      case 13:
        return '3 місяці (13 тиж.)';
      case 4:
        return '1 місяць (4 тиж.)';
      default:
        return '$_durationWeeks тиж.';
    }
  }

  Widget _buildDurationSelector() {
    final durations = [
      {'weeks': 52, 'title': 'Рік', 'sub': '52 тиж.'},
      {'weeks': 26, 'title': 'Пів року', 'sub': '26 тиж.'},
      {'weeks': 13, 'title': '3 місяці', 'sub': '13 тиж.'},
      {'weeks': 4, 'title': '1 місяць', 'sub': '4 тиж.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Період розкладу'),
        const SizedBox(height: 6),
        Row(
          children: durations.map((dur) {
            final w = dur['weeks'] as int;
            final title = dur['title'] as String;
            final sub = dur['sub'] as String;
            final isSelected = _durationWeeks == w;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _durationWeeks = w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : Colors.white.withValues(alpha: 0.16),
                        width: isSelected ? 1.2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white,
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          style: TextStyle(
                            color: isSelected ? Colors.white.withValues(alpha: 0.92) : Colors.white38,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecurringBanner() {
    final count = _calculatedRecurringCount;
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final weekdaysSummary = _getWeekdaysNamesSummary();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.16),
            const Color(0xFF0284C7).withValues(alpha: 0.10),
            const Color(0xFF0F172A).withValues(alpha: 0.60),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(LucideIcons.users, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Розклад постійної групи',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '$count занять',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Група займатиметься щотижня по $weekdaysSummary о $timeStr на «$_selectedLane». Буде автоматично згенеровано $count занять на ${_getDurationPeriodSummary()}.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolAndLaneSelector() {
    final isSport = _selectedPoolType == 'Спортивний басейн';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Басейн та місце проведення'),
        const SizedBox(height: 2),

        // 1. Primary Pool Type Selector (Дитячий vs Спортивний)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              // Спортивний басейн
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPoolType = 'Спортивний басейн';
                      if (_selectedLane == 'Дитячий басейн') {
                        _selectedLane = 'Доріжка 1';
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSport
                          ? const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSport
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.waves,
                          size: 16,
                          color: isSport ? Colors.white : const Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Спортивний',
                          style: TextStyle(
                            color: isSport ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSport ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Дитячий басейн
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPoolType = 'Дитячий басейн';
                      _selectedLane = 'Дитячий басейн';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: !isSport
                          ? const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: !isSport
                          ? [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.40),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.baby,
                          size: 16,
                          color: !isSport ? Colors.white : Colors.amberAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Дитячий басейн',
                          style: TextStyle(
                            color: !isSport ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: !isSport ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Sub-section: Lanes for Спортивний басейн OR Info Card for Дитячий басейн
        if (isSport) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Оберіть доріжку:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedLane,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sportLanes.map((lane) {
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(LucideIcons.check, size: 13, color: Colors.white),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              lane,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ] else ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Дитячий басейн без поділу на доріжки (мала глибина для дітей)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
