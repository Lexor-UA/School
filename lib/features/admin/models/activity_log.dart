import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_log.freezed.dart';
part 'activity_log.g.dart';

@freezed
abstract class ActivityLog with _$ActivityLog {
  const factory ActivityLog({
    required String id,
    required String action,
    required DateTime timestamp,
    required String adminId,
  }) = _ActivityLog;

  factory ActivityLog.fromJson(Map<String, dynamic> json) => _$ActivityLogFromJson(json);
}
