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
  final Map<String, String>? localizedDescriptions;
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
    this.localizedDescriptions,
    this.description,
  });

  String get formattedPrice => '$price $currencySymbol';

  String get formattedPricePretty => CurrencyFormatter.formatPackagePrice(
    price: price,
    currency: currency,
    currencySymbol: currencySymbol,
  );

  String getLocalizedName(String langCode) {
    final code = langCode.toLowerCase();
    if (localizedNames != null && localizedNames!.containsKey(code)) {
      return localizedNames![code]!;
    }
    return name;
  }

  String getLocalizedDescription(String langCode) {
    final code = langCode.toLowerCase();
    if (localizedDescriptions != null && localizedDescriptions!.containsKey(code)) {
      return localizedDescriptions![code]!;
    }
    return description ?? '';
  }

  Map<String, dynamic> toMap([String? langCode]) => {
    'id': id,
    'name': langCode != null ? getLocalizedName(langCode) : name,
    'rawName': name,
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
    if (localizedNames != null) 'localizedNames': localizedNames,
    if (localizedDescriptions != null) 'localizedDescriptions': localizedDescriptions,
    if (description != null)
      'description': langCode != null ? getLocalizedDescription(langCode) : description,
  };

  SubscriptionPackage copyWith({
    String? id,
    String? name,
    String? branchId,
    int? price,
    String? currency,
    String? currencySymbol,
    int? classes,
    int? validityDays,
    bool? isAdult,
    bool? isIndividual,
    bool? isSplit,
    String? ageGroup,
    Map<String, String>? localizedNames,
    Map<String, String>? localizedDescriptions,
    String? description,
  }) {
    return SubscriptionPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      branchId: branchId ?? this.branchId,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      classes: classes ?? this.classes,
      validityDays: validityDays ?? this.validityDays,
      isAdult: isAdult ?? this.isAdult,
      isIndividual: isIndividual ?? this.isIndividual,
      isSplit: isSplit ?? this.isSplit,
      ageGroup: ageGroup ?? this.ageGroup,
      localizedNames: localizedNames ?? this.localizedNames,
      localizedDescriptions: localizedDescriptions ?? this.localizedDescriptions,
      description: description ?? this.description,
    );
  }
}

class SubscriptionPackageCatalog {
  /// Локалізує назву абонемента за збереженим рядком або ID для поточної мови ('uk', 'en', 'de', 'ru')
  static String localizeServiceName(String rawName, String langCode) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return rawName;
    final all = [...kyivPackages, ...viennaPackages, ..._customBranchPackages.values.expand((l) => l)];
    for (final pkg in all) {
      if (pkg.id == trimmed ||
          pkg.name == trimmed ||
          (pkg.localizedNames?.values.any((v) => v == trimmed) ?? false)) {
        return pkg.getLocalizedName(langCode);
      }
    }
    return rawName;
  }

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
        'ru': 'Пробное занятие',
      },
      localizedDescriptions: {
        'uk': 'Безкоштовне перше ознайомче тренування для нових плавців',
        'en': 'Free first introductory training session for new swimmers',
        'de': 'Kostenloses erstes Einführungstraining für neue Schwimmer',
        'ru': 'Бесплатная первая ознакомительная тренировка для новых пловцов',
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
        'ru': 'Разовое занятие',
      },
      localizedDescriptions: {
        'uk': 'Одноразове відвідування тренування',
        'en': 'Single training session visit',
        'de': 'Einmaliger Trainingsbesuch',
        'ru': 'Одноразовое посещение тренировки',
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
        'ru': '4 занятия в месяц',
      },
      localizedDescriptions: {
        'uk': 'Абонемент на 4 заняття протягом 30 днів',
        'en': 'Subscription for 4 lessons within 30 days',
        'de': 'Abo für 4 Einheiten innerhalb von 30 Tagen',
        'ru': 'Абонемент на 4 занятия в течение 30 дней',
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
        'ru': '8 занятий в месяц',
      },
      localizedDescriptions: {
        'uk': 'Стандартний абонемент на 8 занять (двічі на тиждень)',
        'en': 'Standard subscription for 8 lessons (twice a week)',
        'de': 'Standard-Abo für 8 Einheiten (zweimal pro Woche)',
        'ru': 'Стандартный абонемент на 8 занятий (дважды в неделю)',
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
        'ru': '12 занятий в месяц',
      },
      localizedDescriptions: {
        'uk': 'Інтенсивний абонемент на 12 занять (тричі на тиждень)',
        'en': 'Intensive subscription for 12 lessons (three times a week)',
        'de': 'Intensiv-Abo für 12 Einheiten (dreimal pro Woche)',
        'ru': 'Интенсивный абонемент на 12 занятий (трижды в неделю)',
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
        'ru': 'Индивидуальное занятие',
      },
      localizedDescriptions: {
        'uk': 'Персональне тренування з тренером на виділеній доріжці',
        'en': 'Personal training session with a coach in a dedicated lane',
        'de': 'Persönliches Training mit Coach auf eigener Bahn',
        'ru': 'Персональная тренировка с тренером на выделенной дорожке',
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
      localizedNames: {
        'uk': 'Дитячий абонемент 6-8 років (4 тренування)',
        'en': 'Kids Pass 6-8 yrs (4 lessons)',
        'de': 'Kinderabopass 6-8 J. (4 Einheiten)',
        'ru': 'Детский абонемент 6-8 лет (4 тренировки)',
      },
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
      localizedNames: {
        'uk': 'Дитячий абонемент 6-8 років (8 тренувань)',
        'en': 'Kids Pass 6-8 yrs (8 lessons)',
        'de': 'Kinderabopass 6-8 J. (8 Einheiten)',
        'ru': 'Детский абонемент 6-8 лет (8 тренировок)',
      },
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
      localizedNames: {
        'uk': 'Дитячий абонемент 6-8 років (12 тренувань)',
        'en': 'Kids Pass 6-8 yrs (12 lessons)',
        'de': 'Kinderabopass 6-8 J. (12 Einheiten)',
        'ru': 'Детский абонемент 6-8 лет (12 тренировок)',
      },
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
      localizedNames: {
        'uk': 'Разове дитяче тренування 6-8 років',
        'en': 'Single Kids Lesson 6-8 yrs',
        'de': 'Einzeltraining Kinder 6-8 J.',
        'ru': 'Разовая детская тренировка 6-8 лет',
      },
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
      localizedNames: {
        'uk': 'Дитячий абонемент 9-15 років (4 тренування)',
        'en': 'Junior Pass 9-15 yrs (4 lessons)',
        'de': 'Jugendabopass 9-15 J. (4 Einheiten)',
        'ru': 'Детский абонемент 9-15 лет (4 тренировки)',
      },
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
      localizedNames: {
        'uk': 'Дитячий абонемент 9-15 років (8 тренувань)',
        'en': 'Junior Pass 9-15 yrs (8 lessons)',
        'de': 'Jugendabopass 9-15 J. (8 Einheiten)',
        'ru': 'Детский абонемент 9-15 лет (8 тренировок)',
      },
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
      localizedNames: {
        'uk': 'Дитячий абонемент 9-15 років (12 тренувань)',
        'en': 'Junior Pass 9-15 yrs (12 lessons)',
        'de': 'Jugendabopass 9-15 J. (12 Einheiten)',
        'ru': 'Детский абонемент 9-15 лет (12 тренировок)',
      },
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
      localizedNames: {
        'uk': 'Разове дитяче тренування 9-15 років',
        'en': 'Single Junior Lesson 9-15 yrs',
        'de': 'Einzeltraining Jugend 9-15 J.',
        'ru': 'Разовая детская тренировка 9-15 лет',
      },
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
      localizedNames: {
        'uk': 'Разове відвідування (Доросла група)',
        'en': 'Single Visit (Adult Group)',
        'de': 'Einzeltraining Erwachsene',
        'ru': 'Разовое посещение (Взрослая группа)',
      },
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
      localizedNames: {
        'uk': 'Абонемент на 4 тренування (Доросла група)',
        'en': 'Adult Pass (4 lessons)',
        'de': 'Erwachsenenabopass (4 Einheiten)',
        'ru': 'Абонемент на 4 тренировки (Взрослая группа)',
      },
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
      localizedNames: {
        'uk': 'Абонемент на 8 тренувань (Доросла група)',
        'en': 'Adult Pass (8 lessons)',
        'de': 'Erwachsenenabopass (8 Einheiten)',
        'ru': 'Абонемент на 8 тренировок (Взрослая группа)',
      },
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
      localizedNames: {
        'uk': 'Дитячий індивідуальний абонемент (4 тренування)',
        'en': 'Kids Individual Pass (4 lessons)',
        'de': 'Privattraining Kinder (4 Einheiten)',
        'ru': 'Детский индивидуальный абонемент (4 тренировки)',
      },
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
      localizedNames: {
        'uk': 'Дитячий індивідуальний абонемент (8 тренувань)',
        'en': 'Kids Individual Pass (8 lessons)',
        'de': 'Privattraining Kinder (8 Einheiten)',
        'ru': 'Детский индивидуальный абонемент (8 тренировок)',
      },
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
      localizedNames: {
        'uk': 'Разове індивідуальне тренування (діти)',
        'en': 'Single Individual Lesson (Kids)',
        'de': 'Privattraining Kinder Einzelstunde',
        'ru': 'Разовая индивидуальная тренировка (дети)',
      },
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
      localizedNames: {
        'uk': 'Спліт-абонемент на 8 занять (2 особи)',
        'en': 'Split Pass 8 Lessons (2 persons)',
        'de': 'Split-Abo 8 Einheiten (2 Personen)',
        'ru': 'Сплит-абонемент на 8 занятий (2 человека)',
      },
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
      localizedNames: {
        'uk': 'Разове спліт-тренування (2 особи)',
        'en': 'Single Split Lesson (2 persons)',
        'de': 'Split-Einzeltraining (2 Personen)',
        'ru': 'Разовая сплит-тренировка (2 человека)',
      },
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
        'en': 'Trial Lesson (Vienna)',
        'uk': 'Пробне заняття (Відень)',
        'ru': 'Пробное занятие (Вена)',
      },
      localizedDescriptions: {
        'de': 'Kostenloses erstes Probetraining im HappyLand',
        'en': 'Free first trial lesson at HappyLand',
        'uk': 'Безкоштовне перше пробне тренування у HappyLand',
        'ru': 'Бесплатная первая пробная тренировка в HappyLand',
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
        'en': 'Single Lesson (Vienna)',
        'uk': 'Разове заняття (Відень)',
        'ru': 'Разовое занятие (Вена)',
      },
      localizedDescriptions: {
        'de': 'Einmaliges Schwimmtraining',
        'en': 'Single swimming training session',
        'uk': 'Одноразове тренування з плавання',
        'ru': 'Одноразовая тренировка по плаванию',
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
        'en': '4 Lessons / Month (Vienna)',
        'uk': '4 заняття на місяць (Відень)',
        'ru': '4 занятия в месяц (Вена)',
      },
      localizedDescriptions: {
        'de': 'Monatlicher Pass für 4 Trainingseinheiten',
        'en': 'Monthly pass for 4 training sessions',
        'uk': 'Місячний абонемент на 4 тренування',
        'ru': 'Месячный абонемент на 4 тренировки',
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
        'en': '8 Lessons / Month (Vienna)',
        'uk': '8 занять на місяць (Відень)',
        'ru': '8 занятий в месяц (Вена)',
      },
      localizedDescriptions: {
        'de': 'Standard-Monatspass für 8 Einheiten (2x pro Woche)',
        'en': 'Standard monthly pass for 8 sessions (2x per week)',
        'uk': 'Стандартний місячний абонемент на 8 занять (двічі на тиждень)',
        'ru': 'Стандартный месячный абонемент на 8 занятий (дважды в неделю)',
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
        'en': '12 Lessons / Month (Vienna)',
        'uk': '12 занять на місяць (Відень)',
        'ru': '12 занятий в месяц (Вена)',
      },
      localizedDescriptions: {
        'de': 'Intensiv-Pass für 12 Trainingseinheiten (3x pro Woche)',
        'en': 'Intensive pass for 12 training sessions (3x per week)',
        'uk': 'Інтенсивний абонемент на 12 тренувань (тричі на тиждень)',
        'ru': 'Интенсивный абонемент на 12 тренировок (трижды в неделю)',
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
        'en': 'Individual Lesson (Vienna)',
        'uk': 'Індивідуальне заняття (Відень)',
        'ru': 'Индивидуальное занятие (Вена)',
      },
      localizedDescriptions: {
        'de': 'Privates Einzeltraining mit Coach im HappyLand',
        'en': 'Private 1-on-1 training with a coach at HappyLand',
        'uk': 'Персональне індивідуальне тренування з тренером у HappyLand',
        'ru': 'Персональная индивидуальная тренировка с тренером в HappyLand',
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
      localizedNames: {
        'de': 'Kinderabopass 6-8 J. (4 Einheiten)',
        'en': 'Kids Pass 6-8 yrs (4 lessons)',
        'uk': 'Дитячий абонемент 6-8 років (4 тренування)',
        'ru': 'Детский абонемент 6-8 лет (4 тренировки)',
      },
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
      localizedNames: {
        'de': 'Kinderabopass 6-8 J. (8 Einheiten)',
        'en': 'Kids Pass 6-8 yrs (8 lessons)',
        'uk': 'Дитячий абонемент 6-8 років (8 тренувань)',
        'ru': 'Детский абонемент 6-8 лет (8 тренировок)',
      },
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
      localizedNames: {
        'de': 'Kinderabopass 6-8 J. (12 Einheiten)',
        'en': 'Kids Pass 6-8 yrs (12 lessons)',
        'uk': 'Дитячий абонемент 6-8 років (12 тренувань)',
        'ru': 'Детский абонемент 6-8 лет (12 тренировок)',
      },
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
      localizedNames: {
        'de': 'Einzeltraining Kinder 6-8 J.',
        'en': 'Single Kids Lesson 6-8 yrs',
        'uk': 'Разове дитяче тренування 6-8 років',
        'ru': 'Разовая детская тренировка 6-8 лет',
      },
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
      localizedNames: {
        'de': 'Jugendabopass 9-15 J. (4 Einheiten)',
        'en': 'Junior Pass 9-15 yrs (4 lessons)',
        'uk': 'Дитячий абонемент 9-15 років (4 тренування)',
        'ru': 'Детский абонемент 9-15 лет (4 тренировки)',
      },
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
      localizedNames: {
        'de': 'Jugendabopass 9-15 J. (8 Einheiten)',
        'en': 'Junior Pass 9-15 yrs (8 lessons)',
        'uk': 'Дитячий абонемент 9-15 років (8 тренувань)',
        'ru': 'Детский абонемент 9-15 лет (8 тренировок)',
      },
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
      localizedNames: {
        'de': 'Jugendabopass 9-15 J. (12 Einheiten)',
        'en': 'Junior Pass 9-15 yrs (12 lessons)',
        'uk': 'Дитячий абонемент 9-15 років (12 тренувань)',
        'ru': 'Детский абонемент 9-15 лет (12 тренировок)',
      },
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
      localizedNames: {
        'de': 'Einzeltraining Jugend 9-15 J.',
        'en': 'Single Junior Lesson 9-15 yrs',
        'uk': 'Разове дитяче тренування 9-15 років',
        'ru': 'Разовая детская тренировка 9-15 лет',
      },
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
      localizedNames: {
        'de': 'Einzeltraining Erwachsene',
        'en': 'Single Visit (Adult Group)',
        'uk': 'Разове відвідування (Доросла група)',
        'ru': 'Разовое посещение (Взрослая группа)',
      },
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
      localizedNames: {
        'de': 'Erwachsenenabopass (4 Einheiten)',
        'en': 'Adult Pass (4 lessons)',
        'uk': 'Абонемент на 4 тренування (Доросла група)',
        'ru': 'Абонемент на 4 тренировки (Взрослая группа)',
      },
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
      localizedNames: {
        'de': 'Erwachsenenabopass (8 Einheiten)',
        'en': 'Adult Pass (8 lessons)',
        'uk': 'Абонемент на 8 тренувань (Доросла група)',
        'ru': 'Абонемент на 8 тренировок (Взрослая группа)',
      },
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
      localizedNames: {
        'de': 'Privattraining Kinder (4 Einheiten)',
        'en': 'Kids Individual Pass (4 lessons)',
        'uk': 'Дитячий індивідуальний абонемент (4 тренування)',
        'ru': 'Детский индивидуальный абонемент (4 тренировки)',
      },
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
      localizedNames: {
        'de': 'Privattraining Kinder (8 Einheiten)',
        'en': 'Kids Individual Pass (8 lessons)',
        'uk': 'Дитячий індивідуальний абонемент (8 тренувань)',
        'ru': 'Детский индивидуальный абонемент (8 тренировок)',
      },
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
      localizedNames: {
        'de': 'Privattraining Kinder Einzelstunde',
        'en': 'Single Individual Lesson (Kids)',
        'uk': 'Разове індивідуальне тренування (діти)',
        'ru': 'Разовая индивидуальная тренировка (дети)',
      },
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
      localizedNames: {
        'de': 'Split-Abo 8 Einheiten (2 Personen)',
        'en': 'Split Pass 8 Lessons (2 persons)',
        'uk': 'Спліт-абонемент на 8 занять (2 особи)',
        'ru': 'Сплит-абонемент на 8 занятий (2 человека)',
      },
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
      localizedNames: {
        'de': 'Split-Einzeltraining (2 Personen)',
        'en': 'Single Split Lesson (2 persons)',
        'uk': 'Разове спліт-тренування (2 особи)',
        'ru': 'Разовая сплит-тренировка (2 человека)',
      },
    ),
  ];

  static final Map<String, List<SubscriptionPackage>> _customBranchPackages = {};

  static void registerCustomPackages(String branchId, List<SubscriptionPackage> packages) {
    _customBranchPackages[branchId] = packages;
  }

  static void removeCustomPackages(String branchId) {
    _customBranchPackages.remove(branchId);
  }

  /// Автоматична генерація базового каталогу абонементів для нової філії у її валюті
  static List<SubscriptionPackage> generateDefaultPackages({
    required String branchId,
    required String currency,
    required String currencySymbol,
  }) {
    final isEuroOrDollar = currency == 'EUR' || currency == 'USD' || currency == 'GBP';
    final singlePrice = isEuroOrDollar ? 25 : (currency == 'PLN' ? 100 : 450);
    final month4Price = isEuroOrDollar ? 75 : (currency == 'PLN' ? 320 : 1600);
    final month8Price = isEuroOrDollar ? 140 : (currency == 'PLN' ? 600 : 3000);
    final month12Price = isEuroOrDollar ? 195 : (currency == 'PLN' ? 850 : 4200);
    final indivPrice = isEuroOrDollar ? 45 : (currency == 'PLN' ? 180 : 800);

    return [
      SubscriptionPackage(
        id: '${branchId}_trial',
        name: 'Пробне заняття',
        branchId: branchId,
        price: 0,
        currency: currency,
        currencySymbol: currencySymbol,
        classes: 1,
        validityDays: 14,
        localizedNames: const {
          'uk': 'Пробне заняття',
          'en': 'Trial Lesson',
          'de': 'Schnuppertraining',
          'ru': 'Пробное занятие',
        },
        localizedDescriptions: const {
          'uk': 'Безкоштовне перше ознайомче тренування',
          'en': 'Free first introductory training session',
          'de': 'Kostenloses erstes Einführungstraining',
          'ru': 'Бесплатная первая ознакомительная тренировка',
        },
        description: 'Безкоштовне перше ознайомче тренування',
      ),
      SubscriptionPackage(
        id: '${branchId}_single',
        name: 'Разове заняття',
        branchId: branchId,
        price: singlePrice,
        currency: currency,
        currencySymbol: currencySymbol,
        classes: 1,
        validityDays: 30,
        localizedNames: const {
          'uk': 'Разове заняття',
          'en': 'Single Lesson',
          'de': 'Einzelstunde',
          'ru': 'Разовое занятие',
        },
        localizedDescriptions: const {
          'uk': 'Одноразове відвідування тренування',
          'en': 'Single training session visit',
          'de': 'Einmaliger Trainingsbesuch',
          'ru': 'Одноразовое посещение тренировки',
        },
        description: 'Одноразове відвідування тренування',
      ),
      SubscriptionPackage(
        id: '${branchId}_month_4',
        name: '4 заняття на місяць',
        branchId: branchId,
        price: month4Price,
        currency: currency,
        currencySymbol: currencySymbol,
        classes: 4,
        validityDays: 30,
        localizedNames: const {
          'uk': '4 заняття на місяць',
          'en': '4 Lessons / Month',
          'de': '4 Einheiten / Monat',
          'ru': '4 занятия в месяц',
        },
        localizedDescriptions: const {
          'uk': 'Абонемент на 4 заняття протягом 30 днів',
          'en': 'Subscription for 4 lessons within 30 days',
          'de': 'Abo für 4 Einheiten innerhalb von 30 Tagen',
          'ru': 'Абонемент на 4 занятия в течение 30 дней',
        },
        description: 'Абонемент на 4 заняття протягом 30 днів',
      ),
      SubscriptionPackage(
        id: '${branchId}_month_8',
        name: '8 занять на місяць',
        branchId: branchId,
        price: month8Price,
        currency: currency,
        currencySymbol: currencySymbol,
        classes: 8,
        validityDays: 30,
        localizedNames: const {
          'uk': '8 занять на місяць',
          'en': '8 Lessons / Month',
          'de': '8 Einheiten / Monat',
          'ru': '8 занятий в месяц',
        },
        localizedDescriptions: const {
          'uk': 'Абонемент на 8 занять протягом 30 днів',
          'en': 'Subscription for 8 lessons within 30 days',
          'de': 'Abo für 8 Einheiten innerhalb von 30 Tagen',
          'ru': 'Абонемент на 8 занятий в течение 30 дней',
        },
        description: 'Абонемент на 8 занять протягом 30 днів',
      ),
      SubscriptionPackage(
        id: '${branchId}_month_12',
        name: '12 занять на місяць',
        branchId: branchId,
        price: month12Price,
        currency: currency,
        currencySymbol: currencySymbol,
        classes: 12,
        validityDays: 30,
        localizedNames: const {
          'uk': '12 занять на місяць',
          'en': '12 Lessons / Month',
          'de': '12 Einheiten / Monat',
          'ru': '12 занятий в месяц',
        },
        localizedDescriptions: const {
          'uk': 'Абонемент на 12 занять протягом 30 днів',
          'en': 'Subscription for 12 lessons within 30 days',
          'de': 'Abo für 12 Einheiten innerhalb von 30 Tagen',
          'ru': 'Абонемент на 12 занятий в течение 30 дней',
        },
        description: 'Абонемент на 12 занять протягом 30 днів',
      ),
      SubscriptionPackage(
        id: '${branchId}_individual',
        name: 'Індивідуальне заняття',
        branchId: branchId,
        price: indivPrice,
        currency: currency,
        currencySymbol: currencySymbol,
        classes: 1,
        validityDays: 30,
        isIndividual: true,
        localizedNames: const {
          'uk': 'Індивідуальне заняття',
          'en': 'Individual Lesson',
          'de': 'Einzelunterricht',
          'ru': 'Индивидуальное занятие',
        },
        localizedDescriptions: const {
          'uk': 'Персональне тренування з тренером 1-на-1',
          'en': 'Personal 1-on-1 training with a coach',
          'de': 'Persönliches 1-zu-1 Training mit Coach',
          'ru': 'Персональная тренировка с тренером 1-на-1',
        },
        description: 'Персональне тренування з тренером 1-на-1',
      ),
    ];
  }

  static List<SubscriptionPackage> forBranch(String branchId) => getPackagesForBranch(branchId);

  static List<SubscriptionPackage> getPackagesForBranch(String branchId, [String? currency, String? currencySymbol]) {
    if (branchId == 'vienna') {
      return viennaPackages;
    }
    if (branchId == 'kyiv') {
      return kyivPackages;
    }
    if (_customBranchPackages.containsKey(branchId)) {
      return _customBranchPackages[branchId]!;
    }
    final pkgs = generateDefaultPackages(
      branchId: branchId,
      currency: currency ?? 'EUR',
      currencySymbol: currencySymbol ?? (currency == 'UAH' ? '₴' : '€'),
    );
    _customBranchPackages[branchId] = pkgs;
    return pkgs;
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
        : branchId == 'kyiv'
            ? const [
                'kyiv_trial',
                'kyiv_single',
                'kyiv_month_4',
                'kyiv_month_8',
                'kyiv_month_12',
                'kyiv_individual',
              ]
            : [
                '${branchId}_trial',
                '${branchId}_single',
                '${branchId}_month_4',
                '${branchId}_month_8',
                '${branchId}_month_12',
                '${branchId}_individual',
              ];
    return list.where((p) => coreIds.contains(p.id)).toList();
  }

  /// Знайти пакет за унікальним id
  static SubscriptionPackage? getById(String id) {
    final customList = _customBranchPackages.values.expand((l) => l).toList();
    return [...kyivPackages, ...viennaPackages, ...customList].firstWhereOrNull((p) => p.id == id);
  }
}
