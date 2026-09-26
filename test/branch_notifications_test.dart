import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/notification/models/branch_notification.dart';
import 'package:swimming_school_app/features/notification/services/branch_notification_service.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';

void main() {
  group('Stage 11: Branch-Aware Notifications & Reminders Engine Tests (TZ Point 23 & 24)', () {
    final viennaClassSummer = GroupClass(
      id: 'class_vienna_summer',
      title: 'Kinder Schwimmkurs 6-8 J.',
      // In summer, Vienna is UTC+2, so 15:00 UTC is 17:00 Vienna local time
      startTime: DateTime.utc(2026, 6, 10, 15, 0),
      endTime: DateTime.utc(2026, 6, 10, 16, 0),
      coachId: 'coach_maria',
      coachName: 'Coach Maria Huber',
      maxCapacity: 8,
      category: 'Kinder',
      lane: 'Lane 1',
      branchId: 'vienna',
      organizationId: 'cityswim',
      locationId: 'happyland',
      poolId: 'sports_pool',
      timezone: 'Europe/Vienna',
      enrolledChildIds: ['child_maxi'],
    );

    final viennaClassWinter = GroupClass(
      id: 'class_vienna_winter',
      title: 'Winter Technik Kurs',
      // In winter, Vienna is UTC+1, so 16:00 UTC is 17:00 Vienna local time
      startTime: DateTime.utc(2026, 1, 15, 16, 0),
      endTime: DateTime.utc(2026, 1, 15, 17, 0),
      coachId: 'coach_stefan',
      coachName: 'Stefan Gruber',
      maxCapacity: 8,
      category: 'Technik',
      lane: 'Lane 2',
      branchId: 'vienna',
      organizationId: 'cityswim',
      locationId: 'happyland',
      poolId: 'sports_pool',
      timezone: 'Europe/Vienna',
      enrolledChildIds: ['child_maxi'],
    );

    final kyivClass = GroupClass(
      id: 'class_kyiv_main',
      title: 'Групове плавання діти 6-8',
      // In winter, Kyiv is UTC+2, so 16:30 UTC is 18:30 Kyiv local time
      startTime: DateTime.utc(2026, 1, 15, 16, 30),
      endTime: DateTime.utc(2026, 1, 15, 17, 30),
      coachId: 'coach_igor',
      coachName: 'Ігор Мельник',
      maxCapacity: 8,
      category: 'Плавання',
      lane: 'Доріжка 1',
      branchId: 'kyiv',
      organizationId: 'cityswim',
      locationId: 'kyiv_main',
      poolId: 'pool_25m',
      timezone: 'Europe/Kyiv',
      enrolledChildIds: ['child_taras'],
    );

    test('24-Hour Reminder for Vienna: Formats in Vienna local time across languages', () {
      // Ukrainian language for Vienna
      final notifUk = BranchNotificationService.createReminder24h(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        language: 'uk',
      );
      expect(notifUk.branchId, equals('vienna'));
      expect(notifUk.type, equals(BranchNotificationType.reminder24h));
      expect(notifUk.message, contains('17:00 (за Віднем)'));
      expect(notifUk.message, contains('HappyLand'));
      expect(notifUk.message, contains('Sports Pool, Lane 1'));

      // German language for Vienna
      final notifDe = BranchNotificationService.createReminder24h(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        language: 'de',
      );
      expect(notifDe.message, contains('17:00 Uhr (Wien)'));
      expect(notifDe.message, contains('HappyLand'));
      expect(notifDe.message, contains('Sports Pool, Lane 1'));
      expect(notifDe.title, equals('Erinnerung an das Schwimmtraining'));

      // English language for Vienna
      final notifEn = BranchNotificationService.createReminder24h(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        language: 'en',
      );
      expect(notifEn.message, contains('17:00 (Vienna)'));
      expect(notifEn.message, contains('HappyLand'));
      expect(notifEn.title, equals('Class Reminder'));
    });

    test('2-Hour Reminder for Vienna: Formats in Vienna local time', () {
      final notifDe = BranchNotificationService.createReminder2h(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        language: 'de',
      );
      expect(notifDe.type, equals(BranchNotificationType.reminder2h));
      expect(notifDe.title, equals('Training in Kürze!'));
      expect(notifDe.message, contains('17:00 Uhr (Wien)'));
      expect(notifDe.message, contains('Badesachen nicht vergessen'));

      final notifUk = BranchNotificationService.createReminder2h(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        language: 'uk',
      );
      expect(notifUk.title, equals('Заняття незабаром!'));
      expect(notifUk.message, contains('17:00 (за Віднем)'));
    });

    test('DST Precision: Winter and summer classes both display exact 17:00 Vienna time', () {
      final winterReminder = BranchNotificationService.createReminder24h(
        groupClass: viennaClassWinter,
        userId: 'client_anna',
        language: 'de',
      );
      final summerReminder = BranchNotificationService.createReminder24h(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        language: 'de',
      );

      // Even though winter UTC is 16:00 and summer UTC is 15:00,
      // BOTH notifications explicitly state 17:00 to Vienna parents!
      expect(winterReminder.message, contains('17:00 Uhr (Wien)'));
      expect(summerReminder.message, contains('17:00 Uhr (Wien)'));
    });

    test('Kyiv Notifications: Formats in Kyiv local time (Europe/Kyiv)', () {
      final notifUk = BranchNotificationService.createReminder24h(
        groupClass: kyivClass,
        userId: 'client_petro',
        language: 'uk',
      );
      expect(notifUk.branchId, equals('kyiv'));
      expect(notifUk.message, contains('18:30 (за Києвом)'));
      expect(notifUk.message, contains('CitySwim Kyiv Center'));

      final notifEn = BranchNotificationService.createReminder24h(
        groupClass: kyivClass,
        userId: 'client_petro',
        language: 'en',
      );
      expect(notifEn.message, contains('18:30 (Kyiv)'));
      expect(notifEn.message, contains('CitySwim Kyiv Center'));
    });

    test('Schedule Change Notification: Formats localized date and time in branch timezone', () {
      final notif = BranchNotificationService.createScheduleChangeNotification(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        reason: 'Wartung des Beckens',
        language: 'de',
      );

      expect(notif.type, equals(BranchNotificationType.scheduleChange));
      expect(notif.title, equals('Trainingszeit geändert'));
      expect(notif.message, contains('17:00 Uhr (Wien)'));
      expect(notif.message, contains('10.06.2026'));
      expect(notif.message, contains('Wartung des Beckens'));
    });

    test('Cancellation Notification: Formats localized notice with refund reassurance', () {
      final notif = BranchNotificationService.createCancellationNotification(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        reason: 'Feiertag',
        language: 'de',
      );

      expect(notif.type, equals(BranchNotificationType.classCancelled));
      expect(notif.title, equals('Training abgesagt'));
      expect(notif.message, contains('17:00 Uhr (Wien)'));
      expect(notif.message, contains('Das Guthaben wurde nicht verrechnet'));
    });

    test('Payment Receipt Notification: Distinct branding for Vienna and Kyiv', () {
      final viennaReceipt = BranchNotificationService.createPaymentReceiptNotification(
        branchId: 'vienna',
        organizationId: 'cityswim',
        userId: 'client_anna',
        packageName: '8 Einheiten',
        formattedAmount: '€110',
        receiptNumber: 'INV-VIE-2026-001',
        language: 'de',
      );

      expect(viennaReceipt.type, equals(BranchNotificationType.paymentReceipt));
      expect(viennaReceipt.title, contains('Zahlungsbestätigung'));
      expect(viennaReceipt.message, contains('CitySwim Vienna'));
      expect(viennaReceipt.message, contains('8 Einheiten'));
      expect(viennaReceipt.message, contains('€110'));
      expect(viennaReceipt.message, contains('INV-VIE-2026-001'));

      final kyivReceipt = BranchNotificationService.createPaymentReceiptNotification(
        branchId: 'kyiv',
        organizationId: 'cityswim',
        userId: 'client_petro',
        packageName: '8 занять',
        formattedAmount: '3 000 ₴',
        receiptNumber: 'INV-KYIV-2026-001',
        language: 'uk',
      );

      expect(kyivReceipt.message, contains('CitySwim Kyiv'));
      expect(kyivReceipt.message, contains('3 000 ₴'));
      expect(kyivReceipt.message, contains('INV-KYIV-2026-001'));
    });

    test('Automated Class Scanner: Accurately identifies 24h and 2h reminder windows', () {
      final fixedNow = DateTime.utc(2026, 6, 9, 15, 0); // Exactly 24h before viennaClassSummer

      // 1. Class exactly 24 hours away
      final reminders24h = BranchNotificationService.generateUpcomingRemindersForClasses(
        classes: [viennaClassSummer],
        userId: 'client_anna',
        enrolledChildIds: {'child_maxi'},
        nowUtc: fixedNow,
        language: 'de',
      );

      expect(reminders24h.length, equals(1));
      expect(reminders24h.first.type, equals(BranchNotificationType.reminder24h));
      expect(reminders24h.first.id, equals('rem24h_class_vienna_summer_client_anna'));
      expect(reminders24h.first.message, contains('17:00 Uhr (Wien)'));

      // 2. Class 1.5 hours away (90 minutes)
      final nearNow = viennaClassSummer.startTime.toUtc().subtract(const Duration(minutes: 90));
      final reminders2h = BranchNotificationService.generateUpcomingRemindersForClasses(
        classes: [viennaClassSummer],
        userId: 'client_anna',
        enrolledChildIds: {'child_maxi'},
        nowUtc: nearNow,
        language: 'de',
      );

      expect(reminders2h.length, equals(1));
      expect(reminders2h.first.type, equals(BranchNotificationType.reminder2h));
      expect(reminders2h.first.id, equals('rem2h_class_vienna_summer_client_anna'));

      // 3. Class for another child/family is strictly filtered out
      final otherReminders = BranchNotificationService.generateUpcomingRemindersForClasses(
        classes: [viennaClassSummer],
        userId: 'other_user',
        enrolledChildIds: {'other_child'},
        nowUtc: fixedNow,
        language: 'de',
      );
      expect(otherReminders, isEmpty);
    });

    test('Model Serialization and ParentNotification Conversion', () {
      final notif = BranchNotificationService.createReminder24h(
        groupClass: viennaClassSummer,
        userId: 'client_anna',
        language: 'de',
      );

      final json = notif.toJson();
      expect(json['branchId'], equals('vienna'));
      expect(json['organizationId'], equals('cityswim'));
      expect(json['type'], equals('reminder24h'));
      expect(json['userId'], equals('client_anna'));

      final restored = BranchNotification.fromJson(json);
      expect(restored.id, equals(notif.id));
      expect(restored.branchId, equals('vienna'));
      expect(restored.message, equals(notif.message));

      // Test conversion to UI ParentNotification
      final parentNotif = notif.toParentNotification();
      expect(parentNotif.id, equals(notif.id));
      expect(parentNotif.title, equals(notif.title));
      expect(parentNotif.message, equals(notif.message));
      expect(parentNotif.actionType, equals('calendar'));
    });
  });
}
