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
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/schedule/models/class_conflict.dart';
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
  final List<String> _categories = ['Плавання', 'Аквааеробіка'];

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

  String _formatClassesCount(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) {
      return '$count занять';
    }
    if (mod10 == 1) {
      return '$count заняття';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$count заняття';
    }
    return '$count занять';
  }

  String _formatSpotsCount(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) {
      return '$count місць';
    }
    if (mod10 == 1) {
      return '$count місце';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$count місця';
    }
    return '$count місць';
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
      _selectedCategory = _categories.contains(c.category) ? c.category : _categories.first;
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
    final isDark = ref.read(appThemeControllerProvider).isDark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF00E5FF),
                    onPrimary: Colors.black,
                    surface: Color(0xFF162D4A),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0284C7),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? const Color(0xFF162D4A) : Colors.white,
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

  ClassConflict? _checkConflictFor({
    required String lane,
    required DateTime date,
    required TimeOfDay time,
    String? coachId,
  }) {
    final startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final endTime = startTime.add(const Duration(hours: 1));
    return ref.read(scheduleControllerProvider.notifier).checkClassConflict(
      startTime: startTime,
      endTime: endTime,
      lane: lane,
      coachId: coachId ?? (_selectedCoach?.id ?? ''),
      excludeClassId: widget.classToEdit?.id,
    );
  }

  void _showConflictDialog(BuildContext context, ClassConflict conflict, bool isDark, {String? extraInfo}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.amberAccent.withValues(alpha: isDark ? 0.4 : 0.6),
            width: 1.2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: isDark ? 0.2 : 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.triangleAlert, color: Colors.amberAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                conflict.type == ClassConflictType.laneConflict
                    ? 'Конфлікт доріжки'
                    : (conflict.type == ClassConflictType.coachConflict
                        ? 'Конфлікт тренера'
                        : 'Конфлікт у розкладі'),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conflict.message,
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            if (extraInfo != null) ...[
              const SizedBox(height: 10),
              Text(
                extraInfo,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Будь ласка, оберіть іншу вільну доріжку, змініть час або призначте іншого тренера.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'admin.close'.tr(),
              style: TextStyle(
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
    final themeConfig = ref.read(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    // Upfront check for conflict on the chosen date/time/lane/coach
    final upfrontConflict = ref.read(scheduleControllerProvider.notifier).checkClassConflict(
      startTime: startTime,
      endTime: endTime,
      lane: _selectedLane,
      coachId: _selectedCoach!.id,
      excludeClassId: widget.classToEdit?.id,
    );
    if (upfrontConflict != null) {
      if (!_isRecurring || _selectedWeekdays.contains(_selectedDate.weekday)) {
        setState(() => _isSaving = false);
        _showConflictDialog(context, upfrontConflict, isDark);
        return;
      }
    }

    bool success = false;
    if (_isEditing) {
      final conflict = ref.read(scheduleControllerProvider.notifier).checkClassConflict(
        startTime: startTime,
        endTime: endTime,
        lane: _selectedLane,
        coachId: _selectedCoach!.id,
        excludeClassId: widget.classToEdit!.id,
      );
      if (conflict != null) {
        setState(() => _isSaving = false);
        _showConflictDialog(context, conflict, isDark);
        return;
      }

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
          SnackBar(content: Text('admin.select_weekdays_warning'.tr())),
        );
        return;
      }
      final result = await ref.read(scheduleControllerProvider.notifier).createRecurringClasses(
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

      if (result.createdCount == 0 && result.hasSkipped) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        _showConflictDialog(
          context,
          result.conflicts.first,
          isDark,
          extraInfo: 'Усі обрані дати серії (${result.skippedDates.length}) мають конфлікт із зайнятою доріжкою або тренером. Жодного заняття не створено.',
        );
        return;
      }

      success = result.createdCount > 0;
      if (success) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Створено регулярну групу "${_titleController.text.trim()}" на $_durationWeeks тиж. (${_formatClassesCount(result.createdCount)})', admin.id);
        }
        if (mounted) {
          if (result.hasSkipped) {
            final skippedDatesStr = result.skippedDates.take(3).map((d) => DateFormat('d MMMM', 'uk').format(d)).join(', ');
            final moreCount = result.skippedDates.length > 3 ? ' та ще ${result.skippedDates.length - 3}' : '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Створено ${result.createdCount} занять. Пропущено ${result.skippedDates.length} дат через зайнятість ($skippedDatesStr$moreCount).',
                ),
                backgroundColor: Colors.orangeAccent,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('admin.group_created_success'.tr(namedArgs: {
                        'name': _titleController.text.trim(),
                        'count': '${result.createdCount}',
                      })),
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
      }
    } else {
      final conflict = ref.read(scheduleControllerProvider.notifier).checkClassConflict(
        startTime: startTime,
        endTime: endTime,
        lane: _selectedLane,
        coachId: _selectedCoach!.id,
      );
      if (conflict != null) {
        setState(() => _isSaving = false);
        _showConflictDialog(context, conflict, isDark);
        return;
      }

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
      } else {
        setState(() => _isSaving = false);
        final lastConf = ref.read(scheduleControllerProvider.notifier).lastConflict;
        if (lastConf != null && mounted) {
          _showConflictDialog(context, lastConf, isDark);
        }
        return;
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachesAsync = ref.watch(coachesProvider);
    ref.watch(scheduleControllerProvider);
    final mediaQuery = MediaQuery.of(context);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.92,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.22),
                  const Color(0xFF0284C7).withValues(alpha: 0.26),
                  const Color(0xFF0A223D).withValues(alpha: 0.55),
                ]
              : [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF0F9FF).withValues(alpha: 0.98),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF003B73).withValues(alpha: 0.35)
                : const Color(0xFF0284C7).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.20 : 0.08),
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
                        color: isDark ? Colors.white.withValues(alpha: 0.30) : const Color(0xFF94A3B8),
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
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                              style: TextStyle(
                                color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
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
                          color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : const Color(0xFF475569), size: 17),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Title input (Group Name vs Class Title)
                  _buildLabel(_isRecurring ? 'admin.group_name'.tr() : 'admin.class_name'.tr(), isDark: isDark),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      hint: _isRecurring ? 'admin.group_name_hint'.tr() : 'admin.class_name_hint'.tr(),
                      isDark: isDark,
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
                            _buildLabel('admin.class_category'.tr(), isDark: isDark),
                            _buildDropdown(_selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!), isDark: isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('admin.class_coach'.tr(), isDark: isDark),
                            coachesAsync.when(
                              data: (coachesList) {
                                if (coachesList.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1B385D) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFE2E8F0)),
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
                                return _buildCoachDropdown(_selectedCoach, coachesList, (v) => setState(() => _selectedCoach = v!), isDark: isDark);
                              },
                              loading: () => Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1B385D) : const Color(0xFFF1F5F9),
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
                    _buildModeSelector(isDark: isDark),
                    const SizedBox(height: 16),
                  ],

                  // Date Picker Card
                  _buildLabel(_isRecurring ? 'Дата першого тренування (старт)' : 'admin.class_date'.tr(), isDark: isDark),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
                            width: 1.2,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF003B73).withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.22) : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.calendar,
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}', 
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.chevronRight,
                              color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Recurring Options: Weekdays, Duration, Preview Banner
                  if (_isRecurring && !_isEditing) ...[
                    const SizedBox(height: 16),
                    _buildWeekdaysSelector(isDark: isDark),
                    const SizedBox(height: 16),
                    _buildDurationSelector(isDark: isDark),
                    const SizedBox(height: 16),
                    _buildRecurringBanner(isDark: isDark),
                  ],
                  const SizedBox(height: 16),

                  // Apple Alarm-style Time Drum Wheel Picker
                  AppleTimeWheelPicker(
                    initialTime: _selectedTime,
                    isDark: isDark,
                    onTimeChanged: (newTime) {
                      setState(() => _selectedTime = newTime);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pool & Lane selection (Sport pool with lanes vs Kids pool)
                  _buildPoolAndLaneSelector(isDark: isDark),
                  const SizedBox(height: 16),

                  // Capacity Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel(_isRecurring ? 'Місткість групи (кількість учнів)' : 'admin.class_students_limit'.tr(), isDark: isDark),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFF38BDF8),
                          ),
                        ),
                        child: Text(
                          _formatSpotsCount(_maxCapacity),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFCBD5E1),
                      thumbColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      overlayColor: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.18),
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

                  // Submit Button with reactive Conflict Warning Awareness
                  Builder(
                    builder: (context) {
                      final activeConflict = _checkConflictFor(
                        lane: _selectedLane,
                        date: _selectedDate,
                        time: _selectedTime,
                        coachId: _selectedCoach?.id,
                      );
                      final hasConflict = activeConflict != null &&
                          (!_isRecurring || _selectedWeekdays.contains(_selectedDate.weekday));

                      return Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hasConflict
                                ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                                : const [Color(0xFF00D2FF), Color(0xFF0077B6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: hasConflict ? 0.60 : 0.40),
                            width: hasConflict ? 1.4 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (hasConflict ? const Color(0xFFEF4444) : const Color(0xFF00B4D8)).withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSaving
                                ? null
                                : (hasConflict
                                    ? () => _showConflictDialog(context, activeConflict, isDark)
                                    : _save),
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: _isSaving
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2)),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isRecurring ? 'Створення групи (${_formatClassesCount(_calculatedRecurringCount)})...' : 'Збереження...',
                                          style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          hasConflict
                                              ? LucideIcons.triangleAlert
                                              : (_isEditing ? LucideIcons.check : (_isRecurring ? LucideIcons.users : LucideIcons.sparkles)),
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          hasConflict
                                              ? (activeConflict.type == ClassConflictType.laneConflict
                                                  ? 'Доріжка зайнята (Конфлікт)'
                                                  : 'Тренер зайнятий (Конфлікт)')
                                              : (_isEditing
                                                  ? 'Зберегти зміни'
                                                  : (_isRecurring
                                                      ? 'Створити групу (${_formatClassesCount(_calculatedRecurringCount)})'
                                                      : 'admin.class_create_btn'.tr())),
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
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7.0, left: 2),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.90) : const Color(0xFF0F172A),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, required bool isDark}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.38) : const Color(0xFF64748B),
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged, {required bool isDark}) {
    final effectiveValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF003B73).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF0E2544) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          icon: Icon(
            LucideIcons.chevronDown,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
            size: 18,
          ),
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(
              _getCategoryLabel(i),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCoachDropdown(AppUser? value, List<AppUser> items, ValueChanged<AppUser?> onChanged, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF003B73).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppUser>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF0E2544) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          icon: Icon(
            LucideIcons.chevronDown,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
            size: 18,
          ),
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(
              i.name,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildModeSelector({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFCBD5E1),
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
                      color: _isRecurring ? Colors.white : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Постійна група',
                      style: TextStyle(
                        color: _isRecurring
                            ? Colors.white
                            : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
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
                      color: !_isRecurring
                          ? Colors.white
                          : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Разове заняття',
                      style: TextStyle(
                        color: !_isRecurring
                            ? Colors.white
                            : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                        fontSize: 13,
                        fontWeight: !_isRecurring ? FontWeight.w700 : FontWeight.w600,
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

  Widget _buildWeekdaysSelector({required bool isDark}) {
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
            _buildLabel('Дні тижня для регулярної групи', isDark: isDark),
            Text(
              'Обрано: ${_selectedWeekdays.length}',
              style: TextStyle(
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                      color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : (isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFCBD5E1)),
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
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155)),
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
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

  Widget _buildDurationSelector({required bool isDark}) {
    final durations = [
      {'weeks': 52, 'title': 'Рік', 'sub': '52 тиж.'},
      {'weeks': 26, 'title': 'Пів року', 'sub': '26 тиж.'},
      {'weeks': 13, 'title': '3 місяці', 'sub': '13 тиж.'},
      {'weeks': 4, 'title': '1 місяць', 'sub': '4 тиж.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Період розкладу', isDark: isDark),
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
                      color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : (isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFCBD5E1)),
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
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.92)
                                : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569)),
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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

  Widget _buildRecurringBanner({required bool isDark}) {
    final count = _calculatedRecurringCount;
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final weekdaysSummary = _getWeekdaysNamesSummary();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.14),
                  const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  const Color(0xFF0284C7).withValues(alpha: 0.20),
                ]
              : [
                  const Color(0xFFE0F2FE),
                  const Color(0xFFF0F9FF),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF00E5FF).withValues(alpha: 0.50)
              : const Color(0xFF38BDF8).withValues(alpha: 0.60),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.18 : 0.10),
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
                    Text(
                      'Розклад постійної групи',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                            : const Color(0xFFBAE6FD).withValues(alpha: 0.50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                              : const Color(0xFF0284C7).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _formatClassesCount(count),
                        style: TextStyle(
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Група займатиметься щотижня по $weekdaysSummary о $timeStr на «$_selectedLane». Буде автоматично згенеровано ${_formatClassesCount(count)} на ${_getDurationPeriodSummary()}.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolAndLaneSelector({required bool isDark}) {
    final isSport = _selectedPoolType == 'Спортивний басейн';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Басейн та місце проведення', isDark: isDark),
        const SizedBox(height: 2),

        // 1. Primary Pool Type Selector (Дитячий vs Спортивний)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFCBD5E1),
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
                          color: isSport ? Colors.white : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Спортивний',
                          style: TextStyle(
                            color: isSport
                                ? Colors.white
                                : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                            fontSize: 13,
                            fontWeight: isSport ? FontWeight.w800 : FontWeight.w600,
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
                          color: !isSport ? Colors.white : (isDark ? Colors.amberAccent : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Дитячий басейн',
                          style: TextStyle(
                            color: !isSport
                                ? Colors.white
                                : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                            fontSize: 13,
                            fontWeight: !isSport ? FontWeight.w800 : FontWeight.w600,
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
                  color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedLane,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                final conflictForThisLane = _checkConflictFor(
                  lane: lane,
                  date: _selectedDate,
                  time: _selectedTime,
                  coachId: '',
                );
                final isLaneBusy = conflictForThisLane?.type == ClassConflictType.laneConflict;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedLane = lane),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? (isLaneBusy
                                  ? const LinearGradient(
                                      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                                    ))
                              : null,
                          color: isSelected
                              ? null
                              : (isLaneBusy
                                  ? Colors.orangeAccent.withValues(alpha: isDark ? 0.16 : 0.12)
                                  : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9))),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (isLaneBusy ? const Color(0xFFF87171) : const Color(0xFF00E5FF))
                                : (isLaneBusy
                                    ? Colors.orangeAccent.withValues(alpha: 0.6)
                                    : (isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFCBD5E1))),
                            width: isLaneBusy ? 1.3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (isLaneBusy ? const Color(0xFFEF4444) : const Color(0xFF00B4D8)).withValues(alpha: 0.45),
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
                              isLaneBusy ? '$lane ⚠️' : lane,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isLaneBusy
                                        ? (isDark ? Colors.orangeAccent : const Color(0xFFD97706))
                                        : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155))),
                                fontSize: 13,
                                fontWeight: (isSelected || isLaneBusy) ? FontWeight.w700 : FontWeight.w600,
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
              color: isDark ? const Color(0xFF1B385D).withValues(alpha: 0.55) : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.30) : const Color(0xFFBAE6FD),
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
                      color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF0369A1),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Active conflict warning banner
        Builder(
          builder: (context) {
            final activeConflict = _checkConflictFor(
              lane: _selectedLane,
              date: _selectedDate,
              time: _selectedTime,
              coachId: _selectedCoach?.id,
            );
            if (activeConflict == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: isDark ? 0.22 : 0.12),
                    const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.16 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.6),
                  width: 1.1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.triangleAlert, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeConflict.type == ClassConflictType.laneConflict
                              ? 'Доріжка вже зайнята в цей час!'
                              : (activeConflict.type == ClassConflictType.coachConflict
                                  ? 'Тренер вже веде інше заняття в цей час!'
                                  : 'Конфлікт у розкладі!'),
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activeConflict.message,
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF78350F),
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
