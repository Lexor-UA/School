// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_dialog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatDialog _$ChatDialogFromJson(Map<String, dynamic> json) => _ChatDialog(
  id: json['id'] as String,
  clientId: json['clientId'] as String,
  clientName: json['clientName'] as String,
  clientAvatar: json['clientAvatar'] as String? ?? '',
  lastMessage: json['lastMessage'] as String? ?? '',
  lastMessageTime: _dateTimeFromTimestamp(json['lastMessageTime']),
  unreadAdminCount: (json['unreadAdminCount'] as num?)?.toInt() ?? 0,
  unreadClientCount: (json['unreadClientCount'] as num?)?.toInt() ?? 0,
  updatedAt: _dateTimeFromTimestamp(json['updatedAt']),
);

Map<String, dynamic> _$ChatDialogToJson(_ChatDialog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'clientAvatar': instance.clientAvatar,
      'lastMessage': instance.lastMessage,
      'lastMessageTime': _dateTimeToTimestamp(instance.lastMessageTime),
      'unreadAdminCount': instance.unreadAdminCount,
      'unreadClientCount': instance.unreadClientCount,
      'updatedAt': _dateTimeToTimestamp(instance.updatedAt),
    };
