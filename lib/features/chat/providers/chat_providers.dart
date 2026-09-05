import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/chat/models/chat_message.dart';
import 'package:swimming_school_app/features/chat/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final adminChatDialogsStreamProvider = StreamProvider<List<ChatDialog>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamAdminDialogs();
});

final clientChatDialogStreamProvider = StreamProvider.family<ChatDialog?, String>((ref, clientId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamClientDialog(clientId);
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

// A provider that counts total unread dialogs for Admin
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

