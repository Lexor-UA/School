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

@riverpod
class ScheduleController extends _$ScheduleController {
  @override
  Stream<List<GroupClass>> build() {
    return FirebaseFirestore.instance
        .collection('classes')
        .where('startTime', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 1)).toIso8601String())
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

  Future<bool> bookClass(String classId, String childId) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    String ownerName = user.name;
    if (childId != user.id) {
       final childrenAsync = ref.read(childrenControllerProvider);
       final children = childrenAsync.value ?? [];
       try {
         ownerName = children.firstWhere((c) => c.id == childId).name;
       } catch (e) {
         // ignore
       }
    }

    // Get the current user subscription
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final subscription = subscriptionController.getSubscriptionForOwner(user.id, ownerName);
    
    if (subscription == null || subscription.remainingClasses <= 0 || !subscription.isActive) {
      return false; // Not enough classes
    }

    try {
      final classRef = FirebaseFirestore.instance.collection('classes').doc(classId);
      final subRef = FirebaseFirestore.instance.collection('subscriptions').doc(subscription.id);
      
      bool success = false;
      
      GroupClass? bookedClass;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final classDoc = await transaction.get(classRef);
        final subDoc = await transaction.get(subRef);
        
        if (!classDoc.exists || !subDoc.exists) {
          return; // Document missing
        }
        
        final data = Map<String, dynamic>.from(classDoc.data()! as Map);
        data['id'] = classDoc.id;
        final groupClass = GroupClass.fromJson(data);
        bookedClass = groupClass;
        
        final subData = Map<String, dynamic>.from(subDoc.data()! as Map);
        final remainingClasses = subData['remainingClasses'] as int;
        
        if (remainingClasses > 0 && groupClass.enrolledChildIds.length < groupClass.maxCapacity && !groupClass.enrolledChildIds.contains(childId)) {
          // Both conditions met: class has space, user has remaining classes
          List<String> newEnrolled = List.from(groupClass.enrolledChildIds)..add(childId);
          int newRemaining = remainingClasses - 1;
          
          transaction.update(classRef, {'enrolledChildIds': newEnrolled});
          transaction.update(subRef, {
            'remainingClasses': newRemaining,
            'isActive': newRemaining > 0
          });
          
          success = true;
        }
      });
      
      if (success && bookedClass != null) {
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

      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelClass(String classId, String childId) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    String ownerName = user.name;
    if (childId != user.id) {
       final childrenAsync = ref.read(childrenControllerProvider);
       final children = childrenAsync.value ?? [];
       try {
         ownerName = children.firstWhere((c) => c.id == childId).name;
       } catch (e) {
         // ignore
       }
    }

    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final subscription = subscriptionController.getAnySubscriptionForOwner(user.id, ownerName);
    
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
      if (doc.exists) {
        final data = doc.data()!;
        title = data['title'] as String? ?? title;
        coachId = data['coachId'] as String? ?? coachId;
        coachName = data['coachName'] as String? ?? coachName;
      }
      await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
      _logActivity(
        type: ClassActivityType.classCancelled,
        classId: classId,
        classTitle: title,
        coachId: coachId,
        coachName: coachName,
        message: 'Заняття «$title» скасовано адміністратором',
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

