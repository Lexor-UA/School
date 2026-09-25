class SubscriptionDiscount {
  final String id;
  final String serviceName; // Назва абонемента або 'all' (будь-який абонемент)
  final String targetMember; // Ім'я члена сім'ї / дитини або 'all' (всі члени сім'ї)
  final String discountType; // 'fixedPrice' або 'percent'
  final int originalPrice;
  final int discountedPrice; // Підсумкова акційна ціна в грн
  final int discountPercent; // Відсоток знижки
  final DateTime createdAt;

  const SubscriptionDiscount({
    required this.id,
    required this.serviceName,
    required this.targetMember,
    required this.discountType,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'serviceName': serviceName,
    'targetMember': targetMember,
    'discountType': discountType,
    'originalPrice': originalPrice,
    'discountedPrice': discountedPrice,
    'discountPercent': discountPercent,
    'createdAt': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toMap() => toJson();

  factory SubscriptionDiscount.fromJson(Map<String, dynamic> json) {
    return SubscriptionDiscount(
      id: json['id'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? 'all',
      targetMember: json['targetMember'] as String? ?? 'all',
      discountType: json['discountType'] as String? ?? 'fixedPrice',
      originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 0,
      discountedPrice: (json['discountedPrice'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  factory SubscriptionDiscount.fromMap(Map<String, dynamic> map) => SubscriptionDiscount.fromJson(map);

  /// Перевіряє, чи підходить ця знижка під конкретний абонемент та члена сім'ї
  bool matches({required String service, required String owner}) {
    final matchesMember = targetMember == 'all' ||
        targetMember.trim().toLowerCase() == owner.trim().toLowerCase();
    final matchesService = serviceName == 'all' ||
        serviceName.trim().toLowerCase() == service.trim().toLowerCase();
    return matchesMember && matchesService;
  }

  /// Обчислює фінальну вартість з урахуванням знижки
  int calculatePrice(int basePrice) {
    if (discountType == 'fixedPrice') {
      if (discountedPrice > 0 && discountedPrice < basePrice) {
        return discountedPrice;
      }
      return basePrice;
    } else {
      if (discountPercent > 0 && discountPercent <= 100) {
        final calculated = (basePrice * (100 - discountPercent) / 100).round();
        return calculated > 0 ? calculated : 0;
      }
      return basePrice;
    }
  }

  /// Знаходить найкращу знижку для абонемента серед списку знижок клієнта
  static SubscriptionDiscount? findBestDiscount(
    List<SubscriptionDiscount> discounts, {
    required String service,
    required String owner,
    required int basePrice,
  }) {
    SubscriptionDiscount? best;
    int minPrice = basePrice;

    for (final d in discounts) {
      if (d.matches(service: service, owner: owner)) {
        final price = d.calculatePrice(basePrice);
        if (price < minPrice) {
          minPrice = price;
          best = d;
        }
      }
    }
    return best;
  }
}
