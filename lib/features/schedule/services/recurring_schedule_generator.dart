import 'package:flutter/foundation.dart';
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

    // O(N) optimization: index existing classes by calendar day key to eliminate quadratic loop hangs
    final Map<String, List<GroupClass>> dayBuckets = {};
    void addToBucket(GroupClass c) {
      final key = '${c.startTime.year}-${c.startTime.month}-${c.startTime.day}';
      (dayBuckets[key] ??= []).add(c);
      if (c.endTime.day != c.startTime.day) {
        final endKey = '${c.endTime.year}-${c.endTime.month}-${c.endTime.day}';
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
        final dayKey = '${utcStart.year}-${utcStart.month}-${utcStart.day}';
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
    // 1. Фільтрація: тільки заняття цієї ж філії, що перетинаються в часі
    final overlapping = classes.where((c) {
      if (excludeClassId != null && c.id == excludeClassId) return false;
      if (c.branchId != branchId) return false;
      return c.startTime.isBefore(endTimeUtc) && c.endTime.isAfter(startTimeUtc);
    }).toList();

    if (overlapping.isEmpty) return null;

    // 2. Перевірка зайнятості тренера (тренер не може бути у двох місцях одночасно)
    final hasCoach = coachId.trim().isNotEmpty && coachId.trim() != 'unassigned';
    if (hasCoach) {
      for (final c in overlapping) {
        if (c.coachId.trim().isNotEmpty && c.coachId.trim() != 'unassigned' && c.coachId == coachId) {
          final timeStr = c.formatBranchTime();
          final laneDisplay = c.lane.isNotEmpty ? c.lane : 'басейн';
          return ClassConflict(
            type: ClassConflictType.coachConflict,
            conflictingClass: c,
            message: 'Тренер ${c.coachName} вже проводить заняття «${c.title}» о $timeStr ($laneDisplay).',
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
            message: 'Один з учасників вже записаний на інше тренування о $timeStr («${c.title}»).',
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
        message: 'Усі $maxPoolLanes доріжок басейну вже зайняті з $timeStr до $endTimeStr.',
      );
    }

    final l1 = lane.trim().toLowerCase();
    final isWholePool1 = l1.contains('весь') || l1.contains('всі') || l1.contains('whole');
    final hasLane1 = lane.trim().isNotEmpty && lane.trim() != 'Будь-яка';

    for (final c in samePoolClasses) {
      final l2 = c.lane.trim().toLowerCase();
      final isWholePool2 = l2.contains('весь') || l2.contains('всі') || l2.contains('whole');
      final hasLane2 = c.lane.trim().isNotEmpty && c.lane.trim() != 'Будь-яка';

      if (isWholePool1 || isWholePool2) {
        final timeStr = c.formatBranchTime();
        final coachNameDisplay = c.coachName.isNotEmpty ? c.coachName : 'не вказано';
        return ClassConflict(
          type: ClassConflictType.laneConflict,
          conflictingClass: c,
          message: isWholePool2
              ? 'Весь басейн вже зайнятий о $timeStr заняттям «${c.title}» (тренер: $coachNameDisplay).'
              : 'Для оренди всього басейну на цей час ($timeStr) не повинно бути інших занять.',
        );
      } else if (hasLane1 && hasLane2 && l1 == l2) {
        final timeStr = c.formatBranchTime();
        final coachNameDisplay = c.coachName.isNotEmpty ? c.coachName : 'не вказано';
        return ClassConflict(
          type: ClassConflictType.laneConflict,
          conflictingClass: c,
          message: 'Доріжка «$lane» вже зайнята о $timeStr заняттям «${c.title}» (тренер: $coachNameDisplay).',
        );
      }
    }

    return null;
  }
}
