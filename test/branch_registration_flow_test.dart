import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/tenancy/services/branch_invitation_service.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';

void main() {
  group('Stage 12: Client Registration via Branch Links & QR Codes (Branch Invitations & QR Onboarding)', () {
    test('BranchInvitationService: buildRegistrationUrl generates correct HTTPS registration links', () {
      expect(
        BranchInvitationService.buildRegistrationUrl('vienna'),
        'https://cityswim.app/register/vienna',
      );
      expect(
        BranchInvitationService.buildRegistrationUrl('kyiv'),
        'https://cityswim.app/register/kyiv',
      );
      // Fallback for unknown branch
      expect(
        BranchInvitationService.buildRegistrationUrl('unknown_city'),
        'https://cityswim.app/register/kyiv',
      );
    });

    test('BranchInvitationService: buildDeepLink generates app scheme URI for instant mobile onboarding', () {
      expect(
        BranchInvitationService.buildDeepLink('vienna'),
        'cityswim://register/vienna',
      );
      expect(
        BranchInvitationService.buildDeepLink('kyiv'),
        'cityswim://register/kyiv',
      );
    });

    test('BranchInvitationService: resolveBranchFromUrlOrCode parses various link and QR formats', () {
      // 1. Direct path web URLs
      expect(
        BranchInvitationService.resolveBranchFromUrlOrCode('https://cityswim.app/register/vienna'),
        'vienna',
      );
      expect(
        BranchInvitationService.resolveBranchFromUrlOrCode('https://cityswim.app/register/kyiv'),
        'kyiv',
      );

      // 2. Query param web URLs
      expect(
        BranchInvitationService.resolveBranchFromUrlOrCode('https://cityswim.app/register?branch=vienna'),
        'vienna',
      );
      expect(
        BranchInvitationService.resolveBranchFromUrlOrCode('https://cityswim.app/register?branch=kyiv'),
        'kyiv',
      );

      // 3. Mobile app deep links
      expect(
        BranchInvitationService.resolveBranchFromUrlOrCode('cityswim://register/vienna'),
        'vienna',
      );
      expect(
        BranchInvitationService.resolveBranchFromUrlOrCode('cityswim://register/kyiv'),
        'kyiv',
      );

      // 4. Raw codes and multilingual aliases
      expect(BranchInvitationService.resolveBranchFromUrlOrCode('vienna'), 'vienna');
      expect(BranchInvitationService.resolveBranchFromUrlOrCode('wien'), 'vienna');
      expect(BranchInvitationService.resolveBranchFromUrlOrCode('kyiv'), 'kyiv');
      expect(BranchInvitationService.resolveBranchFromUrlOrCode('kiev'), 'kyiv');

      // 5. Fallback for invalid or empty inputs
      expect(BranchInvitationService.resolveBranchFromUrlOrCode(''), 'kyiv');
      expect(BranchInvitationService.resolveBranchFromUrlOrCode('invalid_branch_name'), 'kyiv');
    });

    test('BranchInvitationService: getInvitationDetails provides rich metadata for HappyLand and Kyiv', () {
      final viennaDetails = BranchInvitationService.getInvitationDetails('vienna');
      expect(viennaDetails.branchId, 'vienna');
      expect(viennaDetails.flag, '🇦🇹');
      expect(viennaDetails.branchName, 'CitySwim Vienna');
      expect(viennaDetails.locationName, 'HappyLand Klosterneuburg');
      expect(viennaDetails.address, contains('Klosterneuburg'));
      expect(viennaDetails.currencyCode, 'EUR');
      expect(viennaDetails.currencySymbol, '€');
      expect(viennaDetails.primaryPoolName, contains('Wellenbecken'));
      expect(viennaDetails.getWelcomeMessage('de'), contains('Willkommen bei CitySwim Wien'));
      expect(viennaDetails.getWelcomeMessage('uk'), contains('Ласкаво просимо до CitySwim Відень'));
      expect(viennaDetails.getWelcomeMessage('en'), contains('Welcome to CitySwim Vienna'));

      final kyivDetails = BranchInvitationService.getInvitationDetails('kyiv');
      expect(kyivDetails.branchId, 'kyiv');
      expect(kyivDetails.flag, '🇺🇦');
      expect(kyivDetails.branchName, 'CitySwim Київ');
      expect(kyivDetails.locationName, 'Київський Центр Плавання');
      expect(kyivDetails.currencyCode, 'UAH');
      expect(kyivDetails.currencySymbol, '₴');
      expect(kyivDetails.primaryPoolName, contains('25м'));
    });

    test('Tenancy Integration: Selecting branch from invitation link initializes state for Vienna client', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          currentUserBranchIdProvider.overrideWithValue(null),
        ],
      );
      final controller = container.read(tenancyControllerProvider.notifier);

      // Simulate client scanning Vienna QR code
      final resolvedBranch = BranchInvitationService.resolveBranchFromUrlOrCode('https://cityswim.app/register/vienna');
      expect(resolvedBranch, 'vienna');

      await controller.selectBranch(resolvedBranch);

      final tenancyState = container.read(tenancyControllerProvider);
      expect(tenancyState.activeBranchId, 'vienna');
      expect(tenancyState.currencyCode, 'EUR');
      expect(tenancyState.currencySymbol, '€');
      expect(tenancyState.timezone, 'Europe/Vienna');

      final effectiveBranch = container.read(effectiveBranchProvider);
      expect(effectiveBranch.id, 'vienna');
      expect(effectiveBranch.name, 'Vienna');
      expect(effectiveBranch.country, 'AT');

      // Verify that catalog packages for this newly registered user are in EUR
      final packages = SubscriptionPackageCatalog.getPackagesForBranch('vienna');
      expect(packages.every((p) => p.branchId == 'vienna'), isTrue);
      expect(packages.every((p) => p.currency == 'EUR'), isTrue);
    });

    test('Tenancy Integration: AppUser registered via Vienna link preserves strict branch isolation', () {
      const viennaRegisteredParent = AppUser(
        id: 'new_client_vienna_1',
        name: 'Julia Fischer',
        role: UserRole.parent,
        loginId: 'julia.fischer@example.at',
        phone: '+436761234567',
        branchId: 'vienna',
        branchIds: ['vienna'],
        organizationId: 'cityswim',
      );

      expect(viennaRegisteredParent.branchId, 'vienna');
      expect(viennaRegisteredParent.organizationId, 'cityswim');
      expect(viennaRegisteredParent.branchIds.contains('vienna'), isTrue);
      expect(viennaRegisteredParent.branchIds.contains('kyiv'), isFalse);
    });

    test('Tenancy Integration: AppUser registered via Kyiv link preserves Kyiv branch isolation', () {
      const kyivRegisteredParent = AppUser(
        id: 'new_client_kyiv_1',
        name: 'Оксана Коваленко',
        role: UserRole.parent,
        loginId: 'oksana.kovalenko@example.ua',
        phone: '+380501234567',
        branchId: 'kyiv',
        branchIds: ['kyiv'],
        organizationId: 'cityswim',
      );

      expect(kyivRegisteredParent.branchId, 'kyiv');
      expect(kyivRegisteredParent.organizationId, 'cityswim');
      expect(kyivRegisteredParent.branchIds.contains('kyiv'), isTrue);
      expect(kyivRegisteredParent.branchIds.contains('vienna'), isFalse);
    });
  });
}
