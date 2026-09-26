import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tenancy/controllers/tenancy_controller.dart';

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
  final double revenueGrowth; // у відсотках, напр. 12.5
  final int clientCount;
  final int coachCount;
  final int occupancyPercent;
  final double ltv;
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
    required this.revenueGrowth,
    required this.clientCount,
    required this.coachCount,
    required this.occupancyPercent,
    required this.ltv,
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

  const OwnerAnalyticsState({
    required this.kyiv,
    required this.vienna,
    required this.activeBranchId,
    required this.isAllLocations,
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
  }) {
    return OwnerAnalyticsState(
      kyiv: kyiv ?? this.kyiv,
      vienna: vienna ?? this.vienna,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      isAllLocations: isAllLocations ?? this.isAllLocations,
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
    );
  }
}

/// Контролер аналітики Власника
class OwnerAnalyticsNotifier extends Notifier<OwnerAnalyticsState> {
  @override
  OwnerAnalyticsState build() {
    final tenancyState = ref.watch(tenancyControllerProvider);

    // Базові перевірені метрики для Києва (UAH)
    const kyivSummary = BranchFinancialSummary(
      branchId: 'kyiv',
      branchName: 'CitySwim Kyiv',
      flagEmoji: '🇺🇦',
      currencySymbol: '₴',
      currencyCode: 'UAH',
      totalRevenue: 124500,
      expenses: 40300,
      netProfit: 84200,
      revenueGrowth: 12.5,
      clientCount: 412,
      coachCount: 8,
      occupancyPercent: 84,
      ltv: 12400,
      newSubscriptions: 84,
      churnPercent: 2.4,
    );

    // Базові метрики для Відня (EUR, ТЗ п. 8: 14 850 €)
    const viennaSummary = BranchFinancialSummary(
      branchId: 'vienna',
      branchName: 'CitySwim Vienna',
      flagEmoji: '🇦🇹',
      currencySymbol: '€',
      currencyCode: 'EUR',
      totalRevenue: 14850,
      expenses: 5200,
      netProfit: 9650,
      revenueGrowth: 18.2,
      clientCount: 68,
      coachCount: 3,
      occupancyPercent: 76,
      ltv: 850,
      newSubscriptions: 14,
      churnPercent: 1.8,
    );

    return OwnerAnalyticsState(
      kyiv: kyivSummary,
      vienna: viennaSummary,
      activeBranchId: tenancyState.activeBranchId,
      isAllLocations: tenancyState.isAllLocations,
    );
  }

  /// Зміна часового проміжку
  void setTimeframe(String timeframe) {
    state = state.copyWith(selectedTimeframe: timeframe);
  }
}

/// Riverpod провайдер для аналітики Власника
final ownerAnalyticsControllerProvider =
    NotifierProvider<OwnerAnalyticsNotifier, OwnerAnalyticsState>(
  OwnerAnalyticsNotifier.new,
);
