enum QrCheckInStatus {
  success,
  alreadyAttended,
  wrongDate,
  wrongService,
  expiredOrEmpty,
  notFound,
}

class QrCheckInResult {
  final QrCheckInStatus status;
  final String message;
  final String? studentName;
  final String? serviceName;
  final String? subServiceName;
  final String? classTitle;
  final int? remainingClasses;
  final String? subId;

  const QrCheckInResult({
    required this.status,
    required this.message,
    this.studentName,
    this.serviceName,
    this.subServiceName,
    this.classTitle,
    this.remainingClasses,
    this.subId,
  });

  String? get effectiveServiceName => subServiceName ?? serviceName;
  bool get isSuccess => status == QrCheckInStatus.success;
  bool get isAlreadyAttended => status == QrCheckInStatus.alreadyAttended;
}
