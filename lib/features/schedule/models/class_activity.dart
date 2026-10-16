import 'package:easy_localization/easy_localization.dart';

enum ClassActivityType {
  booking,
  cancellation,
  rescheduled,
  classCancelled,
  unknown,
}

class ClassActivity {
  final String id;
  final ClassActivityType type;
  final String classId;
  final String classTitle;
  final String coachId;
  final String coachName;
  final String? attendeeId;
  final String? attendeeName;
  final String? parentName;
  final String? parentPhone;
  final DateTime timestamp;
  final String message;

  const ClassActivity({
    required this.id,
    required this.type,
    required this.classId,
    required this.classTitle,
    required this.coachId,
    required this.coachName,
    this.attendeeId,
    this.attendeeName,
    this.parentName,
    this.parentPhone,
    required this.timestamp,
    required this.message,
  });

  /// Returns a dynamically localized message using the current active locale,
  /// even if the activity was saved to Firestore when another language (e.g. English) was active.
  String get localizedMessage {
    final title = classTitle.trim().isNotEmpty ? classTitle.trim() : 'schedule.default_training'.tr();
    final name = (attendeeName != null && attendeeName!.trim().isNotEmpty)
        ? attendeeName!.trim()
        : (parentName != null && parentName!.trim().isNotEmpty ? parentName!.trim() : '');

    switch (type) {
      case ClassActivityType.cancellation:
        final lowerMsg = message.toLowerCase();
        final isSplit = lowerMsg.contains('split') ||
            lowerMsg.contains('спліт') ||
            lowerMsg.contains('сплит') ||
            title.toLowerCase().contains('спліт') ||
            title.toLowerCase().contains('split');
        if (isSplit) {
          return 'schedule.log_cancel_split'.tr(namedArgs: {'title': title});
        }
        if (name.isNotEmpty) {
          return 'schedule.log_cancel_single'.tr(namedArgs: {
            'name': name,
            'title': title,
          });
        }
        break;
      case ClassActivityType.booking:
        if (name.isNotEmpty) {
          return 'schedule.log_new_booking'.tr(namedArgs: {
            'names': name,
            'title': title,
          });
        }
        break;
      case ClassActivityType.rescheduled:
        final slotMatch = RegExp(r'\(([^)]+)\)\s*$').firstMatch(message);
        final slot = slotMatch?.group(1) ?? '';
        if (slot.isNotEmpty) {
          return 'schedule.log_rescheduled'.tr(namedArgs: {
            'title': title,
            'slot': slot,
          });
        }
        break;
      case ClassActivityType.classCancelled:
        final countMatch = RegExp(r'\((\d+)').firstMatch(message) ??
            RegExp(r'(\d+)\s+(?:занят|classes|Einheiten|занятий)').firstMatch(message);
        if (countMatch != null) {
          return 'schedule.log_class_cancelled_with_refund'.tr(namedArgs: {
            'title': title,
            'count': countMatch.group(1)!,
          });
        }
        return 'schedule.log_class_cancelled_by_admin'.tr(namedArgs: {'title': title});
      case ClassActivityType.unknown:
        break;
    }

    return sanitizeNotificationText(message);
  }

  /// Cleans up any legacy English prefixes or unreplaced `{...}` placeholders in stored messages.
  static String sanitizeNotificationText(String raw) {
    if (raw.isEmpty) return raw;
    var text = raw;

    // 1. Check if raw matches English cancellation pattern: Cancellation: X cancelled booking for "Y"
    final cancelSingleEn = RegExp(r'^Cancellation:\s*(.+?)\s+cancelled booking for\s+"([^"]+)"', caseSensitive: false).firstMatch(text);
    if (cancelSingleEn != null) {
      return 'schedule.log_cancel_single'.tr(namedArgs: {
        'name': cancelSingleEn.group(1)!,
        'title': cancelSingleEn.group(2)!,
      });
    }

    final cancelSplitEn = RegExp(r'^Split class cancellation:.*?"([^"]+)"', caseSensitive: false).firstMatch(text);
    if (cancelSplitEn != null) {
      return 'schedule.log_cancel_split'.tr(namedArgs: {
        'title': cancelSplitEn.group(1)!,
      });
    }

    final newBookingEn = RegExp(r'^New booking:\s*(.+?)\s+enrolled in\s+"([^"]+)"', caseSensitive: false).firstMatch(text);
    if (newBookingEn != null) {
      return 'schedule.log_new_booking'.tr(namedArgs: {
        'names': newBookingEn.group(1)!,
        'title': newBookingEn.group(2)!,
      });
    }

    final rescheduledEn = RegExp(r'^Schedule change:\s*"([^"]+)"\s*\(([^)]+)\)', caseSensitive: false).firstMatch(text);
    if (rescheduledEn != null) {
      return 'schedule.log_rescheduled'.tr(namedArgs: {
        'title': rescheduledEn.group(1)!,
        'slot': rescheduledEn.group(2)!,
      });
    }

    // 2. Strip any unreplaced {placeholder} tokens that may have been persisted in Firestore
    text = text.replaceAll(RegExp(r'\s*\(\{[a-zA-Z0-9_]+\}\)'), '');
    text = text.replaceAll(RegExp(r'\{[a-zA-Z0-9_]+\}'), '');
    return text.trim();
  }

  static ClassActivityType parseType(String? val) {
    switch (val) {
      case 'booking':
        return ClassActivityType.booking;
      case 'cancellation':
        return ClassActivityType.cancellation;
      case 'rescheduled':
        return ClassActivityType.rescheduled;
      case 'class_cancelled':
        return ClassActivityType.classCancelled;
      default:
        return ClassActivityType.unknown;
    }
  }

  static String typeToString(ClassActivityType type) {
    switch (type) {
      case ClassActivityType.booking:
        return 'booking';
      case ClassActivityType.cancellation:
        return 'cancellation';
      case ClassActivityType.rescheduled:
        return 'rescheduled';
      case ClassActivityType.classCancelled:
        return 'class_cancelled';
      case ClassActivityType.unknown:
        return 'unknown';
    }
  }

  factory ClassActivity.fromJson(Map<String, dynamic> json) {
    return ClassActivity(
      id: json['id'] as String? ?? '',
      type: parseType(json['type'] as String?),
      classId: json['classId'] as String? ?? '',
      classTitle: json['classTitle'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      coachName: json['coachName'] as String? ?? '',
      attendeeId: json['attendeeId'] as String?,
      attendeeName: json['attendeeName'] as String?,
      parentName: json['parentName'] as String?,
      parentPhone: json['parentPhone'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': typeToString(type),
      'classId': classId,
      'classTitle': classTitle,
      'coachId': coachId,
      'coachName': coachName,
      if (attendeeId != null) 'attendeeId': attendeeId,
      if (attendeeName != null) 'attendeeName': attendeeName,
      if (parentName != null) 'parentName': parentName,
      if (parentPhone != null) 'parentPhone': parentPhone,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
    };
  }
}
