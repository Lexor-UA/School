import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/chat/models/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _chats => _firestore.collection('chats');
  
  Stream<List<ChatDialog>> streamAdminDialogs() {
    return _chats.orderBy('updatedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatDialog.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<ChatDialog?> streamClientDialog(String clientId) {
    return _chats.where('clientId', isEqualTo: clientId).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ChatDialog.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
    });
  }

  Stream<List<ChatMessage>> streamMessages(String dialogId) {
    return _chats.doc(dialogId).collection('messages').orderBy('timestamp', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> sendMessage({
    required String dialogId,
    required String clientId,
    required String clientName,
    required String clientAvatar,
    required String senderId, // 'admin' or clientId
    required String text,
  }) async {
    final messageId = _chats.doc(dialogId).collection('messages').doc().id;
    final now = DateTime.now();
    
    final message = ChatMessage(
      id: messageId,
      dialogId: dialogId,
      senderId: senderId,
      text: text,
      timestamp: now,
      isRead: false,
    );

    final batch = _firestore.batch();
    
    // Set message
    final messageRef = _chats.doc(dialogId).collection('messages').doc(messageId);
    batch.set(messageRef, message.toJson());
    
    // Update or create dialog
    final dialogRef = _chats.doc(dialogId);
    
    final unreadAdminCount = senderId != 'admin' ? FieldValue.increment(1) : FieldValue.increment(0);
    final unreadClientCount = senderId == 'admin' ? FieldValue.increment(1) : FieldValue.increment(0);

    batch.set(dialogRef, {
      'id': dialogId,
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'unreadAdminCount': unreadAdminCount,
      'unreadClientCount': unreadClientCount,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> markMessagesAsRead(String dialogId, bool isAdmin) async {
    final dialogRef = _chats.doc(dialogId);
    
    // Reset unread count for the reader
    await dialogRef.update({
      if (isAdmin) 'unreadAdminCount': 0 else 'unreadClientCount': 0,
    });
  }
}
