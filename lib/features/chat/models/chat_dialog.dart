import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chat_dialog.freezed.dart';
part 'chat_dialog.g.dart';

@freezed
abstract class ChatDialog with _$ChatDialog {
  const factory ChatDialog({
    required String id,
    required String clientId,
    required String clientName,
    @Default('') String clientAvatar,
    @Default('') String lastMessage,
    @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
    required DateTime lastMessageTime,
    @Default(0) int unreadAdminCount,
    @Default(0) int unreadClientCount,
    @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
    required DateTime updatedAt,
  }) = _ChatDialog;

  factory ChatDialog.fromJson(Map<String, dynamic> json) => _$ChatDialogFromJson(json);
}

DateTime _dateTimeFromTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  if (timestamp is String) {
    return DateTime.parse(timestamp);
  }
  if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  return DateTime.now();
}

dynamic _dateTimeToTimestamp(DateTime date) {
  return Timestamp.fromDate(date);
}
