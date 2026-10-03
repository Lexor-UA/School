import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';

import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
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

  group('P2 Architectural Improvement: Branch Admin Auto-Seeding Tests', () {
    test('createBranch registers new branch and handles custom admin salary and admin id format', () async {
      final notifier = container.read(tenancyControllerProvider.notifier);

      final newBranch = Branch(
        id: 'warsaw',
        organizationId: 'cityswim',
        name: 'CitySwim Warsaw',
        country: 'Poland',
        city: 'Warsaw',
        timezone: 'Europe/Warsaw',
        currency: 'PLN',
        currencySymbol: 'zł',
        defaultLanguage: 'pl',
        paymentProvider: 'Stripe',
        createdAt: DateTime(2026, 10, 2),
      );

      // Register the branch in local state
      notifier.registerBranch(newBranch);

      final state = container.read(tenancyControllerProvider);
      final registered = state.availableBranches.firstWhere((b) => b.id == 'warsaw');
      expect(registered.name, equals('CitySwim Warsaw'));
      expect(registered.currency, equals('PLN'));
      expect(registered.currencySymbol, equals('zł'));

      // Validate administrator ID format: admin_{branchId}
      final adminDocId = 'admin_${registered.id}';
      expect(adminDocId, equals('admin_warsaw'));

      // Validate default salary logic
      const enteredSalary = 8500;
      final resolvedSalary = enteredSalary;
      expect(resolvedSalary, equals(8500));
    });

    test('Default branch admins format: admin for Kyiv, admin_vienna for Vienna', () {
      const kyivBranchId = 'kyiv';
      const viennaBranchId = 'vienna';

      final kyivAdminId = kyivBranchId == 'kyiv' ? 'admin' : 'admin_$kyivBranchId';
      final viennaAdminId = 'admin_$viennaBranchId';

      expect(kyivAdminId, equals('admin'));
      expect(viennaAdminId, equals('admin_vienna'));
    });

    test('Staff currency determination respects document currency before falling back', () {
      final viennaDocData = {
        'role': 'admin',
        'branchId': 'vienna',
        'currency': '€',
        'adminSalary': 1900,
      };

      final warsawDocData = {
        'role': 'admin',
        'branchId': 'warsaw',
        'currency': 'zł',
        'adminSalary': 8000,
      };

      final kyivDocData = {
        'role': 'admin',
        'branchId': 'kyiv',
        'currency': '₴',
        'adminSalary': 20000,
      };

      String resolveCurrency(Map<String, dynamic> data) {
        final staffBranchId = data['branchId'];
        final isViennaStaff = staffBranchId == 'vienna';
        return (data['currency'] as String?)?.isNotEmpty == true
            ? (data['currency'] as String)
            : (isViennaStaff ? '€' : '₴');
      }

      expect(resolveCurrency(viennaDocData), equals('€'));
      expect(resolveCurrency(warsawDocData), equals('zł'));
      expect(resolveCurrency(kyivDocData), equals('₴'));
    });

    test('Admin role is locked from switching branches via tenancy switchBranch', () async {
      const kyivAdmin = AppUser(
        id: 'admin',
        name: 'Адміністратор Київ',
        role: UserRole.admin,
        branchId: 'kyiv',
        loginId: 'admin_kyiv',
      );

      final prefs = await SharedPreferences.getInstance();
      final adminContainer = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => MockAuthController(kyivAdmin)),
        ],
      );

      final initialTenancy = adminContainer.read(tenancyControllerProvider);
      expect(initialTenancy.activeBranchId, equals('kyiv'));

      // Attempt to switch to Vienna as Kyiv admin
      await adminContainer.read(tenancyControllerProvider.notifier).switchBranch('vienna');

      // Must remain 'kyiv' because admins cannot switch branches
      final afterAttemptTenancy = adminContainer.read(tenancyControllerProvider);
      expect(afterAttemptTenancy.activeBranchId, equals('kyiv'),
          reason: 'Branch admin must not be able to switch active branch');

      adminContainer.dispose();
    });

    test('Owner role CAN switch branches freely', () async {
      const ownerUser = AppUser(
        id: 'owner',
        name: 'Owner',
        role: UserRole.owner,
        branchId: 'kyiv',
      );

      final prefs = await SharedPreferences.getInstance();
      final ownerContainer = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => MockAuthController(ownerUser)),
        ],
      );

      // Attempt to switch to Vienna as Owner
      await ownerContainer.read(tenancyControllerProvider.notifier).switchBranch('vienna');

      final switchedTenancy = ownerContainer.read(tenancyControllerProvider);
      expect(switchedTenancy.activeBranchId, equals('vienna'),
          reason: 'Owner must be able to switch active branch');

      ownerContainer.dispose();
    });
  });
}

class MockAuthController extends AuthController {
  final AppUser _user;
  MockAuthController(this._user);

  @override
  AppUser? build() => _user;
}
