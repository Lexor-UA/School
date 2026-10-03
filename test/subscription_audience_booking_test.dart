import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
    );
  }

  group('SubscriptionAudienceX Classification Tests', () {
    test('PREMIUM PASS is classified as universal subscription', () {
      final sub = Subscription(
        id: 'sub_1',
        userId: 'user_oleksandr',
        serviceName: 'PREMIUM PASS',
        ownerName: 'Oleksandr Spiian',
        totalClasses: 8,
        remainingClasses: 7,
        isActive: true,
      );

      expect(sub.isUniversalSubscription, isTrue);
      expect(sub.isAdultOnlySubscription, isFalse);
      expect(sub.isChildOnlySubscription, isFalse);
      expect(sub.isChildSubscription, isFalse);
      expect(sub.isSplitSubscription, isFalse);
      expect(sub.isGroupSubscription, isTrue);
    });

    test('Standard "8 занять" is classified as universal subscription', () {
      final sub = Subscription(
        id: 'sub_2',
        userId: 'user_1',
        serviceName: 'Абонемент на 8 занять',
        ownerName: 'Іван Іванов',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
      );

      expect(sub.isUniversalSubscription, isTrue);
      expect(sub.isAdultOnlySubscription, isFalse);
      expect(sub.isChildOnlySubscription, isFalse);
      expect(sub.isChildSubscription, isFalse);
    });

    test('Child subscription with age range is classified as child-only', () {
      final sub = Subscription(
        id: 'sub_3',
        userId: 'user_1',
        serviceName: 'Дитячий абонемент 6-8 років (4 тренування)',
        ownerName: 'Максим',
        totalClasses: 4,
        remainingClasses: 4,
        isActive: true,
      );

      expect(sub.isChildOnlySubscription, isTrue);
      expect(sub.isChildSubscription, isTrue);
      expect(sub.isAdultSubscription, isFalse);
      expect(sub.isUniversalSubscription, isFalse);
    });

    test('Adult subscription is classified as adult-only', () {
      final sub = Subscription(
        id: 'sub_4',
        userId: 'user_1',
        serviceName: 'Абонемент на 4 тренування (Доросла група)',
        ownerName: 'Олена',
        totalClasses: 4,
        remainingClasses: 4,
        isActive: true,
      );

      expect(sub.isAdultOnlySubscription, isTrue);
      expect(sub.isAdultSubscription, isTrue);
      expect(sub.isChildOnlySubscription, isFalse);
      expect(sub.isChildSubscription, isFalse);
      expect(sub.isUniversalSubscription, isFalse);
    });
  });

  group('SubscriptionController getSubscriptionForOwner audience matching tests', () {
    test('Adult with PREMIUM PASS and "(Я)" suffix resolves subscription correctly', () {
      final container = createContainer();
      final controller = container.read(subscriptionControllerProvider.notifier);

      final oleksandrSub = Subscription(
        id: 'sub_premium_pass',
        userId: 'user_oleksandr',
        serviceName: 'PREMIUM PASS',
        ownerName: 'Oleksandr Spiian',
        totalClasses: 8,
        remainingClasses: 7,
        isActive: true,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );

      // Inject subscription into controller state
      controller.state = [oleksandrSub];

      // Exact match with "(Я)" suffix passed by the UI picker
      final resolvedWithSuffix = controller.getSubscriptionForOwner(
        'user_oleksandr',
        'Oleksandr Spiian (Я)',
        isAdult: true,
        isSplit: false,
      );

      expect(resolvedWithSuffix, isNotNull);
      expect(resolvedWithSuffix?.id, equals('sub_premium_pass'));
      expect(resolvedWithSuffix?.serviceName, equals('PREMIUM PASS'));

      // Exact match without suffix
      final resolvedDirect = controller.getSubscriptionForOwner(
        'user_oleksandr',
        'Oleksandr Spiian',
        isAdult: true,
        isSplit: false,
      );

      expect(resolvedDirect, isNotNull);
      expect(resolvedDirect?.id, equals('sub_premium_pass'));
    });

    test('Adult cannot use child-only subscription even if name matches', () {
      final container = createContainer();
      final controller = container.read(subscriptionControllerProvider.notifier);

      final childSub = Subscription(
        id: 'sub_child',
        userId: 'user_adult',
        serviceName: 'Дитячий абонемент 6-8 років',
        ownerName: 'Oleksandr Spiian',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
      );

      controller.state = [childSub];

      final result = controller.getSubscriptionForOwner(
        'user_adult',
        'Oleksandr Spiian',
        isAdult: true,
        isSplit: false,
      );

      expect(result, isNull);
    });

    test('Child cannot use adult-only subscription even if name matches', () {
      final container = createContainer();
      final controller = container.read(subscriptionControllerProvider.notifier);

      final adultSub = Subscription(
        id: 'sub_adult',
        userId: 'user_adult',
        serviceName: 'Абонемент для дорослих',
        ownerName: 'Максим',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
      );

      controller.state = [adultSub];

      final result = controller.getSubscriptionForOwner(
        'user_adult',
        'Максим',
        isAdult: false,
        isSplit: false,
      );

      expect(result, isNull);
    });
  });

  group('SubscriptionController canSubscriptionBeUsedForClass audience tests', () {
    final now = DateTime.now();

    final adultClass = GroupClass(
      id: 'class_adult',
      title: 'Плавання для дорослих',
      category: 'Доросла група',
      startTime: now.add(const Duration(hours: 2)),
      endTime: now.add(const Duration(hours: 3)),
      branchId: 'kyiv',
      coachId: 'coach_1',
      coachName: 'Тренер',
      lane: 'Lane 1',
      maxCapacity: 6,
    );

    final childClass = GroupClass(
      id: 'class_child',
      title: 'Дитяча група (6-8 років)',
      category: 'Дитяча група',
      startTime: now.add(const Duration(hours: 2)),
      endTime: now.add(const Duration(hours: 3)),
      branchId: 'kyiv',
      coachId: 'coach_1',
      coachName: 'Тренер',
      lane: 'Lane 1',
      maxCapacity: 6,
    );

    final universalSub = Subscription(
      id: 'sub_uni',
      userId: 'user_1',
      serviceName: 'PREMIUM PASS',
      branchId: 'kyiv',
      totalClasses: 8,
      remainingClasses: 7,
      isActive: true,
    );

    final childSub = Subscription(
      id: 'sub_child',
      userId: 'user_1',
      serviceName: 'Дитячий абонемент 6-8 років',
      branchId: 'kyiv',
      totalClasses: 8,
      remainingClasses: 7,
      isActive: true,
    );

    final adultSub = Subscription(
      id: 'sub_adult',
      userId: 'user_1',
      serviceName: 'Абонемент для дорослих',
      branchId: 'kyiv',
      totalClasses: 8,
      remainingClasses: 7,
      isActive: true,
    );

    test('Universal pass (PREMIUM PASS) is accepted for Adult classes and Child classes', () {
      final container = createContainer();
      final controller = container.read(subscriptionControllerProvider.notifier);

      expect(
        controller.canSubscriptionBeUsedForClass(universalSub, adultClass, clientBranchId: 'kyiv'),
        isTrue,
      );
      expect(
        controller.canSubscriptionBeUsedForClass(universalSub, childClass, clientBranchId: 'kyiv'),
        isTrue,
      );
    });

    test('Child pass is rejected for Adult classes', () {
      final container = createContainer();
      final controller = container.read(subscriptionControllerProvider.notifier);

      expect(
        controller.canSubscriptionBeUsedForClass(childSub, adultClass, clientBranchId: 'kyiv'),
        isFalse,
      );
    });

    test('Adult pass is rejected for Child classes', () {
      final container = createContainer();
      final controller = container.read(subscriptionControllerProvider.notifier);

      expect(
        controller.canSubscriptionBeUsedForClass(adultSub, childClass, clientBranchId: 'kyiv'),
        isFalse,
      );
    });
  });
}
