import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/subscription.dart';
import '../repositories/mock_db.dart';

part 'subscription_controller.g.dart';

@riverpod
class SubscriptionController extends _$SubscriptionController {
  @override
  List<Subscription> build() {
    // Return all mock subscriptions
    return MockDB.subscriptions;
  }

  Subscription? getSubscriptionForUser(String userId) {
    try {
      return state.firstWhere((sub) => sub.userId == userId);
    } catch (e) {
      return null;
    }
  }

  bool deductClass(String userId) {
    final subIndex = state.indexWhere((sub) => sub.userId == userId);
    if (subIndex == -1) return false;

    final sub = state[subIndex];
    if (sub.remainingClasses > 0 && sub.isActive) {
      final updatedSub = sub.copyWith(remainingClasses: sub.remainingClasses - 1);
      final newState = [...state];
      newState[subIndex] = updatedSub;
      state = newState;
      return true;
    }
    return false;
  }
}
