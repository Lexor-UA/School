import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/schedule/models/class_conflict.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/services/recurring_schedule_generator.dart';

void main() {
  group('Stage 10: Automatic Schedule Generator & Branch Timezone Tests (TZ Points 15 & 16)', () {
    test('Generates recurring classes for Vienna in Europe/Vienna at 17:00 local time', () {
      final startDate = DateTime(2026, 6, 2); // Tuesday
      final options = RecurringScheduleOptions(
        title: 'Kinder Schwimmkurs 6-8 J.',
        branchId: 'vienna',
        organizationId: 'cityswim',
        locationId: 'happyland',
        poolId: 'sports_pool',
        lane: 'Lane 1',
        category: 'Kinder',
        coachId: 'coach_maria',
        coachName: 'Coach Maria Huber',
        maxCapacity: 8,
        startDate: startDate,
        hour: 17,
        minute: 0,
        durationMinutes: 60,
        weekdays: {DateTime.tuesday, DateTime.thursday},
        durationWeeks: 4, // 4 weeks = 8 classes (4 Tuesdays + 4 Thursdays)
      );

      final result = RecurringScheduleGenerator.generate(options: options);

      expect(result.createdCount, equals(8));
      expect(result.hasSkipped, isFalse);
      expect(result.conflicts, isEmpty);

      for (final c in result.classesToCreate) {
        expect(c.branchId, equals('vienna'));
        expect(c.organizationId, equals('cityswim'));
        expect(c.locationId, equals('happyland'));
        expect(c.poolId, equals('sports_pool'));
        expect(c.lane, equals('Lane 1'));
        expect(c.timezone, equals('Europe/Vienna'));

        // All classes MUST show 17:00 in Vienna branch local time
        expect(c.formatBranchTime(), equals('17:00'));
        expect(c.branchStartTime.hour, equals(17));
        expect(c.branchStartTime.minute, equals(0));

        // Summer time for Vienna is UTC+2: 17:00 local = 15:00 UTC
        expect(c.startTime.toUtc().hour, equals(15));
      }
    });

    test('DST Transition: Vienna classes remain at 17:00 local time across winter and summer', () {
      // 2026 EU DST begins on Sunday, March 29, 2026.
      // Series starts in February 2026 (Winter, UTC+1) and continues into April 2026 (Summer, UTC+2).
      final winterStart = DateTime(2026, 2, 3); // Tuesday in winter
      final options = RecurringScheduleOptions(
        title: 'Jugend Training 9-15 J.',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
        lane: 'Lane 2',
        category: 'Jugend',
        coachId: 'coach_stefan',
        coachName: 'Coach Stefan Gruber',
        startDate: winterStart,
        hour: 17,
        minute: 0,
        weekdays: {DateTime.tuesday},
        durationWeeks: 10, // from Feb 3 to Apr 7 (crosses March 29 DST)
      );

      final result = RecurringScheduleGenerator.generate(options: options);
      expect(result.createdCount, equals(10));

      final winterClass = result.classesToCreate.firstWhere((c) => c.startTime.month == 2);
      final summerClass = result.classesToCreate.firstWhere((c) => c.startTime.month == 4);

      // In Winter (Feb): Vienna UTC offset is +1 -> 17:00 local is 16:00 UTC
      expect(winterClass.startTime.toUtc().hour, equals(16));
      expect(winterClass.formatBranchTime(), equals('17:00'));
      expect(winterClass.branchStartTime.hour, equals(17));

      // In Summer (Apr): Vienna UTC offset is +2 -> 17:00 local is 15:00 UTC
      expect(summerClass.startTime.toUtc().hour, equals(15));
      expect(summerClass.formatBranchTime(), equals('17:00'));
      expect(summerClass.branchStartTime.hour, equals(17));

      // Both classes reliably show 17:00 to clients and staff in Vienna without shifting!
      expect(result.classesToCreate.every((c) => c.formatBranchTime() == '17:00'), isTrue);
    });

    test('Kyiv Schedule: Zero regression for Kyiv branch (Europe/Kyiv, UTC+2/UTC+3)', () {
      final startDate = DateTime(2026, 1, 12); // Monday (Winter)
      final options = RecurringScheduleOptions(
        title: 'Групове плавання для дітей',
        branchId: 'kyiv',
        organizationId: 'cityswim',
        locationId: 'kyiv_main',
        poolId: 'pool_25m',
        lane: 'Доріжка 1',
        category: 'Плавання',
        coachId: 'coach_igor',
        coachName: 'Ігор Мельник',
        startDate: startDate,
        hour: 18,
        minute: 30,
        durationMinutes: 45,
        weekdays: {DateTime.monday, DateTime.wednesday},
        durationWeeks: 2, // 4 classes
      );

      final result = RecurringScheduleGenerator.generate(options: options);
      expect(result.createdCount, equals(4));

      for (final c in result.classesToCreate) {
        expect(c.branchId, equals('kyiv'));
        expect(c.timezone, equals('Europe/Kyiv'));
        expect(c.formatBranchTime(), equals('18:30'));
        expect(c.branchStartTime.hour, equals(18));
        expect(c.branchStartTime.minute, equals(30));

        // Kyiv winter is UTC+2: 18:30 local = 16:30 UTC
        expect(c.startTime.toUtc().hour, equals(16));
        expect(c.startTime.toUtc().minute, equals(30));
      }
    });

    test('Cross-Branch Lane Isolation: Vienna Lane 1 does NOT conflict with Kyiv Lane 1', () {
      final sharedTimeUtc = DateTime.utc(2026, 6, 2, 15, 0); // 17:00 Vienna, 18:00 Kyiv

      final existingKyivClass = GroupClass(
        id: 'class_kyiv_lane1',
        title: 'Київ Доріжка 1',
        startTime: sharedTimeUtc,
        endTime: sharedTimeUtc.add(const Duration(hours: 1)),
        coachId: 'coach_kyiv',
        coachName: 'Київський тренер',
        maxCapacity: 8,
        category: 'Плавання',
        lane: 'Lane 1',
        branchId: 'kyiv',
        organizationId: 'cityswim',
        locationId: 'kyiv_main',
        poolId: 'pool_25m',
      );

      // Generating class in Vienna on the same lane at the exact same moment
      final options = RecurringScheduleOptions(
        title: 'Відень Lane 1',
        branchId: 'vienna',
        organizationId: 'cityswim',
        locationId: 'happyland',
        poolId: 'sports_pool',
        lane: 'Lane 1',
        category: 'Kinder',
        coachId: 'coach_maria',
        coachName: 'Coach Maria',
        startDate: DateTime(2026, 6, 2),
        hour: 17,
        minute: 0,
        weekdays: {DateTime.tuesday},
        durationWeeks: 1,
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
        existingClasses: [existingKyivClass],
      );

      expect(result.createdCount, equals(1));
      expect(result.hasSkipped, isFalse);
      expect(result.conflicts, isEmpty);
    });

    test('Pool Isolation in Vienna: Classes in Sports Pool do NOT conflict with Wellenbecken', () {
      final sharedTimeUtc = DateTime.utc(2026, 6, 2, 15, 0);

      final wellenbeckenClass = GroupClass(
        id: 'class_vienna_wellenbecken',
        title: 'Aqua Fitness Wellenbecken',
        startTime: sharedTimeUtc,
        endTime: sharedTimeUtc.add(const Duration(hours: 1)),
        coachId: 'coach_anna',
        coachName: 'Anna Trainer',
        maxCapacity: 12,
        category: 'Аквааеробіка',
        lane: 'Zone 1',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'wellenbecken',
      );

      // Now create class in sports_pool on Lane 1 at the same time
      final options = RecurringScheduleOptions(
        title: 'Sports Pool Training',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
        lane: 'Lane 1',
        category: 'Kinder',
        coachId: 'coach_maria',
        coachName: 'Coach Maria',
        startDate: DateTime(2026, 6, 2),
        hour: 17,
        minute: 0,
        weekdays: {DateTime.tuesday},
        durationWeeks: 1,
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
        existingClasses: [wellenbeckenClass],
      );

      expect(result.createdCount, equals(1));
      expect(result.hasSkipped, isFalse);
    });

    test('Same Pool & Same Lane Conflict: Correctly skips conflicting slot and reports conflict', () {
      final classTimeUtc = DateTime.utc(2026, 6, 2, 15, 0); // Tuesday 17:00 Vienna

      final existingClass = GroupClass(
        id: 'existing_class_lane1',
        title: 'Існуюче заняття',
        startTime: classTimeUtc,
        endTime: classTimeUtc.add(const Duration(hours: 1)),
        coachId: 'coach_other',
        coachName: 'Інший тренер',
        maxCapacity: 8,
        category: 'Плавання',
        lane: 'Lane 1',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
      );

      // Try generating a series of 2 Tuesdays at 17:00 on Lane 1
      final options = RecurringScheduleOptions(
        title: 'Нова група на Lane 1',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
        lane: 'Lane 1',
        category: 'Kinder',
        coachId: 'coach_maria',
        coachName: 'Coach Maria',
        startDate: DateTime(2026, 6, 2),
        hour: 17,
        minute: 0,
        weekdays: {DateTime.tuesday},
        durationWeeks: 2, // Tuesday 1 (conflicts) + Tuesday 2 (free)
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
        existingClasses: [existingClass],
      );

      expect(result.createdCount, equals(1)); // 2nd week was created
      expect(result.hasSkipped, isTrue);
      expect(result.skippedDates.length, equals(1));
      expect(result.conflicts.length, equals(1));
      expect(result.conflicts.first.type, equals(ClassConflictType.laneConflict));
      expect(result.conflicts.first.message, contains('Lane 1'));
    });

    test('Whole Pool conflict blocks any lane bookings in the same pool', () {
      final classTimeUtc = DateTime.utc(2026, 6, 2, 15, 0);

      final wholePoolRental = GroupClass(
        id: 'whole_pool_rental',
        title: 'Оренда всього басейну',
        startTime: classTimeUtc,
        endTime: classTimeUtc.add(const Duration(hours: 1)),
        coachId: 'coach_alex',
        coachName: 'Coach Alex',
        maxCapacity: 20,
        category: 'Оренда',
        lane: 'Весь басейн',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
      );

      final options = RecurringScheduleOptions(
        title: 'Спроба бронювання Lane 3',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
        lane: 'Lane 3',
        category: 'Kinder',
        coachId: 'coach_maria',
        coachName: 'Coach Maria',
        startDate: DateTime(2026, 6, 2),
        hour: 17,
        minute: 0,
        weekdays: {DateTime.tuesday},
        durationWeeks: 1,
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
        existingClasses: [wholePoolRental],
      );

      expect(result.createdCount, equals(0));
      expect(result.hasSkipped, isTrue);
      expect(result.conflicts.first.type, equals(ClassConflictType.laneConflict));
      expect(result.conflicts.first.message, contains('Весь басейн'));
    });

    test('Coach Conflict: Same coach cannot teach in two places simultaneously', () {
      final classTimeUtc = DateTime.utc(2026, 6, 2, 15, 0);

      final existingClass = GroupClass(
        id: 'class_coach_stefan',
        title: 'Stefan Sports Pool Class',
        startTime: classTimeUtc,
        endTime: classTimeUtc.add(const Duration(hours: 1)),
        coachId: 'coach_stefan',
        coachName: 'Stefan Gruber',
        maxCapacity: 8,
        category: 'Jugend',
        lane: 'Lane 1',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
      );

      // Attempt to assign coach_stefan to wellenbecken at the same time
      final options = RecurringScheduleOptions(
        title: 'Stefan Wellenbecken Class',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'wellenbecken',
        lane: 'Zone 1',
        category: 'Aqua',
        coachId: 'coach_stefan',
        coachName: 'Stefan Gruber',
        startDate: DateTime(2026, 6, 2),
        hour: 17,
        minute: 0,
        weekdays: {DateTime.tuesday},
        durationWeeks: 1,
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
        existingClasses: [existingClass],
      );

      expect(result.createdCount, equals(0));
      expect(result.hasSkipped, isTrue);
      expect(result.conflicts.first.type, equals(ClassConflictType.coachConflict));
      expect(result.conflicts.first.message, contains('Stefan Gruber'));
    });

    test('Participant Conflict: Child cannot be enrolled in two classes at the same time', () {
      final classTimeUtc = DateTime.utc(2026, 6, 2, 15, 0);

      final existingClass = GroupClass(
        id: 'class_maxi_1',
        title: 'Kinder Group A',
        startTime: classTimeUtc,
        endTime: classTimeUtc.add(const Duration(hours: 1)),
        coachId: 'coach_maria',
        coachName: 'Maria',
        maxCapacity: 8,
        category: 'Kinder',
        lane: 'Lane 1',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
        enrolledChildIds: ['child_maximilian'],
      );

      final options = RecurringScheduleOptions(
        title: 'Kinder Group B',
        branchId: 'vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
        lane: 'Lane 2',
        category: 'Kinder',
        coachId: 'coach_stefan',
        coachName: 'Stefan',
        startDate: DateTime(2026, 6, 2),
        hour: 17,
        minute: 0,
        weekdays: {DateTime.tuesday},
        durationWeeks: 1,
        enrolledChildIds: ['child_maximilian'],
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
        existingClasses: [existingClass],
      );

      expect(result.createdCount, equals(0));
      expect(result.hasSkipped, isTrue);
      expect(result.conflicts.first.type, equals(ClassConflictType.participantConflict));
    });
  });
}
