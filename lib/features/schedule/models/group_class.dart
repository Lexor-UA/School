import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/tenancy/utils/branch_timezone_helper.dart';

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
    @Default('cityswim') String organizationId,
    @Default('kyiv') String branchId,
    @Default('Europe/Kyiv') String timezone,
    @Default('kyiv_main') String locationId,
    @Default('pool_25m') String poolId,
  }) = _GroupClass;

  factory GroupClass.fromJson(Map<String, dynamic> json) => _$GroupClassFromJson(
        _normalizeJson(json),
      );

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['id'] = copy['id']?.toString() ?? '';
    copy['title'] = (copy['title'] != null && copy['title'].toString().trim().isNotEmpty)
        ? copy['title'].toString()
        : (copy['category']?.toString() ?? 'Тренування');
    copy['coachId'] = copy['coachId']?.toString() ?? '';
    copy['coachName'] = (copy['coachName'] != null && copy['coachName'].toString().trim().isNotEmpty)
        ? copy['coachName'].toString()
        : 'Тренер';
    copy['category'] = (copy['category'] != null && copy['category'].toString().trim().isNotEmpty)
        ? copy['category'].toString()
        : 'Плавання';
    copy['maxCapacity'] = (copy['maxCapacity'] is num)
        ? (copy['maxCapacity'] as num).toInt()
        : (int.tryParse(copy['maxCapacity']?.toString() ?? '') ?? 8);

    if (copy['startTime'] is Timestamp) {
      copy['startTime'] = (copy['startTime'] as Timestamp).toDate().toIso8601String();
    } else if (copy['startTime'] is DateTime) {
      copy['startTime'] = (copy['startTime'] as DateTime).toIso8601String();
    } else if (copy['startTime'] == null || copy['startTime'].toString().trim().isEmpty) {
      copy['startTime'] = DateTime.now().toIso8601String();
    }

    if (copy['endTime'] is Timestamp) {
      copy['endTime'] = (copy['endTime'] as Timestamp).toDate().toIso8601String();
    } else if (copy['endTime'] is DateTime) {
      copy['endTime'] = (copy['endTime'] as DateTime).toIso8601String();
    } else if (copy['endTime'] == null || copy['endTime'].toString().trim().isEmpty) {
      copy['endTime'] = DateTime.now().add(const Duration(minutes: 45)).toIso8601String();
    }

    if (copy['enrolledChildIds'] is List) {
      copy['enrolledChildIds'] = (copy['enrolledChildIds'] as List)
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    } else {
      copy['enrolledChildIds'] = const <String>[];
    }

    if (copy['attendedChildIds'] is List) {
      copy['attendedChildIds'] = (copy['attendedChildIds'] as List)
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    } else {
      copy['attendedChildIds'] = const <String>[];
    }

    return copy;
  }
}

extension GroupClassAudienceX on GroupClass {
  bool get isSplit {
    final t = title.toLowerCase();
    return t.contains('спліт') || t.contains('split');
  }

  bool get isChildOnly {
    if (isSplit || isAdultOnly) return false;
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
    // З 16 років — дорослий! Заборонено запис у дитячі групи (потрібен окремий дорослий акаунт)
    if (age >= 16 && isChildOnly) {
      return false;
    }
    // Для дорослих занять — вік від 16 років
    if (age < 16 && isAdultOnly) {
      return false;
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
  final isChild = lower.contains('діт') || lower.contains('дит') || lower.contains('junior') || lower.contains('kids') || lower.contains('підлітк');

  // До 5 років включно — дозволені лише персональні індивідуальні заняття/абонементи для дітей
  if (age <= 5) {
    return isIndividual && !isSplit && !isAdult;
  }
  // З 16 років — дорослий
  if (age >= 16 && isChild) {
    return false;
  }
  if (age < 16 && isAdult) {
    return false;
  }

  // Від 6 років
  final range = parseAgeRange(title);
  if (range == null) return true;
  return age >= range.$1 && age <= range.$2;
}

extension GroupClassTimezoneX on GroupClass {
  /// Місцевий час початку тренування за часовим поясом філії
  DateTime get branchStartTime =>
      BranchTimezoneHelper.toBranchLocalTime(startTime, timezone.isNotEmpty ? timezone : branchId);

  /// Місцевий час завершення тренування за часовим поясом філії
  DateTime get branchEndTime =>
      BranchTimezoneHelper.toBranchLocalTime(endTime, timezone.isNotEmpty ? timezone : branchId);

  /// Форматований час початку тренування у часовому поясі філії (HH:mm)
  String formatBranchTime({String pattern = 'HH:mm'}) {
    return BranchTimezoneHelper.formatTime(startTime,
        branchId: timezone.isNotEmpty ? timezone : branchId, pattern: pattern);
  }

  /// Форматована дата тренування у часовому поясі філії (dd.MM.yyyy)
  String formatBranchDate({String pattern = 'dd.MM.yyyy'}) {
    return BranchTimezoneHelper.formatDate(startTime,
        branchId: timezone.isNotEmpty ? timezone : branchId, pattern: pattern);
  }

  /// Форматований інтервал часу тренування у часовому поясі філії (HH:mm - HH:mm)
  String formatBranchTimeRange({String pattern = 'HH:mm'}) {
    final start = BranchTimezoneHelper.formatTime(startTime,
        branchId: timezone.isNotEmpty ? timezone : branchId, pattern: pattern);
    final end = BranchTimezoneHelper.formatTime(endTime,
        branchId: timezone.isNotEmpty ? timezone : branchId, pattern: pattern);
    return '$start - $end';
  }
}

