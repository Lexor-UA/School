import 'package:flutter/foundation.dart';

@immutable
class BranchPool {
  final String id;
  final String name; // 'Sports Pool', 'Wellenbecken', 'Головний басейн'
  final List<String> lanes; // ['Lane 1', 'Lane 2', 'Lane 5']
  final double? lengthMeters; // 25.0, 50.0

  const BranchPool({
    required this.id,
    required this.name,
    this.lanes = const [],
    this.lengthMeters,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lanes': lanes,
    'lengthMeters': lengthMeters,
  };

  factory BranchPool.fromJson(Map<String, dynamic> json) {
    return BranchPool(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lanes: (json['lanes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      lengthMeters: (json['lengthMeters'] as num?)?.toDouble(),
    );
  }
}

@immutable
class BranchLocation {
  final String id;
  final String name; // 'HappyLand', 'Басейн Олімпійський'
  final String address;
  final List<BranchPool> pools;

  const BranchLocation({
    required this.id,
    required this.name,
    required this.address,
    this.pools = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'pools': pools.map((p) => p.toJson()).toList(),
  };

  factory BranchLocation.fromJson(Map<String, dynamic> json) {
    return BranchLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      pools: (json['pools'] as List<dynamic>?)
              ?.map((e) => BranchPool.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

@immutable
class BranchConfig {
  final String branchId;
  final List<BranchLocation> locations;
  final String contactPhone;
  final String contactEmail;

  const BranchConfig({
    required this.branchId,
    this.locations = const [],
    this.contactPhone = '',
    this.contactEmail = '',
  });

  /// Дефолтна конфігурація для Kyiv
  static const BranchConfig kyivConfig = BranchConfig(
    branchId: 'kyiv',
    locations: [
      BranchLocation(
        id: 'kyiv_main',
        name: 'CitySwim Kyiv Center',
        address: 'вул. Ділова, 10, Київ',
        pools: [
          BranchPool(
            id: 'pool_25m',
            name: 'Головний басейн 25м',
            lanes: ['Доріжка 1', 'Доріжка 2', 'Доріжка 3', 'Доріжка 4', 'Доріжка 5'],
            lengthMeters: 25.0,
          ),
          BranchPool(
            id: 'pool_baby',
            name: 'Дитячий теплий басейн',
            lanes: ['Зона А', 'Зона Б'],
            lengthMeters: 10.0,
          ),
        ],
      ),
    ],
    contactPhone: '+380 44 123 4567',
    contactEmail: 'kyiv@cityswim.app',
  );

  /// Дефолтна конфігурація для Vienna (HappyLand)
  static const BranchConfig viennaConfig = BranchConfig(
    branchId: 'vienna',
    locations: [
      BranchLocation(
        id: 'happyland',
        name: 'HappyLand',
        address: 'Klobuckygasse 25, 3400 Klosterneuburg, Wien',
        pools: [
          BranchPool(
            id: 'sports_pool',
            name: 'Sports Pool',
            lanes: ['Lane 1', 'Lane 2', 'Lane 3', 'Lane 4', 'Lane 5'],
            lengthMeters: 25.0,
          ),
          BranchPool(
            id: 'wellenbecken',
            name: 'Wellenbecken',
            lanes: ['Zone 1', 'Zone 2'],
            lengthMeters: 15.0,
          ),
        ],
      ),
    ],
    contactPhone: '+43 1 234 5678',
    contactEmail: 'vienna@cityswim.app',
  );

  Map<String, dynamic> toJson() => {
    'branchId': branchId,
    'locations': locations.map((l) => l.toJson()).toList(),
    'contactPhone': contactPhone,
    'contactEmail': contactEmail,
  };

  factory BranchConfig.fromJson(Map<String, dynamic> json) {
    return BranchConfig(
      branchId: json['branchId'] as String? ?? 'kyiv',
      locations: (json['locations'] as List<dynamic>?)
              ?.map((e) => BranchLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      contactPhone: json['contactPhone'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
    );
  }

  static BranchConfig forBranch(String branchId) {
    if (branchId == 'vienna') return viennaConfig;
    return kyivConfig;
  }
}
