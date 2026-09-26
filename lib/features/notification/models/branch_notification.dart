import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/parent/controllers/parent_notifications_controller.dart';

/// Типи сповіщень у системі з прив'язкою до філії
enum BranchNotificationType {
  reminder24h,
  reminder2h,
  scheduleChange,
  classCancelled,
  paymentReceipt,
  subscriptionLow,
  general,
}

/// Модель сповіщення з контекстом філії та локальним часом (п. 24 ТЗ)
@immutable
class BranchNotification {
  final String id;
  final String organizationId;
  final String branchId;
  final String userId;
  final BranchNotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final DateTime? scheduledFor;
  final bool isRead;
  final String? classId;
  final String? actionType;
  final Map<String, dynamic> metadata;

  const BranchNotification({
    required this.id,
    this.organizationId = 'cityswim',
    required this.branchId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.scheduledFor,
    this.isRead = false,
    this.classId,
    this.actionType,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'branchId': branchId,
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'scheduledFor': scheduledFor?.toIso8601String(),
        'isRead': isRead,
        'classId': classId,
        'actionType': actionType,
        'metadata': metadata,
      };

  factory BranchNotification.fromJson(Map<String, dynamic> json) {
    return BranchNotification(
      id: json['id'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? 'cityswim',
      branchId: json['branchId'] as String? ?? 'kyiv',
      userId: json['userId'] as String? ?? '',
      type: BranchNotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BranchNotificationType.general,
      ),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is String
              ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
              : DateTime.now())
          : DateTime.now(),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.tryParse(json['scheduledFor'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      classId: json['classId'] as String?,
      actionType: json['actionType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  BranchNotification copyWith({
    bool? isRead,
    String? title,
    String? message,
  }) {
    return BranchNotification(
      id: id,
      organizationId: organizationId,
      branchId: branchId,
      userId: userId,
      type: type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp,
      scheduledFor: scheduledFor,
      isRead: isRead ?? this.isRead,
      classId: classId,
      actionType: actionType,
      metadata: metadata,
    );
  }

  /// Конвертація в [ParentNotification] для безшовної інтеграції в існуючий Notification Sheet
  ParentNotification toParentNotification() {
    IconData icon;
    Color iconColor;
    switch (type) {
      case BranchNotificationType.reminder24h:
      case BranchNotificationType.reminder2h:
        icon = LucideIcons.calendarClock;
        iconColor = const Color(0xFF38BDF8); // Sky blue
        break;
      case BranchNotificationType.scheduleChange:
      case BranchNotificationType.classCancelled:
        icon = LucideIcons.alertTriangle;
        iconColor = const Color(0xFFEF4444); // Red
        break;
      case BranchNotificationType.paymentReceipt:
      case BranchNotificationType.subscriptionLow:
        icon = LucideIcons.creditCard;
        iconColor = const Color(0xFFF59E0B); // Amber
        break;
      case BranchNotificationType.general:
        icon = LucideIcons.bellRing;
        iconColor = const Color(0xFF10B981); // Emerald
        break;
    }

    return ParentNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      icon: icon,
      iconColor: iconColor,
      isRead: isRead,
      actionType: actionType ?? 'calendar',
    );
  }
}
