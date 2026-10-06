import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:swimming_school_app/features/auth/models/app_user.dart';

part 'child.freezed.dart';
part 'child.g.dart';

@freezed
abstract class Child with _$Child {
  const factory Child({
    required String id,
    required String parentId,
    required String name,
    int? age,
    @TimestampConverter() DateTime? birthDate,
    @Default('0xFF40C4FF') String colorHex, // Default cyan-ish
    @Default(1) int level,
    @Default(0) int xp,
    @Default(100) int maxXp,
    @Default([]) List<Achievement> achievements,
    @Default('cityswim') String organizationId,
    @Default('kyiv') String branchId,
  }) = _Child;

  factory Child.fromJson(Map<String, dynamic> json) => _$ChildFromJson(json);
}

class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  @override
  Object? toJson(DateTime? date) {
    if (date == null) return null;
    return date.toIso8601String(); // or Timestamp.fromDate(date) depending on Firestore needs
  }
}

extension ChildAgeX on Child {
  int? get currentAge {
    if (birthDate != null) {
      final now = DateTime.now();
      int years = now.year - birthDate!.year;
      if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) {
        years--;
      }
      return years >= 0 ? years : 0;
    }
    return age;
  }

  int? ageAt(DateTime date) {
    if (birthDate != null) {
      int years = date.year - birthDate!.year;
      if (date.month < birthDate!.month || (date.month == birthDate!.month && date.day < birthDate!.day)) {
        years--;
      }
      return years >= 0 ? years : 0;
    }
    return age;
  }

  bool isAdultAt(DateTime date) => (ageAt(date) ?? 0) >= 16;

  bool get isAdultAge => (currentAge ?? 0) >= 16;
}
