import 'package:freezed_annotation/freezed_annotation.dart';

part 'child.freezed.dart';
part 'child.g.dart';

@freezed
abstract class Child with _$Child {
  const factory Child({
    required String id,
    required String parentId,
    required String name,
    int? age,
    @Default('0xFF40C4FF') String colorHex, // Default cyan-ish
    @Default(1) int level,
    @Default(0) int xp,
    @Default(100) int maxXp,
  }) = _Child;

  factory Child.fromJson(Map<String, dynamic> json) => _$ChildFromJson(json);
}
