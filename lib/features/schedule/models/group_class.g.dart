// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupClass _$GroupClassFromJson(Map<String, dynamic> json) => _GroupClass(
  id: json['id'] as String,
  title: json['title'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  coachId: json['coachId'] as String,
  coachName: json['coachName'] as String,
  maxCapacity: (json['maxCapacity'] as num).toInt(),
  enrolledChildIds:
      (json['enrolledChildIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  attendedChildIds:
      (json['attendedChildIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  category: json['category'] as String,
  lane: json['lane'] as String? ?? '',
);

Map<String, dynamic> _$GroupClassToJson(_GroupClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'coachId': instance.coachId,
      'coachName': instance.coachName,
      'maxCapacity': instance.maxCapacity,
      'enrolledChildIds': instance.enrolledChildIds,
      'attendedChildIds': instance.attendedChildIds,
      'category': instance.category,
      'lane': instance.lane,
    };
