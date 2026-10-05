import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/services/branch_data_integrity_validator.dart';
import 'widgets/apple_time_wheel_picker.dart';

enum ClassAudience {
  adult,
  child,
  split,
}

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
  String? _selectedPoolId;
  String _selectedLane = '';

  BranchConfig get _currentBranchConfig {
    final branch = ref.watch(effectiveBranchProvider);
    return BranchConfig.forBranch(branch.id);
  }

  BranchLocation? get _currentLocation {
    final locs = _currentBranchConfig.locations;
    return locs.isNotEmpty ? locs.first : null;
  }

  List<BranchPool> get _availablePools {
    return _currentLocation?.pools ?? const [];
  }

  BranchPool? get _activePool {
    final pools = _availablePools;
    if (_selectedPoolId != null) {
      for (final p in pools) {
        if (p.id == _selectedPoolId) return p;
      }
    }
    return pools.isNotEmpty ? pools.first : null;
  }

  List<String> get _currentLanes {
    final pool = _activePool;
    if (pool == null) return const [];
    return pool.lanes;
  }

  static const unassignedCoach = AppUser(
    id: 'unassigned',
    name: 'Тренер не призначений',
    role: UserRole.coach,
  );

  AppUser? _selectedCoach;

  ClassAudience _selectedAudience = ClassAudience.adult;
  bool _updateEntireSeries = true;

  String _getDefaultTitleFor(ClassAudience audience) {
    switch (audience) {
      case ClassAudience.adult:
        return 'Плавання для дорослих';
      case ClassAudience.child:
        return 'Дитяча група';
      case ClassAudience.split:
        return 'Спліт-тренування (2 особи)';
    }
  }

  bool _isDefaultTitle(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ||
        trimmed == 'Junior Pro' ||
        trimmed == 'Плавання для дорослих' ||
        trimmed == 'Дитяча група' ||
        trimmed == 'Дитяче плавання' ||
        trimmed == 'Спліт-тренування (2 особи)';
  }

  void _setAudience(ClassAudience audience) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAudience = audience;
      if (_isDefaultTitle(_titleController.text)) {
        _titleController.text = _getDefaultTitleFor(audience);
      }
      if (audience == ClassAudience.adult) {
        if (_selectedPoolId != null && _selectedPoolId!.contains('baby')) {
          final p25 = _availablePools.where((p) => !p.id.contains('baby')).firstOrNull;
          if (p25 != null) {
            _selectedPoolId = p25.id;
            if (p25.lanes.isNotEmpty && !p25.lanes.contains(_selectedLane)) {
              _selectedLane = p25.lanes.first;
            }
          }
        }
      } else if (audience == ClassAudience.split) {
        _maxCapacity = 2;
      }
    });
  }

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
      if (c.isSplit) {
        _selectedAudience = ClassAudience.split;
      } else if (c.isAdultOnly) {
        _selectedAudience = ClassAudience.adult;
      } else {
        _selectedAudience = ClassAudience.child;
      }
      final isUnassigned = c.coachId == 'unassigned' ||
          c.coachId.trim().isEmpty ||
          c.coachName.trim().isEmpty ||
          c.coachName == 'Тренер не призначений' ||
          c.coachName.toLowerCase().contains('не призначен');
      if (isUnassigned) {
        _selectedCoach = unassignedCoach;
      } else {
        _selectedCoach = AppUser(
          id: c.coachId.isNotEmpty ? c.coachId : 'unassigned',
          name: c.coachName,
          role: UserRole.coach,
          branchId: c.branchId,
        );
      }
      _titleController = TextEditingController(text: c.title);
      _selectedDate = c.startTime;
      _selectedTime = TimeOfDay(hour: c.startTime.hour, minute: c.startTime.minute);
      _maxCapacity = c.maxCapacity;
      _selectedCategory = _categories.contains(c.category) ? c.category : _categories.first;
      _selectedLane = c.lane;
      _selectedWeekdays = {c.startTime.weekday};
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      if (widget.initialDate != null) {
        _selectedTime = TimeOfDay(hour: widget.initialDate!.hour, minute: widget.initialDate!.minute);
      }
      _selectedWeekdays = {_selectedDate.weekday};
      _selectedAudience = ClassAudience.adult;
      _titleController = TextEditingController(text: _getDefaultTitleFor(_selectedAudience));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();
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
                    onPrimary: Color(0xFF04182B),
                    surface: Color(0xFF0F1E32),
                    onSurface: Colors.white,
                    surfaceContainerHigh: Color(0xFF0F1E32),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0284C7),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
              headerBackgroundColor: isDark ? const Color(0xFF0E3D64) : const Color(0xFF0284C7),
              headerForegroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                  width: 1.3,
                ),
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF04182B);
                }
                if (states.contains(WidgetState.disabled)) {
                  return isDark ? Colors.white24 : Colors.black26;
                }
                return isDark ? Colors.white : const Color(0xFF0F172A);
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF00E5FF);
                }
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.all(const Color(0xFF00E5FF)),
              todayBackgroundColor: WidgetStateProperty.all(const Color(0xFF00E5FF).withValues(alpha: 0.15)),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : const Color(0xFF64748B),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                  width: 1.3,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
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
    if (_isSaving) return;
    if (_titleController.text.trim().isEmpty) return;
    _selectedCoach ??= unassignedCoach;

    _isSaving = true;
    setState(() {});

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

    final isUnassigned = _selectedCoach == null ||
        _selectedCoach!.id == 'unassigned' ||
        _selectedCoach!.name.toLowerCase().contains('не призначен');
    final effectiveCoachId = isUnassigned ? 'unassigned' : _selectedCoach!.id;
    final effectiveCoachName = isUnassigned ? 'Тренер не призначений' : _selectedCoach!.name;

    final activeBranch = ref.read(effectiveBranchProvider);

    // Multi-tenancy integrity guard: coach assignment (TZ Point 30)
    if (!isUnassigned && _selectedCoach != null) {
      final coachCheck = BranchDataIntegrityValidator.validateCoachAssignment(
        coach: _selectedCoach,
        branchId: activeBranch.id,
      );
      if (!coachCheck.isValid) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(coachCheck.errorMessage ?? 'Тренер не має доступу до цієї філії'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
    }

    // Multi-tenancy integrity guard: location and pool (TZ Point 30)
    final poolCheck = BranchDataIntegrityValidator.validateLocationAndPool(
      branchId: activeBranch.id,
      locationId: _currentLocation?.id,
      poolId: _selectedPoolId ?? _activePool?.id,
    );
    if (!poolCheck.isValid) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(poolCheck.errorMessage ?? 'Невірна локація або басейн для цієї філії'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Upfront check for conflict on the chosen date/time/lane/coach
    final upfrontConflict = ref.read(scheduleControllerProvider.notifier).checkClassConflict(
      startTime: startTime,
      endTime: endTime,
      lane: _selectedLane,
      coachId: effectiveCoachId,
      excludeClassId: widget.classToEdit?.id,
      poolId: _selectedPoolId ?? _activePool?.id,
      locationId: _currentLocation?.id,
    );
    if (upfrontConflict != null) {
      if (!_isRecurring || _selectedWeekdays.contains(_selectedDate.weekday)) {
        setState(() => _isSaving = false);
        _showConflictDialog(context, upfrontConflict, isDark);
        return;
      }
    }

    final String effectiveCategory;
    if (_selectedAudience == ClassAudience.adult) {
      effectiveCategory = _selectedCategory == 'Аквааеробіка' ? 'Аквааеробіка' : 'Плавання (Дорослі)';
    } else if (_selectedAudience == ClassAudience.child) {
      effectiveCategory = _selectedCategory == 'Аквааеробіка' ? 'Аквааеробіка' : 'Плавання (Діти)';
    } else {
      effectiveCategory = 'Спліт';
    }

    bool success = false;
    if (_isEditing) {
      final conflict = ref.read(scheduleControllerProvider.notifier).checkClassConflict(
        startTime: startTime,
        endTime: endTime,
        lane: _selectedLane,
        coachId: effectiveCoachId,
        excludeClassId: widget.classToEdit!.id,
        poolId: _selectedPoolId ?? _activePool?.id,
        locationId: _currentLocation?.id,
      );
      if (conflict != null) {
        setState(() => _isSaving = false);
        _showConflictDialog(context, conflict, isDark);
        return;
      }

      if (_updateEntireSeries) {
        final original = widget.classToEdit!;
        await ref.read(scheduleControllerProvider.notifier).updateClassSeries(
          originalTitle: original.title,
          coachId: original.coachId,
          lane: original.lane,
          newTitle: _titleController.text.trim(),
          newCategory: effectiveCategory,
          newMaxCapacity: _maxCapacity,
          newCoachId: effectiveCoachId,
          newCoachName: effectiveCoachName,
          newLane: _selectedLane,
          locationId: _currentLocation?.id,
          poolId: _selectedPoolId ?? _activePool?.id,
        );
      }

      success = await ref.read(scheduleControllerProvider.notifier).updateClass(
        classId: widget.classToEdit!.id,
        title: _titleController.text.trim(),
        startTime: startTime,
        endTime: endTime,
        coachId: effectiveCoachId,
        coachName: effectiveCoachName,
        maxCapacity: _maxCapacity,
        category: effectiveCategory,
        lane: _selectedLane,
        locationId: _currentLocation?.id,
        poolId: _selectedPoolId ?? _activePool?.id,
      );

      if (success) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          final timeFmt = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
          await logAdminAction('Оновлено заняття "${_titleController.text.trim()}" на $timeFmt', admin.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(LucideIcons.check, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Заняття успішно оновлено!'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
          Navigator.pop(context);
        }
        return;
      } else {
        setState(() => _isSaving = false);
        final lastConf = ref.read(scheduleControllerProvider.notifier).lastConflict;
        if (mounted) {
          if (lastConf != null) {
            _showConflictDialog(context, lastConf, isDark);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Не вдалося зберегти зміни. Перевірте зайнятість тренера або доріжки.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          }
        }
        return;
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
        coachId: effectiveCoachId,
        coachName: effectiveCoachName,
        maxCapacity: _maxCapacity,
        category: effectiveCategory,
        lane: _selectedLane,
        locationId: _currentLocation?.id,
        poolId: _selectedPoolId ?? _activePool?.id,
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
        coachId: effectiveCoachId,
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
        coachId: effectiveCoachId,
        coachName: effectiveCoachName,
        maxCapacity: _maxCapacity,
        category: effectiveCategory,
        lane: _selectedLane,
      );

      if (success) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Створено заняття "${_titleController.text.trim()}"', admin.id);
        }
      } else {
        if (!mounted) return;
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
    final activeBranch = ref.watch(effectiveBranchProvider);
    final pools = _availablePools;
    if (_selectedPoolId == null && pools.isNotEmpty) {
      if (_isEditing) {
        final matching = pools.where((p) => p.lanes.contains(_selectedLane)).firstOrNull;
        _selectedPoolId = matching?.id ?? pools.first.id;
      } else {
        _selectedPoolId = pools.first.id;
        if (_selectedLane.isEmpty && pools.first.lanes.isNotEmpty) {
          _selectedLane = pools.first.lanes.first;
        }
      }
    }
    if (_selectedLane.isEmpty && _activePool != null && _activePool!.lanes.isNotEmpty) {
      _selectedLane = _activePool!.lanes.first;
    }

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
                  const Color(0xFF0F1E32).withValues(alpha: 0.96),
                  const Color(0xFF070E1A).withValues(alpha: 0.98),
                ]
              : [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF0F9FF).withValues(alpha: 0.98),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
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
              mediaQuery.viewInsets.bottom + math.max(mediaQuery.padding.bottom, 16) + 12,
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
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Target Audience Selector (Для дорослих / Для дітей / Спліт)
                  _buildLabel('Цільова аудиторія', isDark: isDark),
                  _buildAudienceSelector(isDark: isDark),
                  const SizedBox(height: 16),

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
                  if (_isEditing) ...[
                    const SizedBox(height: 14),
                    _buildUpdateEntireSeriesToggle(isDark: isDark),
                  ],
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
                              data: (rawCoachesList) {
                                final coachesList = rawCoachesList.where((c) =>
                                  c.branchId == activeBranch.id ||
                                  c.branchIds.contains(activeBranch.id)
                                ).toList();

                                final List<AppUser> availableCoaches = [unassignedCoach];
                                if (_selectedCoach != null && _selectedCoach!.id != 'unassigned') {
                                  availableCoaches.add(_selectedCoach!);
                                }
                                for (final coach in coachesList) {
                                  if (!availableCoaches.any((c) => c.id == coach.id)) {
                                    availableCoaches.add(coach);
                                  }
                                }

                                if (_selectedCoach == null) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      if (_isEditing) {
                                        final isClassUnassigned = widget.classToEdit!.coachId == 'unassigned' ||
                                            widget.classToEdit!.coachId.trim().isEmpty ||
                                            widget.classToEdit!.coachName.trim().isEmpty ||
                                            widget.classToEdit!.coachName == 'Тренер не призначений' ||
                                            widget.classToEdit!.coachName.toLowerCase().contains('не призначен');

                                        if (isClassUnassigned) {
                                          setState(() => _selectedCoach = unassignedCoach);
                                        } else {
                                          final target = availableCoaches.firstWhere(
                                            (c) => c.id == widget.classToEdit!.coachId ||
                                                   (widget.classToEdit!.coachName.isNotEmpty &&
                                                    c.name.toLowerCase() == widget.classToEdit!.coachName.toLowerCase()),
                                            orElse: () => _selectedCoach ?? unassignedCoach,
                                          );
                                          setState(() => _selectedCoach = target);
                                        }
                                      } else if (widget.initialCoachId != null || widget.initialCoachName != null) {
                                        final target = availableCoaches.firstWhere(
                                          (c) => (widget.initialCoachId != null && c.id == widget.initialCoachId) ||
                                                 (widget.initialCoachName != null && c.name.toLowerCase() == widget.initialCoachName!.toLowerCase()),
                                          orElse: () => coachesList.isNotEmpty ? coachesList.first : unassignedCoach,
                                        );
                                        setState(() => _selectedCoach = target);
                                      } else {
                                        setState(() => _selectedCoach = coachesList.isNotEmpty ? coachesList.first : unassignedCoach);
                                      }
                                    }
                                  });
                                }
                                return _buildCoachDropdown(_selectedCoach, availableCoaches, (v) => setState(() => _selectedCoach = v!), isDark: isDark);
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
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hasConflict
                                ? const [Color(0xFFEF4444), Color(0xFF7F1D1D)]
                                : (isDark
                                    ? const [Color(0xFF0E3D64), Color(0xFF082038)]
                                    : const [Color(0xFF0284C7), Color(0xFF0369A1)]),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasConflict
                                ? const Color(0xFFF87171)
                                : (isDark ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.60)),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (hasConflict ? const Color(0xFFEF4444) : const Color(0xFF00E5FF)).withValues(alpha: isDark ? 0.30 : 0.20),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSaving
                                ? null
                                : () {
                                    if (hasConflict) {
                                      HapticFeedback.mediumImpact();
                                      _showConflictDialog(context, activeConflict, isDark);
                                    } else {
                                      HapticFeedback.mediumImpact();
                                      _save();
                                    }
                                  },
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
                                          color: hasConflict ? Colors.white : (isDark ? const Color(0xFF00E5FF) : Colors.white),
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
                                            fontWeight: FontWeight.w800,
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
          borderRadius: BorderRadius.circular(18),
          menuMaxHeight: 320,
          elevation: 12,
          dropdownColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
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
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildCoachDropdown(AppUser? value, List<AppUser> items, ValueChanged<AppUser?> onChanged, {required bool isDark}) {
    AppUser? effectiveValue;
    if (value != null) {
      effectiveValue = items.firstWhere(
        (i) => i.id == value.id || (i.name.isNotEmpty && i.name.toLowerCase() == value.name.toLowerCase()),
        orElse: () => items.first,
      );
    } else if (items.isNotEmpty) {
      effectiveValue = items.first;
    }

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
          value: effectiveValue,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          menuMaxHeight: 320,
          elevation: 12,
          dropdownColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
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
          selectedItemBuilder: (context) {
            return items.map((i) {
              final isUnassigned = i.id == 'unassigned';
              final displayName = isUnassigned ? 'Не обрано' : i.name;
              return Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUnassigned) ...[
                      const Icon(LucideIcons.alertCircle, size: 15, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                    ] else ...[
                      Icon(LucideIcons.user, size: 14, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: isUnassigned
                              ? const Color(0xFFD97706)
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          fontWeight: isUnassigned ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          items: items.map((i) {
            final isUnassigned = i.id == 'unassigned';
            return DropdownMenuItem<AppUser>(
              value: i,
              child: Row(
                children: [
                  if (isUnassigned) ...[
                    const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(LucideIcons.user, size: 15, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      isUnassigned ? 'Не обрано (без тренера)' : i.name,
                      style: TextStyle(
                        color: isUnassigned
                            ? const Color(0xFFD97706)
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        fontWeight: isUnassigned ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildModeSelector({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1625) : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: [
          // 1. Regular Group (Primary default)
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isRecurring = true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _isRecurring
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: _isRecurring
                      ? Border.all(color: const Color(0xFF00E5FF), width: 1.3)
                      : Border.all(color: Colors.transparent, width: 1.3),
                  boxShadow: _isRecurring
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                            blurRadius: 10,
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
                      color: _isRecurring ? const Color(0xFF00E5FF) : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF64748B)),
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
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isRecurring = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: !_isRecurring
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: !_isRecurring
                      ? Border.all(color: const Color(0xFF00E5FF), width: 1.3)
                      : Border.all(color: Colors.transparent, width: 1.3),
                  boxShadow: !_isRecurring
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
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
                      color: !_isRecurring ? const Color(0xFF00E5FF) : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Разове заняття',
                      style: TextStyle(
                        color: !_isRecurring
                            ? Colors.white
                            : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                        fontSize: 13,
                        fontWeight: !_isRecurring ? FontWeight.w800 : FontWeight.w600,
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
                    HapticFeedback.selectionClick();
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
                              colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                            )
                          : null,
                      color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : (isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1)),
                        width: isSelected ? 1.3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
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
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _durationWeeks = w);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                            )
                          : null,
                      color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : (isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1)),
                        width: isSelected ? 1.3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                                blurRadius: 8,
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
                                ? const Color(0xFF00E5FF)
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
    final activeBranch = ref.watch(effectiveBranchProvider);
    final location = _currentLocation;
    final pools = _availablePools;
    final activePool = _activePool;
    final currentLanes = _currentLanes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Басейн та місце проведення', isDark: isDark),
            // Branch badge pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.14) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFF7DD3FC),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeBranch.flag,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    location?.name ?? activeBranch.name,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0369A1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1. Primary Pool Selector (Tabs / Pills)
        if (pools.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A1625) : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: pools.map((pool) {
                final isSelected = activePool?.id == pool.id;
                final isWellen = pool.id.contains('wellen') || pool.name.toLowerCase().contains('дитяч') || pool.name.toLowerCase().contains('baby');

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedPoolId = pool.id;
                        final isBaby = pool.id.contains('baby') || pool.name.toLowerCase().contains('дитяч') || pool.name.toLowerCase().contains('wellen');
                        if (isBaby) {
                          _selectedAudience = ClassAudience.child;
                          if (_isDefaultTitle(_titleController.text)) {
                            _titleController.text = _getDefaultTitleFor(ClassAudience.child);
                          }
                        }
                        if (pool.lanes.isNotEmpty && !pool.lanes.contains(_selectedLane)) {
                          _selectedLane = pool.lanes.first;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E5FF)
                              : (isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1)),
                          width: isSelected ? 1.3 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
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
                            isWellen ? LucideIcons.baby : LucideIcons.waves,
                            size: 16,
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              pool.name,
                              maxLines: 2,
                              softWrap: true,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 2. Sub-section: Lanes / Zones Selector
        if (currentLanes.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Оберіть доріжку / зону:',
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
                  _selectedLane.isNotEmpty ? _selectedLane : (currentLanes.first),
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
              children: currentLanes.map((lane) {
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
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedLane = lane);
                      },
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
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                                    ))
                              : null,
                          color: isSelected
                              ? null
                              : (isLaneBusy
                                  ? Colors.orangeAccent.withValues(alpha: isDark ? 0.16 : 0.12)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9))),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (isLaneBusy ? const Color(0xFFF87171) : const Color(0xFF00E5FF))
                                : (isLaneBusy
                                    ? Colors.orangeAccent.withValues(alpha: 0.6)
                                    : (isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1))),
                            width: isSelected || isLaneBusy ? 1.3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (isLaneBusy ? const Color(0xFFEF4444) : const Color(0xFF00E5FF)).withValues(alpha: 0.28),
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
                              Icon(LucideIcons.check, size: 13, color: isLaneBusy ? Colors.white : const Color(0xFF00E5FF)),
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
          const SizedBox(height: 6),
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
                    'Басейн без додаткового поділу на доріжки',
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

  Widget _buildAudienceSelector({required bool isDark}) {
    final pool = _activePool;
    final isBabyPool = pool != null &&
        (pool.id.contains('baby') || pool.name.toLowerCase().contains('дитяч') || pool.name.toLowerCase().contains('wellen'));

    final options = [
      (
        audience: ClassAudience.adult,
        label: 'Для дорослих',
        icon: LucideIcons.user,
        disabled: isBabyPool,
      ),
      (
        audience: ClassAudience.child,
        label: 'Для дітей',
        icon: LucideIcons.baby,
        disabled: false,
      ),
      (
        audience: ClassAudience.split,
        label: 'Спліт',
        icon: LucideIcons.users,
        disabled: isBabyPool,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1625) : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _selectedAudience == opt.audience;
          final flex = switch (opt.audience) {
            ClassAudience.adult => 13,
            ClassAudience.child => 11,
            ClassAudience.split => 9,
          };
          return Expanded(
            flex: flex,
            child: GestureDetector(
              onTap: opt.disabled
                  ? () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Дитячий басейн призначений лише для дитячих тренувань.'),
                          backgroundColor: Colors.orangeAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  : () => _setAudience(opt.audience),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF00E5FF), width: 1.3)
                      : Border.all(color: Colors.transparent, width: 1.3),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: 14,
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : (opt.disabled
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (opt.disabled
                                    ? (isDark ? Colors.white24 : Colors.black26)
                                    : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B))),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpdateEntireSeriesToggle({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _updateEntireSeries
              ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
              : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.repeat, size: 18, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Оновити всю регулярну серію',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Застосувати зміни для всіх занять цієї групи',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _updateEntireSeries,
            activeTrackColor: const Color(0xFF00E5FF),
            activeThumbColor: Colors.white,
            onChanged: (v) => setState(() => _updateEntireSeries = v),
          ),
        ],
      ),
    );
  }
}
