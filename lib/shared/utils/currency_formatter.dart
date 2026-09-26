import 'package:intl/intl.dart';

/// Утиліта для мультивалютного форматування (CitySwim Kyiv UAH ₴ / CitySwim Vienna EUR €).
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Форматування суми з розділювачем тисяч та відповідним символом валюти.
  /// Наприклад: 124500, 'UAH', '₴' -> '124 500 ₴'
  ///            14850, 'EUR', '€' -> '14 850 €'
  static String format(
    num amount, {
    String currencyCode = 'UAH',
    String? currencySymbol,
    bool showDecimalsIfZero = false,
  }) {
    final symbol = currencySymbol ?? _symbolForCode(currencyCode);
    final numberFormat = NumberFormat('#,##0${showDecimalsIfZero ? '.00' : ''}', 'uk_UA');
    final formattedNumber = numberFormat
        .format(amount)
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll(',', ' ');

    if (currencyCode.toUpperCase() == 'EUR' || symbol == '€') {
      return '$formattedNumber €';
    }
    return '$formattedNumber ₴';
  }

  /// Форматування суми відповідно до філії ('kyiv' -> UAH ₴, 'vienna' -> EUR €).
  static String formatForBranch(num amount, String branchId) {
    if (branchId == 'vienna') {
      return format(amount, currencyCode: 'EUR', currencySymbol: '€');
    }
    return format(amount, currencyCode: 'UAH', currencySymbol: '₴');
  }

  /// Мультивалютний вивід для режиму «All locations» (без некоректного додавання сум).
  /// Наприклад: "124 500 ₴ • 14 850 €"
  static String formatDual({
    required num kyivAmount,
    required num viennaAmount,
    String separator = ' • ',
  }) {
    final kyivFormatted = formatForBranch(kyivAmount, 'kyiv');
    final viennaFormatted = formatForBranch(viennaAmount, 'vienna');
    return '$kyivFormatted$separator$viennaFormatted';
  }

  /// Форматування ціни абонемента за його параметрами.
  static String formatPackagePrice({
    required int price,
    required String currency,
    required String currencySymbol,
  }) {
    if (price == 0) {
      return currency == 'EUR' || currencySymbol == '€' ? '0 €' : '0 ₴';
    }
    return format(price, currencyCode: currency, currencySymbol: currencySymbol);
  }

  static String _symbolForCode(String code) {
    switch (code.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'UAH':
      default:
        return '₴';
    }
  }
}
