import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/models/class_activity.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

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
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return GroupClass.fromJson(data);
      }).toList();
    });
  }

  Future<BookingResult> bookClass(
    String classId, 
    String childId, {
    String? targetUserId,
    String? targetOwnerName,
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return BookingResult.error;

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

    // Get the subscription for effective user
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final subscription = subscriptionController.getSubscriptionForOwner(effectiveUserId, ownerName);
    
    if (subscription == null || subscription.remainingClasses <= 0 || !subscription.isActive) {
      return BookingResult.noSubscription;
    }

    try {
      final classRef = FirebaseFirestore.instance.collection('classes').doc(classId);
      final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(subscription.id);
      
      BookingResult result = BookingResult.error;
      GroupClass? bookedClass;

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
        
        final subData = Map<String, dynamic>.from(subDoc.data()! as Map);
        final remainingClasses = subData['remainingClasses'] as int;

        if (groupClass.enrolledChildIds.contains(childId)) {
          result = BookingResult.alreadyBooked;
          return;
        }

        if (groupClass.enrolledChildIds.length >= groupClass.maxCapacity) {
          result = BookingResult.classFull;
          return;
        }

        if (remainingClasses <= 0) {
          result = BookingResult.noSubscription;
          return;
        }
        
        List<String> newEnrolled = List.from(groupClass.enrolledChildIds)..add(childId);
        int newRemaining = remainingClasses - 1;
        
        transaction.update(classRef, {'enrolledChildIds': newEnrolled});
        transaction.update(subRef, {
          'remainingClasses': newRemaining,
          'isActive': newRemaining > 0
        });
        
        result = BookingResult.success;
      });
      
      if (result.isSuccess && bookedClass != null) {
        _logActivity(
          type: ClassActivityType.booking,
          classId: classId,
          classTitle: bookedClass!.title,
          coachId: bookedClass!.coachId,
          coachName: bookedClass!.coachName,
          attendeeId: childId,
          attendeeName: ownerName,
          parentName: childId != user.id ? user.name : null,
          parentPhone: user.phone,
          message: 'Новий запис: $ownerName записався(-лась) на «${bookedClass!.title}»',
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
        
        if (groupClass.enrolledChildIds.contains(childId)) {
          List<String> newEnrolled = List.from(groupClass.enrolledChildIds)..remove(childId);
          
          DocumentSnapshot? subDoc;
          DocumentReference? subRef;
          if (subscription != null) {
            subRef = FirebaseFirestore.instance.collection('subscriptions').doc(subscription.id);
            subDoc = await transaction.get(subRef);
          }
          
          if (newEnrolled.isEmpty && (groupClass.category == 'Індивідуальне' || groupClass.maxCapacity <= 2)) {
            transaction.delete(classRef);
          } else {
            transaction.update(classRef, {'enrolledChildIds': newEnrolled});
          }

          if (subDoc != null && subDoc.exists && subRef != null) {
            final subData = Map<String, dynamic>.from(subDoc.data()! as Map);
            final remainingClasses = subData['remainingClasses'] as int;
            int newRemaining = remainingClasses + 1;
            transaction.update(subRef, {
              'remainingClasses': newRemaining,
              'isActive': true
            });
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
          message: 'Скасування: $ownerName скасував(-ла) запис на «${cancelledClass!.title}»',
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
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    Subscription? subscription;
    
    if (enrolledChildIds.isNotEmpty) {
      final childId = enrolledChildIds.first;
      String ownerName = user.name;
      if (childId != user.id) {
         final childrenAsync = ref.read(childrenControllerProvider);
         final children = childrenAsync.value ?? [];
          try {
            ownerName = children.firstWhere((c) => c.id == childId).name;
          } catch (_) {
            // Child not found in list, fallback to user.name
          }
      }
      final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
      subscription = subscriptionController.getSubscriptionForOwner(user.id, ownerName);
      
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
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(subscription!.id);
          final subDoc = await transaction.get(subRef);
          
          if (!subDoc.exists) throw Exception("Subscription missing");
          
          final subData = Map<String, dynamic>.from(subDoc.data()! as Map);
          final remainingClasses = subData['remainingClasses'] as int;
          
          if (remainingClasses <= 0) throw Exception("No classes left");
          
          int newRemaining = remainingClasses - 1;
          
          transaction.set(newClassRef, newClass.toJson());
          transaction.update(subRef, {
            'remainingClasses': newRemaining,
            'isActive': newRemaining > 0
          });
        });
      } else {
        await newClassRef.set(newClass.toJson());
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

      if (doc.exists) {
        final data = doc.data()!;
        title = data['title'] as String? ?? title;
        coachId = data['coachId'] as String? ?? coachId;
        coachName = data['coachName'] as String? ?? coachName;
        enrolledChildIds = List<String>.from(data['enrolledChildIds'] ?? []);
      }

      // Auto-refund each enrolled attendee
      if (enrolledChildIds.isNotEmpty) {
        for (final childId in enrolledChildIds) {
          try {
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

                final subData = targetSub.data() as Map<String, dynamic>;
                final curRemaining = (subData['remainingClasses'] as int? ?? 0);
                await targetSub.reference.update({
                  'remainingClasses': curRemaining + 1,
                  'isActive': true,
                });
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

