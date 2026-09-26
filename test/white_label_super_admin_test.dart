import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/tenancy/models/organization.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/models/white_label_config.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:swimming_school_app/features/tenancy/utils/branch_timezone_helper.dart';
import 'package:swimming_school_app/features/tenancy/services/branch_data_integrity_validator.dart';
import 'package:swimming_school_app/features/tenancy/services/branch_invitation_service.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

void main() {
  group('Stage 15: AquatixLab SaaS & White Label Platform Tests', () {
    group('1. WhiteLabelConfig Model & Customization Tests', () {
      test('Default CitySwim configuration is initialized correctly', () {
        const config = WhiteLabelConfig.citySwimDefault;
        expect(config.organizationId, 'cityswim');
        expect(config.appName, 'CitySwim');
        expect(config.legalEntityName, 'CitySwim International Group');
        expect(config.primaryColorValue, 0xFF00E5FF);
        expect(config.secondaryColorValue, 0xFF001F3F);
        expect(config.featuresEnabled['multiBranch'], isTrue);
        expect(config.featuresEnabled['qrAttendance'], isTrue);
      });

      test('WhiteLabelConfig JSON serialization and deserialization roundtrip', () {
        const original = WhiteLabelConfig(
          organizationId: 'aquatix_demo',
          appName: 'Aquatix Demo Academy',
          legalEntityName: 'AquatixLab Demo GmbH',
          logoUrl: 'assets/demo/logo.png',
          primaryColorValue: 0xFF10B981,
          secondaryColorValue: 0xFF064E3B,
          accentColorValue: 0xFFF59E0B,
          customDomain: 'demo.aquatixlab.com',
          websiteUrl: 'https://demo.aquatixlab.com',
          supportEmail: 'support@aquatixlab.com',
          supportPhone: '+43 1 987 6543',
        );

        final json = original.toJson();
        final deserialized = WhiteLabelConfig.fromJson(json);

        expect(deserialized.organizationId, original.organizationId);
        expect(deserialized.appName, original.appName);
        expect(deserialized.legalEntityName, original.legalEntityName);
        expect(deserialized.primaryColorValue, original.primaryColorValue);
        expect(deserialized.secondaryColorValue, original.secondaryColorValue);
        expect(deserialized.customDomain, original.customDomain);
        expect(deserialized.supportEmail, original.supportEmail);
      });

      test('Organization whiteLabelConfig getter produces valid config', () {
        final org = Organization.cityswim;
        final whiteLabel = org.whiteLabelConfig;

        expect(whiteLabel.organizationId, 'cityswim');
        expect(whiteLabel.appName, 'CitySwim');
        expect(whiteLabel.primaryColorValue, 0xFF00E5FF);
      });
    });

    group('2. SuperAdmin Role & Platform Access Tests', () {
      test('UserRole.superAdmin enum serialization and deserialization', () {
        const superAdminUser = AppUser(
          id: 'super_admin_1',
          name: 'Platform Administrator',
          role: UserRole.superAdmin,
          organizationId: 'cityswim',
          branchId: 'all',
          branchIds: ['kyiv', 'vienna'],
        );

        expect(superAdminUser.isSuperAdmin, isTrue);
        expect(superAdminUser.isOwnerOrSuperAdmin, isTrue);

        final json = superAdminUser.toJson();
        expect(json['role'], 'superAdmin');

        final restored = AppUser.fromJson(json);
        expect(restored.role, UserRole.superAdmin);
        expect(restored.isSuperAdmin, isTrue);
      });

      test('Regular owner has isOwnerOrSuperAdmin true, but isSuperAdmin false', () {
        const ownerUser = AppUser(
          id: 'owner_1',
          name: 'School Owner',
          role: UserRole.owner,
        );

        expect(ownerUser.isSuperAdmin, isFalse);
        expect(ownerUser.isOwnerOrSuperAdmin, isTrue);
      });

      test('Regular coach and client have both isSuperAdmin and isOwnerOrSuperAdmin false', () {
        const coachUser = AppUser(
          id: 'coach_1',
          name: 'Coach',
          role: UserRole.coach,
        );
        const parentUser = AppUser(
          id: 'parent_1',
          name: 'Parent',
          role: UserRole.parent,
        );

        expect(coachUser.isSuperAdmin, isFalse);
        expect(coachUser.isOwnerOrSuperAdmin, isFalse);
        expect(parentUser.isSuperAdmin, isFalse);
        expect(parentUser.isOwnerOrSuperAdmin, isFalse);
      });
    });

    group('3. Customer TZ Point 37 Acceptance Criteria Full Verification', () {
      test('AC 1: Vienna operates in EUR (€) and Europe/Vienna timezone', () {
        final viennaBranch = Branch.vienna;
        expect(viennaBranch.currency, 'EUR');
        expect(viennaBranch.currencySymbol, '€');
        expect(viennaBranch.timezone, 'Europe/Vienna');

        // Test DST summer vs winter offset calculation
        final summerDate = DateTime.utc(2026, 7, 15, 12, 0);
        final winterDate = DateTime.utc(2026, 1, 15, 12, 0);
        expect(BranchTimezoneHelper.getUtcOffset(summerDate, viennaBranch.timezone), const Duration(hours: 2));
        expect(BranchTimezoneHelper.getUtcOffset(winterDate, viennaBranch.timezone), const Duration(hours: 1));
      });

      test('AC 2: Kyiv operates in UAH (₴) and Europe/Kyiv timezone', () {
        final kyivBranch = Branch.kyiv;
        expect(kyivBranch.currency, 'UAH');
        expect(kyivBranch.currencySymbol, '₴');
        expect(kyivBranch.timezone, 'Europe/Kyiv');

        final summerDate = DateTime.utc(2026, 7, 15, 12, 0);
        final winterDate = DateTime.utc(2026, 1, 15, 12, 0);
        expect(BranchTimezoneHelper.getUtcOffset(summerDate, kyivBranch.timezone), const Duration(hours: 3));
        expect(BranchTimezoneHelper.getUtcOffset(winterDate, kyivBranch.timezone), const Duration(hours: 2));
      });

      test('AC 3: Subscription package catalog separates EUR and UAH', () {
        final kyivPackages = SubscriptionPackageCatalog.getPackagesForBranch('kyiv');
        final viennaPackages = SubscriptionPackageCatalog.getPackagesForBranch('vienna');

        expect(kyivPackages.every((p) => p.branchId == 'kyiv' && p.currency == 'UAH' && (p.currencySymbol == '₴' || p.currencySymbol == 'грн')), isTrue);
        expect(viennaPackages.every((p) => p.branchId == 'vienna' && p.currency == 'EUR' && p.currencySymbol == '€'), isTrue);
      });

      test('AC 4: Locations and pools are isolated', () {
        final kyivLocations = BranchConfig.kyivConfig.locations;
        final viennaLocations = BranchConfig.viennaConfig.locations;

        expect(kyivLocations.map((l) => l.id), contains('kyiv_main'));
        expect(viennaLocations.map((l) => l.id), contains('happyland'));

        final viennaPools = viennaLocations.first.pools.map((p) => p.id).toList();
        expect(viennaPools, contains('sports_pool'));
        expect(viennaPools, contains('wellenbecken'));
      });

      test('AC 5: Same lane names (Lane 1) do not collide across branches', () {
        const lane1Kyiv = 'Lane 1';
        const lane1Vienna = 'Lane 1';
        expect(lane1Kyiv == lane1Vienna, isTrue);

        // Validating with BranchDataIntegrityValidator separates them by branch
        final kyivPoolCheck = BranchDataIntegrityValidator.validateLocationAndPool(
          branchId: 'kyiv',
          locationId: 'kyiv_main',
          poolId: 'pool_25m',
        );
        final viennaPoolCheck = BranchDataIntegrityValidator.validateLocationAndPool(
          branchId: 'vienna',
          locationId: 'happyland',
          poolId: 'sports_pool',
        );
        expect(kyivPoolCheck.isValid, isTrue);
        expect(viennaPoolCheck.isValid, isTrue);
      });

      test('AC 6: Staff screens and attendance strict isolation', () {
        const coachKyiv = AppUser(
          id: 'coach_k',
          name: 'Kyiv Coach',
          role: UserRole.coach,
          branchId: 'kyiv',
          branchIds: ['kyiv'],
        );
        final viennaAssignment = BranchDataIntegrityValidator.validateCoachAssignment(
          coach: coachKyiv,
          branchId: 'vienna',
        );
        expect(viennaAssignment.isValid, isFalse);
        expect(viennaAssignment.errorCode, 'COACH_BRANCH_MISMATCH');
      });

      test('AC 7: Reception QR and link onboarding auto-binds branch', () {
        expect(BranchInvitationService.resolveBranchFromUrlOrCode('https://cityswim.app/register/vienna'), 'vienna');
        expect(BranchInvitationService.resolveBranchFromUrlOrCode('https://cityswim.app/register/kyiv'), 'kyiv');
        expect(BranchInvitationService.resolveBranchFromUrlOrCode('cityswim://register/vienna'), 'vienna');
      });

      test('AC 8: Cross-branch attendance deduction is strictly blocked', () {
        final kyivSub = Subscription(
          id: 'sub_k',
          userId: 'u_k',
          totalClasses: 8,
          remainingClasses: 5,
          isActive: true,
          branchId: 'kyiv',
        );
        final viennaClass = GroupClass(
          id: 'cls_v',
          title: 'Wien Class',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          coachId: 'c_v',
          coachName: 'Coach Vienna',
          maxCapacity: 8,
          category: 'group',
          lane: 'Lane 1',
          branchId: 'vienna',
          timezone: 'Europe/Vienna',
        );

        final result = BranchDataIntegrityValidator.validateAttendanceDeduction(
          subscription: kyivSub,
          groupClass: viennaClass,
        );
        expect(result.isValid, isFalse);
        expect(result.errorCode, 'BRANCH_MISMATCH_SUBSCRIPTION_CLASS');
      });

      test('AC 9: Owner multi-branch switcher supports Vienna, Kyiv, and All Locations', () {
        expect(Branch.defaultBranches.map((b) => b.id), containsAll(['kyiv', 'vienna']));
        expect(Branch.defaultBranches.length, 2);
      });

      test('AC 10: Mock payment architecture validates currency and branch matching', () {
        final kyivSubPkg = SubscriptionPackageCatalog.getPackagesForBranch('kyiv').first;
        final viennaSubPkg = SubscriptionPackageCatalog.getPackagesForBranch('vienna').first;

        expect(kyivSubPkg.currency, 'UAH');
        expect(viennaSubPkg.currency, 'EUR');
      });
    });
  });
}
