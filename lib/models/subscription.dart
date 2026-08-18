class Subscription {
  final String id;
  final String userId;
  final int totalClasses;
  final int remainingClasses;
  final bool isActive;

  const Subscription({
    required this.id,
    required this.userId,
    required this.totalClasses,
    required this.remainingClasses,
    required this.isActive,
  });

  Subscription copyWith({
    String? id,
    String? userId,
    int? totalClasses,
    int? remainingClasses,
    bool? isActive,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalClasses: totalClasses ?? this.totalClasses,
      remainingClasses: remainingClasses ?? this.remainingClasses,
      isActive: isActive ?? this.isActive,
    );
  }
}
