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
        final prefs = await SharedPreferences.getInstance();
        final savedRoleString = prefs.getString('userRole');
        final mockUserId = prefs.getString('mockUserId');
        
        // Check if this is a mock session (admin, coach, owner, or mock active client)
        if (savedRoleString == 'admin' || savedRoleString == 'coach' || savedRoleString == 'owner' || mockUserId == 'mock_active_client') {
          if (state == null) {
            if (mockUserId == 'mock_active_client') {
              state = const AppUser(
                id: 'mock_active_client',
                name: 'Андрій',
                role: UserRole.parent,
                avatarUrl: 'https://ui-avatars.com/api/?name=Андрій',
              );
            } else {
              final role = UserRole.values.firstWhere((e) => e.name == savedRoleString);
              state = AppUser(
                id: 'mock_$savedRoleString',
                name: role == UserRole.admin ? 'Admin' : (role == UserRole.coach ? 'Coach' : 'Owner'),
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
        bool hasCachedState = false;
        
        if (savedRoleString != null) {
          final role = UserRole.values.firstWhere((e) => e.name == savedRoleString, orElse: () => UserRole.parent);
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
      // Use cache if server is unreachable without throwing a hard timeout exception
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));
          
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
      debugPrint('Simulating Google Sign In for active client...');
      final mockUserId = 'mock_active_client';
      final mockUser = AppUser(
        id: mockUserId,
        name: 'Андрій',
        role: UserRole.parent,
        avatarUrl: 'https://ui-avatars.com/api/?name=Андрій',
      );
      
      final docRef = FirebaseFirestore.instance.collection('users').doc(mockUserId);
      
      // Fire and forget Firestore setup so it doesn't block the UI if network is flaky
      docRef.get().timeout(const Duration(seconds: 3)).then((docSnap) async {
        if (!docSnap.exists) {
          await docRef.set(mockUser.toJson());
          
          final childRef = FirebaseFirestore.instance.collection('children').doc('mock_child_1');
          await childRef.set({
            'id': 'mock_child_1',
            'parentId': mockUserId,
            'name': 'Олександр',
            'colorHex': '0xFF40C4FF',
            'level': 3,
            'xp': 45,
            'maxXp': 100,
          });

          final now = DateTime.now();
          final classRef = FirebaseFirestore.instance.collection('classes').doc('mock_class_1');
          await classRef.set({
            'id': 'mock_class_1',
            'title': 'Кроль (Просунуті)',
            'startTime': DateTime(now.year, now.month, now.day, 16, 0).toIso8601String(),
            'endTime': DateTime(now.year, now.month, now.day, 17, 0).toIso8601String(),
            'coachId': 'coach_1',
            'coachName': 'Тренер Іван',
            'maxCapacity': 10,
            'enrolledChildIds': ['mock_child_1'],
            'category': 'Плавання',
            'lane': 'Доріжка 3',
          });
        }
      }).catchError((e) {
        debugPrint('Failed to seed mock data to Firestore: $e');
      });
      
      state = mockUser;
      await _syncRoleToPrefs(state);
      
      // Also update shared prefs to know this is a mock parent so we don't wipe it on restart
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mockUserId', mockUserId);
      
    } catch (e) {
      debugPrint('Error simulating Google Sign In: $e');
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mockUserId');
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
