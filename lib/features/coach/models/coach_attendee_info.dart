class CoachAttendeeInfo {
  final String id;
  final String name;
  final String? parentName;
  final int? age;
  final String? phone;
  final int remainingClasses;
  final int totalClasses;
  final int bookedClassesCount;
  final bool isExpired;
  final bool isExhausted;
  final DateTime? expiryDate;
  final String? subscriptionTitle;
  final bool isPresent;
  final bool isChild;

  const CoachAttendeeInfo({
    required this.id,
    required this.name,
    this.parentName,
    this.age,
    this.phone,
    this.remainingClasses = 0,
    this.totalClasses = 0,
    this.bookedClassesCount = 0,
    this.isExpired = false,
    this.isExhausted = false,
    this.expiryDate,
    this.subscriptionTitle,
    this.isPresent = false,
    this.isChild = true,
  });

  CoachAttendeeInfo copyWith({
    String? id,
    String? name,
    String? parentName,
    int? age,
    String? phone,
    int? remainingClasses,
    int? totalClasses,
    int? bookedClassesCount,
    bool? isExpired,
    bool? isExhausted,
    DateTime? expiryDate,
    String? subscriptionTitle,
    bool? isPresent,
    bool? isChild,
  }) {
    return CoachAttendeeInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      parentName: parentName ?? this.parentName,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      remainingClasses: remainingClasses ?? this.remainingClasses,
      totalClasses: totalClasses ?? this.totalClasses,
      bookedClassesCount: bookedClassesCount ?? this.bookedClassesCount,
      isExpired: isExpired ?? this.isExpired,
      isExhausted: isExhausted ?? this.isExhausted,
      expiryDate: expiryDate ?? this.expiryDate,
      subscriptionTitle: subscriptionTitle ?? this.subscriptionTitle,
      isPresent: isPresent ?? this.isPresent,
      isChild: isChild ?? this.isChild,
    );
  }
}
