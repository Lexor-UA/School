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
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

part 'subscription_controller.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionController extends _$SubscriptionController {
  StreamSubscription<QuerySnapshot>? _subSubscription;

  @override
  List<Subscription> build() {
    ref.onDispose(() {
      _subSubscription?.cancel();
      _subSubscription = null;
    });

    _listenToSubscriptions();
    return [];
  }

  void _listenToSubscriptions() {
    _subSubscription?.cancel();

    final user = ref.watch(authControllerProvider);
    final tenancyState = ref.watch(tenancyControllerProvider);
    final activeBranchId = tenancyState.activeBranchId;
    final isAllLocations = tenancyState.isAllLocationsSelected;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('subscriptions');

    if (user != null) {
      if (user.role == UserRole.parent) {
        final family = ref.watch(familyStreamProvider).value;
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
      
      _checkExpirations(subs);
      state = subs;
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
      if (sub.isActive && sub.totalClasses == 1 && sub.expiryDate != null) {
        final daysUntilExpiry = sub.expiryDate!.difference(now).inDays;
        if (daysUntilExpiry < 30) {
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

  Subscription? getActiveSubscriptionForOwner(String userId, String ownerName, {bool isSplit = false, List<String>? familyUserIds}) {
    final now = DateTime.now();
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);

    try {
      return state.firstWhere((sub) {
        if (isSplit && !sub.isSplitSubscription) return false;
        if (!isSplit && sub.isSplitSubscription) return false;

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

  Subscription? getSubscriptionForOwner(String userId, String ownerName, {bool? isAdult, bool isSplit = false, List<String>? familyUserIds}) {
    final effectiveFamilyIds = _resolveFamilyUserIds(userId, familyUserIds);

    final userSubs = state.where((sub) {
      if (!sub.isActive || sub.remainingClasses <= 0) return false;
      if (isSplit && !sub.isSplitSubscription) return false;
      if (!isSplit && sub.isSplitSubscription) return false;

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
        if (isAdult && directMatch.isChildSubscription) {
          // Incompatible: adult cannot use child subscription
        } else if (!isAdult && directMatch.isAdultSubscription) {
          // Incompatible: child cannot use adult subscription
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
            return isAdult ? sub.isAdultSubscription : sub.isChildSubscription;
          }
          return true;
        });
      } catch (_) {}
    }

    // 3. If isAdult is specified, try to find compatible unassigned/generic subscription
    if (!isSplit && isAdult != null) {
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
    if (gClass.isAdultOnly && !sub.isAdultSubscription) {
      return false;
    }
    if (gClass.isChildOnly && sub.isAdultSubscription) {
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

    // 2.5 Tenancy Branch Check (Cross-branch security guard & data integrity)
    final integrityResult = BranchDataIntegrityValidator.validateAttendanceDeduction(
      subscription: targetSub,
      groupClass: targetClass,
    );
    if (!integrityResult.isValid) {
      return QrCheckInResult(
        status: QrCheckInStatus.wrongService,
        studentName: targetSub.ownerName,
        classTitle: targetClass.title,
        subServiceName: targetSub.serviceName,
        remainingClasses: targetSub.remainingClasses,
        message: integrityResult.errorMessage ?? 'Перепустку заблоковано через міжфіліальну ізоляцію.',
      );
    }

    // 3. Service compatibility check
    if (!canSubscriptionBeUsedForClass(targetSub, targetClass)) {
      return QrCheckInResult(
        status: QrCheckInStatus.wrongService,
        studentName: targetSub.ownerName,
        classTitle: targetClass.title,
        subServiceName: targetSub.serviceName,
        remainingClasses: targetSub.remainingClasses,
        message: 'Абонемент "${targetSub.serviceName ?? 'Невідомий'}" не відповідає типу заняття "${targetClass.title}".',
      );
    }

    // 4. Remaining classes and active/expiry check
    final isExpired = targetSub.expiryDate != null && targetSub.expiryDate!.isBefore(now);
    if (!targetSub.isActive || targetSub.remainingClasses <= 0 || isExpired) {
      return QrCheckInResult(
        status: QrCheckInStatus.expiredOrEmpty,
        studentName: targetSub.ownerName,
        classTitle: targetClass.title,
        subServiceName: targetSub.serviceName,
        remainingClasses: targetSub.remainingClasses,
        message: isExpired
            ? 'Термін дії абонемента закінчився (${DateFormat('dd.MM.yyyy').format(targetSub.expiryDate!)}).'
            : 'На абонементі вичерпано всі заняття (залишок 0).',
      );
    }

    // 5. Resolve Attendee ID and Student Name
    String attendeeId = explicitUserId ?? targetSub.userId;
    String studentName = (targetSub.ownerName ?? '').trim();

    // Check if ownerName corresponds to a child of this user
    try {
      final childrenSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('parentId', isEqualTo: targetSub.userId)
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
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(targetSub.userId).get();
        studentName = (userDoc.data()?['name'] as String?)?.trim() ?? 'Клієнт';
      } catch (_) {
        studentName = 'Клієнт';
      }
    }

    // 6. Anti-duplicate attendance check: Check live class document in Firestore
    try {
      final classDoc = await FirebaseFirestore.instance.collection('classes').doc(targetClass.id).get();
      if (classDoc.exists) {
        final liveAttended = List<String>.from(
          (classDoc.data()?['attendedChildIds'] as List?) ?? targetClass.attendedChildIds,
        );
        if (liveAttended.contains(attendeeId) || liveAttended.contains(targetSub.userId)) {
          return QrCheckInResult(
            status: QrCheckInStatus.alreadyAttended,
            studentName: studentName,
            classTitle: targetClass.title,
            subServiceName: targetSub.serviceName,
            remainingClasses: targetSub.remainingClasses,
            message: '$studentName вже відмічений(-а) на цьому занятті. Повторне списання заблоковано.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking live attendance: $e');
      if (targetClass.attendedChildIds.contains(attendeeId) || targetClass.attendedChildIds.contains(targetSub.userId)) {
        return QrCheckInResult(
          status: QrCheckInStatus.alreadyAttended,
          studentName: studentName,
          classTitle: targetClass.title,
          subServiceName: targetSub.serviceName,
          remainingClasses: targetSub.remainingClasses,
          message: '$studentName вже відмічений(-а) на цьому занятті. Повторне списання заблоковано.',
        );
      }
    }

    // 7. Deduct 1 pass from subscription
    final newRemaining = targetSub.remainingClasses - 1;
    final newIsActive = newRemaining > 0;

    try {
      await FirebaseFirestore.instance.collection('subscriptions').doc(targetSub.id).update({
        'remainingClasses': newRemaining,
        'isActive': newIsActive,
      });

      // Update in-memory state
      state = state.map((s) {
        if (s.id == targetSub!.id) {
          return s.copyWith(remainingClasses: newRemaining, isActive: newIsActive);
        }
        return s;
      }).toList();

      // 8. Register attendance and enrollment in the class
      await FirebaseFirestore.instance.collection('classes').doc(targetClass.id).update({
        'attendedChildIds': FieldValue.arrayUnion([attendeeId]),
        'enrolledChildIds': FieldValue.arrayUnion([attendeeId]),
      });

      return QrCheckInResult(
        status: QrCheckInStatus.success,
        studentName: studentName,
        classTitle: targetClass.title,
        subServiceName: targetSub.serviceName,
        remainingClasses: newRemaining,
        message: 'Заняття успішно списано для $studentName. Залишок: $newRemaining',
      );
    } catch (e) {
      debugPrint('Error finalizing QR check-in: $e');
      return QrCheckInResult(
        status: QrCheckInStatus.notFound,
        studentName: studentName,
        classTitle: targetClass.title,
        message: 'Помилка збереження списання: $e',
      );
    }
  }
}
