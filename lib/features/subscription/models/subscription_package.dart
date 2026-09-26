import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:swimming_school_app/shared/utils/currency_formatter.dart';

@immutable
class SubscriptionPackage {
  final String id;
  final String name;
  final String branchId;
  final int price;
  final String currency;
  final String currencySymbol;
  final int classes;
  final int validityDays;
  final bool? isAdult; // true: adult, false: child, null: split
  final bool isIndividual;
  final bool isSplit;
  final String? ageGroup; // '6-8', '9-15', etc.
  final Map<String, String>? localizedNames;
  final String? description;

  const SubscriptionPackage({
    required this.id,
    required this.name,
    required this.branchId,
    required this.price,
    required this.currency,
    required this.currencySymbol,
    required this.classes,
    required this.validityDays,
    this.isAdult,
    this.isIndividual = false,
    this.isSplit = false,
    this.ageGroup,
    this.localizedNames,
    this.description,
  });

  String get formattedPrice => '$price $currencySymbol';

  String get formattedPricePretty => CurrencyFormatter.formatPackagePrice(
    price: price,
    currency: currency,
    currencySymbol: currencySymbol,
  );

  String getLocalizedName(String langCode) {
    if (localizedNames != null && localizedNames!.containsKey(langCode)) {
      return localizedNames![langCode]!;
    }
    return name;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'branchId': branchId,
    'price': formattedPrice,
    'priceNum': price,
    'currency': currency,
    'currencySymbol': currencySymbol,
    'classes': classes,
    'validityDays': validityDays,
    'isAdult': isAdult,
    'isIndividual': isIndividual,
    'isSplit': isSplit,
    if (ageGroup != null) 'ageGroup': ageGroup,
    if (description != null) 'description': description,
  };
}

class SubscriptionPackageCatalog {
  /// Пакети для Kyiv (UAH ₴)
  static const List<SubscriptionPackage> kyivPackages = [
    // Базові тарифні пакети CitySwim Kyiv (ТЗ п. 13)
    SubscriptionPackage(
      id: 'kyiv_trial',
      name: 'Пробне заняття',
      branchId: 'kyiv',
      price: 0,
      currency: 'UAH',
      currencySymbol: '₴',
      classes: 1,
      validityDays: 14,
      isAdult: null,
      localizedNames: {
        'uk': 'Пробне заняття',
        'en': 'Trial Lesson',
        'de': 'Schnuppertraining',
      },
      description: 'Безкоштовне перше ознайомче тренування для нових плавців',
    ),
    SubscriptionPackage(
      id: 'kyiv_single',
      name: 'Разове заняття',
      branchId: 'kyiv',
      price: 450,
      currency: 'UAH',
      currencySymbol: '₴',
      classes: 1,
      validityDays: 30,
      isAdult: null,
      localizedNames: {
        'uk': 'Разове заняття',
        'en': 'Single Lesson',
        'de': 'Einzelstunde',
      },
      description: 'Одноразове відвідування тренування',
    ),
    SubscriptionPackage(
      id: 'kyiv_month_4',
      name: '4 заняття на місяць',
      branchId: 'kyiv',
      price: 1600,
      currency: 'UAH',
      currencySymbol: '₴',
      classes: 4,
      validityDays: 30,
      isAdult: null,
      localizedNames: {
        'uk': '4 заняття на місяць',
        'en': '4 Lessons / Month',
        'de': '4 Einheiten / Monat',
      },
      description: 'Абонемент на 4 заняття протягом 30 днів',
    ),
    SubscriptionPackage(
      id: 'kyiv_month_8',
      name: '8 занять на місяць',
      branchId: 'kyiv',
      price: 3000,
      currency: 'UAH',
      currencySymbol: '₴',
      classes: 8,
      validityDays: 30,
      isAdult: null,
      localizedNames: {
        'uk': '8 занять на місяць',
        'en': '8 Lessons / Month',
        'de': '8 Einheiten / Monat',
      },
      description: 'Стандартний абонемент на 8 занять (двічі на тиждень)',
    ),
    SubscriptionPackage(
      id: 'kyiv_month_12',
      name: '12 занять на місяць',
      branchId: 'kyiv',
      price: 4200,
      currency: 'UAH',
      currencySymbol: '₴',
      classes: 12,
      validityDays: 30,
      isAdult: null,
      localizedNames: {
        'uk': '12 занять на місяць',
        'en': '12 Lessons / Month',
        'de': '12 Einheiten / Monat',
      },
      description: 'Інтенсивний абонемент на 12 занять (тричі на тиждень)',
    ),
    SubscriptionPackage(
      id: 'kyiv_individual',
      name: 'Індивідуальне заняття',
      branchId: 'kyiv',
      price: 800,
      currency: 'UAH',
      currencySymbol: '₴',
      classes: 1,
      validityDays: 30,
      isAdult: null,
      isIndividual: true,
      localizedNames: {
        'uk': 'Індивідуальне заняття',
        'en': 'Individual Lesson',
        'de': 'Einzelunterricht',
      },
      description: 'Персональне тренування з тренером на виділеній доріжці',
    ),
    // Дитячі абонементи 6-8 років
    SubscriptionPackage(
      id: 'kyiv_child_6_8_4',
      name: 'Дитячий абонемент 6-8 років (4 тренування)',
      branchId: 'kyiv',
      price: 1200,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 4,
      validityDays: 30,
      isAdult: false,
      ageGroup: '6-8',
    ),
    SubscriptionPackage(
      id: 'kyiv_child_6_8_8',
      name: 'Дитячий абонемент 6-8 років (8 тренувань)',
      branchId: 'kyiv',
      price: 1900,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 8,
      validityDays: 30,
      isAdult: false,
      ageGroup: '6-8',
    ),
    SubscriptionPackage(
      id: 'kyiv_child_6_8_12',
      name: 'Дитячий абонемент 6-8 років (12 тренувань)',
      branchId: 'kyiv',
      price: 2600,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 12,
      validityDays: 30,
      isAdult: false,
      ageGroup: '6-8',
    ),
    SubscriptionPackage(
      id: 'kyiv_child_6_8_single',
      name: 'Разове дитяче тренування 6-8 років',
      branchId: 'kyiv',
      price: 500,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 1,
      validityDays: 365,
      isAdult: false,
      ageGroup: '6-8',
    ),

    // Дитячі абонементи 9-15 років
    SubscriptionPackage(
      id: 'kyiv_child_9_15_4',
      name: 'Дитячий абонемент 9-15 років (4 тренування)',
      branchId: 'kyiv',
      price: 1200,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 4,
      validityDays: 30,
      isAdult: false,
      ageGroup: '9-15',
    ),
    SubscriptionPackage(
      id: 'kyiv_child_9_15_8',
      name: 'Дитячий абонемент 9-15 років (8 тренувань)',
      branchId: 'kyiv',
      price: 1900,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 8,
      validityDays: 30,
      isAdult: false,
      ageGroup: '9-15',
    ),
    SubscriptionPackage(
      id: 'kyiv_child_9_15_12',
      name: 'Дитячий абонемент 9-15 років (12 тренувань)',
      branchId: 'kyiv',
      price: 2600,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 12,
      validityDays: 30,
      isAdult: false,
      ageGroup: '9-15',
    ),
    SubscriptionPackage(
      id: 'kyiv_child_9_15_single',
      name: 'Разове дитяче тренування 9-15 років',
      branchId: 'kyiv',
      price: 500,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 1,
      validityDays: 365,
      isAdult: false,
      ageGroup: '9-15',
    ),

    // Дорослі абонементи
    SubscriptionPackage(
      id: 'kyiv_adult_single',
      name: 'Разове відвідування (Доросла група)',
      branchId: 'kyiv',
      price: 600,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 1,
      validityDays: 365,
      isAdult: true,
    ),
    SubscriptionPackage(
      id: 'kyiv_adult_4',
      name: 'Абонемент на 4 тренування (Доросла група)',
      branchId: 'kyiv',
      price: 1600,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 4,
      validityDays: 30,
      isAdult: true,
    ),
    SubscriptionPackage(
      id: 'kyiv_adult_8',
      name: 'Абонемент на 8 тренувань (Доросла група)',
      branchId: 'kyiv',
      price: 2900,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 8,
      validityDays: 30,
      isAdult: true,
    ),

    // Дитячі індивідуальні абонементи
    SubscriptionPackage(
      id: 'kyiv_indiv_4',
      name: 'Дитячий індивідуальний абонемент (4 тренування)',
      branchId: 'kyiv',
      price: 2200,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 4,
      validityDays: 30,
      isAdult: false,
      isIndividual: true,
    ),
    SubscriptionPackage(
      id: 'kyiv_indiv_8',
      name: 'Дитячий індивідуальний абонемент (8 тренувань)',
      branchId: 'kyiv',
      price: 4000,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 8,
      validityDays: 30,
      isAdult: false,
      isIndividual: true,
    ),
    SubscriptionPackage(
      id: 'kyiv_indiv_single',
      name: 'Разове індивідуальне тренування (діти)',
      branchId: 'kyiv',
      price: 650,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 1,
      validityDays: 365,
      isAdult: false,
      isIndividual: true,
    ),

    // Спліт абонементи
    SubscriptionPackage(
      id: 'kyiv_split_8',
      name: 'Спліт-абонемент на 8 занять (2 особи)',
      branchId: 'kyiv',
      price: 3400,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 8,
      validityDays: 30,
      isAdult: null,
      isSplit: true,
    ),
    SubscriptionPackage(
      id: 'kyiv_split_single',
      name: 'Разове спліт-тренування (2 особи)',
      branchId: 'kyiv',
      price: 900,
      currency: 'UAH',
      currencySymbol: 'грн',
      classes: 1,
      validityDays: 365,
      isAdult: null,
      isSplit: true,
    ),
  ];

  /// Пакети для Vienna (EUR €)
  static const List<SubscriptionPackage> viennaPackages = [
    // Базові тарифні пакети CitySwim Vienna (ТЗ п. 14)
    SubscriptionPackage(
      id: 'vienna_schnuppertraining',
      name: 'Schnuppertraining (пробне)',
      branchId: 'vienna',
      price: 0,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 1,
      validityDays: 14,
      isAdult: null,
      localizedNames: {
        'de': 'Schnuppertraining',
        'en': 'Trial Lesson',
        'uk': 'Пробне заняття (Відень)',
      },
      description: 'Kostenloses erstes Probetraining im HappyLand',
    ),
    SubscriptionPackage(
      id: 'vienna_einzelstunde',
      name: 'Einzelstunde (разове)',
      branchId: 'vienna',
      price: 25,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 1,
      validityDays: 30,
      isAdult: null,
      localizedNames: {
        'de': 'Einzelstunde',
        'en': 'Single Lesson',
        'uk': 'Разове заняття (Відень)',
      },
      description: 'Einmaliges Schwimmtraining',
    ),
    SubscriptionPackage(
      id: 'vienna_monat_4',
      name: '4 Einheiten pro Monat',
      branchId: 'vienna',
      price: 75,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 4,
      validityDays: 30,
      isAdult: null,
      localizedNames: {
        'de': '4 Einheiten pro Monat',
        'en': '4 Lessons / Month',
        'uk': '4 заняття на місяць (Відень)',
      },
      description: 'Monatlicher Pass für 4 Trainingseinheiten',
    ),
    SubscriptionPackage(
      id: 'vienna_monat_8',
      name: '8 Einheiten pro Monat',
      branchId: 'vienna',
      price: 130,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 8,
      validityDays: 30,
      isAdult: null,
      localizedNames: {
        'de': '8 Einheiten pro Monat',
        'en': '8 Lessons / Month',
        'uk': '8 занять на місяць (Відень)',
      },
      description: 'Standard-Monatspass für 8 Einheiten (2x pro Woche)',
    ),
    SubscriptionPackage(
      id: 'vienna_monat_12',
      name: '12 Einheiten pro Monat',
      branchId: 'vienna',
      price: 180,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 12,
      validityDays: 30,
      isAdult: null,
      localizedNames: {
        'de': '12 Einheiten pro Monat',
        'en': '12 Lessons / Month',
        'uk': '12 занять на місяць (Відень)',
      },
      description: 'Intensiv-Pass für 12 Trainingseinheiten (3x pro Woche)',
    ),
    SubscriptionPackage(
      id: 'vienna_einzelunterricht',
      name: 'Einzelunterricht (індивідуальне)',
      branchId: 'vienna',
      price: 60,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 1,
      validityDays: 30,
      isAdult: null,
      isIndividual: true,
      localizedNames: {
        'de': 'Einzelunterricht',
        'en': 'Individual Lesson',
        'uk': 'Індивідуальне заняття (Відень)',
      },
      description: 'Privates Einzeltraining mit Coach im HappyLand',
    ),
    // Дитячі абонементи 6-8 років (Kinder 6-8 Jahre)
    SubscriptionPackage(
      id: 'vienna_child_6_8_4',
      name: 'Kinderabopass 6-8 J. (4 Einheiten)',
      branchId: 'vienna',
      price: 65,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 4,
      validityDays: 30,
      isAdult: false,
      ageGroup: '6-8',
    ),
    SubscriptionPackage(
      id: 'vienna_child_6_8_8',
      name: 'Kinderabopass 6-8 J. (8 Einheiten)',
      branchId: 'vienna',
      price: 110,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 8,
      validityDays: 30,
      isAdult: false,
      ageGroup: '6-8',
    ),
    SubscriptionPackage(
      id: 'vienna_child_6_8_12',
      name: 'Kinderabopass 6-8 J. (12 Einheiten)',
      branchId: 'vienna',
      price: 155,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 12,
      validityDays: 30,
      isAdult: false,
      ageGroup: '6-8',
    ),
    SubscriptionPackage(
      id: 'vienna_child_6_8_single',
      name: 'Einzeltraining Kinder 6-8 J.',
      branchId: 'vienna',
      price: 20,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 1,
      validityDays: 365,
      isAdult: false,
      ageGroup: '6-8',
    ),

    // Дитячі абонементи 9-15 років (Jugend 9-15 Jahre)
    SubscriptionPackage(
      id: 'vienna_child_9_15_4',
      name: 'Jugendabopass 9-15 J. (4 Einheiten)',
      branchId: 'vienna',
      price: 65,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 4,
      validityDays: 30,
      isAdult: false,
      ageGroup: '9-15',
    ),
    SubscriptionPackage(
      id: 'vienna_child_9_15_8',
      name: 'Jugendabopass 9-15 J. (8 Einheiten)',
      branchId: 'vienna',
      price: 110,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 8,
      validityDays: 30,
      isAdult: false,
      ageGroup: '9-15',
    ),
    SubscriptionPackage(
      id: 'vienna_child_9_15_12',
      name: 'Jugendabopass 9-15 J. (12 Einheiten)',
      branchId: 'vienna',
      price: 155,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 12,
      validityDays: 30,
      isAdult: false,
      ageGroup: '9-15',
    ),
    SubscriptionPackage(
      id: 'vienna_child_9_15_single',
      name: 'Einzeltraining Jugend 9-15 J.',
      branchId: 'vienna',
      price: 20,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 1,
      validityDays: 365,
      isAdult: false,
      ageGroup: '9-15',
    ),

    // Дорослі абонементи (Erwachsene)
    SubscriptionPackage(
      id: 'vienna_adult_single',
      name: 'Einzeltraining Erwachsene',
      branchId: 'vienna',
      price: 25,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 1,
      validityDays: 365,
      isAdult: true,
    ),
    SubscriptionPackage(
      id: 'vienna_adult_4',
      name: 'Erwachsenenabopass (4 Einheiten)',
      branchId: 'vienna',
      price: 80,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 4,
      validityDays: 30,
      isAdult: true,
    ),
    SubscriptionPackage(
      id: 'vienna_adult_8',
      name: 'Erwachsenenabopass (8 Einheiten)',
      branchId: 'vienna',
      price: 140,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 8,
      validityDays: 30,
      isAdult: true,
    ),

    // Дитячі індивідуальні тренування (Einzeltraining Privat)
    SubscriptionPackage(
      id: 'vienna_indiv_4',
      name: 'Privattraining Kinder (4 Einheiten)',
      branchId: 'vienna',
      price: 190,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 4,
      validityDays: 30,
      isAdult: false,
      isIndividual: true,
    ),
    SubscriptionPackage(
      id: 'vienna_indiv_8',
      name: 'Privattraining Kinder (8 Einheiten)',
      branchId: 'vienna',
      price: 360,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 8,
      validityDays: 30,
      isAdult: false,
      isIndividual: true,
    ),
    SubscriptionPackage(
      id: 'vienna_indiv_single',
      name: 'Privattraining Kinder Einzelstunde',
      branchId: 'vienna',
      price: 55,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 1,
      validityDays: 365,
      isAdult: false,
      isIndividual: true,
    ),

    // Спліт абонементи (Split-Training 2 Personen)
    SubscriptionPackage(
      id: 'vienna_split_8',
      name: 'Split-Abo 8 Einheiten (2 Personen)',
      branchId: 'vienna',
      price: 210,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 8,
      validityDays: 30,
      isAdult: null,
      isSplit: true,
    ),
    SubscriptionPackage(
      id: 'vienna_split_single',
      name: 'Split-Einzeltraining (2 Personen)',
      branchId: 'vienna',
      price: 35,
      currency: 'EUR',
      currencySymbol: '€',
      classes: 1,
      validityDays: 365,
      isAdult: null,
      isSplit: true,
    ),
  ];

  static List<SubscriptionPackage> forBranch(String branchId) => getPackagesForBranch(branchId);

  static List<SubscriptionPackage> getPackagesForBranch(String branchId) {
    if (branchId == 'vienna') {
      return viennaPackages;
    }
    return kyivPackages;
  }

  static List<Map<String, dynamic>> getServicesMapForBranch(String branchId) {
    return getPackagesForBranch(branchId).map((p) => p.toMap()).toList();
  }

  /// Отримати 6 базових пакетів за ТЗ для зазначеної філії
  static List<SubscriptionPackage> getCorePackages(String branchId) {
    final list = forBranch(branchId);
    final coreIds = branchId == 'vienna'
        ? const [
            'vienna_schnuppertraining',
            'vienna_einzelstunde',
            'vienna_monat_4',
            'vienna_monat_8',
            'vienna_monat_12',
            'vienna_einzelunterricht',
          ]
        : const [
            'kyiv_trial',
            'kyiv_single',
            'kyiv_month_4',
            'kyiv_month_8',
            'kyiv_month_12',
            'kyiv_individual',
          ];
    return list.where((p) => coreIds.contains(p.id)).toList();
  }

  /// Знайти пакет за унікальним id
  static SubscriptionPackage? getById(String id) {
    return [...kyivPackages, ...viennaPackages].firstWhereOrNull((p) => p.id == id);
  }
}
