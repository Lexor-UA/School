import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

part 'schedule_controller.g.dart';

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
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final classDoc = await transaction.get(classRef);
        final subDoc = await transaction.get(subRef);
        
        if (!classDoc.exists || !subDoc.exists) {
          return; // Document missing
        }
        
        final data = Map<String, dynamic>.from(classDoc.data()! as Map);
        data['id'] = classDoc.id;
        final groupClass = GroupClass.fromJson(data);
        
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
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final classDoc = await transaction.get(classRef);
        
        if (!classDoc.exists) return;
        
        final data = Map<String, dynamic>.from(classDoc.data()! as Map);
        data['id'] = classDoc.id;
        final groupClass = GroupClass.fromJson(data);
        
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
         } catch (e) {}
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

  Future<bool> deleteClass(String classId) async {
    try {
      await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
