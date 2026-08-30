import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

part 'subscription_controller.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionController extends _$SubscriptionController {
  @override
  List<Subscription> build() {
    _listenToSubscriptions();
    return [];
  }

  void _listenToSubscriptions() {
    FirebaseFirestore.instance.collection('subscriptions').snapshots().listen((snapshot) {
      final subs = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Subscription.fromJson(data);
      }).toList();
      state = subs;
    });
  }

  Subscription? getSubscriptionForUser(String userId) {
    try {
      return state.firstWhere((sub) => sub.userId == userId && sub.isActive);
    } catch (e) {
      return null;
    }
  }

  Subscription? getSubscriptionForOwner(String userId, String ownerName) {
    try {
      return state.firstWhere((sub) => sub.userId == userId && sub.ownerName == ownerName && sub.isActive);
    } catch (e) {
      return null;
    }
  }

  Subscription? getAnySubscriptionForOwner(String userId, String ownerName) {
    try {
      return state.firstWhere((sub) => sub.userId == userId && sub.ownerName == ownerName);
    } catch (e) {
      return null;
    }
  }

  List<Subscription> getSubscriptionsForUser(String userId) {
    return state.where((sub) => sub.userId == userId).toList();
  }

  Future<bool> deductClass(String userId) async {
    final subIndex = state.indexWhere((sub) => sub.userId == userId);
    if (subIndex == -1) return false;

    final sub = state[subIndex];
    if (sub.remainingClasses > 0 && sub.isActive) {
      final newRemaining = sub.remainingClasses - 1;
      final newIsActive = newRemaining > 0;
      
      try {
        await FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).update({
          'remainingClasses': newRemaining,
          'isActive': newIsActive,
        });
        return true;
      } catch (e) {
        debugPrint('Error deducting class: $e');
        return false;
      }
    }
    return false;
  }
}
