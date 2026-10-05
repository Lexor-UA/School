import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Branch Management, Protection & Data Isolation Tests', () {
    test('System branches (Kyiv and Vienna) have isSystemDefault and isProtected as true', () {
      expect(Branch.kyiv.isSystemDefault, isTrue);
      expect(Branch.kyiv.isProtected, isTrue);
      expect(Branch.vienna.isSystemDefault, isTrue);
      expect(Branch.vienna.isProtected, isTrue);
    });

    test('Custom branch model supports isProtected toggle and serializes accurately', () {
      final customBranch = Branch(
        id: 'warsaw',
        organizationId: 'cityswim',
        name: 'Warsaw Central',
        city: 'Warsaw',
        country: 'PL',
        currency: 'PLN',
        currencySymbol: 'zł',
        timezone: 'Europe/Warsaw',
        defaultLanguage: 'uk',
        paymentProvider: 'stripe',
        isProtected: true,
        createdAt: DateTime.now(),
      );

      expect(customBranch.isSystemDefault, isFalse);
      expect(customBranch.isProtected, isTrue);
      expect(customBranch.flagEmoji, '🇵🇱');

      final json = customBranch.toJson();
      expect(json['isProtected'], isTrue);

      final restored = Branch.fromJson(json);
      expect(restored.id, 'warsaw');
      expect(restored.isProtected, isTrue);
      expect(restored.currency, 'PLN');
      expect(restored.currencySymbol, 'zł');

      final unlocked = restored.copyWith(isProtected: false);
      expect(unlocked.isProtected, isFalse);
    });

    test('BranchConfig.createDefault automatically provisions 1 pool 25m with 4 lanes', () {
      final config = BranchConfig.createDefault(
        branchId: 'berlin',
        branchName: 'CitySwim Berlin',
        city: 'Berlin',
      );
      expect(config.branchId, 'berlin');
      expect(config.locations.length, 1);

      final loc = config.locations.first;
      expect(loc.address, contains('Berlin'));
      expect(loc.pools.length, 1);

      final pool = loc.pools.first;
      expect(pool.name, 'Головний басейн 25м');
      expect(pool.lengthMeters, 25);
      expect(pool.lanes.length, 4);
      expect(pool.lanes, [
        'Доріжка 1',
        'Доріжка 2',
        'Доріжка 3',
        'Доріжка 4',
      ]);
    });

    test('SubscriptionPackageCatalog generates correct default packages in branch currency', () {
      final plnPackages = SubscriptionPackageCatalog.generateDefaultPackages(
        branchId: 'warsaw',
        currency: 'PLN',
        currencySymbol: 'zł',
      );
      expect(plnPackages.length, 6);
      for (final p in plnPackages) {
        expect(p.branchId, 'warsaw');
        expect(p.currency, 'PLN');
        expect(p.currencySymbol, 'zł');
      }

      SubscriptionPackageCatalog.registerCustomPackages('warsaw', plnPackages);
      final fetched = SubscriptionPackageCatalog.getPackagesForBranch('warsaw', 'PLN', 'zł');
      expect(fetched.length, 6);
      expect(fetched.first.currency, 'PLN');
    });

    test('TenancyController refuses to delete system branches (Kyiv and Vienna)', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(tenancyControllerProvider.notifier);

      await expectLater(
        controller.deleteBranch('kyiv'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Неможливо видалити базову системну філію'),
        )),
      );

      await expectLater(
        controller.deleteBranch('vienna'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Неможливо видалити базову системну філію'),
        )),
      );
    });

    test('TenancyController refuses to delete custom branch if isProtected is true', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(tenancyControllerProvider.notifier);

      // Create protected branch
      final protectedBranch = Branch(
        id: 'valencia',
        organizationId: 'cityswim',
        name: 'Valencia',
        city: 'Valencia',
        country: 'ES',
        currency: 'EUR',
        currencySymbol: '€',
        timezone: 'Europe/Madrid',
        defaultLanguage: 'uk',
        paymentProvider: 'stripe',
        isProtected: true,
        createdAt: DateTime.now(),
      );

      controller.registerBranch(protectedBranch);

      await expectLater(
        controller.deleteBranch('valencia'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('захищена від видалення'),
        )),
      );

      // Unprotect branch and verify delete succeeds
      controller.updateBranchInMemory(protectedBranch.copyWith(isProtected: false));
      await controller.deleteBranch('valencia');

      final available = container.read(tenancyControllerProvider).availableBranches;
      expect(available.any((b) => b.id == 'valencia'), isFalse);
    });
  });
}
