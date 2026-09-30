import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/schedule/services/recurring_schedule_generator.dart';
import 'package:swimming_school_app/features/tenancy/services/branch_data_integrity_validator.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Bug Fixes & Inter-Branch Switching Tests', () {
    test('Strict branch isolation prevents cross-branch booking', () {
      // Client is in Kyiv, trying to book Vienna class with Vienna subscription
      final invalidClientResult = BranchDataIntegrityValidator.validateClientBooking(
        clientBranchId: 'kyiv',
        classBranchId: 'vienna',
        subscriptionBranchId: 'vienna',
      );
      expect(invalidClientResult.isValid, isFalse);
      expect(invalidClientResult.errorMessage, contains('філії'));
      expect(invalidClientResult.errorMessage, contains('CitySwim Vienna'));

      // Client is in Vienna, trying to book Vienna class with Kyiv subscription
      final invalidSubResult = BranchDataIntegrityValidator.validateClientBooking(
        clientBranchId: 'vienna',
        classBranchId: 'vienna',
        subscriptionBranchId: 'kyiv',
      );
      expect(invalidSubResult.isValid, isFalse);
      expect(invalidSubResult.errorMessage, contains('філії'));
    });

    test('Client branch switch enables legitimate booking in new branch', () {
      // Client switches branch to Vienna
      final client = const AppUser(
        id: 'client_1',
        name: 'Олена',
        role: UserRole.parent,
        branchId: 'kyiv',
        branchIds: ['kyiv'],
      );

      final switchedClient = client.copyWith(
        branchId: 'vienna',
        branchIds: ['kyiv', 'vienna'],
      );

      expect(switchedClient.branchId, equals('vienna'));
      expect(switchedClient.branchIds, containsAll(['kyiv', 'vienna']));

      // Now client can book Vienna class with Vienna subscription
      final validResult = BranchDataIntegrityValidator.validateClientBooking(
        clientBranchId: switchedClient.branchId,
        classBranchId: 'vienna',
        subscriptionBranchId: 'vienna',
      );
      expect(validResult.isValid, isTrue);
      expect(validResult.errorMessage, isNull);
    });

    test('RecurringScheduleGenerator handles UTC bucketing accurately across day boundaries', () {
      final startDate = DateTime.utc(2026, 10, 5); // Monday
      final options = RecurringScheduleOptions(
        title: 'Вечірнє тренування',
        coachId: 'coach_1',
        coachName: 'Максим',
        startDate: startDate,
        hour: 21,
        minute: 30,
        durationMinutes: 60,
        weekdays: {1}, // Monday
        durationWeeks: 2,
        maxCapacity: 6,
        lane: 'Доріжка 1',
        category: 'Плавання',
        branchId: 'kyiv',
      );

      final result = RecurringScheduleGenerator.generate(
        options: options,
      );

      expect(result.classesToCreate.length, equals(2));
      for (final c in result.classesToCreate) {
        expect(c.branchId, equals('kyiv'));
        expect(c.startTime.isUtc, isTrue);
        expect(c.endTime.isUtc, isTrue);
      }
    });

    test('BranchDataIntegrityValidator strictly blocks cross-branch attendance deduction', () {
      final now = DateTime.now();
      final kyivClass = GroupClass(
        id: 'cls_kyiv_1',
        title: 'Групове тренування',
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        coachId: 'coach_1',
        coachName: 'Максим',
        maxCapacity: 8,
        category: 'Плавання',
        branchId: 'kyiv',
      );

      final viennaSub = Subscription(
        id: 'sub_vienna_1',
        userId: 'user_1',
        serviceName: 'Групове',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
        branchId: 'vienna',
      );

      final deductionResult = BranchDataIntegrityValidator.validateAttendanceDeduction(
        subscription: viennaSub,
        groupClass: kyivClass,
      );

      expect(deductionResult.isValid, isFalse);
      expect(deductionResult.errorMessage, contains('Vienna'));
      expect(deductionResult.errorMessage, contains('Kyiv'));
      expect(deductionResult.errorMessage, contains('міжфіліальну ізоляцію'));
    });
  });
}
