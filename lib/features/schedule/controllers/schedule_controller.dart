import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';

part 'schedule_controller.g.dart';

@riverpod
class ScheduleController extends _$ScheduleController {
  @override
  Stream<List<GroupClass>> build() {
    return FirebaseFirestore.instance
        .collection('classes')
        .where('startTime', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 1)))
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupClass.fromJson({'id': doc.id, ...doc.data()})).toList();
    });
  }

  Future<bool> bookClass(String classId) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    // Get the current user subscription
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final subscription = subscriptionController.getSubscriptionForUser(user.id);
    
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
        
        final groupClass = GroupClass.fromJson({'id': classDoc.id, ...classDoc.data()!});
        final remainingClasses = subDoc.data()!['remainingClasses'] as int;
        
        if (remainingClasses > 0 && groupClass.enrolledUserIds.length < groupClass.maxCapacity && !groupClass.enrolledUserIds.contains(user.id)) {
          // Both conditions met: class has space, user has remaining classes
          List<String> newEnrolled = List.from(groupClass.enrolledUserIds)..add(user.id);
          int newRemaining = remainingClasses - 1;
          
          transaction.update(classRef, {'enrolledUserIds': newEnrolled});
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
}
