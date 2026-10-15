import 'package:flutter/foundation.dart';

/// Конфігурація платіжного шлюзу для конкретної філії (ТЗ п. 20, 21, 22)
/// Архітектура забезпечує розділення провайдерів (LiqPay для Києва, Stripe для Відня)
/// у безпечному тестовому режимі без підключення живих платіжних API.
@immutable
class BranchPaymentConfig {
  final String branchId;
  final String organizationId;
  final String provider; // 'liqpay', 'stripe'
  final String gatewayName; // 'LiqPay', 'Stripe'
  final String currency; // 'UAH', 'EUR'
  final String currencySymbol; // '₴', '€'
  final List<String> supportedMethods; // ['card', 'apple_pay', 'google_pay', 'sepa']
  final bool isTestMode;
  final Map<String, String> legalEntityDetails;

  const BranchPaymentConfig({
    required this.branchId,
    this.organizationId = 'cityswim',
    required this.provider,
    required this.gatewayName,
    required this.currency,
    required this.currencySymbol,
    required this.supportedMethods,
    this.isTestMode = true,
    required this.legalEntityDetails,
  });

  /// Конфігурація шлюзу для CitySwim Kyiv (🇺🇦 LiqPay, UAH ₴)
  static const BranchPaymentConfig kyiv = BranchPaymentConfig(
    branchId: 'kyiv',
    organizationId: 'cityswim',
    provider: 'liqpay',
    gatewayName: 'LiqPay',
    currency: 'UAH',
    currencySymbol: '₴',
    supportedMethods: ['apple_pay', 'google_pay', 'card', 'privat24'],
    isTestMode: true,
    legalEntityDetails: {
      'companyName': 'ТОВ "СітіСвім Україна"',
      'taxIdLabel': 'ЄДРПОУ',
      'taxId': '43892104',
      'address': 'м. Київ, вул. Ділова, 10, Басейн CitySwim',
      'iban': 'UA82305299000002600123456789',
      'bankName': 'АТ КБ "ПриватБанк"',
      'country': 'Україна',
    },
  );

  /// Конфігурація шлюзу для CitySwim Vienna (🇦🇹 Stripe, EUR €)
  static const BranchPaymentConfig vienna = BranchPaymentConfig(
    branchId: 'vienna',
    organizationId: 'cityswim',
    provider: 'stripe',
    gatewayName: 'Stripe',
    currency: 'EUR',
    currencySymbol: '€',
    supportedMethods: ['apple_pay', 'google_pay', 'card', 'sepa', 'eps'],
    isTestMode: true,
    legalEntityDetails: {
      'companyName': 'CitySwim Vienna GmbH',
      'taxIdLabel': 'UID-Nummer',
      'taxId': 'ATU78945612',
      'address': 'In der Au 1, 3400 Klosterneuburg, HappyLand',
      'iban': 'AT893700000001234567',
      'bankName': 'Erste Bank der oesterreichischen Sparkassen AG',
      'zvrNumber': '987654321',
      'country': 'Österreich',
    },
  );

  /// Отримати конфігурацію для відповідної філії
  static BranchPaymentConfig forBranch(String branchId) {
    if (branchId == 'vienna') {
      return vienna;
    }
    return kyiv;
  }

  Map<String, dynamic> toMap() => {
    'branchId': branchId,
    'organizationId': organizationId,
    'provider': provider,
    'gatewayName': gatewayName,
    'currency': currency,
    'currencySymbol': currencySymbol,
    'supportedMethods': supportedMethods,
    'isTestMode': isTestMode,
    'legalEntityDetails': legalEntityDetails,
  };

  BranchPaymentConfig copyWith({
    String? branchId,
    String? organizationId,
    String? provider,
    String? gatewayName,
    String? currency,
    String? currencySymbol,
    List<String>? supportedMethods,
    bool? isTestMode,
    Map<String, String>? legalEntityDetails,
  }) {
    return BranchPaymentConfig(
      branchId: branchId ?? this.branchId,
      organizationId: organizationId ?? this.organizationId,
      provider: provider ?? this.provider,
      gatewayName: gatewayName ?? this.gatewayName,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      supportedMethods: supportedMethods ?? this.supportedMethods,
      isTestMode: isTestMode ?? this.isTestMode,
      legalEntityDetails: legalEntityDetails ?? this.legalEntityDetails,
    );
  }

  factory BranchPaymentConfig.fromMap(Map<String, dynamic> map, {required String defaultBranchId}) {
    final base = BranchPaymentConfig.forBranch(defaultBranchId);
    final rawDetails = map['legalEntityDetails'] as Map<String, dynamic>?;
    final Map<String, String> details = rawDetails != null
        ? rawDetails.map((k, v) => MapEntry(k, v.toString()))
        : Map<String, String>.from(base.legalEntityDetails);

    return BranchPaymentConfig(
      branchId: map['branchId'] as String? ?? base.branchId,
      organizationId: map['organizationId'] as String? ?? base.organizationId,
      provider: map['provider'] as String? ?? base.provider,
      gatewayName: map['gatewayName'] as String? ?? base.gatewayName,
      currency: map['currency'] as String? ?? base.currency,
      currencySymbol: map['currencySymbol'] as String? ?? base.currencySymbol,
      supportedMethods: (map['supportedMethods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? base.supportedMethods,
      isTestMode: map['isTestMode'] as bool? ?? base.isTestMode,
      legalEntityDetails: details,
    );
  }
}
