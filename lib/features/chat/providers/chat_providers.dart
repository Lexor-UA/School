import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/chat/models/chat_message.dart';
import 'package:swimming_school_app/features/chat/repositories/chat_repository.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

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
