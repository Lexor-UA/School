import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/owner/controllers/owner_analytics_controller.dart';
import 'package:swimming_school_app/features/payment/models/payment_transaction.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';

class FakeAuthController extends AuthController {
  final AppUser? _user;
  FakeAuthController(this._user);

  @override
  AppUser? build() => _user;
}

List<PaymentTransaction> generateTestPayments() {
  final now = DateTime.now();
  final list = <PaymentTransaction>[];

  // 84 транзакції Києва із загальною сумою 124 500 ₴
  const kyivTotal = 124500.0;
  final kyivStep = (kyivTotal / 84).floorToDouble();
  double currentKyivSum = 0;
  for (int i = 0; i < 84; i++) {
    final amount = (i == 83) ? (kyivTotal - currentKyivSum) : kyivStep;
    currentKyivSum += amount;
    list.add(PaymentTransaction(
      id: 'pay_kyiv_$i',
      branchId: 'kyiv',
      clientId: 'client_kyiv_$i',
      clientName: 'Клієнт Київ $i',
      packageId: 'pkg_child_$i',
      packageName: 'Абонемент $i',
      amount: amount,
      currency: 'UAH',
      currencySymbol: '₴',
      paymentGateway: 'liqpay',
      status: PaymentStatus.completed,
      transactionId: 'tx_k_$i',
      receiptNumber: 'REC-K-$i',
      paymentMethod: 'card',
      createdAt: now,
    ));
  }

  // 14 транзакцій Відня із загальною сумою 14 850 €
  const viennaTotal = 14850.0;
  final viennaStep = (viennaTotal / 14).floorToDouble();
  double currentViennaSum = 0;
  for (int i = 0; i < 14; i++) {
    final amount = (i == 13) ? (viennaTotal - currentViennaSum) : viennaStep;
    currentViennaSum += amount;
    list.add(PaymentTransaction(
      id: 'pay_vienna_$i',
      branchId: 'vienna',
      clientId: 'client_vienna_$i',
      clientName: 'Client Vienna $i',
      packageId: 'pkg_child_v_$i',
      packageName: 'Einheit $i',
      amount: amount,
      currency: 'EUR',
      currencySymbol: '€',
      paymentGateway: 'stripe',
      status: PaymentStatus.completed,
      transactionId: 'tx_v_$i',
      receiptNumber: 'REC-V-$i',
      paymentMethod: 'card',
      createdAt: now,
    ));
  }

  return list;
}

AdminDashboardState generateTestAdminDashboard() {
  return AdminDashboardState(
    branchMetrics: {
      'kyiv': const BranchSummaryMetric(
        branchId: 'kyiv',
        branchName: 'CitySwim Kyiv',
        currencySymbol: '₴',
        flagEmoji: '🇺🇦',
        activeClientsCount: 412,
        todayClassesCount: 12,
        totalCoachesCount: 8,
        ongoingClassesCount: 2,
        unpaidSubscriptions: 5,
      ),
      'vienna': const BranchSummaryMetric(
        branchId: 'vienna',
        branchName: 'CitySwim Vienna',
        currencySymbol: '€',
        flagEmoji: '🇦🇹',
        activeClientsCount: 68,
        todayClassesCount: 4,
        totalCoachesCount: 3,
        ongoingClassesCount: 1,
        unpaidSubscriptions: 1,
      ),
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Stage 5: Owner Switcher & Multi-Branch Analytics Tests (TZ Point 8 & 26)', () {
    const ownerUser = AppUser(
      id: 'owner_alex',
      name: 'Олександр Власник',
      role: UserRole.owner,
      organizationId: 'cityswim',
      branchIds: ['kyiv', 'vienna'],
    );

    test('Zero transactions state correctly reports 0 revenue and 0 profit', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(ownerUser)),
          ownerPaymentsProvider.overrideWithValue([]),
        ],
      );

      final analytics = container.read(ownerAnalyticsControllerProvider);
      expect(analytics.kyiv.totalRevenue, equals(0.0));
      expect(analytics.kyiv.netProfit, equals(0.0));
      expect(analytics.kyiv.expenses, equals(0.0));
      expect(analytics.kyiv.formatRevenue(), equals('0 ₴'));

      expect(analytics.vienna.totalRevenue, equals(0.0));
      expect(analytics.vienna.netProfit, equals(0.0));
      expect(analytics.vienna.expenses, equals(0.0));
      expect(analytics.vienna.formatRevenue(), equals('€ 0'));
    });

    test('Owner defaults to Kyiv branch with UAH (₴) revenue metrics', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(ownerUser)),
          ownerPaymentsProvider.overrideWithValue(generateTestPayments()),
          adminDashboardProvider.overrideWith((ref) => generateTestAdminDashboard()),
        ],
      );

      final tenancy = container.read(tenancyControllerProvider);
      final analytics = container.read(ownerAnalyticsControllerProvider);

      expect(tenancy.isAllLocations, isFalse);
      expect(tenancy.effectiveBranch.id, equals('kyiv'));
      expect(analytics.isKyivSelected, isTrue);
      expect(analytics.isViennaSelected, isFalse);

      final kyiv = analytics.currentBranchSummary;
      expect(kyiv.branchId, equals('kyiv'));
      expect(kyiv.currencySymbol, equals('₴'));
      expect(kyiv.currencyCode, equals('UAH'));
      expect(kyiv.totalRevenue, equals(124500));
      expect(kyiv.formatRevenue(), contains('124 500 ₴'));
      expect(kyiv.clientCount, equals(412));
    });

    test('Owner switches to Vienna and sees isolated EUR (€) metrics (14,850 €)', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(ownerUser)),
          ownerPaymentsProvider.overrideWithValue(generateTestPayments()),
          adminDashboardProvider.overrideWith((ref) => generateTestAdminDashboard()),
        ],
      );

      // Switch to Vienna
      await container.read(tenancyControllerProvider.notifier).switchBranch('vienna');

      final tenancy = container.read(tenancyControllerProvider);
      final analytics = container.read(ownerAnalyticsControllerProvider);

      expect(tenancy.isAllLocations, isFalse);
      expect(tenancy.activeBranch?.id, equals('vienna'));
      expect(analytics.isViennaSelected, isTrue);
      expect(analytics.isKyivSelected, isFalse);

      final vienna = analytics.currentBranchSummary;
      expect(vienna.branchId, equals('vienna'));
      expect(vienna.currencySymbol, equals('€'));
      expect(vienna.currencyCode, equals('EUR'));
      expect(vienna.totalRevenue, equals(14850)); // ТЗ п. 8: 14 850 €
      expect(vienna.formatRevenue(), contains('€ 14 850'));
      expect(vienna.netProfit, equals(9650));
      expect(vienna.clientCount, equals(68));
    });

    test('Owner switches to "All locations" mode and currencies are strictly separated (NEVER summed)', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(ownerUser)),
          ownerPaymentsProvider.overrideWithValue(generateTestPayments()),
          adminDashboardProvider.overrideWith((ref) => generateTestAdminDashboard()),
        ],
      );

      // Switch to All Locations
      await container.read(tenancyControllerProvider.notifier).switchBranch('all');

      final tenancy = container.read(tenancyControllerProvider);
      final analytics = container.read(ownerAnalyticsControllerProvider);

      expect(tenancy.isAllLocations, isTrue);
      expect(tenancy.activeBranch, isNull);
      expect(analytics.isAllLocations, isTrue);

      // Verify that currency symbol in All Locations mode reflects dual currency
      expect(tenancy.currencySymbol, equals('₴ / €'));
      expect(tenancy.currencyCode, equals('UAH / EUR'));

      // ТЗ п. 8: Дохід показується роздільно по філіях і валютах:
      // Відень — 14 850 €, Київ — 124 500 ₴
      expect(analytics.kyiv.totalRevenue, equals(124500));
      expect(analytics.vienna.totalRevenue, equals(14850));
      expect(analytics.kyiv.currencySymbol, equals('₴'));
      expect(analytics.vienna.currencySymbol, equals('€'));

      // Distinct formatted strings without mixing
      expect(analytics.kyiv.formatRevenue(), equals('124 500 ₴'));
      expect(analytics.vienna.formatRevenue(), equals('€ 14 850'));

      // ТЗ п. 8: кількість клієнтів/тренерів може сумуватися, але з можливістю бачити розбивку
      expect(analytics.totalClients, equals(480)); // 412 + 68
      expect(analytics.kyiv.clientCount, equals(412));
      expect(analytics.vienna.clientCount, equals(68));

      expect(analytics.totalCoaches, equals(11)); // 8 + 3
      expect(analytics.kyiv.coachCount, equals(8));
      expect(analytics.vienna.coachCount, equals(3));

      expect(analytics.totalNewSubscriptions, equals(98)); // 84 + 14
    });

    test('Selected branch is saved in SharedPreferences for Owner session persistence', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeAuthController(ownerUser)),
        ],
      );

      await container.read(tenancyControllerProvider.notifier).switchBranch('vienna');
      expect(prefs.getString('selected_branch_id'), equals('vienna'));

      await container.read(tenancyControllerProvider.notifier).switchBranch('all');
      expect(prefs.getString('selected_branch_id'), equals('all'));

      await container.read(tenancyControllerProvider.notifier).switchBranch('kyiv');
      expect(prefs.getString('selected_branch_id'), equals('kyiv'));
    });
  });
}
