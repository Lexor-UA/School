import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AppUser? build() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        state = null;
        await _syncRoleToPrefs(null);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final savedRoleString = prefs.getString('userRole');
        bool hasCachedState = false;
        
        if (savedRoleString != null) {
          final role = UserRole.values.firstWhere((e) => e.name == savedRoleString, orElse: () => UserRole.parent);
          // Immediately set state using saved role to enter the app without waiting
          state = AppUser(
            id: user.uid,
            name: user.displayName ?? 'User',
            role: role,
          );
          hasCachedState = true;
        }
        
        await _fetchUserFromFirestore(user.uid, hasCachedState: hasCachedState);
      }
    });
    return null;
  }

  Future<void> _syncRoleToPrefs(AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString('userRole', user.role.name);
    } else {
      await prefs.remove('userRole');
    }
  }

  Future<void> _fetchUserFromFirestore(String uid, {bool hasCachedState = false}) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get().timeout(const Duration(seconds: 15));
      if (doc.exists && doc.data() != null) {
        state = AppUser.fromJson(doc.data()!);
        await _syncRoleToPrefs(state);
      } else {
        // Create default user if missing
        state = AppUser(
          id: uid,
          name: 'New User',
          role: UserRole.parent,
        );
        await _syncRoleToPrefs(state);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (!hasCachedState) {
        // Sign out if we can't fetch the user data to prevent weird automatic offline logins
        state = null;
        await _syncRoleToPrefs(null);
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
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
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? '720928546774-5q4bbigk2gjgh90qblrbk2gp2smecifp.apps.googleusercontent.com'
              : null,
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
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
            await _syncRoleToPrefs(state);
          } else {
            final dbUser = AppUser.fromJson(docSnap.data()!);
            // Force role to parent as requested
            state = dbUser.copyWith(role: UserRole.parent);
            await _syncRoleToPrefs(state);
          }
        } catch (e) {
          debugPrint('Firestore error, falling back to default Client role: $e');
          // If Firestore is offline, still log the user in locally as Client!
          state = defaultUser;
          await _syncRoleToPrefs(state);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') {
        debugPrint('Google Sign In cancelled by user.');
        return;
      }
      debugPrint('Error during Google Sign In (FirebaseAuthException): $e');
      rethrow;
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      // Hardcoded test credentials for testing different portals
      final login = email.trim().toLowerCase();
      if (password.trim() == '1') {
        if (login == 'coach') {
          state = const AppUser(id: 'mock_coach', name: 'Coach', role: UserRole.coach);
          await _syncRoleToPrefs(state);
          return;
        } else if (login == 'admin') {
          state = const AppUser(id: 'mock_admin', name: 'Admin', role: UserRole.admin);
          await _syncRoleToPrefs(state);
          return;
        } else if (login == 'owner') {
          state = const AppUser(id: 'mock_owner', name: 'Owner', role: UserRole.owner);
          await _syncRoleToPrefs(state);
          return;
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
    await _syncRoleToPrefs(null);
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
