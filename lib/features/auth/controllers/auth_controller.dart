import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  bool _isLoggingIn = false;

  @override
  AppUser? build() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        final prefs = await SharedPreferences.getInstance();
        final savedRoleString = prefs.getString('userRole');
        final mockUserId = prefs.getString('mockUserId');
        
        // Check if this is a mock session (admin, coach, owner, or mock active client)
        if (savedRoleString == 'admin' || savedRoleString == 'coach' || savedRoleString == 'owner' || mockUserId == 'mock_active_client') {
          if (state == null) {
            if (mockUserId == 'mock_active_client') {
              try {
                final doc = await FirebaseFirestore.instance.collection('users').doc('mock_active_client').get();
                if (doc.exists) {
                  state = AppUser.fromJson(doc.data()!);
                } else {
                  state = const AppUser(
                    id: 'mock_active_client',
                    name: 'Андрій',
                    role: UserRole.parent,
                    avatarUrl: 'https://ui-avatars.com/api/?name=Андрій',
                  );
                }
              } catch (_) {
                state = const AppUser(
                  id: 'mock_active_client',
                  name: 'Андрій',
                  role: UserRole.parent,
                  avatarUrl: 'https://ui-avatars.com/api/?name=Андрій',
                );
              }
            } else if (savedRoleString == 'coach') {
              // Real coach session restoration from Firestore
              final coachId = mockUserId ?? prefs.getString('clientId');
              if (coachId != null && coachId != 'mock_coach') {
                try {
                  final doc = await FirebaseFirestore.instance.collection('users').doc(coachId).get();
                  if (doc.exists) {
                    state = AppUser.fromJson(doc.data()!);
                    return;
                  }
                } catch (_) {}
              }
              // If it was mock_coach or coach was not found, cleanly reset session
              state = null;
              await _syncRoleToPrefs(null);
              await prefs.remove('mockUserId');
              await prefs.remove('clientId');
            } else {
              final role = UserRole.values.firstWhere((e) => e.name == savedRoleString);
              state = AppUser(
                id: 'mock_$savedRoleString',
                name: role == UserRole.admin ? 'Admin' : 'Owner',
                role: role,
              );
            }
          }
        } else {
          // Only clear if it was a parent (Firebase) session
          state = null;
          await _syncRoleToPrefs(null);
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final savedRoleString = prefs.getString('userRole');
        // If user logged in as client via loginId, their UID in Firebase Auth might not match the client's Firestore ID.
        // We should check if they have a saved 'clientId' in SharedPreferences, otherwise fetch by user.uid.
        final clientId = prefs.getString('clientId');
        bool hasCachedState = false;
        
        if (savedRoleString != null) {
          final role = UserRole.values.firstWhere((e) => e.name == savedRoleString, orElse: () => UserRole.parent);
          // Don't overwrite state if we already have the correct user (e.g. from signInWithEmail)
          if (state == null || state!.id != (clientId ?? user.uid)) {
            state = AppUser(
              id: clientId ?? user.uid,
              name: user.displayName ?? 'User',
              role: role,
            );
          }
          hasCachedState = true;
        }
        
        await _fetchUserFromFirestore(clientId ?? user.uid, hasCachedState: hasCachedState);
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
      // Use cache if server is unreachable without throwing a hard timeout exception
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));
          
      if (doc.exists && doc.data() != null) {
        state = AppUser.fromJson(doc.data()!);
        await _syncRoleToPrefs(state);
      } else {
        if (!_isLoggingIn) {
          // Якщо це перезапуск додатку, а не активний процес логіну, і в базі клієнта ще немає,
          // ми просто викидаємо його з сесії, щоб він почав зі стандартного меню.
          state = null;
          await _syncRoleToPrefs(null);
          try {
            await FirebaseAuth.instance.signOut();
            await GoogleSignIn().signOut();
          } catch (_) {}
          return;
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        // Create default user if missing in Firestore (we don't save it yet)
        state = AppUser(
          id: uid,
          name: currentUser?.displayName ?? 'New User',
          role: UserRole.parent,
        );
        await _syncRoleToPrefs(state);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (state == null && !hasCachedState) {
        // Sign out if we can't fetch the user data and we have no state, to prevent weird automatic offline logins
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
      _isLoggingIn = true;
      String? clientId;
      if (kIsWeb) {
        clientId = '720928546774-fm9fipmt88b2uqp2n5cbogq6r0gg1l1u.apps.googleusercontent.com';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        clientId = '720928546774-5q4bbigk2gjgh90qblrbk2gp2smecifp.apps.googleusercontent.com';
      }
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: clientId,
        serverClientId: kIsWeb ? null : '720928546774-fm9fipmt88b2uqp2n5cbogq6r0gg1l1u.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) {
        _isLoggingIn = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _fetchUserFromFirestore(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      rethrow;
    } finally {
      _isLoggingIn = false;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      // Hardcoded test credentials for testing different portals
      final login = email.trim().toLowerCase();
      if (password.trim() == '1') {
        // We defer anonymous sign-in until after setting SharedPreferences to prevent
        // the authStateChanges listener from fetching data with a missing clientId.

        if (login.startsWith('coach')) {
          final usersSnap = await FirebaseFirestore.instance.collection('users').where('loginId', isEqualTo: login).get();
          if (usersSnap.docs.isNotEmpty) {
            state = AppUser.fromJson(usersSnap.docs.first.data());
            await _syncRoleToPrefs(state);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('clientId', state!.id);
            await prefs.setString('mockUserId', state!.id);
            return;
          } else {
            throw Exception('Тренера з логіном $login не знайдено');
          }
        } else if (login == 'admin') {
          state = const AppUser(id: 'mock_admin', name: 'Admin', role: UserRole.admin);
          await _syncRoleToPrefs(state);
          return;
        } else if (login == 'owner') {
          state = const AppUser(id: 'mock_owner', name: 'Owner', role: UserRole.owner);
          await _syncRoleToPrefs(state);
          return;
        } else if (login.startsWith('client')) {
          final usersSnap = await FirebaseFirestore.instance.collection('users').where('loginId', isEqualTo: login).get();
          if (usersSnap.docs.isNotEmpty) {
            state = AppUser.fromJson(usersSnap.docs.first.data());
            await _syncRoleToPrefs(state);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('clientId', state!.id);
            return;
          } else {
            throw Exception('Клієнта з логіном $login не знайдено');
          }
        }

        // Now that SharedPreferences are set, we can sign in. The listener will pick up the correct clientId.
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(email: 'mock_$login@cityswim.com', password: 'password123');
          } catch (e) {
            try {
              await FirebaseAuth.instance.createUserWithEmailAndPassword(email: 'mock_$login@cityswim.com', password: 'password123');
            } catch (_) {}
          }
        }
        return;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mockUserId');
    await prefs.remove('clientId');
  }

  Future<void> updateAvatar(Uint8List bytes, {VoidCallback? onSuccess, void Function(String)? onError}) async {
    if (state == null) return;
    
    final user = state!;
    try {
      // Оптимістичне оновлення для миттєвого відображення
      state = user.copyWith(avatarBytes: bytes);
      
      final base64String = base64Encode(bytes);
      final newUrl = 'data:image/jpeg;base64,$base64String';

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'avatarUrl': newUrl,
      });

      // Update local state permanently
      state = user.copyWith(avatarUrl: newUrl, avatarBytes: null);
      debugPrint('Successfully uploaded and updated avatar!');
      if (onSuccess != null) onSuccess();
      
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (onError != null) onError(e.toString());
      // Revert optimistic update on error
      if (state?.id == user.id) {
        state = user;
      }
    }
  }

  Future<void> completeOnboarding(String name, String phone, {String? childName, String? childAge}) async {
    if (state == null) return;
    
    try {
      final user = state!;
      
      // Calculate max client loginId
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      int maxClientNum = 0;
      for (var doc in usersSnap.docs) {
        final loginId = doc.data()['loginId'] as String?;
        if (loginId != null && loginId.startsWith('client')) {
          final numStr = loginId.replaceAll('client', '');
          final num = int.tryParse(numStr);
          if (num != null && num > maxClientNum) {
            maxClientNum = num;
          }
        }
      }
      final newLoginId = 'client${maxClientNum + 1}';

      // Update state
      final updatedUser = user.copyWith(
        name: name,
        phone: phone,
        loginId: newLoginId,
      );

      // Save user to Firestore
      await FirebaseFirestore.instance.collection('users').doc(updatedUser.id).set(updatedUser.toJson());

      // If child is provided, save it
      if (childName != null && childName.isNotEmpty && childAge != null && childAge.isNotEmpty) {
        final childRef = FirebaseFirestore.instance.collection('children').doc();
        await childRef.set({
          'id': childRef.id,
          'parentId': updatedUser.id,
          'name': childName,
          'level': 1,
          'xp': 0,
          'maxXp': 100,
          'notes': 'Вік: $childAge',
        });
      }

      state = updatedUser;
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    if (state == null) return;
    
    try {
      final user = state!;
      final newUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}';
      
      // Оптимістичне оновлення
      state = user.copyWith(avatarUrl: newUrl, avatarBytes: null);

      if (user.avatarUrl.contains('firebasestorage.googleapis.com')) {
        try {
          final oldRef = FirebaseStorage.instance.ref().child('avatars/${user.id}.jpg');
          await oldRef.delete();
        } catch (_) {
          // Ignore if old avatar file does not exist
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'avatarUrl': newUrl,
      });
    } catch (e) {
      debugPrint('Error deleting avatar: $e');
    }
  }
}
