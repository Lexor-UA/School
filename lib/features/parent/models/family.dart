import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String primaryParentId;
  final List<String> parentIds;
  final Map<String, String> parentNames;
  final Map<String, String> parentPhones;
  final String inviteCode;
  final DateTime createdAt;

  const Family({
    required this.id,
    required this.primaryParentId,
    required this.parentIds,
    required this.parentNames,
    this.parentPhones = const {},
    required this.inviteCode,
    required this.createdAt,
  });

  bool get isPaired => parentIds.length > 1;

  String? getOtherParentId(String currentUserId) {
    for (final id in parentIds) {
      if (id != currentUserId) return id;
    }
    return null;
  }

  String? getOtherParentName(String currentUserId) {
    for (final entry in parentNames.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    return null;
  }

  String? getOtherParentPhone(String currentUserId) {
    for (final entry in parentPhones.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    return null;
  }

  factory Family.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return Family(
      id: json['id'] as String? ?? '',
      primaryParentId: json['primaryParentId'] as String? ?? '',
      parentIds: (json['parentIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      parentNames: (json['parentNames'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      parentPhones: (json['parentPhones'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      inviteCode: json['inviteCode'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryParentId': primaryParentId,
      'parentIds': parentIds,
      'parentNames': parentNames,
      'parentPhones': parentPhones,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
