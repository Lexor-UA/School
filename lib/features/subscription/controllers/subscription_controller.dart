import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/coach/models/qr_check_in_result.dart';
import 'package:swimming_school_app/features/tenancy/services/branch_data_integrity_validator.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

part 'subscription_controller.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionController extends _$SubscriptionController {
  StreamSubscription<QuerySnapshot>? _subSubscription;
  final Set<String> _attemptedSubIds = {};

  @override
  List<Subscription> build() {
    final user = ref.watch(authControllerProvider);
    final isParent = user?.role == UserRole.parent;
    final activeBranchId = isParent ? null : ref.watch(activeBranchProvider)?.id;
    final isAllLocations = isParent ? false : ref.watch(isAllLocationsSelectedProvider);
    final family = isParent ? ref.watch(familyStreamProvider).value : null;

    ref.onDispose(() {
      _subSubscription?.cancel();
      _subSubscription = null;
    });

    _listenToSubscriptions(
      user: user,
      isParent: isParent,
      activeBranchId: activeBranchId,
      isAllLocations: isAllLocations,
      family: family,
    );
    try {
      return state;
    } catch (_) {
      return const <Subscription>[];
    }
  }

  void _listenToSubscriptions({
    required AppUser? user,
    required bool isParent,
    required String? activeBranchId,
    required bool isAllLocations,
    required Family? family,
  }) {
    _subSubscription?.cancel();

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('subscriptions');

    if (user != null) {
      if (isParent) {
        final relevantUserIds = <String>[
          user.id,
          if (family != null) ...family.parentIds,
        ];
        if (relevantUserIds.length == 1) {
          query = query.where('userId', isEqualTo: relevantUserIds.first);
        } else if (relevantUserIds.length > 1) {
          query = query.where('userId', whereIn: relevantUserIds);
        }
      } else if (!isAllLocations && activeBranchId != null) {
        query = query.where('branchId', isEqualTo: activeBranchId);
      }
    }

    _subSubscription = query.snapshots().listen((snapshot) {
      final List<Subscription> subs = [];
      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          if (data['expiryDate'] is Timestamp) {
            data['expiryDate'] = (data['expiryDate'] as Timestamp).toDate().toIso8601String();
          }
          subs.add(Subscription.fromJson(data));
        } catch (e) {
          debugPrint('Warning: Failed to parse subscription ${doc.id}: $e');
        }
      }
      
      Future.microtask(() {
        _checkExpirations(subs);
        state = subs;
      });
    }, onError: (e) {
      debugPrint('Error listening to subscriptions: $e');
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

      // Auto-extend single-class subscriptions to 1 year if they were created with short 1-2 days validity
      if (sub.isActive && sub.totalClasses == 1 && sub.expiryDate != null && !_attemptedSubIds.contains(sub.id)) {
        final daysUntilExpiry = sub.expiryDate!.difference(now).inDays;
        if (daysUntilExpiry < 30) {
          _attemptedSubIds.add(sub.id);
          final oneYearFromNow = now.add(const Duration(days: 365));
          FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).update({
            'expiryDate': Timestamp.fromDate(oneYearFromNow),
          }).catchError((e) {
            debugPrint('Failed to extend single pass subscription ${sub.id}: $e');
          });
        }
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
    final cleanOwner = ownerName.replaceAll(RegExp(r'\s*\([я|i|me]\)', caseSensitive: false), '').trim().toLowerCase();

    return state.any((sub) {
      final subOwner = (sub.ownerName ?? '').replaceAll(RegExp(r'\s*\([я|i|me]\)', caseSensitive: false), '').trim().toLowerCase();
      final matchesOwner = subOwner == cleanOwner || (subOwner.isEmpty && sub.userId == userId);
      final isSubActive = sub.isActive && sub.remainingClasses > 0 && (sub.expiryDate == null || sub.expiryDate!.isAfter(now));
      if (!isSubActive) return false;

      final isCompatibleUser = effectiveFamilyIds.contains(sub.userId);

      return isCompatibleUser && matchesOwner;
    });
  }

  Subscription? getActiveSubscriptionForOwner(String userId, String ownerName, {bool isSplit = false, List<String>? familyUserIds}) {
    final now = DateTime.now();
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);
    final cleanOwner = ownerName.replaceAll(RegExp(r'\s*\([я|i|me]\)', caseSensitive: false), '').trim().toLowerCase();

    try {
      return state.firstWhere((sub) {
        if (isSplit && !sub.isSplitSubscription) return false;
        if (!isSplit && sub.isSplitSubscription) return false;

        final subOwner = (sub.ownerName ?? '').replaceAll(RegExp(r'\s*\([я|i|me]\)', caseSensitive: false), '').trim().toLowerCase();
        final matchesOwner = subOwner == cleanOwner || (subOwner.isEmpty && sub.userId == userId);
        final isSubActive = sub.isActive && sub.remainingClasses > 0 && (sub.expiryDate == null || sub.expiryDate!.isAfter(now));
        if (!isSubActive) return false;

        final isCompatibleUser = effectiveFamilyIds.contains(sub.userId);

        return isCompatibleUser && matchesOwner;
      });
    } catch (_) {
      return null;
    }
  }

  Subscription? getSubscriptionForOwner(String userId, String ownerName, {bool? isAdult, bool isSplit = false, List<String>? familyUserIds}) {
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);

    final userSubs = state.where((sub) {
      if (!sub.isActive || sub.remainingClasses <= 0) return false;
      if (isSplit && !sub.isSplitSubscription) return false;
      if (!isSplit && sub.isSplitSubscription) return false;

      return effectiveFamilyIds.contains(sub.userId);
    }).toList();

    if (userSubs.isEmpty) return null;

    final cleanOwner = ownerName.replaceAll(RegExp(r'\s*\([я|i|me]\)', caseSensitive: false), '').trim().toLowerCase();

    // 1. Direct owner match
    try {
      final directMatch = userSubs.firstWhere((sub) {
        final subOwner = (sub.ownerName ?? '').replaceAll(RegExp(r'\s*\([я|i|me]\)', caseSensitive: false), '').trim().toLowerCase();
        return subOwner == cleanOwner || (subOwner.isEmpty && sub.userId == userId);
      });
      if (isAdult != null) {
        if (isAdult && directMatch.isChildOnlySubscription) {
          // Incompatible: adult cannot use strictly child-only subscription
        } else if (!isAdult && directMatch.isAdultOnlySubscription) {
          // Incompatible: child cannot use strictly adult-only subscription
        } else {
          return directMatch;
        }
      } else {
        return directMatch;
      }
    } catch (_) {}

    // 2. Generic owner matching
    if (isSplit) {
      try {
        return userSubs.firstWhere((sub) => sub.isSplitSubscription);
      } catch (_) {}
    } else {
      try {
        return userSubs.firstWhere((sub) {
          final isGenericOwner = sub.ownerName == null || sub.ownerName!.isEmpty || sub.ownerName == 'Всі';
          if (!isGenericOwner) return false;
          if (isAdult != null) {
            return isAdult ? !sub.isChildOnlySubscription : !sub.isAdultOnlySubscription;
          }
          return true;
        });
      } catch (_) {}
    }

    // 3. If isAdult is specified, try to find compatible unassigned/generic subscription
    if (!isSplit && isAdult != null) {
      try {
        return userSubs.firstWhere((sub) {
          final isEligible = isAdult ? !sub.isChildOnlySubscription : !sub.isAdultOnlySubscription;
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
      return effectiveFamilyIds.contains(sub.userId);
    }).toList();

    if (userSubs.isEmpty) return null;

    final cleanOwner = ownerName.replaceAll(RegExp(r'\s*\([я|i|me]\)', caseSensitive: false), '').trim().toLowerCase();

    // 1. Exact owner match
    try {
      return userSubs.firstWhere((sub) {
        final subOwner = (sub.ownerName ?? '').replaceAll(RegExp(r'\s*\([я|i|me]\)', caseSensitive: false), '').trim().toLowerCase();
        return subOwner == cleanOwner || (subOwner.isEmpty && sub.userId == userId);
      });
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
      return effectiveFamilyIds.contains(sub.userId);
    }).toList();
  }

  Future<bool> deductClass(String code, {String? targetBranchId}) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return false;

    // 1. Direct search by userId or sub.id
    int subIndex = state.indexWhere((sub) =>
        (sub.userId == cleanCode || sub.id == cleanCode) &&
        sub.isActive &&
        sub.remainingClasses > 0 &&
        (targetBranchId == null || sub.branchId == targetBranchId));

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
              sub.userId == resolvedUserId &&
              sub.isActive &&
              sub.remainingClasses > 0 &&
              (targetBranchId == null || sub.branchId == targetBranchId));
        }
      } catch (e) {
        debugPrint('Error looking up client in deductClass: $e');
      }
    }

    if (subIndex == -1) return false;

    final sub = state[subIndex];
    if (targetBranchId != null && sub.branchId != targetBranchId) {
      return false;
    }

    try {
      final success = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(sub.id);
        final subDoc = await transaction.get(subRef);
        
        if (!subDoc.exists) return false;
        
        final currentRemaining = subDoc.data()?['remainingClasses'] as int? ?? 0;
        if (currentRemaining <= 0) return false;
        
        final newRemaining = currentRemaining - 1;
        transaction.update(subRef, {
          'remainingClasses': newRemaining,
          'isActive': newRemaining > 0,
        });
        
        return true;
      });
      return success;
    } catch (e) {
      debugPrint('Error deducting class: $e');
      return false;
    }
  }

  Future<void> deleteSubscription(String subId) async {
    final cleanId = subId.trim();
    if (cleanId.isEmpty) return;

    // 1. Optimistic removal from in-memory state
    final previousState = state;
    state = state.where((s) => s.id != cleanId).toList();

    try {
      // 2. Perform Firestore delete
      await FirebaseFirestore.instance.collection('subscriptions').doc(cleanId).delete();
    } catch (e) {
      debugPrint('Error deleting subscription $cleanId: $e');
      // Rollback optimistic removal on failure
      state = previousState;
      rethrow;
    }
  }

  bool canSubscriptionBeUsedForClass(Subscription sub, GroupClass gClass, {String? clientBranchId}) {
    // 0. Branch isolation & data integrity check (TZ Point 29)
    final integrityResult = BranchDataIntegrityValidator.validateAttendanceDeduction(
      subscription: sub,
      groupClass: gClass,
      clientBranchId: clientBranchId,
    );
    if (!integrityResult.isValid) {
      return false;
    }

    // 1. Split classes: only split subscriptions are valid
    if (gClass.isSplit) {
      return sub.isSplitSubscription;
    }
    // A split subscription cannot be used for standard group or individual classes
    if (sub.isSplitSubscription) {
      return false;
    }

    // 2. Individual classes
    if (gClass.isIndividual) {
      if (!sub.isIndividualSubscription) return false;
    } else {
      // Standard group classes cannot use an individual pass
      if (sub.isIndividualSubscription) return false;
    }

    // 3. Audience checks: adult vs child
    if (gClass.isAdultOnly && sub.isChildOnlySubscription) {
      return false;
    }
    if (gClass.isChildOnly && sub.isAdultOnlySubscription) {
      return false;
    }

    // 4. Age range check if both have explicit age ranges
    final subRange = sub.ageRange;
    final classRange = gClass.ageRange;
    if (subRange != null && classRange != null) {
      if (subRange.$1 > classRange.$2 || subRange.$2 < classRange.$1) {
        return false;
      }
    }

    return true;
  }

  Future<QrCheckInResult> processQrCheckIn({
    required String code,
    required GroupClass targetClass,
    String? scanningCoachBranchId,
    List<String>? scanningCoachBranchIds,
  }) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      return const QrCheckInResult(
        status: QrCheckInStatus.notFound,
        message: 'Порожній QR-код.',
      );
    }

    // 0. Coach Branch Authorization Check
    if (scanningCoachBranchId != null) {
      final allowedBranches = scanningCoachBranchIds ?? [scanningCoachBranchId];
      if (scanningCoachBranchId != targetClass.branchId && !allowedBranches.contains(targetClass.branchId)) {
        final coachBranchName = scanningCoachBranchId == 'vienna' ? 'CitySwim Vienna 🇦🇹' : 'CitySwim Kyiv 🇺🇦';
        final classBranchName = targetClass.branchId == 'vienna' ? 'CitySwim Vienna 🇦🇹' : 'CitySwim Kyiv 🇺🇦';
        return QrCheckInResult(
          status: QrCheckInStatus.wrongService,
          classTitle: targetClass.title,
          message: 'Тренер з філії $coachBranchName не має доступу до списання перепусток на занятті $classBranchName.',
        );
      }
    }

    // 1. Validate date: class MUST be scheduled for today
    final now = DateTime.now();
    final isToday = targetClass.startTime.year == now.year &&
        targetClass.startTime.month == now.month &&
        targetClass.startTime.day == now.day;

    if (!isToday) {
      final classDateStr = DateFormat('dd.MM.yyyy').format(targetClass.startTime);
      return QrCheckInResult(
        status: QrCheckInStatus.wrongDate,
        classTitle: targetClass.title,
        message: 'Заняття призначено на $classDateStr. Списання за QR-кодом можливе лише в день заняття.',
      );
    }

    // 2. Resolve Subscription
    Subscription? targetSub;
    String? explicitUserId;

    if (cleanCode.startsWith('SWIM_SUB:')) {
      final parts = cleanCode.split(':');
      if (parts.length >= 2) {
        final subId = parts[1];
        if (parts.length >= 3) {
          explicitUserId = parts[2];
        }

        try {
          targetSub = state.firstWhere((s) => s.id == subId);
        } catch (_) {
          final doc = await FirebaseFirestore.instance.collection('subscriptions').doc(subId).get();
          if (doc.exists) {
            targetSub = Subscription.fromJson({'id': doc.id, ...doc.data()!});
          }
        }
      }
    }

    // Fallback if not resolved by SWIM_SUB:
    if (targetSub == null) {
      // Try direct sub ID or user ID
      final matchingSubs = state.where((s) => s.id == cleanCode || s.userId == cleanCode).toList();
      if (matchingSubs.isNotEmpty) {
        // Prioritize compatible subscription
        try {
          targetSub = matchingSubs.firstWhere(
            (s) => s.isActive && s.remainingClasses > 0 && canSubscriptionBeUsedForClass(s, targetClass),
          );
        } catch (_) {
          targetSub = matchingSubs.first;
        }
      } else {
        // Fallback smart lookup by loginId, phone, or child ID
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
            explicitUserId = resolvedUserId;
            final userSubs = state.where((s) => s.userId == resolvedUserId).toList();
            if (userSubs.isNotEmpty) {
              try {
                targetSub = userSubs.firstWhere(
                  (s) => s.isActive && s.remainingClasses > 0 && canSubscriptionBeUsedForClass(s, targetClass),
                );
              } catch (_) {
                targetSub = userSubs.first;
              }
            }
          }
        } catch (e) {
          debugPrint('Error looking up client in processQrCheckIn: $e');
        }
      }
    }

    if (targetSub == null) {
      return const QrCheckInResult(
        status: QrCheckInStatus.notFound,
        message: 'Абонемент або клієнта не знайдено за цим кодом.',
      );
    }

    final sub = targetSub;

    // 2.5 Tenancy Branch Check (Cross-branch security guard & data integrity)
    final integrityResult = BranchDataIntegrityValidator.validateAttendanceDeduction(
      subscription: sub,
      groupClass: targetClass,
    );
    if (!integrityResult.isValid) {
      return QrCheckInResult(
        status: QrCheckInStatus.wrongService,
        studentName: sub.ownerName,
        classTitle: targetClass.title,
        subServiceName: sub.serviceName,
        remainingClasses: sub.remainingClasses,
        message: integrityResult.errorMessage ?? 'Перепустку заблоковано через міжфіліальну ізоляцію.',
      );
    }

    // 3. Service compatibility check
    if (!canSubscriptionBeUsedForClass(sub, targetClass)) {
      return QrCheckInResult(
        status: QrCheckInStatus.wrongService,
        studentName: sub.ownerName,
        classTitle: targetClass.title,
        subServiceName: sub.serviceName,
        remainingClasses: sub.remainingClasses,
        message: 'Абонемент "${sub.serviceName ?? 'Невідомий'}" не відповідає типу заняття "${targetClass.title}".',
      );
    }

    // 4. Remaining classes and active/expiry check
    final isExpired = sub.expiryDate != null && sub.expiryDate!.isBefore(now);
    if (!sub.isActive || sub.remainingClasses <= 0 || isExpired) {
      return QrCheckInResult(
        status: QrCheckInStatus.expiredOrEmpty,
        studentName: sub.ownerName,
        classTitle: targetClass.title,
        subServiceName: sub.serviceName,
        remainingClasses: sub.remainingClasses,
        message: isExpired
            ? 'Термін дії абонемента закінчився (${DateFormat('dd.MM.yyyy').format(sub.expiryDate!)}).'
            : 'На абонементі вичерпано всі заняття (залишок 0).',
      );
    }

    // 5. Resolve Attendee ID and Student Name
    String attendeeId = explicitUserId ?? sub.userId;
    String studentName = (sub.ownerName ?? '').trim();

    // Check if ownerName corresponds to a child of this user
    try {
      final childrenSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('parentId', isEqualTo: sub.userId)
          .get();

      if (studentName.isNotEmpty) {
        for (final doc in childrenSnapshot.docs) {
          final cName = (doc.data()['name'] as String?)?.trim() ?? '';
          if (cName.toLowerCase() == studentName.toLowerCase()) {
            attendeeId = doc.id;
            studentName = cName;
            break;
          }
        }
      } else if (childrenSnapshot.docs.length == 1) {
        attendeeId = childrenSnapshot.docs.first.id;
        studentName = (childrenSnapshot.docs.first.data()['name'] as String?) ?? 'Учень';
      }
    } catch (e) {
      debugPrint('Error finding child for subscription: $e');
    }

    if (studentName.isEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(sub.userId).get();
        studentName = (userDoc.data()?['name'] as String?)?.trim() ?? 'Клієнт';
      } catch (_) {
        studentName = 'Клієнт';
      }
    }

    // 6. Atomic Transaction for Attendance Registration & Drop-in Deduction
    try {
      final classRef = FirebaseFirestore.instance.collection('classes').doc(targetClass.id);
      final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(sub.id);

      QrCheckInResult? transactionResult;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final classSnapshot = await transaction.get(classRef);
        final subSnapshot = await transaction.get(subRef);

        if (!classSnapshot.exists) {
          transactionResult = QrCheckInResult(
            status: QrCheckInStatus.notFound,
            studentName: studentName,
            classTitle: targetClass.title,
            message: 'Заняття не знайдено в системі.',
          );
          return;
        }

        final classData = Map<String, dynamic>.from(classSnapshot.data() ?? {});
        final liveAttended = List<String>.from((classData['attendedChildIds'] as List?) ?? []);
        final liveEnrolled = List<String>.from((classData['enrolledChildIds'] as List?) ?? []);

        // Anti-duplicate attendance: check if already attended
        if (liveAttended.contains(attendeeId) || liveAttended.contains(sub.userId)) {
          final currentRem = subSnapshot.exists ? (subSnapshot.data()?['remainingClasses'] as int? ?? sub.remainingClasses) : sub.remainingClasses;
          transactionResult = QrCheckInResult(
            status: QrCheckInStatus.alreadyAttended,
            studentName: studentName,
            classTitle: targetClass.title,
            subServiceName: sub.serviceName,
            remainingClasses: currentRem,
            message: '$studentName вже відмічений(-а) на цьому занятті. Повторне списання заблоковано.',
          );
          return;
        }

        final bool isPreBooked = liveEnrolled.contains(attendeeId) || liveEnrolled.contains(sub.userId);

        if (isPreBooked) {
          // --- CASE A: Student was pre-booked (1 pass was already deducted at booking) ---
          // DO NOT deduct again! Only register attendance.
          final currentRem = subSnapshot.exists ? (subSnapshot.data()?['remainingClasses'] as int? ?? sub.remainingClasses) : sub.remainingClasses;
          final updatedAttended = List<String>.from(liveAttended)..add(attendeeId);

          transaction.update(classRef, {
            'attendedChildIds': updatedAttended,
          });

          transactionResult = QrCheckInResult(
            status: QrCheckInStatus.success,
            studentName: studentName,
            classTitle: targetClass.title,
            subServiceName: sub.serviceName,
            remainingClasses: currentRem,
            message: 'Присутність для $studentName підтверджено (за попереднім записом). Залишок: $currentRem',
          );
        } else {
          // --- CASE B: Drop-in (Student was NOT pre-booked) ---
          final maxCap = (classData['maxCapacity'] as int?) ?? targetClass.maxCapacity;
          if (liveEnrolled.length >= maxCap) {
            transactionResult = QrCheckInResult(
              status: QrCheckInStatus.wrongService,
              studentName: studentName,
              classTitle: targetClass.title,
              subServiceName: sub.serviceName,
              remainingClasses: sub.remainingClasses,
              message: 'Група заповнена ($maxCap/$maxCap). Вільних місць для додаткового запису немає.',
            );
            return;
          }

          if (!subSnapshot.exists) {
            transactionResult = QrCheckInResult(
              status: QrCheckInStatus.notFound,
              studentName: studentName,
              classTitle: targetClass.title,
              message: 'Абонемент не знайдено у базі даних.',
            );
            return;
          }

          final subData = Map<String, dynamic>.from(subSnapshot.data() ?? {});
          final currentRem = subData['remainingClasses'] as int? ?? 0;
          final isActive = subData['isActive'] as bool? ?? false;

          if (currentRem <= 0 || !isActive) {
            transactionResult = QrCheckInResult(
              status: QrCheckInStatus.expiredOrEmpty,
              studentName: studentName,
              classTitle: targetClass.title,
              subServiceName: sub.serviceName,
              remainingClasses: currentRem,
              message: 'На абонементі вичерпано всі заняття (залишок: $currentRem).',
            );
            return;
          }

          final newRemaining = currentRem - 1;
          final newIsActive = newRemaining > 0;

          // 1. Deduct pass from subscription
          transaction.update(subRef, {
            'remainingClasses': newRemaining,
            'isActive': newIsActive,
          });

          // 2. Enroll and mark attendance on class
          final updatedEnrolled = List<String>.from(liveEnrolled)..add(attendeeId);
          final updatedAttended = List<String>.from(liveAttended)..add(attendeeId);
          final bookedMap = Map<String, dynamic>.from((classData['bookedSubscriptions'] as Map?) ?? {});
          bookedMap[attendeeId] = sub.id;

          transaction.update(classRef, {
            'enrolledChildIds': updatedEnrolled,
            'attendedChildIds': updatedAttended,
            'bookedSubscriptions': bookedMap,
          });

          transactionResult = QrCheckInResult(
            status: QrCheckInStatus.success,
            studentName: studentName,
            classTitle: targetClass.title,
            subServiceName: sub.serviceName,
            remainingClasses: newRemaining,
            message: 'Заняття успішно списано для $studentName (Drop-in). Залишок: $newRemaining',
          );
        }
      });

      if (transactionResult != null) {
        if (transactionResult!.status == QrCheckInStatus.success) {
          // Sync in-memory state cleanly
          state = state.map((s) {
            if (s.id == sub.id) {
              final newRem = transactionResult!.remainingClasses ?? 0;
              return s.copyWith(remainingClasses: newRem, isActive: newRem > 0);
            }
            return s;
          }).toList();
        }
        return transactionResult!;
      }

      return QrCheckInResult(
        status: QrCheckInStatus.notFound,
        studentName: studentName,
        classTitle: targetClass.title,
        message: 'Не вдалося виконати операцію чек-іну.',
      );
    } catch (e) {
      debugPrint('Error in atomic QR check-in: $e');
      return QrCheckInResult(
        status: QrCheckInStatus.notFound,
        studentName: studentName,
        classTitle: targetClass.title,
        message: 'Помилка збереження списання: $e',
      );
    }
  }
}
