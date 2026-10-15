import 'package:intl/intl.dart';

/// Утиліта для точного розрахунку та відображення часу у часових поясах філій:
/// - Kyiv: `Europe/Kyiv` (UTC+2 взимку / UTC+3 влітку)
/// - Vienna: `Europe/Vienna` (UTC+1 взимку / UTC+2 влітку)
///
/// Відповідає п. 11 ТЗ:
/// - Збереження часу занять у форматі UTC
/// - Відображення за місцевим часом філії
/// - Тренер у Відні бачить 17:00 (за Віднем), навіть якщо сервер або адмін у Києві
/// - Коректна обробка переходу на літній/зимовий час
class BranchTimezoneHelper {
  BranchTimezoneHelper._();

  static const String kyivTimezone = 'Europe/Kyiv';
  static const String viennaTimezone = 'Europe/Vienna';

  static final Map<String, String> _branchTimezones = {
    'kyiv': kyivTimezone,
    'vienna': viennaTimezone,
  };

  /// Реєстрація часового поясу для динамічної філії
  static void registerBranchTimezone(String branchId, String timezone) {
    final key = branchId.trim().toLowerCase();
    if (key.isNotEmpty && timezone.trim().isNotEmpty) {
      _branchTimezones[key] = timezone.trim();
    }
  }

  /// Видалення часового поясу динамічної філії
  static void removeBranchTimezone(String branchId) {
    final key = branchId.trim().toLowerCase();
    if (key != 'kyiv' && key != 'vienna') {
      _branchTimezones.remove(key);
    }
  }

  /// Перевірка, чи належить ідентифікатор до Відня / центральноєвропейського часу (CET/CEST)
  static bool isVienna(String branchOrTimezone) {
    final lower = branchOrTimezone.trim().toLowerCase();
    if (lower == 'vienna' || lower.contains('vienna') || lower == 'wien') {
      return true;
    }
    final mapped = _branchTimezones[lower]?.toLowerCase() ?? lower;
    return mapped.contains('vienna') ||
        mapped.contains('warsaw') ||
        mapped.contains('berlin') ||
        mapped.contains('prague') ||
        mapped.contains('paris') ||
        mapped.contains('rome') ||
        mapped.contains('madrid') ||
        mapped.contains('zurich') ||
        mapped.contains('budapest') ||
        mapped.contains('amsterdam') ||
        mapped.contains('brussels');
  }

  /// Перевірка, чи належить ідентифікатор до західноєвропейського часу (WET/BST, напр. Лондон)
  static bool isWesternEurope(String branchOrTimezone) {
    final lower = branchOrTimezone.trim().toLowerCase();
    final mapped = _branchTimezones[lower]?.toLowerCase() ?? lower;
    return mapped.contains('london') ||
        mapped.contains('lisbon') ||
        mapped.contains('dublin');
  }

  /// Отримати часовий пояс для вказаної філії
  static String timezoneForBranch(String branchOrTimezone) {
    final lower = branchOrTimezone.trim().toLowerCase();
    if (_branchTimezones.containsKey(lower)) {
      return _branchTimezones[lower]!;
    }
    if (branchOrTimezone.contains('/')) {
      return branchOrTimezone.trim();
    }
    if (isVienna(branchOrTimezone)) return viennaTimezone;
    if (isWesternEurope(branchOrTimezone)) return 'Europe/London';
    return kyivTimezone;
  }

  /// Знаходження дати та часу початку літнього часу в ЄС/Україні для заданого року (остання неділя березня о 01:00 UTC).
  static DateTime getDstStartUtc(int year) {
    // 31 березня - останній можливий день березня
    DateTime lastDay = DateTime.utc(year, 3, 31);
    int dayOfWeek = lastDay.weekday; // 1 = Понеділок ... 7 = Неділя
    int daysToSubtract = dayOfWeek == DateTime.sunday ? 0 : dayOfWeek;
    DateTime lastSunday = lastDay.subtract(Duration(days: daysToSubtract));
    return DateTime.utc(year, 3, lastSunday.day, 1, 0, 0);
  }

  /// Знаходження дати та часу закінчення літнього часу в ЄС/Україні для заданого року (остання неділя жовтня о 01:00 UTC).
  static DateTime getDstEndUtc(int year) {
    DateTime lastDay = DateTime.utc(year, 10, 31);
    int dayOfWeek = lastDay.weekday;
    int daysToSubtract = dayOfWeek == DateTime.sunday ? 0 : dayOfWeek;
    DateTime lastSunday = lastDay.subtract(Duration(days: daysToSubtract));
    return DateTime.utc(year, 10, lastSunday.day, 1, 0, 0);
  }

  /// Чи діє літній час (Daylight Saving Time) для даного моменту часу
  static bool isDaylightSavingTime(DateTime dateTime) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final start = getDstStartUtc(utc.year);
    final end = getDstEndUtc(utc.year);
    return utc.isAfter(start) && utc.isBefore(end);
  }

  /// Отримати зсув від UTC для вказаної філії на задану дату
  static Duration getUtcOffset(DateTime dateTime, String branchOrTimezone) {
    final isDst = isDaylightSavingTime(dateTime);
    if (isWesternEurope(branchOrTimezone)) {
      // London / Lisbon: UTC+0 (standard) or UTC+1 (DST)
      return Duration(hours: isDst ? 1 : 0);
    } else if (isVienna(branchOrTimezone)) {
      // Vienna / CET: UTC+1 (standard) or UTC+2 (DST)
      return Duration(hours: isDst ? 2 : 1);
    } else {
      // Kyiv / EET: UTC+2 (standard) or UTC+3 (DST)
      return Duration(hours: isDst ? 3 : 2);
    }
  }

  /// Конвертувати час (UTC або місцевий) у місцевий час філії (wall-clock time)
  static DateTime toBranchLocalTime(DateTime dateTime, String branchOrTimezone) {
    if (!dateTime.isUtc) {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
      );
    }
    final offset = getUtcOffset(dateTime, branchOrTimezone);
    final localTime = dateTime.add(offset);
    return DateTime(
      localTime.year,
      localTime.month,
      localTime.day,
      localTime.hour,
      localTime.minute,
      localTime.second,
      localTime.millisecond,
    );
  }

  /// Конвертувати місцевий час філії у UTC для збереження у Firestore з урахуванням DST
  static DateTime toUtc(DateTime branchLocalTime, String branchOrTimezone) {
    // Спочатку оцінюємо як UTC для визначення DST
    final assumedUtc = DateTime.utc(
      branchLocalTime.year,
      branchLocalTime.month,
      branchLocalTime.day,
      branchLocalTime.hour,
      branchLocalTime.minute,
      branchLocalTime.second,
    );
    final offset = getUtcOffset(assumedUtc, branchOrTimezone);
    final candidateUtc = assumedUtc.subtract(offset);
    final refinedOffset = getUtcOffset(candidateUtc, branchOrTimezone);
    return assumedUtc.subtract(refinedOffset);
  }

  /// Форматування часу (за замовчуванням HH:mm) у місцевому часі філії
  static String formatTime(
    DateTime dateTime, {
    required String branchId,
    String pattern = 'HH:mm',
  }) {
    final branchLocal = toBranchLocalTime(dateTime, branchId);
    return DateFormat(pattern).format(branchLocal);
  }

  /// Форматування дати (за замовчуванням dd.MM.yyyy) у місцевому часі філії
  static String formatDate(
    DateTime dateTime, {
    required String branchId,
    String pattern = 'dd.MM.yyyy',
  }) {
    final branchLocal = toBranchLocalTime(dateTime, branchId);
    return DateFormat(pattern).format(branchLocal);
  }

  /// Форматування дати та часу у місцевому часі філії
  static String formatDateTime(
    DateTime dateTime, {
    required String branchId,
    String pattern = 'dd.MM.yyyy HH:mm',
  }) {
    final branchLocal = toBranchLocalTime(dateTime, branchId);
    return DateFormat(pattern).format(branchLocal);
  }
}
