import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String dialogId;
  final String senderId; // clientId, coachId, or 'admin'
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? senderRole; // 'coach', 'parent', 'admin', 'client'
  final String? senderName;

  const ChatMessage({
    required this.id,
    required this.dialogId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.senderRole,
    this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      dialogId: json['dialogId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timestamp: _dateTimeFromTimestamp(json['timestamp']),
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      senderRole: json['senderRole'] as String?,
      senderName: json['senderName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dialogId': dialogId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (senderRole != null) 'senderRole': senderRole,
      if (senderName != null) 'senderName': senderName,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? dialogId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? senderRole,
    String? senderName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      dialogId: dialogId ?? this.dialogId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dialogId == other.dialogId &&
          senderId == other.senderId &&
          text == other.text &&
          timestamp == other.timestamp &&
          isRead == other.isRead &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(
        id,
        dialogId,
        senderId,
        text,
        timestamp,
        isRead,
        imageUrl,
      );
}

DateTime _dateTimeFromTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  }
  if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  return DateTime.now();
}
