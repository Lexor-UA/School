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
