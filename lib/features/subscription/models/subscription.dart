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
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    if (copy['expiryDate'] is Timestamp) {
      copy['expiryDate'] = (copy['expiryDate'] as Timestamp).toDate().toIso8601String();
    }
    return _$SubscriptionFromJson(copy);
  }
}

extension SubscriptionAudienceX on Subscription {
  bool get isSplitSubscription {
    final s = (serviceName ?? '').toLowerCase();
    return s.contains('спліт') || s.contains('split') || s.contains('сім');
  }

  bool get isAdultSubscription {
    if (isSplitSubscription) return false;
    final s = (serviceName ?? '').toLowerCase();
    return s.contains('доросла') || s.contains('дорослих') || s.contains('adult');
  }

  bool get isChildSubscription {
    if (isSplitSubscription) return false;
    return !isAdultSubscription;
  }
}
