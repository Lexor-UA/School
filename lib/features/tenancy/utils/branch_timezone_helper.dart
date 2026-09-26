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

  /// Перевірка, чи належить ідентифікатор до Відня
  static bool isVienna(String branchOrTimezone) {
    final lower = branchOrTimezone.toLowerCase();
    return lower == 'vienna' || lower.contains('vienna');
  }

  /// Отримати часовий пояс для вказаної філії (Europe/Vienna або Europe/Kyiv)
  static String timezoneForBranch(String branchOrTimezone) {
    return isVienna(branchOrTimezone) ? viennaTimezone : kyivTimezone;
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
    if (isVienna(branchOrTimezone)) {
      // Vienna: UTC+1 (standard) or UTC+2 (DST)
      return Duration(hours: isDst ? 2 : 1);
    } else {
      // Kyiv: UTC+2 (standard) or UTC+3 (DST)
      return Duration(hours: isDst ? 3 : 2);
    }
  }

  /// Конвертувати час (UTC або будь-який) у місцевий час філії (wall-clock time)
  static DateTime toBranchLocalTime(DateTime dateTime, String branchOrTimezone) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final offset = getUtcOffset(utc, branchOrTimezone);
    final localTime = utc.add(offset);
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
