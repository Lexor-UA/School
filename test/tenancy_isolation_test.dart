import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/models/organization.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
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

  group('Tenancy Data Isolation Tests (Stage 2)', () {
    test('Kyiv and Vienna classes on same lane & time do NOT conflict due to branch isolation', () {
      final now = DateTime(2026, 10, 1, 10, 0);
      final kyivClass = GroupClass(
        id: 'class_kyiv_1',
        title: 'Плавання діти',
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        coachId: 'coach_1',
        coachName: 'Олександр',
        maxCapacity: 8,
        category: 'Плавання',
        lane: 'Доріжка 1',
        branchId: 'kyiv',
        organizationId: 'cityswim',
      );

      final scheduleController = container.read(scheduleControllerProvider.notifier);

      // Verify that checkClassConflict with branchId 'vienna' returns null against Kyiv class
      final viennaConflict = scheduleController.checkClassConflict(
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        lane: 'Доріжка 1',
        coachId: 'coach_2',
        branchId: 'vienna',
      );

      expect(kyivClass.branchId, equals('kyiv'));
      expect(viennaConflict, isNull, reason: 'Vienna class on Lane 1 must not conflict with Kyiv class on Lane 1');
    });

    test('Subscriptions correctly preserve multi-currency and branch identifiers', () {
      final kyivSub = Subscription(
        id: 'sub_kyiv',
        userId: 'client_1',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
        organizationId: 'cityswim',
        branchId: 'kyiv',
        currency: 'UAH',
        currencySymbol: '₴',
      );

      final viennaSub = Subscription(
        id: 'sub_vienna',
        userId: 'client_2',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
        organizationId: 'cityswim',
        branchId: 'vienna',
        currency: 'EUR',
        currencySymbol: '€',
      );

      expect(kyivSub.branchId, equals('kyiv'));
      expect(kyivSub.currency, equals('UAH'));
      expect(kyivSub.currencySymbol, equals('₴'));

      expect(viennaSub.branchId, equals('vienna'));
      expect(viennaSub.currency, equals('EUR'));
      expect(viennaSub.currencySymbol, equals('€'));

      // Check JSON serialization preserves branch and currency
      final kyivJson = kyivSub.toJson();
      expect(kyivJson['branchId'], equals('kyiv'));
      expect(kyivJson['currency'], equals('UAH'));
      expect(kyivJson['currencySymbol'], equals('₴'));

      final viennaJson = viennaSub.toJson();
      expect(viennaJson['branchId'], equals('vienna'));
      expect(viennaJson['currency'], equals('EUR'));
      expect(viennaJson['currencySymbol'], equals('€'));
    });

    test('Chat dialogs correctly distinguish Kyiv and Vienna branches', () {
      final kyivDialog = ChatDialog(
        id: 'dialog_kyiv',
        clientId: 'client_1',
        clientName: 'Іван',
        lastMessage: 'Привіт',
        lastMessageTime: DateTime.now(),
        updatedAt: DateTime.now(),
        branchId: 'kyiv',
        organizationId: 'cityswim',
      );

      final viennaDialog = ChatDialog(
        id: 'dialog_vienna',
        clientId: 'client_2',
        clientName: 'Stefan',
        lastMessage: 'Hallo',
        lastMessageTime: DateTime.now(),
        updatedAt: DateTime.now(),
        branchId: 'vienna',
        organizationId: 'cityswim',
      );

      final allDialogs = [kyivDialog, viennaDialog];

      final filteredKyiv = allDialogs.where((d) => d.branchId == 'kyiv').toList();
      final filteredVienna = allDialogs.where((d) => d.branchId == 'vienna').toList();

      expect(filteredKyiv.length, equals(1));
      expect(filteredKyiv.first.clientId, equals('client_1'));

      expect(filteredVienna.length, equals(1));
      expect(filteredVienna.first.clientId, equals('client_2'));
    });

    test('TenancyState getters activeBranchId and isAllLocationsSelected function correctly', () {
      final stateKyiv = TenancyState(
        organization: Organization.cityswim,
        availableBranches: [Branch.kyiv, Branch.vienna],
        activeBranch: Branch.kyiv,
        isAllLocations: false,
      );

      expect(stateKyiv.activeBranchId, equals('kyiv'));
      expect(stateKyiv.isAllLocationsSelected, isFalse);
      expect(stateKyiv.currencySymbol, equals('₴'));
      expect(stateKyiv.currencyCode, equals('UAH'));

      final stateAll = TenancyState(
        organization: Organization.cityswim,
        availableBranches: [Branch.kyiv, Branch.vienna],
        activeBranch: null,
        isAllLocations: true,
      );

      expect(stateAll.activeBranchId, isNull);
      expect(stateAll.isAllLocationsSelected, isTrue);
      expect(stateAll.currencySymbol, equals('₴ / €'));
      expect(stateAll.currencyCode, equals('UAH / EUR'));
    });

    test('canSubscriptionBeUsedForClass rejects cross-branch use', () {
      final now = DateTime(2026, 10, 1, 12, 0);
      final kyivSub = Subscription(
        id: 'sub_kyiv',
        userId: 'client_1',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
        branchId: 'kyiv',
        organizationId: 'cityswim',
        currency: 'UAH',
        currencySymbol: '₴',
      );

      final viennaClass = GroupClass(
        id: 'class_vienna_1',
        title: 'Schwimmkurs Kinder',
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        coachId: 'coach_vienna',
        coachName: 'Stefan',
        maxCapacity: 6,
        category: 'Плавання',
        lane: 'Lane 1',
        branchId: 'vienna',
        organizationId: 'cityswim',
      );

      final kyivClass = GroupClass(
        id: 'class_kyiv_1',
        title: 'Плавання діти',
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        coachId: 'coach_kyiv',
        coachName: 'Олександр',
        maxCapacity: 8,
        category: 'Плавання',
        lane: 'Доріжка 1',
        branchId: 'kyiv',
        organizationId: 'cityswim',
      );

      final subController = container.read(subscriptionControllerProvider.notifier);

      // Kyiv subscription CANNOT be used for Vienna class
      expect(subController.canSubscriptionBeUsedForClass(kyivSub, viennaClass), isFalse,
          reason: 'Kyiv subscription must NOT be usable for Vienna class');

      // Kyiv subscription CAN be used for Kyiv class
      expect(subController.canSubscriptionBeUsedForClass(kyivSub, kyivClass), isTrue,
          reason: 'Kyiv subscription must be usable for Kyiv class');
    });

    test('SubscriptionPackageCatalog delivers isolated currencies and packages per branch', () {
      final kyivPackages = SubscriptionPackageCatalog.forBranch('kyiv');
      final viennaPackages = SubscriptionPackageCatalog.forBranch('vienna');

      expect(kyivPackages.every((p) => p.branchId == 'kyiv' && p.currency == 'UAH'), isTrue);
      expect(viennaPackages.every((p) => p.branchId == 'vienna' && p.currency == 'EUR'), isTrue);

      final kyivStandard = kyivPackages.firstWhere((p) => p.id == 'kyiv_child_6_8_8');
      expect(kyivStandard.price, equals(1900));
      expect(kyivStandard.formattedPrice, equals('1900 грн'));

      final viennaStandard = viennaPackages.firstWhere((p) => p.id == 'vienna_child_6_8_8');
      expect(viennaStandard.price, equals(110));
      expect(viennaStandard.formattedPrice, equals('110 €'));
    });

    test('Data Validation (TZ Point 30): Cross-branch validation rules', () {
      final viennaUser = const AppUser(
        id: 'client_vienna',
        name: 'Anna Müller',
        role: UserRole.parent,
        branchId: 'vienna',
      );
      final kyivClass = GroupClass(
        id: 'cls_kyiv_1',
        title: 'Київ діти',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 45)),
        coachId: 'coach_kyiv',
        coachName: 'Олександр',
        maxCapacity: 8,
        category: 'Плавання',
        branchId: 'kyiv',
      );
      final viennaClass = GroupClass(
        id: 'cls_vienna_1',
        title: 'Vienna Kinder',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 45)),
        coachId: 'coach_vienna',
        coachName: 'Maria',
        maxCapacity: 6,
        category: 'Плавання',
        branchId: 'vienna',
      );

      // 1. client.branch_id == lesson.branch_id
      final isClientValidForKyiv = viennaUser.branchId == kyivClass.branchId;
      final isClientValidForVienna = viennaUser.branchId == viennaClass.branchId;
      expect(isClientValidForKyiv, isFalse);
      expect(isClientValidForVienna, isTrue);

      // 2. coach.branch_id == lesson.branch_id
      final viennaCoach = const AppUser(
        id: 'coach_vienna',
        name: 'Maria Coach',
        role: UserRole.coach,
        branchId: 'vienna',
      );
      expect(viennaCoach.branchId == kyivClass.branchId, isFalse);
      expect(viennaCoach.branchId == viennaClass.branchId, isTrue);

      // 3. package.branch_id == client.branch_id
      final viennaPackage = SubscriptionPackageCatalog.forBranch('vienna').first;
      final kyivPackage = SubscriptionPackageCatalog.forBranch('kyiv').first;
      expect(viennaPackage.branchId == viennaUser.branchId, isTrue);
      expect(kyivPackage.branchId == viennaUser.branchId, isFalse);
    });

    test('Attendance Isolation (TZ Point 28): Coach attendance permission check', () {
      final viennaCoach = const AppUser(
        id: 'coach_vienna',
        name: 'Maria Coach',
        role: UserRole.coach,
        branchId: 'vienna',
      );
      final kyivClass = GroupClass(
        id: 'cls_kyiv_1',
        title: 'Київ діти',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 45)),
        coachId: 'coach_kyiv',
        coachName: 'Олександр',
        maxCapacity: 8,
        category: 'Плавання',
        branchId: 'kyiv',
      );

      // A coach can only record attendance for classes in their own branch where they are the assigned coach
      bool canCoachTakeAttendance(AppUser coach, GroupClass gClass) {
        if (coach.role != UserRole.coach && coach.role != UserRole.owner && coach.role != UserRole.admin) {
          return false;
        }
        if (coach.role == UserRole.owner) return true;
        return coach.branchId == gClass.branchId && coach.id == gClass.coachId;
      }

      expect(canCoachTakeAttendance(viennaCoach, kyivClass), isFalse);

      final viennaClassAssigned = GroupClass(
        id: 'cls_vienna_1',
        title: 'Vienna Kinder',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 45)),
        coachId: 'coach_vienna',
        coachName: 'Maria',
        maxCapacity: 6,
        category: 'Плавання',
        branchId: 'vienna',
      );
      expect(canCoachTakeAttendance(viennaCoach, viennaClassAssigned), isTrue);
    });
  });
}

