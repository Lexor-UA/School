import 'package:freezed_annotation/freezed_annotation.dart';

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
    DateTime? birthDate,
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

  bool get isAdultAge => (currentAge ?? 0) >= 16;
}
