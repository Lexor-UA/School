import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        state = AppUser.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          final newUser = AppUser(
            id: user.uid,
            name: user.displayName ?? 'New User',
            role: UserRole.parent,
            avatarUrl: user.photoURL ?? 'https://ui-avatars.com/api/?name=${user.displayName ?? 'User'}',
          );
          await docRef.set(newUser.toJson());
          state = newUser;
        } else {
          state = AppUser.fromJson(docSnap.data()!);
        }
      }
    } catch (e) {
      print('Error during Google Sign In: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _fetchUserFromFirestore(userCredential.user!.uid);
      }
    } catch (e) {
      print('Error during Email Sign In: $e');
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
          print('Old avatar deleted successfully.');
        } catch (e) {
          print('Error deleting old avatar: $e');
          // Proceed with upload even if delete fails (e.g. file doesn't exist)
        }
      }

      // Upload new avatar
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newAvatarRef = storageRef.child('avatars/${user.id}_$timestamp.jpg');
      
      final uploadTask = await newAvatarRef.putData(
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
      print('Error uploading avatar: $e');
    }
  }
}
