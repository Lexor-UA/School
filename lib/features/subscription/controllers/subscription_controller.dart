import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';

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
      final List<Subscription> subs = [];
      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['id'] = doc.id;
          if (data['expiryDate'] is Timestamp) {
            data['expiryDate'] = (data['expiryDate'] as Timestamp).toDate().toIso8601String();
          }
          subs.add(Subscription.fromJson(data));
        } catch (e) {
          debugPrint('Warning: Failed to parse subscription ${doc.id}: $e');
        }
      }
      
      _checkExpirations(subs);
      state = subs;
    });
  }

  void _checkExpirations(List<Subscription> subs) {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final isAdminOrOwner = user.role == UserRole.admin || user.role == UserRole.owner;
    final family = ref.read(familyStreamProvider).value;
    final relevantUserIds = <String>{
      user.id,
      if (family != null) ...family.parentIds,
    };

    final now = DateTime.now();
    for (final sub in subs) {
      if (!isAdminOrOwner && !relevantUserIds.contains(sub.userId)) {
        continue; // Skip checking/updating other clients' subscriptions
      }

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

  List<String> _resolveFamilyUserIds(String userId, List<String>? familyUserIds) {
    if (familyUserIds != null && familyUserIds.isNotEmpty) return familyUserIds;
    try {
      final family = ref.read(familyStreamProvider).value;
      if (family != null && family.parentIds.isNotEmpty) {
        return family.parentIds;
      }
    } catch (_) {}
    return [userId];
  }

  bool hasActiveSubscriptionForOwner(String userId, String ownerName, {List<String>? familyUserIds}) {
    final now = DateTime.now();
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);

    return state.any((sub) {
      final matchesOwner = (sub.ownerName ?? '').trim().toLowerCase() == ownerName.trim().toLowerCase();
      final isSubActive = sub.isActive && sub.remainingClasses > 0 && (sub.expiryDate == null || sub.expiryDate!.isAfter(now));
      if (!isSubActive) return false;

      final isCompatibleUser = !sub.isAdultSubscription
          ? effectiveFamilyIds.contains(sub.userId)
          : sub.userId == userId;

      return isCompatibleUser && matchesOwner;
    });
  }

  Subscription? getActiveSubscriptionForOwner(String userId, String ownerName, {List<String>? familyUserIds}) {
    final now = DateTime.now();
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);

    try {
      return state.firstWhere((sub) {
        final matchesOwner = (sub.ownerName ?? '').trim().toLowerCase() == ownerName.trim().toLowerCase();
        final isSubActive = sub.isActive && sub.remainingClasses > 0 && (sub.expiryDate == null || sub.expiryDate!.isAfter(now));
        if (!isSubActive) return false;

        final isCompatibleUser = !sub.isAdultSubscription
            ? effectiveFamilyIds.contains(sub.userId)
            : sub.userId == userId;

        return isCompatibleUser && matchesOwner;
      });
    } catch (_) {
      return null;
    }
  }

  Subscription? getSubscriptionForOwner(String userId, String ownerName, {bool? isAdult, List<String>? familyUserIds}) {
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);

    final userSubs = state.where((sub) {
      if (!sub.isActive || sub.remainingClasses <= 0) return false;
      if (sub.isAdultSubscription) {
        return sub.userId == userId;
      } else {
        return effectiveFamilyIds.contains(sub.userId);
      }
    }).toList();

    if (userSubs.isEmpty) return null;

    final cleanOwner = ownerName.trim().toLowerCase();

    // 1. Direct owner match
    try {
      final directMatch = userSubs.firstWhere((sub) => (sub.ownerName ?? '').trim().toLowerCase() == cleanOwner);
      if (isAdult != null) {
        if (isAdult && directMatch.isChildSubscription && !directMatch.isSplitSubscription) {
          // Incompatible: adult cannot use child subscription
        } else if (!isAdult && directMatch.isAdultSubscription && !directMatch.isSplitSubscription) {
          // Incompatible: child cannot use adult subscription
        } else {
          return directMatch;
        }
      } else {
        return directMatch;
      }
    } catch (_) {}

    // 2. Split or family subscription matching (allowed for everyone)
    try {
      return userSubs.firstWhere((sub) {
        final sName = sub.serviceName?.toLowerCase() ?? '';
        final isSplit = sub.isSplitSubscription || sName.contains('спліт') || sName.contains('сім') || sName.contains('split');
        final isGenericOwner = sub.ownerName == null || sub.ownerName!.isEmpty || sub.ownerName == 'Всі';
        return isSplit || isGenericOwner;
      });
    } catch (_) {}

    // 3. If isAdult is specified, try to find compatible unassigned/generic subscription
    if (isAdult != null) {
      try {
        return userSubs.firstWhere((sub) {
          final isEligible = isAdult ? sub.isAdultSubscription : sub.isChildSubscription;
          final isGeneric = sub.ownerName == null || sub.ownerName!.isEmpty || sub.ownerName == 'Всі';
          return isEligible && isGeneric;
        });
      } catch (_) {}
    }

    return null;
  }

  Subscription? getAnySubscriptionForOwner(String userId, String ownerName, {List<String>? familyUserIds}) {
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);

    final userSubs = state.where((sub) {
      if (sub.isAdultSubscription) {
        return sub.userId == userId;
      } else {
        return effectiveFamilyIds.contains(sub.userId);
      }
    }).toList();

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

  List<Subscription> getSubscriptionsForUser(String userId, {List<String>? familyUserIds}) {
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);

    return state.where((sub) {
      if (sub.isAdultSubscription) {
        return sub.userId == userId;
      } else {
        return effectiveFamilyIds.contains(sub.userId);
      }
    }).toList();
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
