import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String primaryParentId;
  final List<String> parentIds;
  final Map<String, String> parentNames;
  final Map<String, String> parentPhones;
  final String inviteCode;
  final DateTime createdAt;
  final String organizationId;
  final String branchId;

  const Family({
    required this.id,
    required this.primaryParentId,
    required this.parentIds,
    required this.parentNames,
    this.parentPhones = const {},
    required this.inviteCode,
    required this.createdAt,
    this.organizationId = 'cityswim',
    this.branchId = 'kyiv',
  });

  bool get isPaired => parentIds.length > 1 || parentNames.length > 1;

  String? getOtherParentId(String currentUserId) {
    for (final id in parentIds) {
      if (id != currentUserId) return id;
    }
    for (final id in parentNames.keys) {
      if (id != currentUserId) return id;
    }
    return null;
  }

  String? getOtherParentName(String currentUserId) {
    for (final entry in parentNames.entries) {
      if (entry.key != currentUserId && entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
    // Fallback: if currentUserId is not in parentNames or matches, find first non-empty name
    for (final entry in parentNames.entries) {
      if (entry.value.trim().isNotEmpty && entry.key != currentUserId) {
        return entry.value.trim();
      }
    }
    return null;
  }

  String? getOtherParentPhone(String currentUserId) {
    for (final entry in parentPhones.entries) {
      if (entry.key != currentUserId && entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
    for (final entry in parentPhones.entries) {
      if (entry.value.trim().isNotEmpty && entry.key != currentUserId) {
        return entry.value.trim();
      }
    }
    return null;
  }

  factory Family.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, String> parseStringMap(dynamic map) {
      if (map is! Map) return {};
      final result = <String, String>{};
      map.forEach((k, v) {
        if (k != null && v != null) {
          result[k.toString()] = v.toString();
        }
      });
      return result;
    }

    return Family(
      id: json['id'] as String? ?? '',
      primaryParentId: json['primaryParentId'] as String? ?? '',
      parentIds: (json['parentIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      parentNames: parseStringMap(json['parentNames']),
      parentPhones: parseStringMap(json['parentPhones']),
      inviteCode: json['inviteCode'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      organizationId: json['organizationId'] as String? ?? 'cityswim',
      branchId: json['branchId'] as String? ?? 'kyiv',
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
      'organizationId': organizationId,
      'branchId': branchId,
    };
  }
}
