import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AppUser? build() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        state = null;
      } else {
        await _fetchUserFromFirestore(user.uid);
      }
    });
    return null;
  }

  Future<void> _fetchUserFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get().timeout(const Duration(seconds: 15));
      if (doc.exists && doc.data() != null) {
        state = AppUser.fromJson(doc.data()!);
      } else {
        // Create default user if missing
        state = AppUser(
          id: uid,
          name: 'New User',
          role: UserRole.parent,
        );
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      // Fallback for offline or permission issues
      state = AppUser(
        id: uid,
        name: 'Offline User',
        role: UserRole.parent,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      User? user;
      
      if (kIsWeb) {
        // Use Firebase's built-in popup for Web (much more reliable and recommended)
        final authProvider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(authProvider);
        user = userCredential.user;
      } else {
        // Use google_sign_in plugin for Android/iOS
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; 

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        user = userCredential.user;
      }

      if (user != null) {
        final defaultUser = AppUser(
          id: user.uid,
          name: user.displayName ?? 'New User',
          role: UserRole.parent,
          avatarUrl: user.photoURL ?? 'https://ui-avatars.com/api/?name=${user.displayName ?? 'User'}',
        );

        try {
          final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          final docSnap = await docRef.get().timeout(const Duration(seconds: 15));

          if (!docSnap.exists) {
            await docRef.set(defaultUser.toJson()).timeout(const Duration(seconds: 15));
            state = defaultUser;
          } else {
            final dbUser = AppUser.fromJson(docSnap.data()!);
            // Force role to parent as requested
            state = dbUser.copyWith(role: UserRole.parent);
          }
        } catch (e) {
          debugPrint('Firestore error, falling back to default Client role: $e');
          // If Firestore is offline, still log the user in locally as Client!
          state = defaultUser;
        }
      }
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      if (kDebugMode) {
        // Hardcoded test credentials for testing different portals
        final login = email.trim().toLowerCase();
        if (password.trim() == '1') {
          if (login == 'coach') {
            state = const AppUser(id: 'mock_coach', name: 'Тренер Тест', role: UserRole.coach);
            return;
          } else if (login == 'admin') {
            state = const AppUser(id: 'mock_admin', name: 'Адмін Тест', role: UserRole.admin);
            return;
          } else if (login == 'owner') {
            state = const AppUser(id: 'mock_owner', name: 'Власник Тест', role: UserRole.owner);
            return;
          }
        }
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _fetchUserFromFirestore(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint('Error during Email Sign In: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    state = null;
  }

  Future<void> updateAvatar(Uint8List bytes) async {
    if (state == null) return;
    
    try {
      final user = state!;
      final storageRef = FirebaseStorage.instance.ref();
      
      // Delete old avatar if it's a Firebase Storage URL
      if (user.avatarUrl.contains('firebasestorage.googleapis.com')) {
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(user.avatarUrl);
          await oldRef.delete();
          debugPrint('Old avatar deleted successfully.');
        } catch (e) {
          debugPrint('Error deleting old avatar: $e');
          // Proceed with upload even if delete fails (e.g. file doesn't exist)
        }
      }

      // Upload new avatar
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newAvatarRef = storageRef.child('avatars/${user.id}_$timestamp.jpg');
      
      await newAvatarRef.putData(
        bytes, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final newUrl = await newAvatarRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'avatarUrl': newUrl,
      });

      // Update local state
      state = user.copyWith(avatarUrl: newUrl, avatarBytes: null);
      
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
    }
  }
}
