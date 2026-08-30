// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Child _$ChildFromJson(Map<String, dynamic> json) => _Child(
  id: json['id'] as String,
  parentId: json['parentId'] as String,
  name: json['name'] as String,
  age: (json['age'] as num?)?.toInt(),
  colorHex: json['colorHex'] as String? ?? '0xFF40C4FF',
  level: (json['level'] as num?)?.toInt() ?? 1,
  xp: (json['xp'] as num?)?.toInt() ?? 0,
  maxXp: (json['maxXp'] as num?)?.toInt() ?? 100,
  achievements:
      (json['achievements'] as List<dynamic>?)
          ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ChildToJson(_Child instance) => <String, dynamic>{
  'id': instance.id,
  'parentId': instance.parentId,
  'name': instance.name,
  'age': instance.age,
  'colorHex': instance.colorHex,
  'level': instance.level,
  'xp': instance.xp,
  'maxXp': instance.maxXp,
  'achievements': instance.achievements,
};
