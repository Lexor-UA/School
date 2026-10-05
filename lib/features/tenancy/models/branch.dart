import 'package:flutter/foundation.dart';

@immutable
class Branch {
  final String id;
  final String organizationId;
  final String name;
  final String country; // 'UA', 'AT', etc.
  final String city; // 'Kyiv', 'Vienna', etc.
  final String timezone; // 'Europe/Kyiv', 'Europe/Vienna', etc.
  final String currency; // 'UAH', 'EUR', etc.
  final String currencySymbol; // '₴', '€', etc.
  final String defaultLanguage; // 'uk', 'de', 'en'
  final String paymentProvider; // 'liqpay', 'stripe'
  final String status; // 'active', 'inactive'
  final bool isProtected; // Захист від випадкового видалення
  final DateTime createdAt;

  const Branch({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.country,
    required this.city,
    required this.timezone,
    required this.currency,
    required this.currencySymbol,
    required this.defaultLanguage,
    required this.paymentProvider,
    this.status = 'active',
    this.isProtected = false,
    required this.createdAt,
  });

  /// Чи є філія базовою системною (Київ або Відень)
  bool get isSystemDefault => id == 'kyiv' || id == 'vienna';

  String get currencyCode => currency;

  /// Філія Київ
  static final Branch kyiv = Branch(
    id: 'kyiv',
    organizationId: 'cityswim',
    name: 'Kyiv',
    country: 'UA',
    city: 'Kyiv',
    timezone: 'Europe/Kyiv',
    currency: 'UAH',
    currencySymbol: '₴',
    defaultLanguage: 'uk',
    paymentProvider: 'liqpay',
    status: 'active',
    isProtected: true,
    createdAt: DateTime(2025, 1, 1),
  );

  /// Філія Відень
  static final Branch vienna = Branch(
    id: 'vienna',
    organizationId: 'cityswim',
    name: 'Vienna',
    country: 'AT',
    city: 'Vienna',
    timezone: 'Europe/Vienna',
    currency: 'EUR',
    currencySymbol: '€',
    defaultLanguage: 'de',
    paymentProvider: 'stripe',
    status: 'active',
    isProtected: true,
    createdAt: DateTime(2025, 1, 1),
  );

  /// Список дефолтних філій CitySwim
  static final List<Branch> defaultBranches = [kyiv, vienna];

  /// Емодзі прапора країни
  String get flagEmoji {
    final code = country.toUpperCase();
    switch (code) {
      case 'UA':
        return '🇺🇦';
      case 'AT':
        return '🇦🇹';
      case 'DE':
        return '🇩🇪';
      case 'PL':
        return '🇵🇱';
      case 'AE':
        return '🇦🇪';
      case 'ES':
        return '🇪🇸';
      case 'US':
        return '🇺🇸';
      case 'GB':
        return '🇬🇧';
      case 'FR':
        return '🇫🇷';
      case 'IT':
        return '🇮🇹';
      default:
        if (code.length == 2 && code.codeUnits.every((c) => c >= 65 && c <= 90)) {
          final first = String.fromCharCode(0x1F1E6 + code.codeUnitAt(0) - 65);
          final second = String.fromCharCode(0x1F1E6 + code.codeUnitAt(1) - 65);
          return '$first$second';
        }
        return '📍';
    }
  }

  String get flag => flagEmoji;

  /// Підтримувані мови для філії (всі 4 мови доступні в будь-якій філії)
  List<String> get supportedLanguages => const ['uk', 'ru', 'en', 'de'];

  /// Локалізована назва міста для UI
  String localizedCity(String languageCode) {
    if (id == 'kyiv') {
      switch (languageCode) {
        case 'uk':
          return 'Київ';
        case 'ru':
          return 'Киев';
        case 'de':
          return 'Kiew';
        default:
          return 'Kyiv';
      }
    } else if (id == 'vienna') {
      switch (languageCode) {
        case 'uk':
          return 'Відень';
        case 'ru':
          return 'Вена';
        case 'de':
          return 'Wien';
        default:
          return 'Vienna';
      }
    }
    return city;
  }

  Branch copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? country,
    String? city,
    String? timezone,
    String? currency,
    String? currencySymbol,
    String? defaultLanguage,
    String? paymentProvider,
    String? status,
    bool? isProtected,
    DateTime? createdAt,
  }) {
    return Branch(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      status: status ?? this.status,
      isProtected: isProtected ?? this.isProtected,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'name': name,
    'country': country,
    'city': city,
    'timezone': timezone,
    'currency': currency,
    'currencySymbol': currencySymbol,
    'defaultLanguage': defaultLanguage,
    'paymentProvider': paymentProvider,
    'status': status,
    'isProtected': isProtected,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Branch.fromJson(Map<String, dynamic> json) {
    final branchId = json['id'] as String? ?? 'kyiv';
    final isSystem = branchId == 'kyiv' || branchId == 'vienna';
    return Branch(
      id: branchId,
      organizationId: json['organizationId'] as String? ?? 'cityswim',
      name: json['name'] as String? ?? 'Kyiv',
      country: json['country'] as String? ?? 'UA',
      city: json['city'] as String? ?? 'Kyiv',
      timezone: json['timezone'] as String? ?? 'Europe/Kyiv',
      currency: json['currency'] as String? ?? 'UAH',
      currencySymbol: json['currencySymbol'] as String? ?? '₴',
      defaultLanguage: json['defaultLanguage'] as String? ?? 'uk',
      paymentProvider: json['paymentProvider'] as String? ?? 'liqpay',
      status: json['status'] as String? ?? 'active',
      isProtected: json['isProtected'] as bool? ?? isSystem,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Branch(id: $id, name: $name, currency: $currency)';
}
