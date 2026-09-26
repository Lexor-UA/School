import 'package:flutter/foundation.dart';
import 'package:swimming_school_app/features/tenancy/models/white_label_config.dart';

@immutable
class Organization {
  final String id;
  final String name;
  final String? logoUrl;
  final String status; // 'active', 'suspended'
  final DateTime createdAt;
  final Map<String, dynamic>? branding;

  const Organization({
    required this.id,
    required this.name,
    this.logoUrl,
    this.status = 'active',
    required this.createdAt,
    this.branding,
  });

  /// White label configuration for this organization
  WhiteLabelConfig get whiteLabelConfig {
    if (branding != null) {
      final map = Map<String, dynamic>.from(branding!);
      map['organizationId'] = id;
      map['appName'] = map['appName'] ?? name;
      return WhiteLabelConfig.fromJson(map);
    }
    return WhiteLabelConfig.citySwimDefault.copyWith(organizationId: id, appName: name);
  }

  /// Дефолтна організація для CitySwim
  static final Organization cityswim = Organization(
    id: 'cityswim',
    name: 'CitySwim',
    logoUrl: 'assets/images/logo_light.png',
    status: 'active',
    createdAt: DateTime(2025, 1, 1),
    branding: {
      'primaryColor': 0xFF00E5FF,
      'primaryColorValue': 0xFF00E5FF,
      'secondaryColorValue': 0xFF001F3F,
      'accentColorValue': 0xFF10B981,
      'appName': 'CitySwim',
      'legalEntityName': 'CitySwim International Group',
    },
  );

  Organization copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? status,
    DateTime? createdAt,
    Map<String, dynamic>? branding,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      branding: branding ?? this.branding,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'branding': branding,
  };

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String? ?? 'cityswim',
      name: json['name'] as String? ?? 'CitySwim',
      logoUrl: json['logoUrl'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      branding: json['branding'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organization &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Organization(id: $id, name: $name)';
}
