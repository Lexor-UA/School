import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/schedule/models/class_conflict.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/utils/branch_timezone_helper.dart';

/// Параметри для генерації регулярного розкладу занять у часовому поясі філії
@immutable
class RecurringScheduleOptions {
  final String title;
  final String branchId;
  final String organizationId;
  final String locationId;
  final String poolId;
  final String lane;
  final String category;
  final String coachId;
  final String coachName;
  final int maxCapacity;
  final DateTime startDate;
  final int hour; // 0..23 за місцевим часом філії
  final int minute; // 0..59 за місцевим часом філії
  final int durationMinutes;
  final Set<int> weekdays; // 1..7 (1 = Понеділок ... 7 = Неділя)
  final int durationWeeks;
  final List<String> enrolledChildIds;
  final String Function(DateTime classStartUtc, int index)? idGenerator;

  const RecurringScheduleOptions({
    required this.title,
    required this.branchId,
    this.organizationId = 'cityswim',
    this.locationId = '',
    this.poolId = '',
    this.lane = '',
    required this.category,
    required this.coachId,
    required this.coachName,
    this.maxCapacity = 8,
    required this.startDate,
    required this.hour,
    required this.minute,
    this.durationMinutes = 60,
    required this.weekdays,
    required this.durationWeeks,
    this.enrolledChildIds = const [],
    this.idGenerator,
  });
}

/// Результат роботи генератора регулярних занять
@immutable
class RecurringScheduleResult {
  final List<GroupClass> classesToCreate;
  final List<DateTime> skippedDates; // Локальні дати, пропущені через конфлікти
  final List<ClassConflict> conflicts;

  const RecurringScheduleResult({
    required this.classesToCreate,
    this.skippedDates = const [],
    this.conflicts = const [],
  });

  int get createdCount => classesToCreate.length;
  bool get hasSkipped => skippedDates.isNotEmpty;
}

/// Сервіс генерації повторюваних занять у часовому поясі філії (п. 15, 16 ТЗ)
///
/// Забезпечує:
/// 1. Генерацію занять у строгому локальному часі філії (`Europe/Vienna` для Відня, `Europe/Kyiv` для Києва).
/// 2. Збереження точного часу занять (наприклад, 17:00) при переході на літній/зимовий час (DST).
/// 3. Перевірку конфліктів доріжок у межах одного басейну/філії без хибних конфліктів між філіями або різними басейнами.
class RecurringScheduleGenerator {
  RecurringScheduleGenerator._();

  /// Генерація списку занять відповідно до параметрів та існуючого розкладу
  static RecurringScheduleResult generate({
    required RecurringScheduleOptions options,
    List<GroupClass> existingClasses = const [],
  }) {
    final effectiveTimezone = BranchTimezoneHelper.timezoneForBranch(options.branchId);
    final config = BranchConfig.forBranch(options.branchId);

    // Визначення locationId та poolId за замовчуванням з конфігурації філії
    String effectiveLocationId = options.locationId;
    if (effectiveLocationId.isEmpty && config.locations.isNotEmpty) {
      effectiveLocationId = config.locations.first.id;
    }

    String effectivePoolId = options.poolId;
    if (effectivePoolId.isEmpty && config.locations.isNotEmpty) {
      final loc = config.locations.firstWhere(
        (l) => l.id == effectiveLocationId,
        orElse: () => config.locations.first,
      );
      if (loc.pools.isNotEmpty) {
        effectivePoolId = loc.pools.first.id;
      }
    }

    final safeDurationWeeks = options.durationWeeks.clamp(1, 52);
    final totalDays = safeDurationWeeks * 7;
    final baseDate = DateTime(options.startDate.year, options.startDate.month, options.startDate.day);

    final List<GroupClass> newlyGenerated = [];
    final List<DateTime> skippedDates = [];
    final List<ClassConflict> conflicts = [];

    // O(N) optimization: index existing classes by calendar day key (in UTC) to eliminate quadratic loop hangs
    final Map<String, List<GroupClass>> dayBuckets = {};
    void addToBucket(GroupClass c) {
      final startUtc = c.startTime.isUtc
          ? c.startTime
          : BranchTimezoneHelper.toUtc(c.startTime, c.branchId);
      final endUtc = c.endTime.isUtc
          ? c.endTime
          : BranchTimezoneHelper.toUtc(c.endTime, c.branchId);
      final key = '${startUtc.year}-${startUtc.month}-${startUtc.day}';
      (dayBuckets[key] ??= []).add(c);
      if (endUtc.year != startUtc.year || endUtc.month != startUtc.month || endUtc.day != startUtc.day) {
        final endKey = '${endUtc.year}-${endUtc.month}-${endUtc.day}';
        (dayBuckets[endKey] ??= []).add(c);
      }
    }

    for (final c in existingClasses) {
      if (c.branchId == options.branchId) {
        addToBucket(c);
      }
    }

    int classIndex = 0;

    for (int i = 0; i < totalDays; i++) {
      final date = baseDate.add(Duration(days: i));
      if (options.weekdays.contains(date.weekday)) {
        // 1. Побудова часу за місцевим годинником філії (wall-clock time)
        final localStart = DateTime(date.year, date.month, date.day, options.hour, options.minute);

        // 2. Точна математична конвертація в UTC для збереження з урахуванням DST
        final utcStart = BranchTimezoneHelper.toUtc(localStart, options.branchId);
        final utcEnd = utcStart.add(Duration(minutes: options.durationMinutes));

        // 3. Швидка оцінка конфліктів тільки проти занять у цей же день
        final startUtc = utcStart.toUtc();
        final dayKey = '${startUtc.year}-${startUtc.month}-${startUtc.day}';
        final classesToCheck = dayBuckets[dayKey] ?? const <GroupClass>[];

        final conflict = evaluateConflict(
          classes: classesToCheck,
          startTimeUtc: utcStart,
          endTimeUtc: utcEnd,
          branchId: options.branchId,
          locationId: effectiveLocationId,
          poolId: effectivePoolId,
          lane: options.lane,
          coachId: options.coachId,
          enrolledChildIds: options.enrolledChildIds,
        );

        if (conflict != null) {
          skippedDates.add(localStart);
          conflicts.add(conflict);
        } else {
          final id = options.idGenerator != null
              ? options.idGenerator!(utcStart, classIndex)
              : 'rec_${options.branchId}_${utcStart.millisecondsSinceEpoch}_$classIndex';

          final newClass = GroupClass(
            id: id,
            title: options.title,
            startTime: utcStart,
            endTime: utcEnd,
            coachId: options.coachId,
            coachName: options.coachName,
            maxCapacity: options.maxCapacity,
            enrolledChildIds: options.enrolledChildIds,
            attendedChildIds: const [],
            category: options.category,
            lane: options.lane,
            organizationId: options.organizationId,
            branchId: options.branchId,
            timezone: effectiveTimezone,
            locationId: effectiveLocationId,
            poolId: effectivePoolId,
          );

          newlyGenerated.add(newClass);
          addToBucket(newClass);
          classIndex++;
        }
      }
    }

    return RecurringScheduleResult(
      classesToCreate: newlyGenerated,
      skippedDates: skippedDates,
      conflicts: conflicts,
    );
  }

  static String _resolveTr(String translated, String key, String fallback) {
    return translated == key ? fallback : translated;
  }

  /// Оцінка конфлікту для одного слоту тренування
  static ClassConflict? evaluateConflict({
    required List<GroupClass> classes,
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    required String branchId,
    String? locationId,
    String? poolId,
    required String lane,
    required String coachId,
    String? excludeClassId,
    List<String> enrolledChildIds = const [],
  }) {
    final targetStartUtc = startTimeUtc.isUtc
        ? startTimeUtc
        : BranchTimezoneHelper.toUtc(startTimeUtc, branchId);
    final targetEndUtc = endTimeUtc.isUtc
        ? endTimeUtc
        : BranchTimezoneHelper.toUtc(endTimeUtc, branchId);

    // 1. Фільтрація: тільки заняття цієї ж філії, що перетинаються в часі
    final overlapping = classes.where((c) {
      if (excludeClassId != null && c.id == excludeClassId) return false;
      if (c.branchId != branchId) return false;
      final cStartUtc = c.startTime.isUtc
          ? c.startTime
          : BranchTimezoneHelper.toUtc(c.startTime, c.branchId);
      final cEndUtc = c.endTime.isUtc
          ? c.endTime
          : BranchTimezoneHelper.toUtc(c.endTime, c.branchId);
      return cStartUtc.isBefore(targetEndUtc) && cEndUtc.isAfter(targetStartUtc);
    }).toList();

    if (overlapping.isEmpty) return null;

    // 2. Перевірка зайнятості тренера (тренер не може бути у двох місцях одночасно)
    final hasCoach = coachId.trim().isNotEmpty && coachId.trim() != 'unassigned';
    if (hasCoach) {
      for (final c in overlapping) {
        if (c.coachId.trim().isNotEmpty && c.coachId.trim() != 'unassigned' && c.coachId == coachId) {
          final timeStr = c.formatBranchTime();
          final defaultPool = _resolveTr('schedule.pool_default'.tr(), 'schedule.pool_default', 'pool');
          final laneDisplay = c.lane.isNotEmpty ? c.lane : defaultPool;
          return ClassConflict(
            type: ClassConflictType.coachConflict,
            conflictingClass: c,
            message: _resolveTr(
              'schedule.conflict_coach_busy'.tr(namedArgs: {
                'coach': c.coachName,
                'title': c.title,
                'time': timeStr,
                'lane': laneDisplay,
              }),
              'schedule.conflict_coach_busy',
              'Coach ${c.coachName} is already teaching "${c.title}" at $timeStr ($laneDisplay).',
            ),
          );
        }
      }
    }

    // 3. Перевірка зайнятості учасників (дитина не може бути на двох заняттях одночасно)
    if (enrolledChildIds.isNotEmpty) {
      for (final c in overlapping) {
        if (c.enrolledChildIds.any(enrolledChildIds.contains)) {
          final timeStr = c.formatBranchTime();
          return ClassConflict(
            type: ClassConflictType.participantConflict,
            conflictingClass: c,
            message: _resolveTr(
              'schedule.conflict_participant_busy'.tr(namedArgs: {
                'time': timeStr,
                'title': c.title,
              }),
              'schedule.conflict_participant_busy',
              'Participant is already enrolled in "${c.title}" at $timeStr.',
            ),
          );
        }
      }
    }

    // 4. Перевірка доріжок та басейну (тільки для того ж басейну!)
    final effectivePool = poolId?.trim() ?? '';
    final samePoolClasses = overlapping.where((c) {
      if (effectivePool.isEmpty || c.poolId.isEmpty) return true;
      return c.poolId == effectivePool;
    }).toList();

    // Визначаємо ліміт доріжок для цього басейну з конфігурації
    final config = BranchConfig.forBranch(branchId);
    int maxPoolLanes = 5;
    if (effectivePool.isNotEmpty) {
      for (final loc in config.locations) {
        for (final p in loc.pools) {
          if (p.id == effectivePool && p.lanes.isNotEmpty) {
            maxPoolLanes = p.lanes.length;
            break;
          }
        }
      }
    }

    if (samePoolClasses.length >= maxPoolLanes) {
      final timeStr = BranchTimezoneHelper.formatTime(startTimeUtc, branchId: branchId);
      final endTimeStr = BranchTimezoneHelper.formatTime(endTimeUtc, branchId: branchId);
      return ClassConflict(
        type: ClassConflictType.laneConflict,
        conflictingClass: samePoolClasses.first,
        message: _resolveTr(
          'schedule.conflict_all_lanes_busy'.tr(namedArgs: {
            'count': maxPoolLanes.toString(),
            'start': timeStr,
            'end': endTimeStr,
          }),
          'schedule.conflict_all_lanes_busy',
          'All $maxPoolLanes lanes are busy from $timeStr to $endTimeStr.',
        ),
      );
    }

    final l1 = lane.trim().toLowerCase();
    final isWholePool1 = l1.contains('весь') || l1.contains('всі') || l1.contains('whole') || l1.contains('gesamtes');
    final hasLane1 = lane.trim().isNotEmpty && lane.trim() != 'Будь-яка' && lane.trim() != 'schedule.any_lane'.tr();

    for (final c in samePoolClasses) {
      final l2 = c.lane.trim().toLowerCase();
      final isWholePool2 = l2.contains('весь') || l2.contains('всі') || l2.contains('whole') || l2.contains('gesamtes');
      final hasLane2 = c.lane.trim().isNotEmpty && c.lane.trim() != 'Будь-яка' && c.lane.trim() != 'schedule.any_lane'.tr();

      if (isWholePool1 || isWholePool2) {
        final timeStr = c.formatBranchTime();
        final defaultCoach = _resolveTr('common.not_specified'.tr(), 'common.not_specified', 'N/A');
        final coachNameDisplay = c.coachName.isNotEmpty ? c.coachName : defaultCoach;
        return ClassConflict(
          type: ClassConflictType.laneConflict,
          conflictingClass: c,
          message: isWholePool2
              ? _resolveTr(
                  'schedule.conflict_whole_pool_busy'.tr(namedArgs: {
                    'time': timeStr,
                    'title': c.title,
                    'coach': coachNameDisplay,
                  }),
                  'schedule.conflict_whole_pool_busy',
                  'Whole pool (${c.lane}) is busy at $timeStr with "${c.title}" (coach: $coachNameDisplay).',
                )
              : _resolveTr(
                  'schedule.conflict_whole_pool_requires_empty'.tr(namedArgs: {
                    'time': timeStr,
                  }),
                  'schedule.conflict_whole_pool_requires_empty',
                  'No other classes allowed at $timeStr for whole pool booking.',
                ),
        );
      } else if (hasLane1 && hasLane2 && l1 == l2) {
        final timeStr = c.formatBranchTime();
        final defaultCoach = _resolveTr('common.not_specified'.tr(), 'common.not_specified', 'N/A');
        final coachNameDisplay = c.coachName.isNotEmpty ? c.coachName : defaultCoach;
        return ClassConflict(
          type: ClassConflictType.laneConflict,
          conflictingClass: c,
          message: _resolveTr(
            'schedule.conflict_lane_busy'.tr(namedArgs: {
              'lane': lane,
              'time': timeStr,
              'title': c.title,
              'coach': coachNameDisplay,
            }),
            'schedule.conflict_lane_busy',
            'Lane "$lane" is already busy at $timeStr with "${c.title}" (coach: $coachNameDisplay).',
          ),
        );
      }
    }

    return null;
  }
}
