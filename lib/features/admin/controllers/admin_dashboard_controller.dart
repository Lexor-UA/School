import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/admin/models/admin_task.dart';
import 'package:swimming_school_app/features/admin/models/activity_log.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

part 'admin_dashboard_controller.g.dart';

class AdminDashboardState {
  final List<GroupClass> todayClasses;
  final int activeUpcomingClassesCount;
  final int activeClientsCount;
  final int totalCoachesCount;
  final int todayClientsCount;
  final int todayCoachesCount;
  final int unpaidSubscriptions;
  final int newRequests;
  final int missedCalls;
  final GroupClass? nearestClass;
  final List<AdminTask> tasks;
  final List<ActivityLog> recentActions;

  // Live pool telemetry
  final int ongoingClassesCount;
  final int ongoingClientsCount;
  final int ongoingCoachesCount;
  final List<GroupClass> ongoingClasses;

  AdminDashboardState({
    this.todayClasses = const [],
    this.activeUpcomingClassesCount = 0,
    this.activeClientsCount = 0,
    this.totalCoachesCount = 0,
    this.todayClientsCount = 0,
    this.todayCoachesCount = 0,
    this.unpaidSubscriptions = 0,
    this.newRequests = 0,
    this.missedCalls = 0,
    this.nearestClass,
    this.tasks = const [],
    this.recentActions = const [],
    this.ongoingClassesCount = 0,
    this.ongoingClientsCount = 0,
    this.ongoingCoachesCount = 0,
    this.ongoingClasses = const [],
  });
}

@riverpod
Stream<List<GroupClass>> todayClasses(Ref ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

  return FirebaseFirestore.instance
      .collection('classes')
      .where('startTime', isGreaterThanOrEqualTo: startOfDay)
      .where('startTime', isLessThanOrEqualTo: endOfDay)
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

@riverpod
Stream<List<ActivityLog>> recentActions(Ref ref) {
  return FirebaseFirestore.instance
      .collection('activity_logs')
      .orderBy('timestamp', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      // Convert Firestore Timestamp to IsoString for Freezed
      if (data['timestamp'] is Timestamp) {
         data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
      }
      return ActivityLog.fromJson(data);
    }).toList();
  });
}

@riverpod
Stream<List<AdminTask>> adminTasks(Ref ref) {
  return FirebaseFirestore.instance
      .collection('admin_tasks')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      if (data['createdAt'] is Timestamp) {
         data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      return AdminTask.fromJson(data);
    }).toList();
  });
}

@riverpod
Stream<int> unpaidSubscriptionsCount(Ref ref) {
  return FirebaseFirestore.instance
      .collection('subscriptions')
      .where('isActive', isEqualTo: true)
      .where('remainingClasses', isEqualTo: 0)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

@riverpod
Stream<List<Subscription>> allSubscriptions(Ref ref) {
  return FirebaseFirestore.instance
      .collection('subscriptions')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      // Convert expiryDate
      if (data['expiryDate'] is Timestamp) {
         data['expiryDate'] = (data['expiryDate'] as Timestamp).toDate().toIso8601String();
      }
      return Subscription.fromJson(data);
    }).toList();
  });
}

@riverpod
Stream<List<AppUser>> coaches(Ref ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'coach')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return AppUser.fromJson(data);
    }).toList();
  });
}

final adminAllClassesProvider = StreamProvider.autoDispose<List<GroupClass>>((ref) {
  return FirebaseFirestore.instance
      .collection('classes')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return GroupClass.fromJson(data);
    }).toList();
  });
});

@riverpod
AdminDashboardState adminDashboard(Ref ref) {
  final todayClassesList = ref.watch(todayClassesProvider).value ?? [];
  final recentActionsList = ref.watch(recentActionsProvider).value ?? [];
  final tasksList = ref.watch(adminTasksProvider).value ?? [];
  final coachesList = ref.watch(coachesProvider).value ?? [];
  final allSubs = ref.watch(allSubscriptionsProvider).value ?? [];
  final allClassesList = ref.watch(adminAllClassesProvider).value ?? [];

  final now = DateTime.now();

  // 1. Активні та майбутні заняття (ті, що ще не закінчились)
  final activeUpcomingClasses = allClassesList.where((c) => c.endTime.isAfter(now)).toList();
  activeUpcomingClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

  // 2. Найближче заняття (серед майбутніх або поточних)
  final GroupClass? nearest = activeUpcomingClasses.isNotEmpty ? activeUpcomingClasses.first : null;

  // 3. Активні клієнти (унікальні користувачі з дійсним абонементом > 0 занять)
  final Set<String> activeClientIds = {};
  for (final sub in allSubs) {
    if (sub.isActive && sub.remainingClasses > 0) {
      activeClientIds.add(sub.userId);
    }
  }

  // 4. Загальна кількість тренерів
  final int totalCoaches = coachesList.length;

  // Calculate unique clients and coaches for today (backward compat)
  final Set<String> uniqueClientsToday = {};
  final Set<String> uniqueCoachesToday = {};
  for (final c in todayClassesList) {
    uniqueCoachesToday.add(c.coachId);
    uniqueClientsToday.addAll(c.enrolledChildIds);
  }

  // Fetch inactive subscriptions for auto-tasks
  final inactiveSubs = allSubs.where((s) => !s.isActive || s.remainingClasses == 0).toList();
  
  final List<AdminTask> autoTasks = inactiveSubs.map((sub) {
    return AdminTask(
      id: 'auto_${sub.id}',
      title: 'Нагадати про оплату',
      subtitle: 'Клієнт: ${sub.ownerName ?? "Невідомо"} (0 занять)',
      priority: TaskPriority.urgent,
      createdAt: DateTime.now(), // Realtime
      isAutoGenerated: true,
    );
  }).toList();

  // Combine auto tasks with manual tasks (auto tasks first)
  final List<AdminTask> combinedTasks = [...autoTasks, ...tasksList];

  // 1. Активні заняття, які ПРЯМО ЗАРАЗ проводяться у басейні (live in pool)
  final ongoingClasses = allClassesList.where((c) {
    return (now.isAfter(c.startTime) || now.isAtSameMomentAs(c.startTime)) &&
           (now.isBefore(c.endTime) || now.isAtSameMomentAs(c.endTime));
  }).toList();

  // 2. Клієнти (діти/учні), які займаються прямо зараз
  final Set<String> ongoingClientIds = {};
  for (final c in ongoingClasses) {
    ongoingClientIds.addAll(c.enrolledChildIds);
  }

  // 3. Тренери, які працюють прямо зараз (проводять поточні заняття)
  final Set<String> ongoingCoachIds = {};
  for (final c in ongoingClasses) {
    if (c.coachId.isNotEmpty) {
      ongoingCoachIds.add(c.coachId);
    }
  }

  return AdminDashboardState(
    todayClasses: todayClassesList,
    activeUpcomingClassesCount: activeUpcomingClasses.length,
    activeClientsCount: activeClientIds.length,
    totalCoachesCount: totalCoaches,
    todayClientsCount: uniqueClientsToday.length,
    todayCoachesCount: uniqueCoachesToday.length,
    unpaidSubscriptions: inactiveSubs.length,
    newRequests: 0,
    missedCalls: 0,
    nearestClass: nearest,
    tasks: combinedTasks,
    recentActions: recentActionsList,
    ongoingClassesCount: ongoingClasses.length,
    ongoingClientsCount: ongoingClientIds.length,
    ongoingCoachesCount: ongoingCoachIds.length,
    ongoingClasses: ongoingClasses,
  );
}

// Helper to add actions
Future<void> logAdminAction(String action, String adminId) async {
  await FirebaseFirestore.instance.collection('activity_logs').add({
    'action': action,
    'timestamp': FieldValue.serverTimestamp(),
    'adminId': adminId,
  });
}
