import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Stage 4: Branch Context & Auto-Detection Tests (TZ Point 9 & 10)', () {
    test('Vienna client automatically enters Vienna context without selecting country', () {
      const viennaClient = AppUser(
        id: 'client_anna',
        name: 'Anna Müller',
        role: UserRole.parent,
        branchId: 'vienna',
        organizationId: 'cityswim',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(viennaClient)),
        ],
      );

      final branchId = container.read(currentUserBranchIdProvider);
      expect(branchId, equals('vienna'));

      final tenancyState = container.read(tenancyControllerProvider);
      expect(tenancyState.activeBranch?.id, equals('vienna'));
      expect(tenancyState.isAllLocations, isFalse);
      expect(container.read(activeCurrencySymbolProvider), equals('€'));
      expect(container.read(activeCurrencyCodeProvider), equals('EUR'));
      expect(container.read(activeTimezoneProvider), equals('Europe/Vienna'));
    });

    test('Kyiv client automatically enters Kyiv context without selecting country', () {
      const kyivClient = AppUser(
        id: 'client_petro',
        name: 'Петро Коваленко',
        role: UserRole.parent,
        branchId: 'kyiv',
        organizationId: 'cityswim',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(kyivClient)),
        ],
      );

      final branchId = container.read(currentUserBranchIdProvider);
      expect(branchId, equals('kyiv'));

      final tenancyState = container.read(tenancyControllerProvider);
      expect(tenancyState.activeBranch?.id, equals('kyiv'));
      expect(tenancyState.isAllLocations, isFalse);
      expect(container.read(activeCurrencySymbolProvider), equals('₴'));
      expect(container.read(activeCurrencyCodeProvider), equals('UAH'));
      expect(container.read(activeTimezoneProvider), equals('Europe/Kyiv'));
    });

    test('Vienna Coach and Admin are locked to Vienna', () {
      const viennaCoach = AppUser(
        id: 'coach_maria',
        name: 'Maria Trainer',
        role: UserRole.coach,
        branchId: 'vienna',
        organizationId: 'cityswim',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(viennaCoach)),
        ],
      );

      expect(container.read(currentUserBranchIdProvider), equals('vienna'));
      expect(container.read(effectiveBranchProvider).id, equals('vienna'));
    });

    test('Owner is NOT locked to single branch and can switch freely', () async {
      const ownerUser = AppUser(
        id: 'owner_andrii',
        name: 'Andrii Owner',
        role: UserRole.owner,
        branchId: 'kyiv',
        branchIds: ['kyiv', 'vienna'],
        organizationId: 'cityswim',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(ownerUser)),
        ],
      );

      // Owner is NOT locked: currentUserBranchIdProvider returns null
      expect(container.read(currentUserBranchIdProvider), isNull);

      final controller = container.read(tenancyControllerProvider.notifier);

      // Switch to Vienna
      await controller.switchBranch('vienna');
      expect(container.read(tenancyControllerProvider).activeBranch?.id, equals('vienna'));
      expect(container.read(activeCurrencySymbolProvider), equals('€'));

      // Switch to All locations
      await controller.switchBranch('all');
      expect(container.read(tenancyControllerProvider).isAllLocations, isTrue);
      expect(container.read(activeCurrencySymbolProvider), equals('₴ / €'));

      // Switch back to Kyiv
      await controller.switchBranch('kyiv');
      expect(container.read(tenancyControllerProvider).activeBranch?.id, equals('kyiv'));
      expect(container.read(activeCurrencySymbolProvider), equals('₴'));
    });

    test('Cached branch from SharedPreferences activates instantly on startup', () {
      // Simulate cached offline/startup state
      prefs.setString('userBranchId', 'vienna');
      prefs.setString('userRole', 'parent');

      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(null)),
        ],
      );

      expect(container.read(currentUserBranchIdProvider), equals('vienna'));
      expect(container.read(effectiveBranchProvider).id, equals('vienna'));
    });
  });
}

class FakeAuthController extends AuthController {
  final AppUser? _user;
  FakeAuthController(this._user);

  @override
  AppUser? build() => _user;
}
