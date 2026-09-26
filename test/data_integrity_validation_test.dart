import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/tenancy/services/branch_data_integrity_validator.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Stage 14: BranchDataIntegrityValidator Tests', () {
    final now = DateTime(2026, 9, 26, 10, 0);

    final kyivSub = Subscription(
      id: 'sub_kyiv_1',
      userId: 'client_kyiv_1',
      totalClasses: 8,
      remainingClasses: 6,
      isActive: true,
      serviceName: 'Групові заняття (8 занять)',
      branchId: 'kyiv',
      currency: 'UAH',
      currencySymbol: '₴',
    );

    final viennaSub = Subscription(
      id: 'sub_vienna_1',
      userId: 'client_vienna_1',
      totalClasses: 8,
      remainingClasses: 7,
      isActive: true,
      serviceName: 'Gruppentraining (8 Einheiten)',
      branchId: 'vienna',
      currency: 'EUR',
      currencySymbol: '€',
    );

    final kyivClass = GroupClass(
      id: 'class_kyiv_1',
      title: 'Групове тренування (Діти 7-9 років)',
      startTime: now.add(const Duration(hours: 2)),
      endTime: now.add(const Duration(hours: 3)),
      coachId: 'coach_kyiv_1',
      coachName: 'Олександр Коваль',
      maxCapacity: 8,
      category: 'group',
      lane: 'Доріжка 1',
      branchId: 'kyiv',
      timezone: 'Europe/Kyiv',
    );

    final viennaClass = GroupClass(
      id: 'class_vienna_1',
      title: 'Schwimmkurs Kinder (Fortgeschritten)',
      startTime: now.add(const Duration(hours: 2)),
      endTime: now.add(const Duration(hours: 3)),
      coachId: 'coach_vienna_1',
      coachName: 'Maria Huber',
      maxCapacity: 8,
      category: 'group',
      lane: 'Lane 1',
      branchId: 'vienna',
      timezone: 'Europe/Vienna',
    );

    final kyivCoach = const AppUser(
      id: 'coach_kyiv_1',
      name: 'Олександр Коваль',
      phone: '+380501112233',
      role: UserRole.coach,
      branchId: 'kyiv',
      branchIds: ['kyiv'],
    );

    final viennaCoach = const AppUser(
      id: 'coach_vienna_1',
      name: 'Stefan Gruber',
      phone: '+436601234567',
      role: UserRole.coach,
      branchId: 'vienna',
      branchIds: ['vienna'],
    );

    final multiBranchCoach = const AppUser(
      id: 'coach_multi_1',
      name: 'Elena Rostova (Head Coach)',
      phone: '+380509998877',
      role: UserRole.coach,
      branchId: 'kyiv',
      branchIds: ['kyiv', 'vienna'],
    );

    group('Rule 1: validateAttendanceDeduction (TZ Point 29)', () {
      test('Kyiv sub for Kyiv class is valid', () {
        final result = BranchDataIntegrityValidator.validateAttendanceDeduction(
          subscription: kyivSub,
          groupClass: kyivClass,
          clientBranchId: 'kyiv',
        );
        expect(result.isValid, isTrue);
      });

      test('Vienna sub for Vienna class is valid', () {
        final result = BranchDataIntegrityValidator.validateAttendanceDeduction(
          subscription: viennaSub,
          groupClass: viennaClass,
          clientBranchId: 'vienna',
        );
        expect(result.isValid, isTrue);
      });

      test('Vienna sub for Kyiv class is strictly blocked', () {
        final result = BranchDataIntegrityValidator.validateAttendanceDeduction(
          subscription: viennaSub,
          groupClass: kyivClass,
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'BRANCH_MISMATCH_SUBSCRIPTION_CLASS');
        expect(result.errorMessage, contains('CitySwim Vienna 🇦🇹'));
        expect(result.errorMessage, contains('CitySwim Kyiv 🇺🇦'));
      });

      test('Kyiv sub for Vienna class is strictly blocked', () {
        final result = BranchDataIntegrityValidator.validateAttendanceDeduction(
          subscription: kyivSub,
          groupClass: viennaClass,
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'BRANCH_MISMATCH_SUBSCRIPTION_CLASS');
      });

      test('Mismatched client branch is strictly blocked even if sub and class match', () {
        final result = BranchDataIntegrityValidator.validateAttendanceDeduction(
          subscription: kyivSub,
          groupClass: kyivClass,
          clientBranchId: 'vienna',
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'BRANCH_MISMATCH_CLIENT_CLASS');
        expect(result.errorMessage, contains('CitySwim Vienna 🇦🇹'));
      });
    });

    group('Rule 2: validateCoachAssignment (TZ Point 30)', () {
      test('Unassigned coach is always allowed', () {
        final result = BranchDataIntegrityValidator.validateCoachAssignment(
          coach: const AppUser(id: 'unassigned', name: 'Не призначений', phone: '', role: UserRole.coach),
          branchId: 'vienna',
        );
        expect(result.isValid, isTrue);
      });

      test('Kyiv coach assigned to Kyiv class is allowed', () {
        final result = BranchDataIntegrityValidator.validateCoachAssignment(
          coach: kyivCoach,
          branchId: 'kyiv',
        );
        expect(result.isValid, isTrue);
      });

      test('Vienna coach assigned to Vienna class is allowed', () {
        final result = BranchDataIntegrityValidator.validateCoachAssignment(
          coach: viennaCoach,
          branchId: 'vienna',
        );
        expect(result.isValid, isTrue);
      });

      test('Kyiv single-branch coach assigned to Vienna class is strictly blocked', () {
        final result = BranchDataIntegrityValidator.validateCoachAssignment(
          coach: kyivCoach,
          branchId: 'vienna',
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'COACH_BRANCH_MISMATCH');
        expect(result.errorMessage, contains('Олександр Коваль'));
        expect(result.errorMessage, contains('CitySwim Vienna 🇦🇹'));
      });

      test('Vienna single-branch coach assigned to Kyiv class is strictly blocked', () {
        final result = BranchDataIntegrityValidator.validateCoachAssignment(
          coach: viennaCoach,
          branchId: 'kyiv',
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'COACH_BRANCH_MISMATCH');
      });

      test('Multi-branch coach can be assigned to both Kyiv and Vienna', () {
        final resVienna = BranchDataIntegrityValidator.validateCoachAssignment(
          coach: multiBranchCoach,
          branchId: 'vienna',
        );
        final resKyiv = BranchDataIntegrityValidator.validateCoachAssignment(
          coach: multiBranchCoach,
          branchId: 'kyiv',
        );
        expect(resVienna.isValid, isTrue);
        expect(resKyiv.isValid, isTrue);
      });
    });

    group('Rule 3: validateLocationAndPool (TZ Point 30)', () {
      test('HappyLand Klosterneuburg and sports_pool are valid for Vienna', () {
        final result = BranchDataIntegrityValidator.validateLocationAndPool(
          branchId: 'vienna',
          locationId: 'happyland',
          poolId: 'sports_pool',
        );
        expect(result.isValid, isTrue);
      });

      test('Wellenbecken is valid for Vienna', () {
        final result = BranchDataIntegrityValidator.validateLocationAndPool(
          branchId: 'vienna',
          locationId: 'happyland',
          poolId: 'wellenbecken',
        );
        expect(result.isValid, isTrue);
      });

      test('Kyiv location in Vienna branch is blocked', () {
        final result = BranchDataIntegrityValidator.validateLocationAndPool(
          branchId: 'vienna',
          locationId: 'kyiv_main',
          poolId: 'sports_pool',
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'INVALID_LOCATION_FOR_BRANCH');
      });

      test('Non-existent pool in Vienna branch is blocked', () {
        final result = BranchDataIntegrityValidator.validateLocationAndPool(
          branchId: 'vienna',
          locationId: 'happyland',
          poolId: 'olympic_50m',
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'INVALID_POOL_FOR_BRANCH');
      });

      test('Vienna pool in Kyiv branch is blocked', () {
        final result = BranchDataIntegrityValidator.validateLocationAndPool(
          branchId: 'kyiv',
          locationId: 'kyiv_main',
          poolId: 'sports_pool',
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'INVALID_POOL_FOR_BRANCH');
      });
    });

    group('Rule 4: validateClientBooking', () {
      test('Vienna client booking Vienna class with Vienna sub is valid', () {
        final result = BranchDataIntegrityValidator.validateClientBooking(
          clientBranchId: 'vienna',
          classBranchId: 'vienna',
          subscriptionBranchId: 'vienna',
        );
        expect(result.isValid, isTrue);
      });

      test('Kyiv client booking Kyiv class with Kyiv sub is valid', () {
        final result = BranchDataIntegrityValidator.validateClientBooking(
          clientBranchId: 'kyiv',
          classBranchId: 'kyiv',
          subscriptionBranchId: 'kyiv',
        );
        expect(result.isValid, isTrue);
      });

      test('Client booking with mismatched sub branch is blocked', () {
        final result = BranchDataIntegrityValidator.validateClientBooking(
          clientBranchId: 'vienna',
          classBranchId: 'vienna',
          subscriptionBranchId: 'kyiv',
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'BOOKING_SUB_BRANCH_MISMATCH');
      });

      test('Client booking in a different branch is blocked', () {
        final result = BranchDataIntegrityValidator.validateClientBooking(
          clientBranchId: 'kyiv',
          classBranchId: 'vienna',
          subscriptionBranchId: 'vienna',
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'BOOKING_CLIENT_BRANCH_MISMATCH');
      });
    });

    group('SubscriptionController canSubscriptionBeUsedForClass Integration', () {
      test('blocks cross-branch subscription via controller method', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final controller = container.read(subscriptionControllerProvider.notifier);

        final canUseViennaForKyiv = controller.canSubscriptionBeUsedForClass(viennaSub, kyivClass);
        final canUseKyivForVienna = controller.canSubscriptionBeUsedForClass(kyivSub, viennaClass);
        final canUseViennaForVienna = controller.canSubscriptionBeUsedForClass(viennaSub, viennaClass);
        final canUseKyivForKyiv = controller.canSubscriptionBeUsedForClass(kyivSub, kyivClass);

        expect(canUseViennaForKyiv, isFalse);
        expect(canUseKyivForVienna, isFalse);
        expect(canUseViennaForVienna, isTrue);
        expect(canUseKyivForKyiv, isTrue);
      });
    });
  });
}
