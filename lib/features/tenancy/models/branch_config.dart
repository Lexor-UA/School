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

  String getLocalizedName(String langCode) =>
      BranchConfig.localizePoolName(name, langCode);

  List<String> getLocalizedLanes(String langCode) =>
      lanes.map((l) => BranchConfig.localizeLaneName(l, langCode)).toList();

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

  String getLocalizedAddress(String langCode) =>
      BranchConfig.localizeAddress(address, langCode);

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

  static final Map<String, BranchConfig> _customConfigs = {};

  static void registerConfig(BranchConfig config) {
    _customConfigs[config.branchId] = config;
  }

  static void removeConfig(String branchId) {
    _customConfigs.remove(branchId);
  }

  /// Створення стандартної локації та 25м басейну для нової філії
  static BranchConfig createDefault({
    required String branchId,
    required String branchName,
    required String city,
  }) {
    final locId = 'loc_${branchId}_main';
    final poolId = 'pool_${branchId}_25m';
    return BranchConfig(
      branchId: branchId,
      locations: [
        BranchLocation(
          id: locId,
          name: '$branchName Center',
          address: city.isNotEmpty ? 'вул. Спортивна, 1, $city' : 'вул. Спортивна, 1',
          pools: [
            BranchPool(
              id: poolId,
              name: 'Головний басейн 25м',
              lanes: const ['Доріжка 1', 'Доріжка 2', 'Доріжка 3', 'Доріжка 4'],
              lengthMeters: 25.0,
            ),
          ],
        ),
      ],
      contactPhone: '+380 00 000 0000',
      contactEmail: '$branchId@cityswim.app',
    );
  }

  static BranchConfig forBranch(String branchId, [String? branchName, String? city]) {
    if (branchId == 'vienna') return viennaConfig;
    if (branchId == 'kyiv') return kyivConfig;
    if (_customConfigs.containsKey(branchId)) return _customConfigs[branchId]!;
    final created = createDefault(
      branchId: branchId,
      branchName: branchName ?? branchId,
      city: city ?? '',
    );
    _customConfigs[branchId] = created;
    return created;
  }

  static String localizePoolName(String rawName, String langCode) {
    final code = langCode.trim().toLowerCase();
    final trimmed = rawName.trim();
    if (trimmed == 'Головний басейн 25м') {
      switch (code) {
        case 'en':
          return 'Main Pool 25m';
        case 'de':
          return 'Hauptbecken 25m';
        case 'ru':
          return 'Главный бассейн 25м';
        default:
          return 'Головний басейн 25м';
      }
    }
    if (trimmed == 'Дитячий теплий басейн') {
      switch (code) {
        case 'en':
          return 'Warm Kids Pool';
        case 'de':
          return 'Warmes Kinderbecken';
        case 'ru':
          return 'Детский теплый бассейн';
        default:
          return 'Дитячий теплий басейн';
      }
    }
    if (trimmed == 'Sports Pool') {
      switch (code) {
        case 'uk':
          return 'Спортивний басейн (Sports Pool)';
        case 'de':
          return 'Sportbecken (Sports Pool)';
        case 'ru':
          return 'Спортивный бассейн (Sports Pool)';
        default:
          return 'Sports Pool';
      }
    }
    if (trimmed == 'Wellenbecken') {
      switch (code) {
        case 'uk':
          return 'Хвильовий басейн (Wellenbecken)';
        case 'en':
          return 'Wave Pool (Wellenbecken)';
        case 'ru':
          return 'Волновой бассейн (Wellenbecken)';
        default:
          return 'Wellenbecken';
      }
    }
    return rawName;
  }

  static String localizeLaneName(String rawLane, String langCode) {
    final code = langCode.trim().toLowerCase();
    final trimmed = rawLane.trim();

    final laneMatchUk = RegExp(r'^Доріжка\s+(\d+)$', caseSensitive: false).firstMatch(trimmed);
    final laneMatchEn = RegExp(r'^Lane\s+(\d+)$', caseSensitive: false).firstMatch(trimmed);
    final laneMatchDe = RegExp(r'^Bahn\s+(\d+)$', caseSensitive: false).firstMatch(trimmed);
    final laneMatchRu = RegExp(r'^Дорожка\s+(\d+)$', caseSensitive: false).firstMatch(trimmed);
    final numStr = laneMatchUk?.group(1) ??
        laneMatchEn?.group(1) ??
        laneMatchDe?.group(1) ??
        laneMatchRu?.group(1);

    if (numStr != null) {
      switch (code) {
        case 'en':
          return 'Lane $numStr';
        case 'de':
          return 'Bahn $numStr';
        case 'ru':
          return 'Дорожка $numStr';
        default:
          return 'Доріжка $numStr';
      }
    }

    if (trimmed == 'Зона А' || trimmed == 'Zone A') {
      switch (code) {
        case 'en':
        case 'de':
          return 'Zone A';
        default:
          return 'Зона А';
      }
    }
    if (trimmed == 'Зона Б' || trimmed == 'Zone B') {
      switch (code) {
        case 'en':
        case 'de':
          return 'Zone B';
        default:
          return 'Зона Б';
      }
    }

    final zoneMatch = RegExp(r'^(?:Zone|Зона)\s+(\d+)$', caseSensitive: false).firstMatch(trimmed);
    if (zoneMatch != null) {
      final zNum = zoneMatch.group(1)!;
      switch (code) {
        case 'en':
        case 'de':
          return 'Zone $zNum';
        default:
          return 'Зона $zNum';
      }
    }

    return rawLane;
  }

  static String localizeAddress(String rawAddress, String langCode) {
    final code = langCode.trim().toLowerCase();
    final trimmed = rawAddress.trim();
    if (trimmed == 'вул. Ділова, 10, Київ') {
      switch (code) {
        case 'en':
          return '10 Dilova St, Kyiv';
        case 'de':
          return 'Dilowa-Str. 10, Kiew';
        case 'ru':
          return 'ул. Деловая, 10, Киев';
        default:
          return 'вул. Ділова, 10, Київ';
      }
    }
    if (trimmed == 'Klobuckygasse 25, 3400 Klosterneuburg, Wien') {
      switch (code) {
        case 'uk':
          return 'Klobuckygasse 25, 3400 Klosterneuburg, Відень';
        case 'en':
          return 'Klobuckygasse 25, 3400 Klosterneuburg, Vienna';
        case 'ru':
          return 'Klobuckygasse 25, 3400 Klosterneuburg, Вена';
        default:
          return 'Klobuckygasse 25, 3400 Klosterneuburg, Wien';
      }
    }
    return rawAddress;
  }

  static String translatePoolOrLane(String raw, String langCode) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;
    if (trimmed.contains('•')) {
      final parts = trimmed.split('•').map((p) => translatePoolOrLane(p.trim(), langCode)).toList();
      return parts.join(' • ');
    }
    final byPool = localizePoolName(trimmed, langCode);
    if (byPool != trimmed) return byPool;
    return localizeLaneName(trimmed, langCode);
  }
}
