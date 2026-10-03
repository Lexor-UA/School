import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../tenancy/controllers/tenancy_controller.dart';
import '../../payment/models/payment_transaction.dart';
import '../../admin/controllers/admin_dashboard_controller.dart';

/// Фінансові та операційні показники для конкретної філії
class BranchFinancialSummary {
  final String branchId;
  final String branchName;
  final String flagEmoji;
  final String currencySymbol;
  final String currencyCode;
  final double totalRevenue;
  final double expenses;
  final double netProfit;
  final double childRevenue;
  final double adultRevenue;
  final double revenueGrowth; // у відсотках, напр. 12.5
  final int clientCount;
  final int coachCount;
  final int occupancyPercent;
  final double ltv;
  final double averageCheck;
  final int newSubscriptions;
  final double churnPercent;

  const BranchFinancialSummary({
    required this.branchId,
    required this.branchName,
    required this.flagEmoji,
    required this.currencySymbol,
    required this.currencyCode,
    required this.totalRevenue,
    required this.expenses,
    required this.netProfit,
    required this.childRevenue,
    required this.adultRevenue,
    required this.revenueGrowth,
    required this.clientCount,
    required this.coachCount,
    required this.occupancyPercent,
    required this.ltv,
    required this.averageCheck,
    required this.newSubscriptions,
    required this.churnPercent,
  });

  /// Форматування суми з символом валюти (наприклад: "124 500 ₴" або "€ 14,850")
  String formatRevenue() => formatMoney(totalRevenue);
  String formatExpenses() => formatMoney(expenses);
  String formatNetProfit() => formatMoney(netProfit);
  String formatLtv() => formatMoney(ltv);

  String formatMoney(double amount) {
    final formattedNum = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
    if (currencySymbol == '€') {
      return '€ $formattedNum';
    }
    return '$formattedNum $currencySymbol';
  }
}

/// Стан аналітики для Власника з підтримкою ізоляції філій та мультивалютності (ТЗ п. 8, 26)
class OwnerAnalyticsState {
  final BranchFinancialSummary kyiv;
  final BranchFinancialSummary vienna;
  final String? activeBranchId;
  final bool isAllLocations;
  final String selectedTimeframe; // 'Тиждень', 'Місяць', 'Квартал', 'Рік'
  final List<PaymentTransaction> recentTransactions;

  const OwnerAnalyticsState({
    required this.kyiv,
    required this.vienna,
    required this.activeBranchId,
    required this.isAllLocations,
    required this.recentTransactions,
    this.selectedTimeframe = 'Місяць',
  });

  /// Чи активний Відень
  bool get isViennaSelected => !isAllLocations && activeBranchId == 'vienna';

  /// Чи активний Київ
  bool get isKyivSelected => !isAllLocations && (activeBranchId == 'kyiv' || activeBranchId == null);

  /// Метрики обраної філії (для одноголокаційного режиму)
  BranchFinancialSummary get currentBranchSummary {
    if (isViennaSelected) return vienna;
    return kyiv;
  }

  /// Загальна кількість клієнтів (сумування дозволено згідно з ТЗ п. 8)
  int get totalClients => kyiv.clientCount + vienna.clientCount;

  /// Загальна кількість тренерів
  int get totalCoaches => kyiv.coachCount + vienna.coachCount;

  /// Середня заповнюваність басейнів
  int get averageOccupancy => ((kyiv.occupancyPercent + vienna.occupancyPercent) / 2).round();

  /// Загальна кількість нових абонементів
  int get totalNewSubscriptions => kyiv.newSubscriptions + vienna.newSubscriptions;

  OwnerAnalyticsState copyWith({
    BranchFinancialSummary? kyiv,
    BranchFinancialSummary? vienna,
    String? activeBranchId,
    bool? isAllLocations,
    String? selectedTimeframe,
    List<PaymentTransaction>? recentTransactions,
  }) {
    return OwnerAnalyticsState(
      kyiv: kyiv ?? this.kyiv,
      vienna: vienna ?? this.vienna,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      isAllLocations: isAllLocations ?? this.isAllLocations,
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}

/// Провайдер потоку платежів для аналітики
final ownerPaymentsProvider = StreamProvider.autoDispose<List<PaymentTransaction>>((ref) {
  return FirebaseFirestore.instance
      .collection('payments')
      .where('status', isEqualTo: 'completed')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => PaymentTransaction.fromMap(doc.data(), id: doc.id)).toList();
  });
});

/// Контролер аналітики Власника
class OwnerAnalyticsNotifier extends Notifier<OwnerAnalyticsState> {
  String _currentTimeframe = 'Місяць';

  @override
  OwnerAnalyticsState build() {
    return _calculateState(_currentTimeframe);
  }

  OwnerAnalyticsState _calculateState(String timeframe) {
    final tenancyState = ref.watch(tenancyControllerProvider);
    final adminDashboard = ref.watch(adminDashboardProvider);
    final allPayments = ref.watch(ownerPaymentsProvider).value ?? [];

    final now = DateTime.now();
    DateTime startDate;
    if (timeframe == 'День') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (timeframe == 'Тиждень') {
      var d = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(d.year, d.month, d.day);
    } else { // 'Місяць'
      startDate = DateTime(now.year, now.month, 1);
    }

    final payments = allPayments.where((p) {
      return p.createdAt.isAfter(startDate) || p.createdAt.isAtSameMomentAs(startDate);
    }).toList();

    // Calculate Kyiv Revenue
    final kyivPayments = payments.where((p) => p.branchId == 'kyiv');
    final double kyivRevenue = kyivPayments.fold(0.0, (acc, p) => acc + p.amount);
    final double kyivChildRevenue = kyivPayments
        .where((p) => p.packageId.contains('child') || (p.childId != null && p.childId!.isNotEmpty))
        .fold(0.0, (acc, p) => acc + p.amount);
    final double kyivAdultRevenue = kyivRevenue - kyivChildRevenue;
    final int kyivClients = adminDashboard.branchMetrics['kyiv']?.activeClientsCount ?? 0;
    final double kyivProfit = kyivRevenue * 0.676; // Зашита маржа 67.6% (Варіант А)
    final double kyivExpenses = kyivRevenue - kyivProfit;
    final double kyivLtv = kyivClients > 0 ? (kyivRevenue / kyivClients) : 0;

    final double kyivAvgCheck = kyivPayments.isNotEmpty ? kyivRevenue / kyivPayments.length : 0;
    final int kyivNewSubs = kyivPayments.length; // Counting all subscription purchases

    final kyivSummary = BranchFinancialSummary(
      branchId: 'kyiv',
      branchName: 'CitySwim Kyiv',
      flagEmoji: '🇺🇦',
      currencySymbol: '₴',
      currencyCode: 'UAH',
      totalRevenue: kyivRevenue,
      expenses: kyivExpenses,
      netProfit: kyivProfit,
      childRevenue: kyivChildRevenue,
      adultRevenue: kyivAdultRevenue,
      revenueGrowth: 0.0, // TODO: calculate vs last month
      clientCount: kyivClients,
      coachCount: adminDashboard.branchMetrics['kyiv']?.totalCoachesCount ?? 0,
      occupancyPercent: 84, // TODO: calculate real occupancy
      ltv: kyivLtv,
      averageCheck: kyivAvgCheck,
      newSubscriptions: kyivNewSubs,
      churnPercent: 2.4, // Hardcoded for now
    );

    // Calculate Vienna Revenue
    final viennaPayments = payments.where((p) => p.branchId == 'vienna');
    final double viennaRevenue = viennaPayments.fold(0.0, (acc, p) => acc + p.amount);
    final double viennaChildRevenue = viennaPayments
        .where((p) => p.packageId.contains('child') || (p.childId != null && p.childId!.isNotEmpty))
        .fold(0.0, (acc, p) => acc + p.amount);
    final double viennaAdultRevenue = viennaRevenue - viennaChildRevenue;
    final int viennaClients = adminDashboard.branchMetrics['vienna']?.activeClientsCount ?? 0;
    final double viennaProfit = viennaRevenue * 0.676;
    final double viennaExpenses = viennaRevenue - viennaProfit;
    final double viennaLtv = viennaClients > 0 ? (viennaRevenue / viennaClients) : 0;

    final double viennaAvgCheck = viennaPayments.isNotEmpty ? viennaRevenue / viennaPayments.length : 0;
    final int viennaNewSubs = viennaPayments.length;

    final viennaSummary = BranchFinancialSummary(
      branchId: 'vienna',
      branchName: 'CitySwim Vienna',
      flagEmoji: '🇦🇹',
      currencySymbol: '€',
      currencyCode: 'EUR',
      totalRevenue: viennaRevenue,
      expenses: viennaExpenses,
      netProfit: viennaProfit,
      childRevenue: viennaChildRevenue,
      adultRevenue: viennaAdultRevenue,
      revenueGrowth: 0.0,
      clientCount: viennaClients,
      coachCount: adminDashboard.branchMetrics['vienna']?.totalCoachesCount ?? 0,
      occupancyPercent: 76,
      ltv: viennaLtv,
      averageCheck: viennaAvgCheck,
      newSubscriptions: viennaNewSubs,
      churnPercent: 1.8,
    );

    // Prepare recent transactions sorted by date
    var sortedPayments = List<PaymentTransaction>.from(allPayments); // Show all recent regardless of timeframe
    if (!tenancyState.isAllLocationsSelected && tenancyState.activeBranchId != null) {
      sortedPayments = sortedPayments.where((p) => p.branchId == tenancyState.activeBranchId).toList();
    }
    sortedPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return OwnerAnalyticsState(
      kyiv: kyivSummary,
      vienna: viennaSummary,
      activeBranchId: tenancyState.activeBranchId,
      isAllLocations: tenancyState.isAllLocationsSelected,
      recentTransactions: sortedPayments,
      selectedTimeframe: timeframe,
    );
  }

  /// Зміна часового проміжку
  void setTimeframe(String timeframe) {
    _currentTimeframe = timeframe;
    state = _calculateState(timeframe);
  }
}

/// Riverpod провайдер для аналітики Власника
final ownerAnalyticsControllerProvider =
    NotifierProvider<OwnerAnalyticsNotifier, OwnerAnalyticsState>(
  OwnerAnalyticsNotifier.new,
);
