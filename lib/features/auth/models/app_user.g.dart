// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Achievement _$AchievementFromJson(Map<String, dynamic> json) => _Achievement(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  iconType: json['iconType'] as String,
  isUnlocked: json['isUnlocked'] as bool? ?? false,
);

Map<String, dynamic> _$AchievementToJson(_Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'iconType': instance.iconType,
      'isUnlocked': instance.isUnlocked,
    };

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: json['id'] as String,
  name: json['name'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  phone: json['phone'] as String?,
  loginId: json['loginId'] as String?,
  level: (json['level'] as num?)?.toInt() ?? 1,
  xp: (json['xp'] as num?)?.toInt() ?? 0,
  maxXp: (json['maxXp'] as num?)?.toInt() ?? 100,
  achievements:
      (json['achievements'] as List<dynamic>?)
          ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  avatarUrl:
      json['avatarUrl'] as String? ?? 'https://ui-avatars.com/api/?name=User',
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'role': _$UserRoleEnumMap[instance.role]!,
  'phone': instance.phone,
  'loginId': instance.loginId,
  'level': instance.level,
  'xp': instance.xp,
  'maxXp': instance.maxXp,
  'achievements': instance.achievements,
  'avatarUrl': instance.avatarUrl,
};

const _$UserRoleEnumMap = {
  UserRole.parent: 'parent',
  UserRole.coach: 'coach',
  UserRole.owner: 'owner',
  UserRole.admin: 'admin',
};
