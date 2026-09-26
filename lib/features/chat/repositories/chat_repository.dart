import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/chat/models/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _chats => _firestore.collection('chats');

  /// Stream all dialogs for the Admin Support & Monitoring Center
  Stream<List<ChatDialog>> streamAdminDialogs({String? branchId}) {
    return _chats.orderBy('updatedAt', descending: true).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatDialog.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      if (branchId == null || branchId.isEmpty) {
        return list;
      }
      return list.where((d) => d.branchId == branchId).toList();
    });
  }

  /// Backward compatible single client support dialog stream
  Stream<ChatDialog?> streamClientDialog(String clientId) {
    return _chats.where('clientId', isEqualTo: clientId).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ChatDialog.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
    });
  }

  /// Stream all dialogs relevant to a specific Client (Support + Coach chats)
  Stream<List<ChatDialog>> streamClientDialogs(String clientId) {
    return _chats.snapshots().map((snapshot) {
      final dialogs = <ChatDialog>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final d = ChatDialog.fromJson(data);
        if (d.clientId == clientId || d.id == clientId || d.participantIds.contains(clientId)) {
          dialogs.add(d);
        }
      }
      dialogs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return dialogs;
    });
  }

  /// Stream all dialogs relevant to a specific Coach (Support + Client chats)
  Stream<List<ChatDialog>> streamCoachDialogs(String coachId) {
    return _chats.snapshots().map((snapshot) {
      final dialogs = <ChatDialog>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final d = ChatDialog.fromJson(data);
        if (d.coachId == coachId ||
            d.participantIds.contains(coachId) ||
            (d.id == coachId && d.type == 'support')) {
          dialogs.add(d);
        }
      }
      dialogs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return dialogs;
    });
  }

  /// Stream all messages for a specific dialog
  Stream<List<ChatMessage>> streamMessages(String dialogId) {
    return _chats
        .doc(dialogId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data())).toList();
    });
  }

  /// Send message in any dialog (support or coach_client)
  Future<void> sendMessage({
    required String dialogId,
    required String senderId, // 'admin', coachId, or clientId
    String? senderName,
    String? senderRole, // 'coach', 'parent', 'admin', 'client'
    required String text,
    String? imageUrl,
    required String clientId,
    required String clientName,
    String clientAvatar = '',
    String? coachId,
    String? coachName,
    String? coachAvatar,
    String? childName,
    String type = 'support', // 'support', 'coach_client', 'recovery'
    String? clientRole,
    String? organizationId,
    String? branchId,
  }) async {
    final messageId = _chats.doc(dialogId).collection('messages').doc().id;
    final now = DateTime.now();

    final effectiveRole = senderRole ??
        (senderId == 'admin'
            ? 'admin'
            : (coachId != null && senderId == coachId ? 'coach' : 'parent'));

    final message = ChatMessage(
      id: messageId,
      dialogId: dialogId,
      senderId: senderId,
      senderName: senderName,
      senderRole: effectiveRole,
      text: text,
      timestamp: now,
      isRead: false,
      imageUrl: imageUrl,
    );

    final batch = _firestore.batch();

    // 1. Set message in subcollection
    final messageRef = _chats.doc(dialogId).collection('messages').doc(messageId);
    batch.set(messageRef, message.toJson());

    // 2. Determine unread increments and participants
    final isCoachSender = coachId != null && senderId == coachId;
    final isAdminSender = senderId == 'admin';

    dynamic unreadAdminCount;
    dynamic unreadCoachCount;
    dynamic unreadClientCount;

    if (type == 'coach_client') {
      // In Coach <-> Client chat: Admin is strictly stealth (unreadAdminCount stays 0)
      unreadAdminCount = FieldValue.increment(0);
      if (isCoachSender) {
        unreadClientCount = FieldValue.increment(1);
        unreadCoachCount = 0;
      } else {
        unreadCoachCount = FieldValue.increment(1);
        unreadClientCount = 0;
      }
    } else {
      // Support dialog (Client/Coach <-> Admin)
      unreadAdminCount = !isAdminSender ? FieldValue.increment(1) : FieldValue.increment(0);
      unreadClientCount = isAdminSender ? FieldValue.increment(1) : FieldValue.increment(0);
      unreadCoachCount = 0;
    }

    final participants = <String>{};
    if (clientId.isNotEmpty) participants.add(clientId);
    if (coachId != null && coachId.isNotEmpty) participants.add(coachId);
    if (type == 'support') participants.add('admin');

    final summaryText = text.isNotEmpty
        ? text
        : (imageUrl != null ? '📷 Фотографія' : '');

    final dialogRef = _chats.doc(dialogId);
    batch.set(dialogRef, {
      'id': dialogId,
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'lastMessage': summaryText,
      'lastMessageTime': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'lastSenderId': senderId,
      'unreadAdminCount': unreadAdminCount,
      'unreadClientCount': unreadClientCount,
      'unreadCoachCount': unreadCoachCount,
      'type': type,
      'participantIds': participants.toList(),
      'coachId': ?coachId,
      'coachName': ?coachName,
      'coachAvatar': ?coachAvatar,
      'childName': ?childName,
      'clientRole': ?clientRole,
      'organizationId': ?organizationId,
      'branchId': ?branchId,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Mark messages as read by a specific party
  Future<void> markMessagesAsRead(
    String dialogId, {
    bool isAdmin = false,
    bool isCoach = false,
    bool isClient = false,
  }) async {
    final dialogRef = _chats.doc(dialogId);
    final Map<String, dynamic> updates = {};
    if (isAdmin) updates['unreadAdminCount'] = 0;
    if (isCoach) updates['unreadCoachCount'] = 0;
    if (isClient) updates['unreadClientCount'] = 0;

    if (updates.isNotEmpty) {
      await dialogRef.update(updates).catchError((_) {});
    }
  }
}
