import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_class.freezed.dart';
part 'group_class.g.dart';

@freezed
abstract class GroupClass with _$GroupClass {
  const factory GroupClass({
    required String id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String coachId,
    required String coachName,
    required int maxCapacity,
    @Default([]) List<String> enrolledChildIds,
    @Default([]) List<String> attendedChildIds,
    required String category, // 'Плавання', 'Стрибки' etc.
    @Default('') String lane, // 'Доріжка 3' etc.
  }) = _GroupClass;

  factory GroupClass.fromJson(Map<String, dynamic> json) => _$GroupClassFromJson(json);
}
