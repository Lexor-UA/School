import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory GroupClass.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    if (copy['startTime'] is Timestamp) {
      copy['startTime'] = (copy['startTime'] as Timestamp).toDate().toIso8601String();
    }
    if (copy['endTime'] is Timestamp) {
      copy['endTime'] = (copy['endTime'] as Timestamp).toDate().toIso8601String();
    }
    return _$GroupClassFromJson(copy);
  }
}

extension GroupClassAudienceX on GroupClass {
  bool get isSplit {
    final t = title.toLowerCase();
    return t.contains('спліт') || t.contains('split');
  }

  bool get isChildOnly {
    if (isSplit) return false;
    final t = title.toLowerCase();
    final c = category.toLowerCase();
    return t.contains('діт') ||
        t.contains('дит') ||
        t.contains('junior') ||
        t.contains('kids') ||
        t.contains('child') ||
        t.contains('підлітк') ||
        t.contains('юніор') ||
        c.contains('діт') ||
        c.contains('дит') ||
        c.contains('junior');
  }

  bool get isAdultOnly {
    if (isSplit) return false;
    final t = title.toLowerCase();
    final c = category.toLowerCase();
    return t.contains('доросл') ||
        t.contains('adult') ||
        t.contains('аква') ||
        c.contains('доросл') ||
        c.contains('adult') ||
        c.contains('аква');
  }

  bool get isIndividual {
    if (isSplit) return false;
    final t = title.toLowerCase();
    final c = category.toLowerCase();
    return t.contains('індивідуал') ||
        t.contains('individual') ||
        t.contains('персон') ||
        c.contains('індивідуал') ||
        maxCapacity <= 1;
  }

  bool get isGroup => !isSplit && !isIndividual;

  bool get isUniversal => !isChildOnly && !isAdultOnly;

  (int, int)? get ageRange => parseAgeRange(title) ?? parseAgeRange(category);

  bool isAgeCompatible(int? age) {
    if (age == null) return true;
    // До 5 років включно — тільки персональні індивідуальні заняття для дітей.
    // Групові, спліт та дорослі заняття заборонені.
    if (age <= 5) {
      return isIndividual && isChildOnly;
    }
    // Від 6 років дозволено індивідуально, в групах та спліт (за діапазоном віку)
    final range = ageRange;
    if (range == null) return true;
    return age >= range.$1 && age <= range.$2;
  }
}

(int, int)? parseAgeRange(String text) {
  final match = RegExp(r'(\d+)\s*[-–]\s*(\d+)', caseSensitive: false).firstMatch(text);
  if (match != null) {
    final min = int.tryParse(match.group(1)!);
    final max = int.tryParse(match.group(2)!);
    if (min != null && max != null) {
      return (min, max);
    }
  }
  return null;
}

bool isServiceAgeCompatible(String title, int? age) {
  if (age == null) return true;
  final lower = title.toLowerCase();
  final isIndividual = lower.contains('індивідуал') || lower.contains('персон') || lower.contains('individual');
  final isSplit = lower.contains('спліт') || lower.contains('split');
  final isAdult = lower.contains('доросла') || lower.contains('дорослих') || lower.contains('adult');

  // До 5 років включно — дозволені лише персональні індивідуальні заняття/абонементи для дітей
  if (age <= 5) {
    return isIndividual && !isSplit && !isAdult;
  }

  // Від 6 років
  final range = parseAgeRange(title);
  if (range == null) return true;
  return age >= range.$1 && age <= range.$2;
}
