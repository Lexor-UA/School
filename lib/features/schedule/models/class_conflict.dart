import 'package:swimming_school_app/features/schedule/models/group_class.dart';

enum ClassConflictType {
  laneConflict,
  coachConflict,
  participantConflict,
  subscriptionExpired,
}

class ClassConflict {
  final ClassConflictType type;
  final GroupClass? conflictingClass;
  final String message;

  const ClassConflict({
    required this.type,
    this.conflictingClass,
    required this.message,
  });
}

class CreateRecurringClassesResult {
  final int createdCount;
  final List<DateTime> skippedDates;
  final List<ClassConflict> conflicts;

  const CreateRecurringClassesResult({
    required this.createdCount,
    this.skippedDates = const [],
    this.conflicts = const [],
  });

  bool get hasSkipped => skippedDates.isNotEmpty;
}
