import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';

class ParentNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color? iconColor;
  final bool isRead;
  final String? actionType; // 'chat', 'calendar', 'subscription'

  const ParentNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    this.iconColor,
    this.isRead = false,
    this.actionType,
  });

  ParentNotification copyWith({bool? isRead}) {
    return ParentNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      icon: icon,
      iconColor: iconColor,
      isRead: isRead ?? this.isRead,
      actionType: actionType,
    );
  }
}

class ParentNotificationsState {
  final List<ParentNotification> notifications;
  final Set<String> readIds;

  const ParentNotificationsState({
    required this.notifications,
    required this.readIds,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
}

final parentFirestoreNotificationsStreamProvider =
    StreamProvider.family<List<ParentNotification>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    final list = <ParentNotification>[];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        final iconName = data['icon']?.toString() ?? 'bell';
        IconData iconData;
        switch (iconName) {
          case 'creditCard':
            iconData = LucideIcons.creditCard;
            break;
          case 'messageSquare':
            iconData = LucideIcons.messageSquare;
            break;
          case 'calendarClock':
            iconData = LucideIcons.calendarClock;
            break;
          case 'award':
            iconData = LucideIcons.award;
            break;
          case 'bellRing':
          default:
            iconData = LucideIcons.bellRing;
            break;
        }

        Color? iconColor;
        if (data['iconColor'] != null && data['iconColor'] is int) {
          iconColor = Color(data['iconColor'] as int);
        }

        DateTime timestamp = DateTime.now();
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          timestamp = DateTime.tryParse(data['timestamp'] as String) ?? DateTime.now();
        }

        list.add(
          ParentNotification(
            id: doc.id,
            title: data['title']?.toString() ?? 'Нагадування про абонемент',
            message: data['message']?.toString() ?? '',
            timestamp: timestamp,
            icon: iconData,
            iconColor: iconColor ?? const Color(0xFFF59E0B),
            isRead: data['isRead'] as bool? ?? false,
            actionType: data['actionType']?.toString() ?? 'subscription',
          ),
        );
      } catch (e) {
        debugPrint('Error parsing notification ${doc.id}: $e');
      }
    }
    return list;
  });
});

class ParentNotificationsController extends Notifier<ParentNotificationsState> {
  static const _prefsKeyPrefix = 'read_parent_notifications_v1_';

  String _getPrefsKey(String userId) => '$_prefsKeyPrefix$userId';

  @override
  ParentNotificationsState build() {
    final user = ref.watch(authControllerProvider);
    final prefs = ref.watch(sharedPrefsProvider);
    final userId = user?.id ?? 'guest';

    final savedReadIds = prefs.getStringList(_getPrefsKey(userId))?.toSet() ?? <String>{};
    final allNotifications = <ParentNotification>[];

    // 1. Cloud Notifications from Firestore (Admin reminders & alerts)
    if (user != null) {
      final cloudNotifsAsync = ref.watch(parentFirestoreNotificationsStreamProvider(user.id));
      cloudNotifsAsync.whenData((notifs) {
        for (final item in notifs) {
          final isRead = item.isRead || savedReadIds.contains(item.id);
          allNotifications.add(item.copyWith(isRead: isRead));
        }
      });
    }

    // 2. Chat dialog with admin (unread message or reminder message)
    if (user != null) {
      final clientDialogAsync = ref.watch(clientChatDialogStreamProvider(user.id));
      clientDialogAsync.whenData((dialog) {
        if (dialog != null) {
          final isUnread = dialog.unreadClientCount > 0;
          final msgText = dialog.lastMessage.toLowerCase();
          final isReminder = msgText.contains('абонемент') ||
              msgText.contains('нагаду') ||
              msgText.contains('cityswim');

          if (isUnread || isReminder) {
            final id = 'chat_dialog_${dialog.id}_${dialog.lastMessageTime.millisecondsSinceEpoch}';
            final isRead = !isUnread || savedReadIds.contains(id);
            allNotifications.add(
              ParentNotification(
                id: id,
                title: isReminder ? 'Нагадування від адміністратора' : 'Повідомлення від адміністратора',
                message: dialog.lastMessage.isNotEmpty
                    ? dialog.lastMessage
                    : 'У вас нове повідомлення у чаті підтримки',
                timestamp: dialog.lastMessageTime,
                icon: isReminder ? LucideIcons.creditCard : LucideIcons.messageSquare,
                iconColor: isReminder ? const Color(0xFFF59E0B) : const Color(0xFF00E5FF),
                isRead: isRead,
                actionType: isReminder ? 'subscription' : 'chat',
              ),
            );
          }
        }
      });
    }

    // 3. Class activities (cancellations, rescheduling, bookings)
    final activitiesAsync = ref.watch(classActivitiesStreamProvider);
    final childrenAsync = ref.watch(childrenControllerProvider);
    final childIds = childrenAsync.value?.map((c) => c.id).toSet() ?? <String>{};

    activitiesAsync.whenData((activities) {
      for (final activity in activities.take(10)) {
        final isRelevant = (user != null && activity.attendeeId == user.id) ||
            (activity.attendeeId != null && childIds.contains(activity.attendeeId)) ||
            (user != null &&
                activity.parentName != null &&
                activity.parentName!.toLowerCase() == user.name.toLowerCase());

        if (isRelevant) {
          final id = 'activity_${activity.id}';
          final isRead = savedReadIds.contains(id);
          allNotifications.add(
            ParentNotification(
              id: id,
              title: activity.classTitle.isNotEmpty ? activity.classTitle : 'Оновлення розкладу',
              message: activity.message,
              timestamp: activity.timestamp,
              icon: LucideIcons.calendarClock,
              iconColor: const Color(0xFF38BDF8),
              isRead: isRead,
              actionType: 'calendar',
            ),
          );
        }
      }
    });

    // 4. Subscription status
    if (user != null) {
      final allSubs = ref.watch(subscriptionControllerProvider.notifier).getSubscriptionsForUser(user.id);
      final activeSubs = allSubs.where((s) => s.isActive).toList();
      for (final sub in activeSubs) {
        if (sub.remainingClasses <= 2) {
          final id = 'sub_low_${sub.id}_${sub.remainingClasses}';
          final isRead = savedReadIds.contains(id);
          allNotifications.add(
            ParentNotification(
              id: id,
              title: 'Абонемент завершується',
              message: 'Залишилось ${sub.remainingClasses} занять. Не забудьте подовжити абонемент!',
              timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              icon: LucideIcons.creditCard,
              iconColor: const Color(0xFFF59E0B),
              isRead: isRead,
              actionType: 'subscription',
            ),
          );
        }
      }
    }

    // 5. Default system notifications (if no notifications exist yet)
    final defaultItems = [
      ParentNotification(
        id: 'default_notif_rescheduled',
        title: 'Тренування перенесено',
        message: 'Сьогоднішнє заняття о 16:00 перенесено на 16:15.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
        icon: LucideIcons.clock,
        iconColor: const Color(0xFF00E5FF),
        isRead: savedReadIds.contains('default_notif_rescheduled'),
        actionType: 'calendar',
      ),
      ParentNotification(
        id: 'default_notif_badge',
        title: 'Нове досягнення!',
        message: 'Ваша дитина отримала бейдж "Акула басейну".',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        icon: LucideIcons.award,
        iconColor: const Color(0xFFA855F7),
        isRead: savedReadIds.contains('default_notif_badge'),
      ),
    ];

    for (final item in defaultItems) {
      if (!allNotifications.any((n) => n.id == item.id)) {
        allNotifications.add(item);
      }
    }

    // Deduplicate by ID
    final uniqueMap = <String, ParentNotification>{};
    for (final notif in allNotifications) {
      if (!uniqueMap.containsKey(notif.id)) {
        uniqueMap[notif.id] = notif;
      }
    }
    final uniqueNotifications = uniqueMap.values.toList();

    // Sort notifications: unread first, then by timestamp descending
    uniqueNotifications.sort((a, b) {
      if (a.isRead != b.isRead) {
        return a.isRead ? 1 : -1;
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    return ParentNotificationsState(
      notifications: uniqueNotifications,
      readIds: savedReadIds,
    );
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(authControllerProvider);
    final prefs = ref.read(sharedPrefsProvider);
    final userId = user?.id ?? 'guest';

    final updatedReadIds = Set<String>.from(state.readIds);
    for (final notif in state.notifications) {
      updatedReadIds.add(notif.id);
      if (!notif.id.startsWith('default_') &&
          !notif.id.startsWith('chat_') &&
          !notif.id.startsWith('activity_') &&
          !notif.id.startsWith('sub_')) {
        try {
          FirebaseFirestore.instance.collection('notifications').doc(notif.id).update({'isRead': true});
        } catch (_) {}
      }
    }

    await prefs.setStringList(_getPrefsKey(userId), updatedReadIds.toList());

    final updatedNotifications = state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    state = ParentNotificationsState(
      notifications: updatedNotifications,
      readIds: updatedReadIds,
    );
  }

  Future<void> markAsRead(String id) async {
    final user = ref.read(authControllerProvider);
    final prefs = ref.read(sharedPrefsProvider);
    final userId = user?.id ?? 'guest';

    final updatedReadIds = Set<String>.from(state.readIds)..add(id);
    await prefs.setStringList(_getPrefsKey(userId), updatedReadIds.toList());

    if (!id.startsWith('default_') &&
        !id.startsWith('chat_') &&
        !id.startsWith('activity_') &&
        !id.startsWith('sub_')) {
      try {
        await FirebaseFirestore.instance.collection('notifications').doc(id).update({'isRead': true});
      } catch (_) {}
    }

    final updatedNotifications = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = ParentNotificationsState(
      notifications: updatedNotifications,
      readIds: updatedReadIds,
    );
  }

  Future<void> clearAll() async {
    await markAllAsRead();
  }
}

final parentNotificationsControllerProvider =
    NotifierProvider<ParentNotificationsController, ParentNotificationsState>(() {
  return ParentNotificationsController();
});

final pushNotificationsEnabledProvider =
    NotifierProvider<PushNotificationsController, bool>(() {
  return PushNotificationsController();
});

class PushNotificationsController extends Notifier<bool> {
  static const _key = 'push_notifications_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getBool(_key) ?? true;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_key, value);
  }
}


