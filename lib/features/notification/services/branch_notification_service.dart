import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:swimming_school_app/features/notification/models/branch_notification.dart';
import 'package:swimming_school_app/features/notification/services/branch_notification_templates.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';

/// Сервіс для генерації, планування та відправки сповіщень у контексті часового поясу філії (п. 24 ТЗ)
class BranchNotificationService {
  BranchNotificationService._();

  /// Створення нагадування за 24 години до заняття
  static BranchNotification createReminder24h({
    required GroupClass groupClass,
    required String userId,
    String language = 'uk',
    DateTime? timestamp,
  }) {
    final localTimeFormatted = groupClass.formatBranchTime();
    final names = _resolveLocationAndPoolNames(groupClass);

    final template = BranchNotificationTemplates.reminder24h(
      branchId: groupClass.branchId,
      classTitle: groupClass.title,
      timeFormatted: localTimeFormatted,
      locationName: names.locationName,
      poolName: names.poolName,
      lane: groupClass.lane,
      language: language,
    );

    return BranchNotification(
      id: 'rem24h_${groupClass.id}_$userId',
      organizationId: groupClass.organizationId,
      branchId: groupClass.branchId,
      userId: userId,
      type: BranchNotificationType.reminder24h,
      title: template.title,
      message: template.body,
      timestamp: timestamp ?? DateTime.now(),
      scheduledFor: groupClass.startTime.subtract(const Duration(hours: 24)),
      classId: groupClass.id,
      actionType: 'calendar',
      metadata: {
        'classTitle': groupClass.title,
        'branchLocalTime': localTimeFormatted,
        'timezone': groupClass.timezone,
        'lane': groupClass.lane,
      },
    );
  }

  /// Створення нагадування за 2 години до початку заняття
  static BranchNotification createReminder2h({
    required GroupClass groupClass,
    required String userId,
    String language = 'uk',
    DateTime? timestamp,
  }) {
    final localTimeFormatted = groupClass.formatBranchTime();
    final names = _resolveLocationAndPoolNames(groupClass);

    final template = BranchNotificationTemplates.reminder2h(
      branchId: groupClass.branchId,
      classTitle: groupClass.title,
      timeFormatted: localTimeFormatted,
      locationName: names.locationName,
      poolName: names.poolName,
      lane: groupClass.lane,
      language: language,
    );

    return BranchNotification(
      id: 'rem2h_${groupClass.id}_$userId',
      organizationId: groupClass.organizationId,
      branchId: groupClass.branchId,
      userId: userId,
      type: BranchNotificationType.reminder2h,
      title: template.title,
      message: template.body,
      timestamp: timestamp ?? DateTime.now(),
      scheduledFor: groupClass.startTime.subtract(const Duration(hours: 2)),
      classId: groupClass.id,
      actionType: 'calendar',
      metadata: {
        'classTitle': groupClass.title,
        'branchLocalTime': localTimeFormatted,
        'timezone': groupClass.timezone,
        'lane': groupClass.lane,
      },
    );
  }

  /// Створення сповіщення про перенесення заняття на новий час
  static BranchNotification createScheduleChangeNotification({
    required GroupClass groupClass,
    required String userId,
    required String reason,
    String language = 'uk',
    DateTime? timestamp,
  }) {
    final localDateFormatted = groupClass.formatBranchDate();
    final localTimeFormatted = groupClass.formatBranchTime();

    final template = BranchNotificationTemplates.scheduleChange(
      branchId: groupClass.branchId,
      classTitle: groupClass.title,
      newDateFormatted: localDateFormatted,
      newTimeFormatted: localTimeFormatted,
      reason: reason,
      language: language,
    );

    return BranchNotification(
      id: 'change_${groupClass.id}_${(timestamp ?? DateTime.now()).millisecondsSinceEpoch}',
      organizationId: groupClass.organizationId,
      branchId: groupClass.branchId,
      userId: userId,
      type: BranchNotificationType.scheduleChange,
      title: template.title,
      message: template.body,
      timestamp: timestamp ?? DateTime.now(),
      classId: groupClass.id,
      actionType: 'calendar',
      metadata: {
        'classTitle': groupClass.title,
        'newBranchLocalTime': localTimeFormatted,
        'newBranchLocalDate': localDateFormatted,
        'timezone': groupClass.timezone,
      },
    );
  }

  /// Створення сповіщення про скасування заняття
  static BranchNotification createCancellationNotification({
    required GroupClass groupClass,
    required String userId,
    required String reason,
    String language = 'uk',
    DateTime? timestamp,
  }) {
    final localDateFormatted = groupClass.formatBranchDate();
    final localTimeFormatted = groupClass.formatBranchTime();

    final template = BranchNotificationTemplates.classCancelled(
      branchId: groupClass.branchId,
      classTitle: groupClass.title,
      dateFormatted: localDateFormatted,
      timeFormatted: localTimeFormatted,
      reason: reason,
      language: language,
    );

    return BranchNotification(
      id: 'cancel_${groupClass.id}_${(timestamp ?? DateTime.now()).millisecondsSinceEpoch}',
      organizationId: groupClass.organizationId,
      branchId: groupClass.branchId,
      userId: userId,
      type: BranchNotificationType.classCancelled,
      title: template.title,
      message: template.body,
      timestamp: timestamp ?? DateTime.now(),
      classId: groupClass.id,
      actionType: 'calendar',
      metadata: {
        'classTitle': groupClass.title,
        'branchLocalTime': localTimeFormatted,
        'branchLocalDate': localDateFormatted,
        'timezone': groupClass.timezone,
      },
    );
  }

  /// Створення сповіщення про оплату абонемента з генерацією електронного чека
  static BranchNotification createPaymentReceiptNotification({
    required String branchId,
    required String organizationId,
    required String userId,
    required String packageName,
    required String formattedAmount,
    required String receiptNumber,
    String language = 'uk',
    DateTime? timestamp,
  }) {
    final template = BranchNotificationTemplates.paymentReceipt(
      branchId: branchId,
      packageName: packageName,
      formattedAmount: formattedAmount,
      receiptNumber: receiptNumber,
      language: language,
    );

    return BranchNotification(
      id: 'pay_$receiptNumber',
      organizationId: organizationId,
      branchId: branchId,
      userId: userId,
      type: BranchNotificationType.paymentReceipt,
      title: template.title,
      message: template.body,
      timestamp: timestamp ?? DateTime.now(),
      actionType: 'subscription',
      metadata: {
        'packageName': packageName,
        'formattedAmount': formattedAmount,
        'receiptNumber': receiptNumber,
      },
    );
  }

  /// Автоматичне сканування найближчих занять користувача та генерація нагадувань (24г та 2г)
  static List<BranchNotification> generateUpcomingRemindersForClasses({
    required List<GroupClass> classes,
    required String userId,
    required Set<String> enrolledChildIds,
    DateTime? nowUtc,
    String language = 'uk',
  }) {
    final now = nowUtc ?? DateTime.now().toUtc();
    final List<BranchNotification> reminders = [];

    // Фільтруємо заняття, де записана дитина користувача або сам користувач
    final relevantClasses = classes.where((c) {
      return enrolledChildIds.any(c.enrolledChildIds.contains) || c.enrolledChildIds.contains(userId);
    }).toList();

    for (final groupClass in relevantClasses) {
      final classStartUtc = groupClass.startTime.isUtc ? groupClass.startTime : groupClass.startTime.toUtc();
      final difference = classStartUtc.difference(now);

      // Вікно нагадування за 24 години: заняття починається через 20..26 годин
      if (difference.inMinutes >= 20 * 60 && difference.inMinutes <= 26 * 60) {
        reminders.add(createReminder24h(
          groupClass: groupClass,
          userId: userId,
          language: language,
          timestamp: now,
        ));
      }

      // Вікно нагадування за 2 години: заняття починається через 45..150 хвилин
      if (difference.inMinutes >= 45 && difference.inMinutes <= 150) {
        reminders.add(createReminder2h(
          groupClass: groupClass,
          userId: userId,
          language: language,
          timestamp: now,
        ));
      }
    }

    return reminders;
  }

  /// Збереження сповіщення у Firestore колекцію `notifications`
  static Future<bool> saveNotificationToFirestore(BranchNotification notification) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('notifications').doc(notification.id).set(notification.toJson());
      return true;
    } catch (e) {
      debugPrint('Notice: Failed to save notification to Firestore: $e');
      return false;
    }
  }

  static ({String locationName, String poolName}) _resolveLocationAndPoolNames(GroupClass groupClass) {
    final config = BranchConfig.forBranch(groupClass.branchId);
    String locationName = '';
    String poolName = '';

    for (final loc in config.locations) {
      if (loc.id == groupClass.locationId || locationName.isEmpty) {
        locationName = loc.name;
        for (final p in loc.pools) {
          if (p.id == groupClass.poolId || poolName.isEmpty) {
            poolName = p.name;
            if (p.id == groupClass.poolId) break;
          }
        }
        if (loc.id == groupClass.locationId) break;
      }
    }

    return (locationName: locationName, poolName: poolName);
  }
}
