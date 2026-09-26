import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/tenancy/models/organization.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Organization Model Tests', () {
    test('Default CitySwim organization initialization', () {
      final org = Organization.cityswim;
      expect(org.id, 'cityswim');
      expect(org.name, 'CitySwim');
      expect(org.status, 'active');
      expect(org.branding?['primaryColor'], 0xFF00E5FF);
    });

    test('Organization JSON serialization', () {
      final org = Organization.cityswim;
      final json = org.toJson();
      final fromJson = Organization.fromJson(json);

      expect(fromJson.id, org.id);
      expect(fromJson.name, org.name);
      expect(fromJson, equals(org));
    });
  });

  group('Branch Model Tests', () {
    test('Predefined Kyiv branch parameters', () {
      final kyiv = Branch.kyiv;
      expect(kyiv.id, 'kyiv');
      expect(kyiv.organizationId, 'cityswim');
      expect(kyiv.country, 'UA');
      expect(kyiv.city, 'Kyiv');
      expect(kyiv.currency, 'UAH');
      expect(kyiv.currencySymbol, '₴');
      expect(kyiv.timezone, 'Europe/Kyiv');
      expect(kyiv.defaultLanguage, 'uk');
      expect(kyiv.paymentProvider, 'liqpay');
      expect(kyiv.flagEmoji, '🇺🇦');
      expect(kyiv.localizedCity('uk'), 'Київ');
    });

    test('Predefined Vienna branch parameters', () {
      final vienna = Branch.vienna;
      expect(vienna.id, 'vienna');
      expect(vienna.organizationId, 'cityswim');
      expect(vienna.country, 'AT');
      expect(vienna.city, 'Vienna');
      expect(vienna.currency, 'EUR');
      expect(vienna.currencySymbol, '€');
      expect(vienna.timezone, 'Europe/Vienna');
      expect(vienna.defaultLanguage, 'de');
      expect(vienna.paymentProvider, 'stripe');
      expect(vienna.flagEmoji, '🇦🇹');
      expect(vienna.localizedCity('uk'), 'Відень');
      expect(vienna.localizedCity('de'), 'Wien');
    });

    test('Branch JSON serialization', () {
      final vienna = Branch.vienna;
      final json = vienna.toJson();
      final fromJson = Branch.fromJson(json);

      expect(fromJson.id, vienna.id);
      expect(fromJson.currency, 'EUR');
      expect(fromJson.timezone, 'Europe/Vienna');
      expect(fromJson, equals(vienna));
    });
  });

  group('BranchConfig Hierarchy Tests (Org -> Branch -> Location -> Pool -> Lane)', () {
    test('HappyLand Vienna configuration structure', () {
      final config = BranchConfig.viennaConfig;
      expect(config.branchId, 'vienna');
      expect(config.locations.length, 1);

      final happyLand = config.locations.first;
      expect(happyLand.name, 'HappyLand');
      expect(happyLand.pools.length, 2);

      final sportsPool = happyLand.pools.firstWhere((p) => p.id == 'sports_pool');
      expect(sportsPool.name, 'Sports Pool');
      expect(sportsPool.lanes.contains('Lane 1'), true);
      expect(sportsPool.lanes.contains('Lane 5'), true);
      expect(sportsPool.lengthMeters, 25.0);
    });

    test('Kyiv configuration structure', () {
      final config = BranchConfig.kyivConfig;
      expect(config.branchId, 'kyiv');
      expect(config.locations.length, 1);
      expect(config.locations.first.pools.any((p) => p.id == 'pool_25m'), true);
    });
  });

  group('TenancyController State Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Default initial state is Kyiv with UAH ₴', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          currentUserBranchIdProvider.overrideWithValue(null),
        ],
      );

      final state = container.read(tenancyControllerProvider);
      expect(state.activeBranch?.id, 'kyiv');
      expect(state.isAllLocations, false);
      expect(container.read(activeCurrencySymbolProvider), '₴');
      expect(container.read(activeCurrencyCodeProvider), 'UAH');
      expect(container.read(activeTimezoneProvider), 'Europe/Kyiv');
    });

    test('Switching to Vienna updates currency to EUR € and timezone to Europe/Vienna', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          currentUserBranchIdProvider.overrideWithValue(null),
        ],
      );

      final controller = container.read(tenancyControllerProvider.notifier);
      await controller.switchBranch('vienna');

      final state = container.read(tenancyControllerProvider);
      expect(state.activeBranch?.id, 'vienna');
      expect(state.isAllLocations, false);
      expect(container.read(activeCurrencySymbolProvider), '€');
      expect(container.read(activeCurrencyCodeProvider), 'EUR');
      expect(container.read(activeTimezoneProvider), 'Europe/Vienna');
      expect(prefs.getString('selected_branch_id'), 'vienna');
    });

    test('Switching to All Locations (Owner mode)', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          currentUserBranchIdProvider.overrideWithValue(null),
        ],
      );

      final controller = container.read(tenancyControllerProvider.notifier);
      await controller.switchBranch('all');

      final state = container.read(tenancyControllerProvider);
      expect(state.isAllLocations, true);
      expect(state.activeBranch, isNull);
      expect(container.read(effectiveBranchProvider).id, 'kyiv');
      expect(container.read(isAllLocationsSelectedProvider), true);
      expect(container.read(activeCurrencySymbolProvider), '₴ / €');
      expect(container.read(activeCurrencyCodeProvider), 'UAH / EUR');
      expect(prefs.getString('selected_branch_id'), 'all');
    });
  });

  group('Domain Models Multi-tenancy Architecture Tests (Stage 1)', () {
    test('AppUser multi-tenancy attributes and owner multi-branch access', () {
      final defaultUser = const AppUser(
        id: 'user_1',
        name: 'Client Anna',
        role: UserRole.parent,
      );
      expect(defaultUser.organizationId, 'cityswim');
      expect(defaultUser.branchId, 'kyiv');
      expect(defaultUser.branchIds, ['kyiv']);

      final ownerUser = const AppUser(
        id: 'owner_1',
        name: 'Andrii Owner',
        role: UserRole.owner,
        branchIds: ['kyiv', 'vienna'],
      );
      expect(ownerUser.branchIds.contains('kyiv'), true);
      expect(ownerUser.branchIds.contains('vienna'), true);

      final userJson = ownerUser.toJson();
      final fromJson = AppUser.fromJson(userJson);
      expect(fromJson.organizationId, 'cityswim');
      expect(fromJson.branchIds, ['kyiv', 'vienna']);
    });

    test('GroupClass preserves Location -> Pool -> Lane hierarchy and timezone', () {
      final now = DateTime(2026, 10, 1, 10, 0);
      final kyivClass = GroupClass(
        id: 'cls_kyiv',
        title: 'Київ ранкове плавання',
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        coachId: 'coach_kyiv',
        coachName: 'Олександр',
        maxCapacity: 8,
        category: 'Плавання',
        lane: 'Доріжка 1',
      );
      expect(kyivClass.organizationId, 'cityswim');
      expect(kyivClass.branchId, 'kyiv');
      expect(kyivClass.timezone, 'Europe/Kyiv');
      expect(kyivClass.locationId, 'kyiv_main');
      expect(kyivClass.poolId, 'pool_25m');
      expect(kyivClass.lane, 'Доріжка 1');

      final viennaClass = GroupClass(
        id: 'cls_vienna',
        title: 'Vienna HappyLand Kids',
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        coachId: 'coach_vienna',
        coachName: 'Maria',
        maxCapacity: 6,
        category: 'Плавання',
        organizationId: 'cityswim',
        branchId: 'vienna',
        timezone: 'Europe/Vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
        lane: 'Lane 1',
      );
      expect(viennaClass.branchId, 'vienna');
      expect(viennaClass.timezone, 'Europe/Vienna');
      expect(viennaClass.locationId, 'happyland');
      expect(viennaClass.poolId, 'sports_pool');
      expect(viennaClass.lane, 'Lane 1');

      final viennaJson = viennaClass.toJson();
      final fromJson = GroupClass.fromJson(viennaJson);
      expect(fromJson.branchId, 'vienna');
      expect(fromJson.timezone, 'Europe/Vienna');
      expect(fromJson.locationId, 'happyland');
      expect(fromJson.poolId, 'sports_pool');
    });

    test('Subscription and SubscriptionPackage isolation in Stage 1', () {
      final sub = const Subscription(
        id: 'sub_1',
        userId: 'client_1',
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
      );
      expect(sub.organizationId, 'cityswim');
      expect(sub.branchId, 'kyiv');
      expect(sub.currency, 'UAH');
      expect(sub.currencySymbol, '₴');

      final kyivPacks = SubscriptionPackageCatalog.forBranch('kyiv');
      final viennaPacks = SubscriptionPackageCatalog.forBranch('vienna');
      expect(kyivPacks.every((p) => p.branchId == 'kyiv' && p.currency == 'UAH'), true);
      expect(viennaPacks.every((p) => p.branchId == 'vienna' && p.currency == 'EUR'), true);
    });

    test('Child, Family, and ChatDialog adhere to multi-tenancy fields', () {
      final child = const Child(
        id: 'child_1',
        parentId: 'parent_1',
        name: 'Тимофій',
      );
      expect(child.organizationId, 'cityswim');
      expect(child.branchId, 'kyiv');

      final family = Family(
        id: 'fam_1',
        primaryParentId: 'parent_1',
        parentIds: ['parent_1'],
        parentNames: {'parent_1': 'Олена'},
        inviteCode: 'INV123',
        createdAt: DateTime.now(),
      );
      expect(family.organizationId, 'cityswim');
      expect(family.branchId, 'kyiv');

      final chat = ChatDialog(
        id: 'chat_1',
        clientId: 'client_1',
        clientName: 'Anna',
        lastMessageTime: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(chat.organizationId, 'cityswim');
      expect(chat.branchId, 'kyiv');
    });
  });
}

