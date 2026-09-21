import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/models/class_activity.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:collection/collection.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/class_conflict.dart';
import 'package:intl/intl.dart';

part 'schedule_controller.g.dart';

final classActivitiesStreamProvider = StreamProvider<List<ClassActivity>>((ref) {
  return FirebaseFirestore.instance
      .collection('class_activities')
      .orderBy('timestamp', descending: true)
      .limit(60)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return ClassActivity.fromJson(data);
    }).toList();
  });
});

enum BookingStatus {
  success,
  classFull,
  noSubscription,
  alreadyBooked,
  classPast,
  error,
}

class BookingResult {
  final bool isSuccess;
  final String message;
  final BookingStatus status;

  const BookingResult({
    required this.isSuccess,
    required this.message,
    required this.status,
  });

  static const success = BookingResult(
    isSuccess: true,
    message: 'Успішно записано на тренування!',
    status: BookingStatus.success,
  );

  static const classFull = BookingResult(
    isSuccess: false,
    message: 'У цій групі вже немає вільних місць.',
    status: BookingStatus.classFull,
  );

  static const noSubscription = BookingResult(
    isSuccess: false,
    message: 'Немає активного абонемента з доступними заняттями.',
    status: BookingStatus.noSubscription,
  );

  static const alreadyBooked = BookingResult(
    isSuccess: false,
    message: 'Ви вже записані на це тренування.',
    status: BookingStatus.alreadyBooked,
  );

  static const classPast = BookingResult(
    isSuccess: false,
    message: 'Це тренування вже завершилося. Запис неможливий.',
    status: BookingStatus.classPast,
  );

  static const error = BookingResult(
    isSuccess: false,
    message: 'Помилка запису. Спробуйте пізніше.',
    status: BookingStatus.error,
  );
}

@Riverpod(keepAlive: true)
class ScheduleController extends _$ScheduleController {
  ClassConflict? lastConflict;

  ClassConflict? _evaluateConflictAgainst({
    required List<GroupClass> classes,
    required DateTime startTime,
    required DateTime endTime,
    required String lane,
    required String coachId,
    String? excludeClassId,
    List<String> enrolledChildIds = const [],
  }) {
    final overlappingClasses = classes.where((c) {
      if (excludeClassId != null && c.id == excludeClassId) return false;
      return c.startTime.isBefore(endTime) && c.endTime.isAfter(startTime);
    }).toList();

    // 1. Pool Capacity: Maximum 4 simultaneous classes in the 4-lane pool
    if (overlappingClasses.length >= 4) {
      final timeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      return ClassConflict(
        type: ClassConflictType.laneConflict,
        conflictingClass: overlappingClasses.first,
        message: 'Усі 4 доріжки басейну вже зайняті з $timeStr до $endTimeStr (максимум 4 заняття одночасно).',
      );
    }

    final l1 = lane.trim().toLowerCase();
    final isWholePool1 = l1.contains('весь') || l1.contains('всі');
    final hasLane = lane.trim().isNotEmpty && lane.trim() != 'Будь-яка';

    for (final c in overlappingClasses) {
      final l2 = c.lane.trim().toLowerCase();
      final isWholePool2 = l2.contains('весь') || l2.contains('всі');
      final cHasLane = c.lane.trim().isNotEmpty && c.lane.trim() != 'Будь-яка';

      // 2. Whole Pool or Direct Lane conflict check
      if (isWholePool1 || isWholePool2) {
        final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
        final endTimeStr = '${c.endTime.hour.toString().padLeft(2, '0')}:${c.endTime.minute.toString().padLeft(2, '0')}';
        final coachNameDisplay = c.coachName.isNotEmpty ? c.coachName : 'не вказано';
        return ClassConflict(
          type: ClassConflictType.laneConflict,
          conflictingClass: c,
          message: isWholePool2
              ? 'Весь басейн вже зайнятий з $timeStr до $endTimeStr заняттям «${c.title}» (тренер: $coachNameDisplay).'
              : 'Для оренди всього басейну на цей час не повинно бути інших занять ($timeStr-$endTimeStr).',
        );
      } else if (hasLane && cHasLane && l1 == l2) {
        final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
        final endTimeStr = '${c.endTime.hour.toString().padLeft(2, '0')}:${c.endTime.minute.toString().padLeft(2, '0')}';
        final coachNameDisplay = c.coachName.isNotEmpty ? c.coachName : 'не вказано';
        return ClassConflict(
          type: ClassConflictType.laneConflict,
          conflictingClass: c,
          message: 'Доріжка «$lane» вже зайнята з $timeStr до $endTimeStr заняттям «${c.title}» (тренер: $coachNameDisplay).',
        );
      }

      // 3. Coach conflict check
      final hasCoach = coachId.trim().isNotEmpty && coachId.trim() != 'unassigned';
      final cHasCoach = c.coachId.trim().isNotEmpty && c.coachId.trim() != 'unassigned';
      if (hasCoach && cHasCoach && c.coachId == coachId) {
        final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
        final endTimeStr = '${c.endTime.hour.toString().padLeft(2, '0')}:${c.endTime.minute.toString().padLeft(2, '0')}';
        final laneDisplay = c.lane.isNotEmpty ? c.lane : 'басейн';
        return ClassConflict(
          type: ClassConflictType.coachConflict,
          conflictingClass: c,
          message: 'Тренер ${c.coachName} вже проводить заняття «${c.title}» з $timeStr до $endTimeStr ($laneDisplay).',
        );
      }

      // 4. Member conflict check
      if (enrolledChildIds.isNotEmpty && c.enrolledChildIds.any((id) => enrolledChildIds.contains(id))) {
        final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
        final endTimeStr = '${c.endTime.hour.toString().padLeft(2, '0')}:${c.endTime.minute.toString().padLeft(2, '0')}';
        return ClassConflict(
          type: ClassConflictType.participantConflict,
          conflictingClass: c,
          message: 'Один з обраних учасників вже записаний на інше тренування з $timeStr до $endTimeStr («${c.title}»).',
        );
      }
    }
    return null;
  }

  ClassConflict? checkClassConflict({
    required DateTime startTime,
    required DateTime endTime,
    required String lane,
    required String coachId,
    String? excludeClassId,
    List<String> enrolledChildIds = const [],
    List<GroupClass>? additionalClasses,
  }) {
    final combined = [...(state.value ?? []), ...(additionalClasses ?? [])];
    return _evaluateConflictAgainst(
      classes: combined,
      startTime: startTime,
      endTime: endTime,
      lane: lane,
      coachId: coachId,
      excludeClassId: excludeClassId,
      enrolledChildIds: enrolledChildIds,
    );
  }

  Future<ClassConflict?> checkAuthoritativeConflict({
    required DateTime startTime,
    required DateTime endTime,
    required String lane,
    required String coachId,
    String? excludeClassId,
    List<String> enrolledChildIds = const [],
    List<GroupClass>? additionalClasses,
  }) async {
    // 1. Fast in-memory check
    final localConflict = checkClassConflict(
      startTime: startTime,
      endTime: endTime,
      lane: lane,
      coachId: coachId,
      excludeClassId: excludeClassId,
      enrolledChildIds: enrolledChildIds,
      additionalClasses: additionalClasses,
    );
    if (localConflict != null) return localConflict;

    // 2. Authoritative Firestore query for the date to avoid race conditions or uninitialized cache
    try {
      final dayStart = DateTime(startTime.year, startTime.month, startTime.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('startTime', isGreaterThanOrEqualTo: dayStart.toIso8601String())
          .where('startTime', isLessThan: dayEnd.toIso8601String())
          .get();

      final List<GroupClass> remoteClasses = [];
      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['id'] = doc.id;
          if (data['startTime'] is Timestamp) {
            data['startTime'] = (data['startTime'] as Timestamp).toDate().toIso8601String();
          }
          if (data['endTime'] is Timestamp) {
            data['endTime'] = (data['endTime'] as Timestamp).toDate().toIso8601String();
          }
          remoteClasses.add(GroupClass.fromJson(data));
        } catch (_) {}
      }

      final combined = [...remoteClasses, ...(additionalClasses ?? [])];
      return _evaluateConflictAgainst(
        classes: combined,
        startTime: startTime,
        endTime: endTime,
        lane: lane,
        coachId: coachId,
        excludeClassId: excludeClassId,
        enrolledChildIds: enrolledChildIds,
      );
    } catch (e) {
      debugPrint('Error in checkAuthoritativeConflict: $e');
      return null;
    }
  }

  @override
  Stream<List<GroupClass>> build() {
    return FirebaseFirestore.instance
        .collection('classes')
        .where('startTime', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 45)).toIso8601String())
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      final List<GroupClass> classes = [];
      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['id'] = doc.id;
          if (data['startTime'] is Timestamp) {
            data['startTime'] = (data['startTime'] as Timestamp).toDate().toIso8601String();
          }
          if (data['endTime'] is Timestamp) {
            data['endTime'] = (data['endTime'] as Timestamp).toDate().toIso8601String();
          }

          // Self-heal group classes created with maxCapacity <= 2 or wrong category
          final titleLower = (data['title'] as String? ?? '').toLowerCase();
          final isGroupTitle = titleLower.contains('групов') || titleLower.contains('аквааеробіка');
          final currentCap = (data['maxCapacity'] as num?)?.toInt() ?? 0;
          if (isGroupTitle && currentCap <= 2) {
            data['maxCapacity'] = 10;
            final correctCategory = titleLower.contains('аквааеробіка') ? 'Аквааеробіка' : 'Групове';
            data['category'] = correctCategory;
            doc.reference.update({
              'maxCapacity': 10,
              'category': correctCategory,
            }).catchError((e) {
              debugPrint('Failed to auto-heal group class ${doc.id}: $e');
            });
          }

          classes.add(GroupClass.fromJson(data));
        } catch (e) {
          debugPrint('Warning: Failed to parse class document ${doc.id}: $e');
        }
      }
      return classes;
    });
  }

  Future<BookingResult> bookClass(
    String classId, 
    String childId, {
    String? secondParticipantId,
    String? targetUserId,
    String? targetOwnerName,
    bool autoEnrollFamilyForSplit = true,
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return BookingResult.error;

    final effectiveUserId = targetUserId ?? user.id;
    final childrenAsync = ref.read(childrenControllerProvider);
    final children = childrenAsync.value ?? [];
    final family = ref.read(familyStreamProvider).value;
    final familyParentIds = (family != null && family.parentIds.isNotEmpty)
        ? family.parentIds
        : [user.id];

    String getMemberName(String id) {
      if (id == user.id) return user.name;
      if (family != null && family.parentNames.containsKey(id) && family.parentNames[id]!.trim().isNotEmpty) {
        return family.parentNames[id]!;
      }
      final ch = children.where((c) => c.id == id).firstOrNull;
      if (ch != null) return ch.name;
      return id;
    }

    String ownerName = targetOwnerName ?? getMemberName(childId);
    final isAdult = childId == effectiveUserId || familyParentIds.contains(childId);

    // Get the subscription for effective user / family
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    Subscription? subscription;

    // Check if target class is a split class
    final classDocPre = await FirebaseFirestore.instance.collection('classes').doc(classId).get();
    final groupClassPreTitle = (classDocPre.data()?['title'] as String? ?? '').toLowerCase();
    final bool isSplitPre = groupClassPreTitle.contains('спліт') || groupClassPreTitle.contains('split');

    DateTime? classStartTime;
    final classData = classDocPre.data();
    if (classData != null && classData['startTime'] != null) {
      if (classData['startTime'] is Timestamp) {
        classStartTime = (classData['startTime'] as Timestamp).toDate();
      } else if (classData['startTime'] is String) {
        classStartTime = DateTime.tryParse(classData['startTime'] as String);
      }
    }

    if (secondParticipantId != null || isSplitPre) {
      // Prioritize split subscription for the user / family
      final userSubs = subscriptionController.getSubscriptionsForUser(effectiveUserId);
      subscription = userSubs.firstWhereOrNull((s) => s.isActive && s.remainingClasses > 0 && s.isSplitSubscription);

      if (subscription == null && family != null) {
        for (final pId in family.parentIds) {
          if (pId != effectiveUserId) {
            final partnerSubs = subscriptionController.getSubscriptionsForUser(pId);
            subscription = partnerSubs.firstWhereOrNull((s) => s.isActive && s.remainingClasses > 0 && s.isSplitSubscription);
            if (subscription != null) break;
          }
        }
      }
    } else {
      subscription = subscriptionController.getSubscriptionForOwner(effectiveUserId, ownerName, isAdult: isAdult, isSplit: false);
      if (subscription?.isSplitSubscription == true) {
        subscription = null;
      }
    }
    
    if (subscription == null || subscription.remainingClasses <= 0 || !subscription.isActive) {
      return BookingResult.noSubscription;
    }

    final effectiveSubscription = subscription;

    if (classStartTime != null && effectiveSubscription.expiryDate != null) {
      final endOfExpiryDay = DateTime(
        effectiveSubscription.expiryDate!.year,
        effectiveSubscription.expiryDate!.month,
        effectiveSubscription.expiryDate!.day,
        23, 59, 59,
      );
      if (classStartTime.isAfter(endOfExpiryDay)) {
        final expiryStr = DateFormat('dd.MM.yyyy').format(effectiveSubscription.expiryDate!);
        final dateStr = DateFormat('dd.MM.yyyy').format(classStartTime);
        return BookingResult(
          isSuccess: false,
          message: 'Термін дії абонемента закінчується $expiryStr (до дати тренування $dateStr).',
          status: BookingStatus.error,
        );
      }
    }

    try {
      final classRef = FirebaseFirestore.instance.collection('classes').doc(classId);
      final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(effectiveSubscription.id);
      
      BookingResult result = BookingResult.error;
      GroupClass? bookedClass;
      List<String> confirmedAttendees = [];

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final classDoc = await transaction.get(classRef);
        final subDoc = await transaction.get(subRef);
        
        if (!classDoc.exists || !subDoc.exists) {
          result = BookingResult.error;
          return;
        }
        
        final data = Map<String, dynamic>.from(classDoc.data()! as Map);
        data['id'] = classDoc.id;
        final groupClass = GroupClass.fromJson(data);
        bookedClass = groupClass;

        // Strict category validation between class and subscription
        if (groupClass.isSplit && !effectiveSubscription.isSplitSubscription) {
          result = const BookingResult(
            isSuccess: false,
            message: 'Для запису на спліт-тренування потрібен спліт-абонемент (на 2 особи).',
            status: BookingStatus.error,
          );
          return;
        }

        if (!groupClass.isSplit && effectiveSubscription.isSplitSubscription) {
          result = const BookingResult(
            isSuccess: false,
            message: 'Спліт-абонемент призначений лише для спліт-тренувань (на 2 особи). Для цього заняття потрібен звичайний абонемент.',
            status: BookingStatus.error,
          );
          return;
        }

        // Determine all members to enroll
        final List<String> attendeesToAdd = [childId];
        if (groupClass.isSplit && groupClass.enrolledChildIds.isEmpty) {
          if (secondParticipantId != null && secondParticipantId != childId) {
            attendeesToAdd.add(secondParticipantId);
          } else if (autoEnrollFamilyForSplit) {
            if (childId != user.id) {
              attendeesToAdd.add(user.id);
            } else {
              // If parent booked: check available family members (partner, children)
              final partnerId = family?.getOtherParentId(user.id);
              if (children.isEmpty && partnerId != null) {
                attendeesToAdd.add(partnerId);
              } else if (children.length == 1 && partnerId == null) {
                attendeesToAdd.add(children.first.id);
              } else {
                // If there are multiple family options, DO NOT guess! Force selection.
                result = const BookingResult(
                  isSuccess: false,
                  message: 'Для спліт-тренування оберіть обох учасників (двоє дорослих, дорослий + дитина або двоє дітей).',
                  status: BookingStatus.error,
                );
                return;
              }
            }
          }
        }

        // Validate each attendee
        for (final attId in attendeesToAdd) {
          final isAttAdult = attId == effectiveUserId || familyParentIds.contains(attId);
          
          if (!groupClass.isSplit) {
            if (isAttAdult && groupClass.isChildOnly) {
              result = const BookingResult(
                isSuccess: false,
                message: 'Це тренування лише для дітей. Будь ласка, оберіть профіль дитини.',
                status: BookingStatus.error,
              );
              return;
            }

            if (!isAttAdult && groupClass.isAdultOnly) {
              result = const BookingResult(
                isSuccess: false,
                message: 'Це тренування призначене лише для дорослих.',
                status: BookingStatus.error,
              );
              return;
            }

            if (!isAttAdult && effectiveSubscription.isAdultSubscription) {
              result = const BookingResult(
                isSuccess: false,
                message: 'Дорослий абонемент не може використовуватися для дитячих занять.',
                status: BookingStatus.error,
              );
              return;
            }

            if (isAttAdult && effectiveSubscription.isChildSubscription) {
              result = const BookingResult(
                isSuccess: false,
                message: 'Дитячий абонемент не може використовуватися для дорослих занять.',
                status: BookingStatus.error,
              );
              return;
            }
          }

          if (!isAttAdult) {
            final child = children.where((c) => c.id == attId).firstOrNull;
            final childAge = child?.currentAge;
            if (childAge != null && !groupClass.isAgeCompatible(childAge)) {
              final range = groupClass.ageRange;
              final msg = childAge <= 5
                  ? 'Для дітей до 5 років включно (${child?.name ?? ''}, вік: $childAge р.) доступні лише персональні індивідуальні заняття. Групові та спліт-тренування доступні від 6 років.'
                  : 'Вік дитини ${child?.name ?? ''} ($childAge р.) не відповідає віковій групі цього тренування (${range?.$1 ?? 0}-${range?.$2 ?? 0} р.).';
              result = BookingResult(
                isSuccess: false,
                message: msg,
                status: BookingStatus.error,
              );
              return;
            }

            if (childAge != null && !effectiveSubscription.isAgeCompatible(childAge)) {
              final subRange = effectiveSubscription.ageRange;
              final subMsg = childAge <= 5
                  ? 'Для дитини віком $childAge р. потрібен індивідуальний дитячий абонемент (групові та спліт-абонементи доступні від 6 років).'
                  : 'Абонемент призначений для вікової групи ${subRange?.$1 ?? 0}-${subRange?.$2 ?? 0} р. (вік дитини: $childAge р.).';
              result = BookingResult(
                isSuccess: false,
                message: subMsg,
                status: BookingStatus.error,
              );
              return;
            }
          }
        }
        
        final subData = Map<String, dynamic>.from(subDoc.data()! as Map);
        final remainingClasses = subData['remainingClasses'] as int;

        DateTime? subExpiry = effectiveSubscription.expiryDate;
        if (subData['expiryDate'] is Timestamp) {
          subExpiry = (subData['expiryDate'] as Timestamp).toDate();
        } else if (subData['expiryDate'] is String) {
          subExpiry = DateTime.tryParse(subData['expiryDate'] as String);
        }

        if (subExpiry != null) {
          final endOfExpiryDay = DateTime(subExpiry.year, subExpiry.month, subExpiry.day, 23, 59, 59);
          if (groupClass.startTime.isAfter(endOfExpiryDay)) {
            final expiryStr = DateFormat('dd.MM.yyyy').format(subExpiry);
            final dateStr = DateFormat('dd.MM.yyyy').format(groupClass.startTime);
            result = BookingResult(
              isSuccess: false,
              message: 'Термін дії абонемента закінчується $expiryStr (до дати тренування $dateStr).',
              status: BookingStatus.error,
            );
            return;
          }
        }

        if (groupClass.startTime.isBefore(DateTime.now())) {
          result = BookingResult.classPast;
          return;
        }

        for (final attId in attendeesToAdd) {
          if (groupClass.enrolledChildIds.contains(attId)) {
            result = BookingResult.alreadyBooked;
            return;
          }
        }

        if (groupClass.enrolledChildIds.length + attendeesToAdd.length > groupClass.maxCapacity) {
          result = BookingResult.classFull;
          return;
        }

        if (remainingClasses <= 0) {
          result = BookingResult.noSubscription;
          return;
        }

        // Time overlap check across other classes
        final conflictingClass = (state.value ?? []).firstWhereOrNull((c) {
          if (c.id == classId) return false;
          final overlaps = c.startTime.isBefore(groupClass.endTime) && c.endTime.isAfter(groupClass.startTime);
          if (!overlaps) return false;
          return c.enrolledChildIds.any((id) => attendeesToAdd.contains(id));
        });

        if (conflictingClass != null) {
          result = const BookingResult(
            isSuccess: false,
            message: 'Учень вже записаний на інше заняття у цей самий час. Оберіть інший час.',
            status: BookingStatus.error,
          );
          return;
        }

        List<String> newEnrolled = List.from(groupClass.enrolledChildIds)..addAll(attendeesToAdd);
        int newRemaining = remainingClasses - 1;
        
        final Map<String, dynamic> classUpdates = {
          'enrolledChildIds': newEnrolled,
        };
        for (final attId in attendeesToAdd) {
          classUpdates['bookedSubscriptions.$attId'] = effectiveSubscription.id;
        }

        transaction.update(classRef, classUpdates);
        transaction.update(subRef, {
          'remainingClasses': newRemaining,
          'isActive': newRemaining > 0
        });
        
        confirmedAttendees = List.from(attendeesToAdd);
        final enrolledNames = attendeesToAdd.map(getMemberName).join(' та ');
        result = groupClass.isSplit && attendeesToAdd.length == 2
            ? BookingResult(
                isSuccess: true,
                message: 'Спліт-заняття успішно заброньовано ($enrolledNames)!',
                status: BookingStatus.success,
              )
            : BookingResult.success;
      });
      
      if (result.isSuccess && bookedClass != null) {
        final enrolledNames = confirmedAttendees.isNotEmpty
            ? confirmedAttendees.map(getMemberName).join(' та ')
            : ownerName;
        _logActivity(
          type: ClassActivityType.booking,
          classId: classId,
          classTitle: bookedClass!.title,
          coachId: bookedClass!.coachId,
          coachName: bookedClass!.coachName,
          attendeeId: childId,
          attendeeName: enrolledNames,
          parentName: user.name,
          parentPhone: user.phone,
          message: 'Новий запис: $enrolledNames записався(-лась) на «${bookedClass!.title}»',
        );
      }

      return result;
    } catch (e) {
      debugPrint('Error booking class: $e');
      return BookingResult.error;
    }
  }

  Future<bool> cancelClass(
    String classId, 
    String childId, {
    String? targetUserId,
    String? targetOwnerName,
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    final family = ref.read(familyStreamProvider).value;
    final effectiveUserId = targetUserId ?? user.id;
    String ownerName = targetOwnerName ?? user.name;
    if (targetOwnerName == null && childId != effectiveUserId) {
       if (family != null && family.parentNames.containsKey(childId) && family.parentNames[childId]!.trim().isNotEmpty) {
         ownerName = family.parentNames[childId]!;
       } else {
         final childrenAsync = ref.read(childrenControllerProvider);
         final children = childrenAsync.value ?? [];
         try {
           ownerName = children.firstWhere((c) => c.id == childId).name;
         } catch (e) {
           // ignore
         }
       }
    }

    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final subscription = subscriptionController.getAnySubscriptionForOwner(effectiveUserId, ownerName);
    
    try {
      final classRef = FirebaseFirestore.instance.collection('classes').doc(classId);
      
      bool success = false;
      GroupClass? cancelledClass;
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final classDoc = await transaction.get(classRef);
        
        if (!classDoc.exists) return;
        
        final data = Map<String, dynamic>.from(classDoc.data()! as Map);
        data['id'] = classDoc.id;
        final groupClass = GroupClass.fromJson(data);
        cancelledClass = groupClass;
        
        if (groupClass.startTime.isBefore(DateTime.now())) {
          return;
        }

        if (groupClass.enrolledChildIds.contains(childId)) {
          final isSplitClass = groupClass.isSplit;
          // For Split training: cancel booking for BOTH participants
          final List<String> membersToRemove = isSplitClass
              ? List<String>.from(groupClass.enrolledChildIds)
              : [childId];

          List<String> newEnrolled = List.from(groupClass.enrolledChildIds);
          for (final mId in membersToRemove) {
            newEnrolled.remove(mId);
          }

          final bookedSubMap = data['bookedSubscriptions'] as Map?;
          final Set<String> refundedSubIds = {};

          for (final mId in membersToRemove) {
            final bookedSubId = bookedSubMap?[mId] as String?;
            final targetSubId = bookedSubId ?? subscription?.id;

            if (targetSubId != null && !refundedSubIds.contains(targetSubId)) {
              refundedSubIds.add(targetSubId);
              final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(targetSubId);
              final subDoc = await transaction.get(subRef);
              if (subDoc.exists) {
                final subData = Map<String, dynamic>.from(subDoc.data()! as Map);
                final remainingClasses = subData['remainingClasses'] as int? ?? 0;
                final totalClasses = subData['totalClasses'] as int? ?? remainingClasses;
                if (remainingClasses < totalClasses) {
                  int newRemaining = (remainingClasses + 1).clamp(0, totalClasses);
                  transaction.update(subRef, {
                    'remainingClasses': newRemaining,
                    'isActive': true,
                  });
                }
              }
            }
          }
          
          final isCustomBooking = data['isCustomBooking'] == true || data['createdByRole'] == 'parent';
          if (newEnrolled.isEmpty && isCustomBooking) {
            transaction.delete(classRef);
          } else {
            final Map<String, dynamic> classUpdates = {'enrolledChildIds': newEnrolled};
            for (final mId in membersToRemove) {
              if (bookedSubMap?.containsKey(mId) == true) {
                classUpdates['bookedSubscriptions.$mId'] = FieldValue.delete();
              }
            }
            transaction.update(classRef, classUpdates);
          }
          
          success = true;
        }
      });
      
      if (success && cancelledClass != null) {
        _logActivity(
          type: ClassActivityType.cancellation,
          classId: classId,
          classTitle: cancelledClass!.title,
          coachId: cancelledClass!.coachId,
          coachName: cancelledClass!.coachName,
          attendeeId: childId,
          attendeeName: ownerName,
          parentName: childId != user.id ? user.name : null,
          parentPhone: user.phone,
          message: cancelledClass!.isSplit
              ? 'Скасування спліт-заняття: скасовано запис обох учасників на «${cancelledClass!.title}»'
              : 'Скасування: $ownerName скасував(-ла) запис на «${cancelledClass!.title}»',
        );
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createClass({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String coachId,
    required String coachName,
    required int maxCapacity,
    required String category,
    required String lane,
    List<String> enrolledChildIds = const [],
    bool isCustomBooking = false,
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    // Collision check (Lane, Coach, and Enrolled Members) - authoritative
    final conflict = await checkAuthoritativeConflict(
      startTime: startTime,
      endTime: endTime,
      lane: lane,
      coachId: coachId,
      enrolledChildIds: enrolledChildIds,
    );
    if (conflict != null) {
      lastConflict = conflict;
      debugPrint('Conflict in createClass: ${conflict.message}');
      return false;
    }
    lastConflict = null;

    Subscription? subscription;
    final Map<String, Subscription> memberSubscriptions = {};
    final Map<String, int> deductionCounts = {};
    
    if (enrolledChildIds.isNotEmpty) {
      final titleLower = title.toLowerCase();
      final isSplit = titleLower.contains('спліт') || titleLower.contains('split');
      final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
      final userSubs = subscriptionController.getSubscriptionsForUser(user.id);
      final family = ref.read(familyStreamProvider).value;
      final familyParentIds = (family != null && family.parentIds.isNotEmpty) ? family.parentIds : [user.id];

      if (isSplit) {
        // Priority 1: dedicated active split subscription of user
        subscription = userSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
          (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
        );

        // Priority 2: dedicated active split subscription of partner
        if (subscription == null && family != null) {
          for (final pId in family.parentIds) {
            if (pId != user.id) {
              final partnerSubs = subscriptionController.getSubscriptionsForUser(pId);
              subscription = partnerSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
                (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
              );
              if (subscription != null) break;
            }
          }
        }

        if (subscription == null || subscription.remainingClasses <= 0) {
          lastConflict = const ClassConflict(
            type: ClassConflictType.participantConflict,
            message: 'Відсутній активний спліт-абонемент або закінчилися заняття.',
          );
          return false;
        }

        if (subscription.expiryDate != null) {
          final endOfExpiryDay = DateTime(
            subscription.expiryDate!.year,
            subscription.expiryDate!.month,
            subscription.expiryDate!.day,
            23, 59, 59,
          );
          if (startTime.isAfter(endOfExpiryDay)) {
            final expiryStr = DateFormat('dd.MM.yyyy').format(subscription.expiryDate!);
            final dateStr = DateFormat('dd.MM.yyyy').format(startTime);
            lastConflict = ClassConflict(
              type: ClassConflictType.subscriptionExpired,
              message: 'Термін дії спліт-абонемента закінчується $expiryStr (до обраної дати тренування $dateStr).',
            );
            return false;
          }
        }
      } else {
        // Non-split: each participant in enrolledChildIds must have a subscription
        final isChildService = titleLower.contains('діт') || titleLower.contains('дитяч') || titleLower.contains('junior');
        final isAdultService = titleLower.contains('доросла') || titleLower.contains('дорослих') || titleLower.contains('adult') || titleLower.contains('аквааеробіка');

        for (final attId in enrolledChildIds) {
          final isAttAdult = attId == user.id || familyParentIds.contains(attId);
          String ownerName = user.name;
          if (!isAttAdult) {
            final childrenAsync = ref.read(childrenControllerProvider);
            final children = childrenAsync.value ?? [];
            try {
              ownerName = children.firstWhere((c) => c.id == attId).name;
            } catch (_) {}
          } else if (attId != user.id && family != null && family.parentNames.containsKey(attId)) {
            ownerName = family.parentNames[attId]!;
          }

          if (isAttAdult && isChildService) return false;
          if (!isAttAdult && isAdultService) return false;

          Subscription? sub = subscriptionController.getSubscriptionForOwner(attId, ownerName, isAdult: isAttAdult, isSplit: false, familyUserIds: familyParentIds);
          sub ??= subscriptionController.getSubscriptionForOwner(user.id, ownerName, isAdult: isAttAdult, isSplit: false, familyUserIds: familyParentIds);

          if (sub == null || sub.isSplitSubscription) {
            lastConflict = ClassConflict(
              type: ClassConflictType.participantConflict,
              message: 'Відсутній абонемент для $ownerName.',
            );
            return false;
          }

          final alreadyUsed = deductionCounts[sub.id] ?? 0;
          if (sub.remainingClasses - alreadyUsed <= 0) {
            lastConflict = ClassConflict(
              type: ClassConflictType.participantConflict,
              message: 'Недостатньо занять в абонементі для $ownerName.',
            );
            return false;
          }

          if (sub.expiryDate != null) {
            final endOfExpiryDay = DateTime(
              sub.expiryDate!.year,
              sub.expiryDate!.month,
              sub.expiryDate!.day,
              23, 59, 59,
            );
            if (startTime.isAfter(endOfExpiryDay)) {
              final expiryStr = DateFormat('dd.MM.yyyy').format(sub.expiryDate!);
              final dateStr = DateFormat('dd.MM.yyyy').format(startTime);
              lastConflict = ClassConflict(
                type: ClassConflictType.subscriptionExpired,
                message: 'Термін дії абонемента для $ownerName закінчується $expiryStr (до обраної дати тренування $dateStr).',
              );
              return false;
            }
          }

          memberSubscriptions[attId] = sub;
          deductionCounts[sub.id] = alreadyUsed + 1;
        }
      }
    }

    try {
      final newClassRef = FirebaseFirestore.instance.collection('classes').doc();
      final newClass = GroupClass(
        id: newClassRef.id,
        title: title,
        startTime: startTime,
        endTime: endTime,
        coachId: coachId,
        coachName: coachName,
        maxCapacity: maxCapacity,
        enrolledChildIds: enrolledChildIds,
        category: category,
        lane: lane,
      );

      if (subscription != null) {
        final activeSub = subscription;
        final String subId = activeSub.id;
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(subId);
          final subDoc = await transaction.get(subRef);
          
          if (!subDoc.exists) throw Exception("Subscription missing");
          
          final subData = Map<String, dynamic>.from(subDoc.data()! as Map);
          final remainingClasses = subData['remainingClasses'] as int;
          
          if (remainingClasses <= 0) throw Exception("No classes left");

          DateTime? subExpiry = activeSub.expiryDate;
          if (subData['expiryDate'] is Timestamp) {
            subExpiry = (subData['expiryDate'] as Timestamp).toDate();
          } else if (subData['expiryDate'] is String) {
            subExpiry = DateTime.tryParse(subData['expiryDate'] as String);
          }
          if (subExpiry != null) {
            final endOfExpiryDay = DateTime(subExpiry.year, subExpiry.month, subExpiry.day, 23, 59, 59);
            if (startTime.isAfter(endOfExpiryDay)) {
              throw Exception("Subscription expired before class date");
            }
          }
          
          int newRemaining = remainingClasses - 1;
          
          final classMap = newClass.toJson();
          if (isCustomBooking || user.role == UserRole.parent) {
            classMap['isCustomBooking'] = true;
            classMap['createdByRole'] = user.role.name;
          }
          if (enrolledChildIds.isNotEmpty) {
            final bookedMap = <String, String>{};
            for (final eId in enrolledChildIds) {
              bookedMap[eId] = subId;
            }
            classMap['bookedSubscriptions'] = bookedMap;
          }

          transaction.set(newClassRef, classMap);
          transaction.update(subRef, {
            'remainingClasses': newRemaining,
            'isActive': newRemaining > 0
          });
        });
      } else if (memberSubscriptions.isNotEmpty) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final Map<String, int> currentRemainings = {};
          for (final subId in deductionCounts.keys) {
            final sRef = FirebaseFirestore.instance.collection('subscriptions').doc(subId);
            final sDoc = await transaction.get(sRef);
            if (!sDoc.exists) throw Exception("Subscription missing: $subId");
            final rem = (sDoc.data()!['remainingClasses'] as num).toInt();
            final needed = deductionCounts[subId]!;
            if (rem < needed) throw Exception("Not enough classes in subscription $subId");

            DateTime? subExpiry = memberSubscriptions.values.firstWhereOrNull((s) => s.id == subId)?.expiryDate;
            if (sDoc.data()!['expiryDate'] is Timestamp) {
              subExpiry = (sDoc.data()!['expiryDate'] as Timestamp).toDate();
            } else if (sDoc.data()!['expiryDate'] is String) {
              subExpiry = DateTime.tryParse(sDoc.data()!['expiryDate'] as String);
            }
            if (subExpiry != null) {
              final endOfExpiryDay = DateTime(subExpiry.year, subExpiry.month, subExpiry.day, 23, 59, 59);
              if (startTime.isAfter(endOfExpiryDay)) {
                throw Exception("Subscription expired before class date");
              }
            }

            currentRemainings[subId] = rem - needed;
          }

          final classMap = newClass.toJson();
          if (isCustomBooking || user.role == UserRole.parent) {
            classMap['isCustomBooking'] = true;
            classMap['createdByRole'] = user.role.name;
          }
          final bookedMap = <String, String>{};
          for (final entry in memberSubscriptions.entries) {
            bookedMap[entry.key] = entry.value.id;
          }
          classMap['bookedSubscriptions'] = bookedMap;

          transaction.set(newClassRef, classMap);
          for (final entry in currentRemainings.entries) {
            final sRef = FirebaseFirestore.instance.collection('subscriptions').doc(entry.key);
            transaction.update(sRef, {
              'remainingClasses': entry.value,
              'isActive': entry.value > 0,
            });
          }
        });
      } else {
        final classMap = newClass.toJson();
        if (isCustomBooking || user.role == UserRole.parent) {
          classMap['isCustomBooking'] = true;
          classMap['createdByRole'] = user.role.name;
        }
        await newClassRef.set(classMap);
      }
      
      // Optimistically update state so consecutive creations see the new class instantly
      final current = state.value ?? [];
      state = AsyncData([...current, newClass]);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<CreateRecurringClassesResult> createRecurringClasses({
    required String title,
    required DateTime startDate,
    required int hour,
    required int minute,
    int durationMinutes = 60,
    required Set<int> weekdays,
    required int durationWeeks,
    required String coachId,
    required String coachName,
    required int maxCapacity,
    required String category,
    required String lane,
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) {
      return const CreateRecurringClassesResult(createdCount: 0);
    }

    try {
      final List<DateTime> validStartTimes = [];
      final List<DateTime> skippedDates = [];
      final List<ClassConflict> conflicts = [];
      final totalDays = durationWeeks * 7;
      final baseDate = DateTime(startDate.year, startDate.month, startDate.day);
      final rangeEnd = baseDate.add(Duration(days: totalDays + 1));

      // Fetch all existing classes in the full recurring range from Firestore to be authoritative
      final snap = await FirebaseFirestore.instance
          .collection('classes')
          .where('startTime', isGreaterThanOrEqualTo: baseDate.toIso8601String())
          .where('startTime', isLessThan: rangeEnd.toIso8601String())
          .get();

      final Map<String, GroupClass> allKnownClasses = {};
      for (final c in (state.value ?? [])) {
        allKnownClasses[c.id] = c;
      }
      for (final doc in snap.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['id'] = doc.id;
          if (data['startTime'] is Timestamp) {
            data['startTime'] = (data['startTime'] as Timestamp).toDate().toIso8601String();
          }
          if (data['endTime'] is Timestamp) {
            data['endTime'] = (data['endTime'] as Timestamp).toDate().toIso8601String();
          }
          allKnownClasses[doc.id] = GroupClass.fromJson(data);
        } catch (_) {}
      }

      final List<GroupClass> existingList = allKnownClasses.values.toList();
      final List<GroupClass> newlyGenerated = [];

      for (int i = 0; i < totalDays; i++) {
        final date = baseDate.add(Duration(days: i));
        if (weekdays.contains(date.weekday)) {
          final classStart = DateTime(date.year, date.month, date.day, hour, minute);
          final classEnd = classStart.add(Duration(minutes: durationMinutes));

          final combined = [...existingList, ...newlyGenerated];
          final conflict = _evaluateConflictAgainst(
            classes: combined,
            startTime: classStart,
            endTime: classEnd,
            lane: lane,
            coachId: coachId,
          );

          if (conflict != null) {
            skippedDates.add(classStart);
            conflicts.add(conflict);
          } else {
            validStartTimes.add(classStart);
            newlyGenerated.add(GroupClass(
              id: 'temp_${classStart.millisecondsSinceEpoch}',
              title: title,
              startTime: classStart,
              endTime: classEnd,
              coachId: coachId,
              coachName: coachName,
              maxCapacity: maxCapacity,
              category: category,
              lane: lane,
            ));
          }
        }
      }

      if (validStartTimes.isEmpty) {
        return CreateRecurringClassesResult(
          createdCount: 0,
          skippedDates: skippedDates,
          conflicts: conflicts,
        );
      }

      final firestore = FirebaseFirestore.instance;
      const chunkSize = 400;
      final List<GroupClass> createdClasses = [];

      for (int i = 0; i < validStartTimes.length; i += chunkSize) {
        final chunk = validStartTimes.sublist(
          i,
          (i + chunkSize > validStartTimes.length) ? validStartTimes.length : i + chunkSize,
        );
        final batch = firestore.batch();
        for (final st in chunk) {
          final docRef = firestore.collection('classes').doc();
          final et = st.add(Duration(minutes: durationMinutes));
          final groupClass = GroupClass(
            id: docRef.id,
            title: title,
            startTime: st,
            endTime: et,
            coachId: coachId,
            coachName: coachName,
            maxCapacity: maxCapacity,
            enrolledChildIds: const [],
            attendedChildIds: const [],
            category: category,
            lane: lane,
          );
          batch.set(docRef, groupClass.toJson());
          createdClasses.add(groupClass);
        }
        await batch.commit();
      }

      // Optimistically update state so newly created recurring classes are immediately visible
      final current = state.value ?? [];
      state = AsyncData([...current, ...createdClasses]);

      return CreateRecurringClassesResult(
        createdCount: validStartTimes.length,
        skippedDates: skippedDates,
        conflicts: conflicts,
      );
    } catch (e) {
      debugPrint('Error creating recurring classes: $e');
      return const CreateRecurringClassesResult(createdCount: 0);
    }
  }

  Future<bool> updateClass({
    required String classId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String coachId,
    required String coachName,
    required int maxCapacity,
    required String category,
    required String lane,
  }) async {
    final conflict = await checkAuthoritativeConflict(
      startTime: startTime,
      endTime: endTime,
      lane: lane,
      coachId: coachId,
      excludeClassId: classId,
    );
    if (conflict != null) {
      lastConflict = conflict;
      debugPrint('Conflict in updateClass: ${conflict.message}');
      return false;
    }
    lastConflict = null;

    try {
      await FirebaseFirestore.instance.collection('classes').doc(classId).update({
        'title': title,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'coachId': coachId,
        'coachName': coachName,
        'maxCapacity': maxCapacity,
        'category': category,
        'lane': lane,
      });
      final timeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      _logActivity(
        type: ClassActivityType.rescheduled,
        classId: classId,
        classTitle: title,
        coachId: coachId,
        coachName: coachName,
        message: 'Зміна в розкладі: «$title» ($timeStr${lane.isNotEmpty ? ", $lane" : ""})',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteClass(String classId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('classes').doc(classId).get();
      String title = 'Заняття';
      String coachId = '';
      String coachName = '';
      List<String> enrolledChildIds = [];
      Map<String, dynamic>? bookedSubMap;

      if (doc.exists) {
        final data = doc.data()!;
        title = data['title'] as String? ?? title;
        coachId = data['coachId'] as String? ?? coachId;
        coachName = data['coachName'] as String? ?? coachName;
        enrolledChildIds = List<String>.from(data['enrolledChildIds'] ?? []);
        if (data['bookedSubscriptions'] is Map) {
          bookedSubMap = Map<String, dynamic>.from(data['bookedSubscriptions'] as Map);
        }
      }

      // Auto-refund each enrolled attendee accurately
      if (enrolledChildIds.isNotEmpty) {
        final Set<String> refundedSubIds = {};
        for (final childId in enrolledChildIds) {
          try {
            final bookedSubId = bookedSubMap?[childId] as String?;
            if (bookedSubId != null && !refundedSubIds.contains(bookedSubId)) {
              refundedSubIds.add(bookedSubId);
              final subDoc = await FirebaseFirestore.instance.collection('subscriptions').doc(bookedSubId).get();
              if (subDoc.exists) {
                final subData = subDoc.data()!;
                final curRemaining = (subData['remainingClasses'] as int? ?? 0);
                final totalClasses = (subData['totalClasses'] as int? ?? curRemaining + 1);
                await subDoc.reference.update({
                  'remainingClasses': (curRemaining + 1).clamp(0, totalClasses),
                  'isActive': true,
                });
                continue; // Successfully refunded directly
              }
            }

            // Fallback lookup if not tracked in bookedSubscriptions
            String? parentId;
            String? ownerName;

            final childDoc = await FirebaseFirestore.instance.collection('children').doc(childId).get();
            if (childDoc.exists) {
              final cData = childDoc.data()!;
              parentId = cData['parentId'] as String?;
              ownerName = cData['name'] as String?;
            } else {
              // Direct user
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(childId).get();
              if (userDoc.exists) {
                parentId = childId;
                ownerName = userDoc.data()?['name'] as String?;
              }
            }

            if (parentId != null) {
              final subsSnap = await FirebaseFirestore.instance
                  .collection('subscriptions')
                  .where('userId', isEqualTo: parentId)
                  .get();

              DocumentSnapshot? targetSub;
              if (subsSnap.docs.isNotEmpty) {
                if (ownerName != null) {
                  for (final sDoc in subsSnap.docs) {
                    if (sDoc.data()['ownerName'] == ownerName) {
                      targetSub = sDoc;
                      break;
                    }
                  }
                }
                targetSub ??= subsSnap.docs.firstWhere(
                  (sDoc) {
                    final sName = (sDoc.data()['serviceName'] as String? ?? '').toLowerCase();
                    return sName.contains('спліт') || sName.contains('сім');
                  },
                  orElse: () => subsSnap.docs.first,
                );

                if (!refundedSubIds.contains(targetSub.id)) {
                  refundedSubIds.add(targetSub.id);
                  final subData = targetSub.data() as Map<String, dynamic>;
                  final curRemaining = (subData['remainingClasses'] as int? ?? 0);
                  final totalClasses = (subData['totalClasses'] as int? ?? curRemaining + 1);
                  await targetSub.reference.update({
                    'remainingClasses': (curRemaining + 1).clamp(0, totalClasses),
                    'isActive': true,
                  });
                }
              }
            }
          } catch (refundErr) {
            debugPrint('Error refunding attendee $childId: $refundErr');
          }
        }
      }

      await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
      _logActivity(
        type: ClassActivityType.classCancelled,
        classId: classId,
        classTitle: title,
        coachId: coachId,
        coachName: coachName,
        message: 'Заняття «$title» скасовано адміністратором${enrolledChildIds.isNotEmpty ? ' (повернено ${enrolledChildIds.length} занять учням)' : ''}',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _logActivity({
    required ClassActivityType type,
    required String classId,
    required String classTitle,
    required String coachId,
    required String coachName,
    String? attendeeId,
    String? attendeeName,
    String? parentName,
    String? parentPhone,
    required String message,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('class_activities').doc();
      final act = ClassActivity(
        id: docRef.id,
        type: type,
        classId: classId,
        classTitle: classTitle,
        coachId: coachId,
        coachName: coachName,
        attendeeId: attendeeId,
        attendeeName: attendeeName,
        parentName: parentName,
        parentPhone: parentPhone,
        timestamp: DateTime.now(),
        message: message,
      );
      await docRef.set(act.toJson());
    } catch (e) {
      debugPrint('Error logging class activity: $e');
    }
  }
}

