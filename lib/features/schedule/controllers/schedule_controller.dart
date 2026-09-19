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
import 'package:collection/collection.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';

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

@riverpod
class ScheduleController extends _$ScheduleController {
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

    String getMemberName(String id) {
      if (id == user.id) return user.name;
      final ch = children.where((c) => c.id == id).firstOrNull;
      if (ch != null) return ch.name;
      return id;
    }

    String ownerName = targetOwnerName ?? getMemberName(childId);
    final isAdult = childId == effectiveUserId;

    // Get the subscription for effective user
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final subscription = subscriptionController.getSubscriptionForOwner(effectiveUserId, ownerName, isAdult: isAdult);
    
    if (subscription == null || subscription.remainingClasses <= 0 || !subscription.isActive) {
      return BookingResult.noSubscription;
    }

    try {
      final classRef = FirebaseFirestore.instance.collection('classes').doc(classId);
      final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(subscription.id);
      
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

        // Determine all members to enroll
        final List<String> attendeesToAdd = [childId];
        if (groupClass.isSplit && groupClass.enrolledChildIds.isEmpty) {
          if (secondParticipantId != null && secondParticipantId != childId) {
            attendeesToAdd.add(secondParticipantId);
          } else if (autoEnrollFamilyForSplit) {
            if (childId != user.id) {
              attendeesToAdd.add(user.id);
            } else {
              // If parent booked and there is only 1 child, auto-pair with that child
              if (children.length == 1) {
                attendeesToAdd.add(children.first.id);
              } else if (children.length > 1) {
                // If there are multiple children, DO NOT guess! Force selection.
                result = const BookingResult(
                  isSuccess: false,
                  message: 'Для спліт-тренування оберіть, кого саме з дітей записати разом з вами.',
                  status: BookingStatus.error,
                );
                return;
              }
            }
          }
        }

        // Validate each attendee
        for (final attId in attendeesToAdd) {
          final isAttAdult = attId == effectiveUserId;
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

          if (!isAttAdult) {
            final child = children.where((c) => c.id == attId).firstOrNull;
            final childAge = child?.currentAge;
            if (childAge != null && !groupClass.isAgeCompatible(childAge)) {
              final range = groupClass.ageRange;
              result = BookingResult(
                isSuccess: false,
                message: 'Вік дитини ${child?.name ?? ''} ($childAge р.) не відповідає віковій групі цього тренування (${range?.$1 ?? 0}-${range?.$2 ?? 0} р.).',
                status: BookingStatus.error,
              );
              return;
            }

            if (childAge != null && !subscription.isAgeCompatible(childAge)) {
              final subRange = subscription.ageRange;
              result = BookingResult(
                isSuccess: false,
                message: 'Абонемент призначений для вікової групи ${subRange?.$1 ?? 0}-${subRange?.$2 ?? 0} р. (вік дитини: $childAge р.).',
                status: BookingStatus.error,
              );
              return;
            }
          }
        }
        
        final subData = Map<String, dynamic>.from(subDoc.data()! as Map);
        final remainingClasses = subData['remainingClasses'] as int;

        DateTime? subExpiry;
        if (subData['expiryDate'] is Timestamp) {
          subExpiry = (subData['expiryDate'] as Timestamp).toDate();
        } else if (subData['expiryDate'] is String) {
          subExpiry = DateTime.tryParse(subData['expiryDate'] as String);
        }

        if (subExpiry != null) {
          final endOfExpiryDay = DateTime(subExpiry.year, subExpiry.month, subExpiry.day, 23, 59, 59);
          if (groupClass.startTime.isAfter(endOfExpiryDay)) {
            result = const BookingResult(
              isSuccess: false,
              message: 'Термін дії абонемента закінчується до дати цього тренування.',
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
          classUpdates['bookedSubscriptions.$attId'] = subscription.id;
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

    final effectiveUserId = targetUserId ?? user.id;
    String ownerName = targetOwnerName ?? user.name;
    if (targetOwnerName == null && childId != effectiveUserId) {
       final childrenAsync = ref.read(childrenControllerProvider);
       final children = childrenAsync.value ?? [];
       try {
         ownerName = children.firstWhere((c) => c.id == childId).name;
       } catch (e) {
         // ignore
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

    // Time collision check
    final currentClasses = state.value ?? [];
    final hasConflict = currentClasses.any((c) {
      final overlaps = c.startTime.isBefore(endTime) && c.endTime.isAfter(startTime);
      if (!overlaps) return false;
      return c.enrolledChildIds.any((id) => enrolledChildIds.contains(id));
    });
    if (hasConflict) {
      debugPrint('Conflict: Member already booked at this time');
      return false;
    }

    Subscription? subscription;
    
    if (enrolledChildIds.isNotEmpty) {
      final titleLower = title.toLowerCase();
      final isSplit = titleLower.contains('спліт') || titleLower.contains('split');
      final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
      final userSubs = subscriptionController.getSubscriptionsForUser(user.id);

      if (isSplit) {
        // Priority 1: dedicated active split subscription
        subscription = userSubs.where((s) => s.isActive && s.remainingClasses > 0).firstWhereOrNull(
          (s) => s.isSplitSubscription || (s.serviceName?.toLowerCase().contains('спліт') ?? false),
        );

        // Priority 2: subscription of either enrolled participant
        if (subscription == null) {
          final children = ref.read(childrenControllerProvider).value ?? [];
          for (final id in enrolledChildIds) {
            final isAdult = id == user.id;
            final name = isAdult ? user.name : (children.firstWhereOrNull((c) => c.id == id)?.name ?? user.name);
            final sub = subscriptionController.getSubscriptionForOwner(user.id, name, isAdult: isAdult);
            if (sub != null && sub.remainingClasses > 0) {
              subscription = sub;
              break;
            }
          }
        }

        // Priority 3: any active subscription with remaining classes
        subscription ??= userSubs.firstWhereOrNull((s) => s.isActive && s.remainingClasses > 0);
      } else {
        final childId = enrolledChildIds.first;
        final isAdult = childId == user.id;
        String ownerName = user.name;
        if (!isAdult) {
           final childrenAsync = ref.read(childrenControllerProvider);
           final children = childrenAsync.value ?? [];
            try {
              ownerName = children.firstWhere((c) => c.id == childId).name;
            } catch (_) {
              // Child not found in list, fallback to user.name
            }
        }

        final isChildService = titleLower.contains('діт') || titleLower.contains('дитяч') || titleLower.contains('junior');
        final isAdultService = titleLower.contains('доросла') || titleLower.contains('дорослих') || titleLower.contains('adult') || titleLower.contains('аквааеробіка');
        if (isAdult && isChildService) return false;
        if (!isAdult && isAdultService) return false;

        subscription = subscriptionController.getSubscriptionForOwner(user.id, ownerName, isAdult: isAdult);
      }
      
      if (subscription == null || subscription.remainingClasses <= 0) {
        return false;
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
      } else {
        final classMap = newClass.toJson();
        if (isCustomBooking || user.role == UserRole.parent) {
          classMap['isCustomBooking'] = true;
          classMap['createdByRole'] = user.role.name;
        }
        await newClassRef.set(classMap);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> createRecurringClasses({
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
    if (user == null) return 0;

    try {
      final List<DateTime> startTimes = [];
      final totalDays = durationWeeks * 7;
      final baseDate = DateTime(startDate.year, startDate.month, startDate.day);

      for (int i = 0; i < totalDays; i++) {
        final date = baseDate.add(Duration(days: i));
        if (weekdays.contains(date.weekday)) {
          final classStart = DateTime(date.year, date.month, date.day, hour, minute);
          startTimes.add(classStart);
        }
      }

      if (startTimes.isEmpty) return 0;

      final firestore = FirebaseFirestore.instance;
      const chunkSize = 400;

      for (int i = 0; i < startTimes.length; i += chunkSize) {
        final chunk = startTimes.sublist(
          i,
          (i + chunkSize > startTimes.length) ? startTimes.length : i + chunkSize,
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
        }
        await batch.commit();
      }

      return startTimes.length;
    } catch (e) {
      debugPrint('Error creating recurring classes: $e');
      return 0;
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

