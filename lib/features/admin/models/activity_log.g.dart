// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityLog _$ActivityLogFromJson(Map<String, dynamic> json) => _ActivityLog(
  id: json['id'] as String,
  action: json['action'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  adminId: json['adminId'] as String,
);

Map<String, dynamic> _$ActivityLogToJson(_ActivityLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'timestamp': instance.timestamp.toIso8601String(),
      'adminId': instance.adminId,
    };
