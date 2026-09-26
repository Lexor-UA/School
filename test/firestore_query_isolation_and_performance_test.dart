import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/services/recurring_schedule_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Audit & Performance Verification Tests', () {
    test('1. RecurringScheduleGenerator 52-Week (1 Year) Generation & Bucket Index Performance', () {
      final startDate = DateTime.utc(2026, 1, 5, 10, 0); // Monday

      // Seed 100 existing classes in Kyiv and Vienna
      final List<GroupClass> existing = [];
      for (int i = 0; i < 50; i++) {
        existing.add(GroupClass(
          id: 'exist_k_$i',
          title: 'Kyiv Class $i',
          startTime: startDate.add(Duration(days: i, hours: 2)),
          endTime: startDate.add(Duration(days: i, hours: 3)),
          coachId: 'coach_k',
          coachName: 'Kyiv Coach',
          maxCapacity: 8,
          category: 'group',
          lane: 'Lane 1',
          branchId: 'kyiv',
          timezone: 'Europe/Kyiv',
        ));
        existing.add(GroupClass(
          id: 'exist_v_$i',
          title: 'Vienna Class $i',
          startTime: startDate.add(Duration(days: i, hours: 2)),
          endTime: startDate.add(Duration(days: i, hours: 3)),
          coachId: 'coach_v',
          coachName: 'Vienna Coach',
          maxCapacity: 8,
          category: 'group',
          lane: 'Lane 1',
          branchId: 'vienna',
          timezone: 'Europe/Vienna',
        ));
      }

      final stopwatch = Stopwatch()..start();

      // Generate 52 weeks (1 full year) for Vienna on Mon, Wed, Fri (156 classes)
      final options = RecurringScheduleOptions(
        title: 'Vienna Mon/Wed/Fri Pro',
        branchId: 'vienna',
        category: 'group',
        coachId: 'coach_v_new',
        coachName: 'Vienna Pro Coach',
        startDate: startDate,
        hour: 17,
        minute: 0,
        durationMinutes: 60,
        weekdays: {1, 3, 5},
        durationWeeks: 52, // 1 full year as required by user
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
        existingClasses: existing,
      );

      stopwatch.stop();

      // 52 weeks * 3 days = 156 classes
      expect(result.createdCount, 156);
      expect(result.conflicts.isEmpty, isTrue);

      // Must complete rapidly (under 200ms) with the O(N) day-bucket index optimization
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      // All classes must strictly belong to Vienna branch
      expect(result.classesToCreate.every((c) => c.branchId == 'vienna'), isTrue);
    });

    test('2. Conflict detection works accurately in day-indexed bucket', () {
      final startDate = DateTime.utc(2026, 2, 2, 10, 0); // Monday

      final conflictingClass = GroupClass(
        id: 'conflict_target',
        title: 'Blocked Slot',
        startTime: DateTime.utc(2026, 2, 2, 17, 0), // 17:00 UTC (18:00 Vienna)
        endTime: DateTime.utc(2026, 2, 2, 18, 0),
        coachId: 'coach_v_busy',
        coachName: 'Busy Coach',
        maxCapacity: 8,
        category: 'group',
        lane: 'Lane 1',
        branchId: 'vienna',
        timezone: 'Europe/Vienna',
      );

      final options = RecurringScheduleOptions(
        title: 'Colliding Class',
        branchId: 'vienna',
        category: 'group',
        coachId: 'coach_v_busy', // Same coach -> must conflict
        coachName: 'Busy Coach',
        startDate: startDate,
        hour: 18, // 18:00 Vienna = 17:00 UTC
        minute: 0,
        durationMinutes: 60,
        weekdays: {1}, // Monday
        durationWeeks: 4,
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
        existingClasses: [conflictingClass],
      );

      // First Monday was skipped due to coach collision
      expect(result.skippedDates.length, 1);
      expect(result.conflicts.length, 1);
      expect(result.createdCount, 3);
    });

    test('3. firestore.indexes.json exists, is valid JSON, and defines composite indexes', () {
      final indexFile = File('firestore.indexes.json');
      expect(indexFile.existsSync(), isTrue);

      final content = indexFile.readAsStringSync();
      final Map<String, dynamic> json = jsonDecode(content);

      expect(json.containsKey('indexes'), isTrue);
      final indexes = json['indexes'] as List;
      expect(indexes.length, greaterThanOrEqualTo(6));

      // Check classes branchId + startTime index
      final hasClassIndex = indexes.any((idx) {
        final collection = idx['collectionGroup'];
        final fields = (idx['fields'] as List).map((f) => f['fieldPath']).toList();
        return collection == 'classes' && fields.contains('branchId') && fields.contains('startTime');
      });
      expect(hasClassIndex, isTrue);

      // Check subscriptions branchId + isActive index
      final hasSubIndex = indexes.any((idx) {
        final collection = idx['collectionGroup'];
        final fields = (idx['fields'] as List).map((f) => f['fieldPath']).toList();
        return collection == 'subscriptions' && fields.contains('branchId') && fields.contains('isActive');
      });
      expect(hasSubIndex, isTrue);
    });

    test('4. firebase.json correctly references firestore.rules and firestore.indexes.json', () {
      final firebaseConfigFile = File('firebase.json');
      expect(firebaseConfigFile.existsSync(), isTrue);

      final content = firebaseConfigFile.readAsStringSync();
      final Map<String, dynamic> json = jsonDecode(content);

      expect(json.containsKey('firestore'), isTrue);
      expect(json['firestore']['rules'], 'firestore.rules');
      expect(json['firestore']['indexes'], 'firestore.indexes.json');
    });

    test('5. firestore.rules contains hasUserData and isSuperAdmin safeguards', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final content = rulesFile.readAsStringSync();
      expect(content.contains('function hasUserData()'), isTrue);
      expect(content.contains('function isSuperAdmin()'), isTrue);
      expect(content.contains('request.auth.token.role == \'superAdmin\''), isTrue);
    });
  });
}
