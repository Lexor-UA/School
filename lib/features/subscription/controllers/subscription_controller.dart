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
      
      _checkExpirations(subs);
      state = subs;
    });
  }

  void _checkExpirations(List<Subscription> subs) {
    final now = DateTime.now();
    for (final sub in subs) {
      if (sub.isActive && sub.expiryDate != null) {
        if (now.isAfter(sub.expiryDate!)) {
          // Auto deactivate expired subscription
          FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).update({
            'isActive': false,
          }).catchError((e) {
            debugPrint('Failed to auto-deactivate subscription ${sub.id}: $e');
          });
        }
      }

      // Auto-heal overflowed subscriptions (e.g. 13 of 12) back to totalClasses
      if (sub.totalClasses > 0 && sub.remainingClasses > sub.totalClasses) {
        FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).update({
          'remainingClasses': sub.totalClasses,
        }).catchError((e) {
          debugPrint('Failed to auto-heal subscription ${sub.id}: $e');
        });
      }
    }
  }

  bool hasActiveSubscriptionForOwner(String userId, String ownerName) {
    final now = DateTime.now();
    return state.any((sub) =>
        sub.userId == userId &&
        (sub.ownerName ?? '').trim() == ownerName.trim() &&
        sub.isActive &&
        sub.remainingClasses > 0 &&
        (sub.expiryDate == null || sub.expiryDate!.isAfter(now)));
  }

  Subscription? getActiveSubscriptionForOwner(String userId, String ownerName) {
    final now = DateTime.now();
    try {
      return state.firstWhere((sub) =>
          sub.userId == userId &&
          (sub.ownerName ?? '').trim() == ownerName.trim() &&
          sub.isActive &&
          sub.remainingClasses > 0 &&
          (sub.expiryDate == null || sub.expiryDate!.isAfter(now)));
    } catch (_) {
      return null;
    }
  }

  Subscription? getSubscriptionForOwner(String userId, String ownerName) {
    final userSubs = state.where((sub) => sub.userId == userId && sub.isActive && sub.remainingClasses > 0).toList();
    if (userSubs.isEmpty) return null;

    final cleanOwner = ownerName.trim().toLowerCase();

    // 1. Direct owner match
    try {
      return userSubs.firstWhere((sub) => (sub.ownerName ?? '').trim().toLowerCase() == cleanOwner);
    } catch (_) {}

    // 2. Split or family subscription matching
    try {
      return userSubs.firstWhere((sub) {
        final sName = sub.serviceName?.toLowerCase() ?? '';
        final isSplit = sName.contains('спліт') || sName.contains('сім') || sName.contains('split');
        final isGenericOwner = sub.ownerName == null || sub.ownerName!.isEmpty || sub.ownerName == 'Всі';
        return isSplit || isGenericOwner;
      });
    } catch (_) {}

    // 3. If user has only 1 active subscription with remaining classes, use it as primary family sub
    if (userSubs.length == 1) {
      return userSubs.first;
    }

    // 4. Look for an unassigned / generic owner sub among multiple subscriptions
    try {
      return userSubs.firstWhere((sub) {
        return sub.ownerName == null || sub.ownerName!.isEmpty || sub.ownerName == 'Всі';
      });
    } catch (_) {}

    // 5. Fallback to any active user subscription (enables children to use parent's account sub)
    return userSubs.first;
  }

  Subscription? getAnySubscriptionForOwner(String userId, String ownerName) {
    final userSubs = state.where((sub) => sub.userId == userId).toList();
    if (userSubs.isEmpty) return null;

    final cleanOwner = ownerName.trim().toLowerCase();

    // 1. Exact owner match
    try {
      return userSubs.firstWhere((sub) => (sub.ownerName ?? '').trim().toLowerCase() == cleanOwner);
    } catch (_) {}

    // 2. Split or generic owner
    try {
      return userSubs.firstWhere((sub) {
        final sName = sub.serviceName?.toLowerCase() ?? '';
        return sName.contains('спліт') || sName.contains('сім') || sub.ownerName == null || sub.ownerName!.isEmpty || sub.ownerName == 'Всі';
      });
    } catch (_) {}

    // 3. Fallback to any user sub
    return userSubs.first;
  }

  List<Subscription> getSubscriptionsForUser(String userId) {
    return state.where((sub) => sub.userId == userId).toList();
  }

  Future<bool> deductClass(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return false;

    // 1. Direct search by userId or sub.id
    int subIndex = state.indexWhere((sub) =>
        (sub.userId == cleanCode || sub.id == cleanCode) && sub.isActive && sub.remainingClasses > 0);

    // 2. Fallback smart lookup by loginId, phone, or child ID
    if (subIndex == -1) {
      try {
        final usersByLogin = await FirebaseFirestore.instance
            .collection('users')
            .where('loginId', isEqualTo: cleanCode)
            .limit(1)
            .get();

        String? resolvedUserId;
        if (usersByLogin.docs.isNotEmpty) {
          resolvedUserId = usersByLogin.docs.first.id;
        } else {
          final usersByPhone = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: cleanCode)
              .limit(1)
              .get();
          if (usersByPhone.docs.isNotEmpty) {
            resolvedUserId = usersByPhone.docs.first.id;
          } else {
            final childDoc = await FirebaseFirestore.instance
                .collection('children')
                .doc(cleanCode)
                .get();
            if (childDoc.exists) {
              resolvedUserId = childDoc.data()?['parentId'] as String?;
            }
          }
        }

        if (resolvedUserId != null) {
          subIndex = state.indexWhere((sub) =>
              sub.userId == resolvedUserId && sub.isActive && sub.remainingClasses > 0);
        }
      } catch (e) {
        debugPrint('Error looking up client in deductClass: $e');
      }
    }

    if (subIndex == -1) return false;

    final sub = state[subIndex];
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
}
