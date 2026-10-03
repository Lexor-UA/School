import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';

void main() {
  group('Coach Chat Selection by Future Classes Logic', () {
    final now = DateTime.now();

    final pastClass = GroupClass(
      id: 'class_past',
      title: 'Минуле тренування',
      coachId: 'coach_past_only',
      coachName: 'Олег Тренер',
      startTime: now.subtract(const Duration(hours: 3)),
      endTime: now.subtract(const Duration(hours: 2)),
      enrolledChildIds: ['child_1'],
      maxCapacity: 6,
      category: 'Плавання',
    );

    final futureClass1 = GroupClass(
      id: 'class_future_1',
      title: 'Плавання для дітей',
      coachId: 'coach_active_1',
      coachName: 'Анна Коваль',
      startTime: now.add(const Duration(days: 1)),
      endTime: now.add(const Duration(days: 1, hours: 1)),
      enrolledChildIds: ['child_1'],
      maxCapacity: 6,
      category: 'Плавання',
    );

    final futureClass2 = GroupClass(
      id: 'class_future_2',
      title: 'Спортивне плавання',
      coachId: 'coach_active_2',
      coachName: 'Максим Сидор',
      startTime: now.add(const Duration(days: 2)),
      endTime: now.add(const Duration(days: 2, hours: 1)),
      enrolledChildIds: ['parent_user_1'], // enrolled parent / adult
      maxCapacity: 6,
      category: 'Плавання',
    );

    final otherFamilyFutureClass = GroupClass(
      id: 'class_other',
      title: 'Інша група',
      coachId: 'coach_other',
      coachName: 'Сергій Вовк',
      startTime: now.add(const Duration(days: 1)),
      endTime: now.add(const Duration(days: 1, hours: 1)),
      enrolledChildIds: ['stranger_child'],
      maxCapacity: 6,
      category: 'Плавання',
    );

    final myFamilyIds = {'parent_user_1', 'child_1'};

    test('Filters out past classes and stranger classes', () {
      final schedule = [pastClass, futureClass1, futureClass2, otherFamilyFutureClass];

      final futureClasses = schedule.where((c) {
        final isFutureOrOngoing = c.endTime.isAfter(now) || c.startTime.isAfter(now);
        if (!isFutureOrOngoing) return false;
        return c.enrolledChildIds.any((id) => myFamilyIds.contains(id));
      }).toList();

      expect(futureClasses.length, equals(2));
      expect(futureClasses.map((c) => c.id).toSet(), equals({'class_future_1', 'class_future_2'}));

      final Map<String, (String coachName, String classTitle, DateTime startTime)> futureCoachesMap = {};
      for (final c in futureClasses) {
        if (c.coachId.isNotEmpty &&
            c.coachName.isNotEmpty &&
            c.coachName != 'Тренер не призначений' &&
            !c.coachName.toLowerCase().contains('не призначен')) {
          if (!futureCoachesMap.containsKey(c.coachId) || c.startTime.isBefore(futureCoachesMap[c.coachId]!.$3)) {
            futureCoachesMap[c.coachId] = (c.coachName, c.title, c.startTime);
          }
        }
      }

      final futureCoachIds = futureCoachesMap.keys.toSet();
      expect(futureCoachIds, equals({'coach_active_1', 'coach_active_2'}));
      expect(futureCoachIds.contains('coach_past_only'), isFalse);
      expect(futureCoachIds.contains('coach_other'), isFalse);
    });

    test('Dialogues with past-only coaches disappear from active coach dialogs', () {
      final futureCoachIds = {'coach_active_1'};

      final activeDialogs = [
        ChatDialog(
          id: 'dialog_coach_past',
          clientId: 'parent_user_1',
          clientName: 'Тато',
          coachId: 'coach_past_only',
          coachName: 'Олег Тренер',
          type: 'coach_client',
          lastMessage: 'Побачимось на занятті',
          lastMessageTime: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        ChatDialog(
          id: 'dialog_coach_active',
          clientId: 'parent_user_1',
          clientName: 'Тато',
          coachId: 'coach_active_1',
          coachName: 'Анна Коваль',
          type: 'coach_client',
          lastMessage: 'Вітаю!',
          lastMessageTime: now.subtract(const Duration(hours: 1)),
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
        ChatDialog(
          id: 'dialog_support',
          clientId: 'parent_user_1',
          clientName: 'Тато',
          type: 'client_admin',
          lastMessage: 'Підтримка',
          lastMessageTime: now,
          updatedAt: now,
        ),
      ];

      final validCoachDialogs = activeDialogs.where((d) {
        return d.type == 'coach_client' &&
            d.coachId != null &&
            futureCoachIds.contains(d.coachId);
      }).toList();

      expect(validCoachDialogs.length, equals(1));
      expect(validCoachDialogs.first.coachId, equals('coach_active_1'));
      // Dialog with past coach disappears!
      expect(validCoachDialogs.any((d) => d.coachId == 'coach_past_only'), isFalse);
    });

    test('When no future classes are booked, futureCoachIds is empty triggering empty state', () {
      final schedule = [pastClass];

      final futureClasses = schedule.where((c) {
        final isFutureOrOngoing = c.endTime.isAfter(now) || c.startTime.isAfter(now);
        if (!isFutureOrOngoing) return false;
        return c.enrolledChildIds.any((id) => myFamilyIds.contains(id));
      }).toList();

      expect(futureClasses.isEmpty, isTrue);

      final Map<String, (String coachName, String classTitle, DateTime startTime)> futureCoachesMap = {};
      for (final c in futureClasses) {
        if (c.coachId.isNotEmpty &&
            c.coachName.isNotEmpty &&
            c.coachName != 'Тренер не призначений' &&
            !c.coachName.toLowerCase().contains('не призначен')) {
          futureCoachesMap[c.coachId] = (c.coachName, c.title, c.startTime);
        }
      }

      final futureCoachIds = futureCoachesMap.keys.toSet();
      expect(futureCoachIds.isEmpty, isTrue);
    });
  });
}
