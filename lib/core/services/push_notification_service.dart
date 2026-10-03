import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

// Handle background messages at the top level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

class PushNotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  AppUser? _currentUser;

  PushNotificationService(this._ref) {
    // Listen to user changes to update FCM token when user logs in/out
    _ref.listen<AppUser?>(authControllerProvider, (previous, next) {
      if (next?.id != previous?.id) {
        _currentUser = next;
        if (next != null) {
          _updateUserToken();
        }
      }
    });
  }

  Future<void> initialize() async {
    if (kIsWeb) return; // Push not fully setup for web right now

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    try {
      // 1. Request Permission (shows popup on iOS)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Show banner, badge, and sound even when app is open in foreground
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Ensure APNs token is available on iOS before getting FCM token
        if (!kIsWeb && Platform.isIOS) {
          await _fcm.getAPNSToken();
        }

        // 2. Get initial token and save it
        await _updateUserToken();

        // 3. Listen for token refreshes
        _fcm.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(newToken);
        });

        // 4. Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');

          if (message.notification != null) {
            debugPrint('Message also contained a notification: ${message.notification?.title}');
            // Note: Optional local snackbar or in-app notification can be displayed here
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
    }
  }

  Future<void> _updateUserToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    // Try to get current user from controller if not set
    _currentUser ??= _ref.read(authControllerProvider);
    
    if (_currentUser == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCM Token saved for user ${_currentUser!.id}');
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }
}
