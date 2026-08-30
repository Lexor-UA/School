// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  dialogId: json['dialogId'] as String,
  senderId: json['senderId'] as String,
  text: json['text'] as String,
  timestamp: _dateTimeFromTimestamp(json['timestamp']),
  isRead: json['isRead'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dialogId': instance.dialogId,
      'senderId': instance.senderId,
      'text': instance.text,
      'timestamp': _dateTimeToTimestamp(instance.timestamp),
      'isRead': instance.isRead,
    };
