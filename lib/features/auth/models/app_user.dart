import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole { parent, coach, owner, admin }

@freezed
abstract class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String name,
    required String description,
    required String iconType,
    @Default(false) bool isUnlocked,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
}

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String name,
    required UserRole role,
    String? phone,
    String? loginId,
    @Default(1) int level,
    @Default(0) int xp,
    @Default(100) int maxXp,
    @Default([]) List<Achievement> achievements,
    @Default('https://ui-avatars.com/api/?name=User') String avatarUrl,
    @JsonKey(includeFromJson: false, includeToJson: false) Uint8List? avatarBytes,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}
