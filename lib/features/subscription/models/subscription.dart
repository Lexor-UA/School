import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String userId,
    required int totalClasses,
    required int remainingClasses,
    required bool isActive,
    String? serviceName,
    DateTime? expiryDate,
    String? ownerName,
    @Default('cityswim') String organizationId,
    @Default('kyiv') String branchId,
    @Default('UAH') String currency,
    @Default('₴') String currencySymbol,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(
        json['expiryDate'] is Timestamp
            ? {...json, 'expiryDate': (json['expiryDate'] as Timestamp).toDate().toIso8601String()}
            : json,
      );
}

extension SubscriptionAudienceX on Subscription {
  bool get isSplitSubscription {
    final s = (serviceName ?? '').toLowerCase();
    return s.contains('спліт') || s.contains('split') || s.contains('сім');
  }

  bool get isAdultOnlySubscription {
    if (isSplitSubscription) return false;
    final s = (serviceName ?? '').toLowerCase();
    return s.contains('доросл') ||
        s.contains('adult') ||
        s.contains('аква');
  }

  bool get isAdultSubscription => isAdultOnlySubscription;

  bool get isChildOnlySubscription {
    if (isSplitSubscription) return false;
    final s = (serviceName ?? '').toLowerCase();
    return s.contains('діт') ||
        s.contains('дит') ||
        s.contains('junior') ||
        s.contains('kids') ||
        s.contains('child') ||
        s.contains('підлітк') ||
        s.contains('юніор');
  }

  bool get isChildSubscription {
    if (isSplitSubscription) return false;
    return !isAdultSubscription;
  }

  bool get isIndividualSubscription {
    final s = (serviceName ?? '').toLowerCase();
    return s.contains('індивідуал') || s.contains('персон') || s.contains('individual');
  }

  bool get isGroupSubscription => !isIndividualSubscription && !isSplitSubscription && !isAdultSubscription;

  (int, int)? get ageRange {
    final s = serviceName ?? '';
    final match = RegExp(r'(\d+)\s*[-–]\s*(\d+)', caseSensitive: false).firstMatch(s);
    if (match != null) {
      final min = int.tryParse(match.group(1)!);
      final max = int.tryParse(match.group(2)!);
      if (min != null && max != null) {
        return (min, max);
      }
    }
    return null;
  }

  bool isAgeCompatible(int? age) {
    if (age == null) return true;
    // До 5 років включно — тільки персональні індивідуальні абонементи для дітей
    if (age <= 5) {
      return isIndividualSubscription && isChildSubscription;
    }
    // Від 6 років — індивідуальні, групові або спліт відповідно до вікових груп
    final range = ageRange;
    if (range == null) return true;
    return age >= range.$1 && age <= range.$2;
  }
}
