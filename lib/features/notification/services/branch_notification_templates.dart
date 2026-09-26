/// Мультиязичні шаблони сповіщень за локальним часом філії (п. 23, 24 ТЗ)
class BranchNotificationTemplates {
  BranchNotificationTemplates._();

  /// Локалізована мітка часового поясу / міста філії
  static String branchTimezoneLabel(String branchId, String language) {
    final isVienna = branchId.toLowerCase().contains('vienna');
    switch (language.toLowerCase()) {
      case 'de':
        return isVienna ? 'Wien' : 'Kiew';
      case 'en':
        return isVienna ? 'Vienna' : 'Kyiv';
      case 'uk':
      default:
        return isVienna ? 'за Віднем' : 'за Києвом';
    }
  }

  /// Нагадування за 24 години до початку тренування
  static ({String title, String body}) reminder24h({
    required String branchId,
    required String classTitle,
    required String timeFormatted, // Наприклад '17:00'
    String locationName = '',
    String poolName = '',
    String lane = '',
    String language = 'uk',
  }) {
    final tzLabel = branchTimezoneLabel(branchId, language);
    final locationInfo = _formatLocationSuffix(locationName, poolName, lane, language);

    switch (language.toLowerCase()) {
      case 'de':
        return (
          title: 'Erinnerung an das Schwimmtraining',
          body: 'Dein Training «$classTitle» ist morgen um $timeFormatted Uhr ($tzLabel)$locationInfo. Wir freuen uns auf dich!',
        );
      case 'en':
        return (
          title: 'Class Reminder',
          body: 'Your class "$classTitle" is tomorrow at $timeFormatted ($tzLabel)$locationInfo. See you at the pool!',
        );
      case 'uk':
      default:
        return (
          title: 'Нагадування про заняття',
          body: 'Ваше заняття «$classTitle» завтра о $timeFormatted ($tzLabel)$locationInfo. Чекаємо на вас!',
        );
    }
  }

  /// Нагадування за 2 години до початку тренування
  static ({String title, String body}) reminder2h({
    required String branchId,
    required String classTitle,
    required String timeFormatted,
    String locationName = '',
    String poolName = '',
    String lane = '',
    String language = 'uk',
  }) {
    final tzLabel = branchTimezoneLabel(branchId, language);
    final locationInfo = _formatLocationSuffix(locationName, poolName, lane, language);

    switch (language.toLowerCase()) {
      case 'de':
        return (
          title: 'Training in Kürze!',
          body: 'Erinnerung: Dein Training «$classTitle» beginnt heute um $timeFormatted Uhr ($tzLabel)$locationInfo. Badesachen nicht vergessen!',
        );
      case 'en':
        return (
          title: 'Class starting soon!',
          body: 'Reminder: Your class "$classTitle" starts today at $timeFormatted ($tzLabel)$locationInfo. Don\'t forget your swim gear!',
        );
      case 'uk':
      default:
        return (
          title: 'Заняття незабаром!',
          body: 'Нагадуємо: заняття «$classTitle» розпочнеться сьогодні о $timeFormatted ($tzLabel)$locationInfo. Не забудьте плавальні речі!',
        );
    }
  }

  /// Сповіщення про перенесення або зміну розкладу
  static ({String title, String body}) scheduleChange({
    required String branchId,
    required String classTitle,
    required String newDateFormatted,
    required String newTimeFormatted,
    required String reason,
    String language = 'uk',
  }) {
    final tzLabel = branchTimezoneLabel(branchId, language);

    switch (language.toLowerCase()) {
      case 'de':
        return (
          title: 'Trainingszeit geändert',
          body: 'Das Training «$classTitle» wurde auf $newDateFormatted um $newTimeFormatted Uhr ($tzLabel) verschoben.${reasonTextDe(reason)}',
        );
      case 'en':
        return (
          title: 'Class Rescheduled',
          body: 'Your class "$classTitle" has been rescheduled to $newDateFormatted at $newTimeFormatted ($tzLabel).${reasonTextEn(reason)}',
        );
      case 'uk':
      default:
        return (
          title: 'Зміна розкладу заняття',
          body: 'Заняття «$classTitle» перенесено на $newDateFormatted о $newTimeFormatted ($tzLabel).${reasonTextUk(reason)}',
        );
    }
  }

  /// Сповіщення про скасування заняття
  static ({String title, String body}) classCancelled({
    required String branchId,
    required String classTitle,
    required String dateFormatted,
    required String timeFormatted,
    required String reason,
    String language = 'uk',
  }) {
    final tzLabel = branchTimezoneLabel(branchId, language);

    switch (language.toLowerCase()) {
      case 'de':
        return (
          title: 'Training abgesagt',
          body: 'Das Training «$classTitle» am $dateFormatted um $timeFormatted Uhr ($tzLabel) wurde abgesagt. Das Guthaben wurde nicht verrechnet.${reasonTextDe(reason)}',
        );
      case 'en':
        return (
          title: 'Class Cancelled',
          body: 'The class "$classTitle" on $dateFormatted at $timeFormatted ($tzLabel) has been cancelled. Your lesson credit remains intact.${reasonTextEn(reason)}',
        );
      case 'uk':
      default:
        return (
          title: 'Заняття скасовано',
          body: 'Заняття «$classTitle» $dateFormatted о $timeFormatted ($tzLabel) скасовано. Заняття не списано з вашого балансу.${reasonTextUk(reason)}',
        );
    }
  }

  /// Сповіщення про успішну оплату та генерацію квитанції
  static ({String title, String body}) paymentReceipt({
    required String branchId,
    required String packageName,
    required String formattedAmount,
    required String receiptNumber,
    String language = 'uk',
  }) {
    final isVienna = branchId.toLowerCase().contains('vienna');
    final schoolName = isVienna ? 'CitySwim Vienna' : 'CitySwim Kyiv';

    switch (language.toLowerCase()) {
      case 'de':
        return (
          title: 'Zahlungsbestätigung & Rechnung',
          body: 'Vielen Dank für Ihre Zahlung bei $schoolName! Paket: $packageName ($formattedAmount). Rechnungsnummer: $receiptNumber.',
        );
      case 'en':
        return (
          title: 'Payment Confirmation & Invoice',
          body: 'Thank you for your payment at $schoolName! Package: $packageName ($formattedAmount). Invoice #: $receiptNumber.',
        );
      case 'uk':
      default:
        return (
          title: 'Оплата успішна & Електронний чек',
          body: 'Дякуємо за оплату в $schoolName! Придбано: $packageName на суму $formattedAmount. Номер квитанції: $receiptNumber.',
        );
    }
  }

  static String _formatLocationSuffix(String loc, String pool, String lane, String lang) {
    final parts = <String>[];
    if (pool.isNotEmpty) parts.add(pool);
    if (lane.isNotEmpty) parts.add(lane);

    final details = parts.isNotEmpty ? ' (${parts.join(', ')})' : '';
    if (loc.isEmpty) return details;

    switch (lang.toLowerCase()) {
      case 'de':
        return ' im $loc$details';
      case 'en':
        return ' at $loc$details';
      case 'uk':
      default:
        return ' у $loc$details';
    }
  }

  static String reasonTextUk(String reason) => reason.isNotEmpty ? ' Причина: $reason.' : '';
  static String reasonTextDe(String reason) => reason.isNotEmpty ? ' Grund: $reason.' : '';
  static String reasonTextEn(String reason) => reason.isNotEmpty ? ' Reason: $reason.' : '';
}
