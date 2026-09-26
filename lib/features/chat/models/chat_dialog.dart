import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDialog {
  final String id;
  final String clientId;
  final String clientName;
  final String clientAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadAdminCount;
  final int unreadClientCount;
  final DateTime updatedAt;

  // Fields for Coach <-> Client chat and stealth admin monitoring
  final String? coachId;
  final String? coachName;
  final String? coachAvatar;
  final String? childName;
  final String type; // 'support', 'coach_client', 'recovery'
  final int unreadCoachCount;
  final List<String> participantIds;
  final String? lastSenderId;
  final String organizationId;
  final String branchId;

  const ChatDialog({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAvatar = '',
    this.lastMessage = '',
    required this.lastMessageTime,
    this.unreadAdminCount = 0,
    this.unreadClientCount = 0,
    required this.updatedAt,
    this.coachId,
    this.coachName,
    this.coachAvatar,
    this.childName,
    this.type = 'support',
    this.unreadCoachCount = 0,
    this.participantIds = const [],
    this.lastSenderId,
    this.organizationId = 'cityswim',
    this.branchId = 'kyiv',
  });

  factory ChatDialog.fromJson(Map<String, dynamic> json) {
    return ChatDialog(
      id: json['id'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      clientAvatar: json['clientAvatar'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: _dateTimeFromTimestamp(json['lastMessageTime']),
      unreadAdminCount: (json['unreadAdminCount'] as num?)?.toInt() ?? 0,
      unreadClientCount: (json['unreadClientCount'] as num?)?.toInt() ?? 0,
      updatedAt: _dateTimeFromTimestamp(json['updatedAt']),
      coachId: json['coachId'] as String?,
      coachName: json['coachName'] as String?,
      coachAvatar: json['coachAvatar'] as String?,
      childName: json['childName'] as String?,
      type: json['type'] as String? ?? 'support',
      unreadCoachCount: (json['unreadCoachCount'] as num?)?.toInt() ?? 0,
      participantIds: (json['participantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastSenderId: json['lastSenderId'] as String?,
      organizationId: json['organizationId'] as String? ?? 'cityswim',
      branchId: json['branchId'] as String? ?? 'kyiv',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadAdminCount': unreadAdminCount,
      'unreadClientCount': unreadClientCount,
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (coachId != null) 'coachId': coachId,
      if (coachName != null) 'coachName': coachName,
      if (coachAvatar != null) 'coachAvatar': coachAvatar,
      if (childName != null) 'childName': childName,
      'type': type,
      'unreadCoachCount': unreadCoachCount,
      'participantIds': participantIds,
      if (lastSenderId != null) 'lastSenderId': lastSenderId,
      'organizationId': organizationId,
      'branchId': branchId,
    };
  }

  ChatDialog copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadAdminCount,
    int? unreadClientCount,
    DateTime? updatedAt,
    String? coachId,
    String? coachName,
    String? coachAvatar,
    String? childName,
    String? type,
    int? unreadCoachCount,
    List<String>? participantIds,
    String? lastSenderId,
    String? organizationId,
    String? branchId,
  }) {
    return ChatDialog(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadAdminCount: unreadAdminCount ?? this.unreadAdminCount,
      unreadClientCount: unreadClientCount ?? this.unreadClientCount,
      updatedAt: updatedAt ?? this.updatedAt,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      coachAvatar: coachAvatar ?? this.coachAvatar,
      childName: childName ?? this.childName,
      type: type ?? this.type,
      unreadCoachCount: unreadCoachCount ?? this.unreadCoachCount,
      participantIds: participantIds ?? this.participantIds,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatDialog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clientId == other.clientId &&
          clientName == other.clientName &&
          lastMessageTime == other.lastMessageTime &&
          unreadAdminCount == other.unreadAdminCount &&
          unreadClientCount == other.unreadClientCount &&
          unreadCoachCount == other.unreadCoachCount &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        clientName,
        lastMessageTime,
        unreadAdminCount,
        unreadClientCount,
        unreadCoachCount,
        updatedAt,
      );

  @override
  String toString() {
    return 'ChatDialog(id: $id, type: $type, coach: $coachName, client: $clientName, lastMessage: $lastMessage)';
  }
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
