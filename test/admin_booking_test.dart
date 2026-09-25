import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

void main() {
  group('Admin Booking Class Audience & Subscription Tests', () {
    test('GroupClassAudienceX correctly identifies adult vs child vs split', () {
      final adultClass = GroupClass(
        id: '1',
        title: 'Доросла група з плавання',
        startTime: DateTime(2026, 9, 23, 20, 0),
        endTime: DateTime(2026, 9, 23, 20, 45),
        coachId: 'c1',
        coachName: 'Coach',
        maxCapacity: 10,
        category: 'Плавання',
      );

      final childClass = GroupClass(
        id: '2',
        title: 'Дитяча група (9-15 р.)',
        startTime: DateTime(2026, 9, 23, 11, 0),
        endTime: DateTime(2026, 9, 23, 11, 45),
        coachId: 'c1',
        coachName: 'Coach',
        maxCapacity: 7,
        category: 'Плавання',
      );

      final splitClass = GroupClass(
        id: '3',
        title: 'Спліт заняття (2 ос.)',
        startTime: DateTime(2026, 9, 23, 15, 0),
        endTime: DateTime(2026, 9, 23, 15, 45),
        coachId: 'c1',
        coachName: 'Coach',
        maxCapacity: 2,
        category: 'Спліт',
      );

      expect(adultClass.isAdultOnly, isTrue);
      expect(adultClass.isChildOnly, isFalse);
      expect(adultClass.isSplit, isFalse);

      expect(childClass.isChildOnly, isTrue);
      expect(childClass.isAdultOnly, isFalse);
      expect(childClass.ageRange, equals((9, 15)));

      expect(splitClass.isSplit, isTrue);
      expect(splitClass.isChildOnly, isFalse);
      expect(splitClass.isAdultOnly, isFalse);
    });

    test('SubscriptionAudienceX correctly distinguishes adult-only vs child-only', () {
      final adultSub = Subscription(
        id: 's1',
        userId: 'u1',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
        serviceName: 'Дорослий абонемент (8 занять)',
      );

      final childSub = Subscription(
        id: 's2',
        userId: 'u1',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
        serviceName: 'Дитячий абонемент (9-15 років)',
      );

      final aquaSub = Subscription(
        id: 's3',
        userId: 'u1',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
        serviceName: 'Аквааеробіка (8 занять)',
      );

      expect(adultSub.isAdultOnlySubscription, isTrue);
      expect(adultSub.isChildOnlySubscription, isFalse);

      expect(childSub.isChildOnlySubscription, isTrue);
      expect(childSub.isAdultOnlySubscription, isFalse);

      expect(aquaSub.isAdultOnlySubscription, isTrue);
      expect(aquaSub.isChildOnlySubscription, isFalse);
    });
  });
}
