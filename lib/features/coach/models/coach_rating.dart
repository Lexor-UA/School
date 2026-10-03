import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a client's star rating and optional review for a coach on a specific class.
class CoachRating {
  final String id;
  final String classId;
  final String coachId;
  final String coachName;
  final String clientId;
  final String clientName;
  final int stars; // 1 to 5
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoachRating({
    required this.id,
    required this.classId,
    required this.coachId,
    required this.coachName,
    required this.clientId,
    required this.clientName,
    required int stars,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  }) : stars = stars.clamp(1, 5);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'coachId': coachId,
      'coachName': coachName,
      'clientId': clientId,
      'clientName': clientName,
      'stars': stars,
      if (comment != null) 'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CoachRating.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CoachRating(
      id: docId ?? (map['id'] as String? ?? ''),
      classId: map['classId'] as String? ?? '',
      coachId: map['coachId'] as String? ?? '',
      coachName: map['coachName'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      stars: (map['stars'] as num?)?.toInt().clamp(1, 5) ?? 5,
      comment: map['comment'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  CoachRating copyWith({
    String? id,
    String? classId,
    String? coachId,
    String? coachName,
    String? clientId,
    String? clientName,
    int? stars,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachRating(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      stars: stars ?? this.stars,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
