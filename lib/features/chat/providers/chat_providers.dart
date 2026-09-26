import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/chat/models/chat_message.dart';
import 'package:swimming_school_app/features/chat/repositories/chat_repository.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final adminChatDialogsStreamProvider = StreamProvider<List<ChatDialog>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final tenancy = ref.watch(tenancyControllerProvider);
  final branchId = tenancy.isAllLocationsSelected ? null : tenancy.activeBranchId;
  return repo.streamAdminDialogs(branchId: branchId);
});

final clientChatDialogStreamProvider = StreamProvider.family<ChatDialog?, String>((ref, clientId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamClientDialog(clientId);
});

final clientAllDialogsStreamProvider = StreamProvider.family<List<ChatDialog>, String>((ref, clientId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamClientDialogs(clientId);
});

final coachAllDialogsStreamProvider = StreamProvider.family<List<ChatDialog>, String>((ref, coachId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamCoachDialogs(coachId);
});

final chatMessagesStreamProvider = StreamProvider.family<List<ChatMessage>, String>((ref, dialogId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamMessages(dialogId);
});

// A provider that maps userId and name to user role ('coach', 'parent', 'admin')
final usersRoleMapProvider = StreamProvider<Map<String, String>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
    final map = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final role = data['role']?.toString().toLowerCase() ?? 'parent';
      map[doc.id] = role;
      final name = data['name']?.toString().trim().toLowerCase();
      if (name != null && name.isNotEmpty) {
        map['name_$name'] = role;
      }
    }
    return map;
  });
});

// Total unread dialogs count for Admin Support Center (only support/recovery, excluding coach_client)
final unreadAdminChatBadgeProvider = Provider<int>((ref) {
  final dialogsAsync = ref.watch(adminChatDialogsStreamProvider);
  return dialogsAsync.maybeWhen(
    data: (dialogs) {
      int count = 0;
      for (final dialog in dialogs) {
        if (dialog.unreadAdminCount > 0) {
          count++;
        }
      }
      return count;
    },
    orElse: () => 0,
  );
});

// Total unread count for a Coach across their dialogs
final coachUnreadBadgeProvider = Provider.family<int, String>((ref, coachId) {
  final dialogsAsync = ref.watch(coachAllDialogsStreamProvider(coachId));
  return dialogsAsync.maybeWhen(
    data: (dialogs) {
      int count = 0;
      for (final d in dialogs) {
        if (d.type == 'support' && d.unreadClientCount > 0) {
          count += d.unreadClientCount;
        } else if (d.type == 'coach_client' && d.unreadCoachCount > 0) {
          count += d.unreadCoachCount;
        }
      }
      return count;
    },
    orElse: () => 0,
  );
});

// Total unread count for a Client across their dialogs
final clientUnreadBadgeProvider = Provider.family<int, String>((ref, clientId) {
  final dialogsAsync = ref.watch(clientAllDialogsStreamProvider(clientId));
  return dialogsAsync.maybeWhen(
    data: (dialogs) {
      int count = 0;
      for (final d in dialogs) {
        if (d.unreadClientCount > 0) {
          count += d.unreadClientCount;
        }
      }
      return count;
    },
    orElse: () => 0,
  );
});
