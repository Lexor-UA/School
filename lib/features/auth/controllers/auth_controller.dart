import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/shared/utils/password_security_helper.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  bool _isLoggingIn = false;
  bool _isLoggingOut = false;

  @override
  AppUser? build() {
    // Ensure default admin account exists in Firestore
    ensureAdminInFirestore();

    // Synchronously restore cached user from SharedPreferences for instant UI state
    AppUser? initialUser;
    try {
      final prefs = ref.read(sharedPrefsProvider);
      final cachedJsonStr = prefs.getString('cachedUserJson');
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        final json = jsonDecode(cachedJsonStr) as Map<String, dynamic>;
        initialUser = AppUser.fromJson(json);
      } else {
        final savedRoleString = prefs.getString('userRole');
        final clientId = prefs.getString('clientId');
        if (savedRoleString != null) {
          final role = UserRole.values.firstWhereOrNull((e) => e.name == savedRoleString) ?? UserRole.parent;
          if (clientId != null || role == UserRole.admin || role == UserRole.owner) {
            initialUser = AppUser(
              id: clientId ?? (role == UserRole.admin ? 'admin' : 'mock_owner'),
              name: prefs.getString('userName') ?? (role == UserRole.admin ? 'Адміністратор' : 'Користувач'),
              role: role,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring initial user in build(): $e');
    }

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (_isLoggingOut) return;
      final prefs = await SharedPreferences.getInstance();
      final savedRoleString = prefs.getString('userRole');
      final mockUserId = prefs.getString('mockUserId');
      final clientId = prefs.getString('clientId');

      if (user == null) {
        // Check if there is a saved session (client, admin, coach, owner)
        if (savedRoleString != null || clientId != null || mockUserId != null) {
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
              await _syncRoleToPrefs(state);
            } catch (_) {
              state = const AppUser(
                id: 'mock_active_client',
                name: 'Андрій',
                role: UserRole.parent,
                avatarUrl: 'https://ui-avatars.com/api/?name=Андрій',
              );
            }
          } else if (savedRoleString == 'coach') {
            // Coach session restoration
            final coachId = mockUserId ?? clientId;
            if (coachId != null && coachId != 'mock_coach') {
              try {
                final doc = await FirebaseFirestore.instance.collection('users').doc(coachId).get();
                if (doc.exists) {
                  state = AppUser.fromJson(doc.data()!);
                  await _syncRoleToPrefs(state);
                  return;
                }
              } catch (_) {}
            }
            state = null;
            await _syncRoleToPrefs(null);
            await prefs.remove('mockUserId');
            await prefs.remove('clientId');
          } else if (savedRoleString == 'admin') {
            try {
              final doc = await FirebaseFirestore.instance.collection('users').doc('admin').get();
              if (doc.exists) {
                state = AppUser.fromJson(doc.data()!);
              } else {
                state = const AppUser(
                  id: 'admin',
                  name: 'Адміністратор',
                  role: UserRole.admin,
                  loginId: 'Admin',
                  phone: '+380 (99) 000-00-01',
                  avatarUrl: 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff',
                );
              }
              await _syncRoleToPrefs(state);
            } catch (_) {
              state = const AppUser(id: 'admin', name: 'Admin', role: UserRole.admin);
            }
          } else if (savedRoleString == 'owner') {
            state = const AppUser(
              id: 'mock_owner',
              name: 'Owner',
              role: UserRole.owner,
            );
            await _syncRoleToPrefs(state);
          } else if (savedRoleString == 'parent' || clientId != null) {
            // Real client / parent session restoration!
            final targetId = clientId ?? mockUserId;
            if (targetId != null) {
              await _fetchUserFromFirestore(targetId, hasCachedState: state != null);
            }
          }
        } else {
          // Genuinely unauthenticated - only clear when there is no saved role or clientId
          state = null;
          await _syncRoleToPrefs(null);
        }
      } else {
        // Firebase Auth user exists
        final effectiveId = clientId ?? user.uid;
        bool hasCachedState = state != null;

        if (savedRoleString != null) {
          final role = UserRole.values.firstWhereOrNull((e) => e.name == savedRoleString) ?? UserRole.parent;
          if (state == null || state!.id != effectiveId) {
            state = AppUser(
              id: effectiveId,
              name: user.displayName ?? prefs.getString('userName') ?? 'User',
              role: role,
            );
            hasCachedState = true;
          }
        }

        await _fetchUserFromFirestore(effectiveId, hasCachedState: hasCachedState);
      }
    });
    return initialUser;
  }

  Future<void> _syncRoleToPrefs(AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString('userRole', user.role.name);
      await prefs.setString('clientId', user.id);
      await prefs.setString('userName', user.name);
      try {
        await prefs.setString('cachedUserJson', jsonEncode(user.toJson()));
      } catch (e) {
        debugPrint('Error caching user json: $e');
      }
    } else {
      await prefs.remove('userRole');
      await prefs.remove('clientId');
      await prefs.remove('userName');
      await prefs.remove('cachedUserJson');
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
          // If we already have a cached state, do not drop session on transient cache miss
          if (!hasCachedState) {
            state = null;
            await _syncRoleToPrefs(null);
            try {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
            } catch (_) {}
            return;
          } else {
            return;
          }
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

      // Check role/login-based accounts
      if (login == 'admin' || login == 'admin@cityswim.com' || login == 'admin@gmail.com') {
        final docRef = FirebaseFirestore.instance.collection('users').doc('admin');
        final docSnap = await docRef.get();
        final storedPassword = (docSnap.data()?['password'] as String?) ?? '1';
        if (!PasswordSecurityHelper.verifyPassword(password, storedPassword)) {
          throw Exception('Невірний пароль');
        }
        if (!PasswordSecurityHelper.isHashed(storedPassword)) {
          docRef.update({'password': PasswordSecurityHelper.hashPassword(password)}).catchError((_) {});
        }

        if (docSnap.exists) {
          final data = docSnap.data()!;
          state = AppUser(
            id: 'admin',
            name: (data['name'] as String?) ?? 'Адміністратор',
            role: UserRole.admin,
            phone: data['phone'] as String?,
            loginId: (data['loginId'] as String?) ?? 'Admin',
            avatarUrl: (data['avatarUrl'] as String?) ?? 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff',
          );
        } else {
          final adminData = {
            'id': 'admin',
            'name': 'Адміністратор',
            'role': 'admin',
            'loginId': 'Admin',
            'password': '1',
            'phone': '+380 (99) 000-00-01',
            'adminSalary': 20000,
            'avatarUrl': 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff',
            'createdAt': FieldValue.serverTimestamp(),
          };
          await docRef.set(adminData);
          state = const AppUser(
            id: 'admin',
            name: 'Адміністратор',
            role: UserRole.admin,
            phone: '+380 (99) 000-00-01',
            loginId: 'Admin',
            avatarUrl: 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff',
          );
        }
        await _syncRoleToPrefs(state);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mockUserId', 'admin');
        await prefs.setString('clientId', 'admin');
        try {
          if (FirebaseAuth.instance.currentUser == null) {
            await FirebaseAuth.instance.signInAnonymously();
          }
        } catch (_) {}
        return;
      } else if (login == 'owner' || login == 'owner@cityswim.com' || login == 'owner@gmail.com') {
        final docRef = FirebaseFirestore.instance.collection('users').doc('mock_owner');
        final docSnap = await docRef.get();
        final storedPassword = (docSnap.data()?['password'] as String?) ?? '1';
        if (!PasswordSecurityHelper.verifyPassword(password, storedPassword)) {
          throw Exception('Невірний пароль');
        }
        if (!PasswordSecurityHelper.isHashed(storedPassword)) {
          docRef.update({'password': PasswordSecurityHelper.hashPassword(password)}).catchError((_) {});
        }
        state = const AppUser(id: 'mock_owner', name: 'Owner', role: UserRole.owner);
        await _syncRoleToPrefs(state);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mockUserId', 'mock_owner');
        await prefs.setString('clientId', 'mock_owner');
        try {
          if (FirebaseAuth.instance.currentUser == null) {
            await FirebaseAuth.instance.signInAnonymously();
          }
        } catch (_) {}
        return;
      } else if (login.startsWith('coach')) {
        final usersSnap = await FirebaseFirestore.instance.collection('users').where('loginId', isEqualTo: login).get();
        if (usersSnap.docs.isNotEmpty) {
          final userData = usersSnap.docs.first.data();
          final storedPassword = (userData['password'] as String?) ?? '1';
          if (!PasswordSecurityHelper.verifyPassword(password, storedPassword)) {
            throw Exception('Невірний пароль');
          }
          if (!PasswordSecurityHelper.isHashed(storedPassword)) {
            usersSnap.docs.first.reference.update({'password': PasswordSecurityHelper.hashPassword(password)}).catchError((_) {});
          }
          state = AppUser.fromJson(userData);
          await _syncRoleToPrefs(state);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('clientId', state!.id);
          await prefs.setString('mockUserId', state!.id);
          try {
            if (FirebaseAuth.instance.currentUser == null) {
              await FirebaseAuth.instance.signInAnonymously();
            }
          } catch (_) {}
          return;
        } else {
          throw Exception('Тренера з логіном $login не знайдено');
        }
      } else if (login == 'client' || login == 'client1' || login == 'parent' || login.startsWith('client') || !login.contains('@')) {
        final normalizedPhone = _normalizePhone(email);
        final rawDigits = email.replaceAll(RegExp(r'\D'), '');

        var usersSnap = await FirebaseFirestore.instance.collection('users').where('loginId', isEqualTo: login).get();
        if (usersSnap.docs.isEmpty) {
          usersSnap = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: normalizedPhone).get();
        }
        if (usersSnap.docs.isEmpty && rawDigits.length >= 9) {
          final allParents = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'parent').get();
          final last9 = rawDigits.substring(rawDigits.length - 9);
          final matchedDoc = allParents.docs.firstWhereOrNull((d) {
            final p = (d.data()['phone'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
            return p.endsWith(last9);
          });
          if (matchedDoc != null) {
            usersSnap = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, isEqualTo: matchedDoc.id).get();
          }
        }
        if (usersSnap.docs.isEmpty && (login == 'client' || login == 'client1' || login == 'parent')) {
          usersSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'parent').limit(1).get();
        }
        if (usersSnap.docs.isNotEmpty) {
          final userData = usersSnap.docs.first.data();
          final storedPassword = (userData['password'] as String?) ?? '1';
          if (!PasswordSecurityHelper.verifyPassword(password, storedPassword)) {
            throw Exception('Невірний пароль');
          }
          if (!PasswordSecurityHelper.isHashed(storedPassword)) {
            usersSnap.docs.first.reference.update({'password': PasswordSecurityHelper.hashPassword(password)}).catchError((_) {});
          }
          state = AppUser.fromJson(userData);
          await _syncRoleToPrefs(state);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('clientId', state!.id);
          try {
            if (FirebaseAuth.instance.currentUser == null) {
              await FirebaseAuth.instance.signInAnonymously();
            }
          } catch (_) {}
          return;
        } else if (login == 'client' || login == 'client1' || login == 'parent') {
          final demoClient = {
            'id': 'demo_client',
            'name': 'Олександр Спіян',
            'role': 'parent',
            'phone': '+380685566322',
            'loginId': 'client',
            'password': '1',
            'avatarUrl': 'https://ui-avatars.com/api/?name=Oleksandr+Spiian&background=0284c7&color=ffffff',
            'createdAt': FieldValue.serverTimestamp(),
          };
          await FirebaseFirestore.instance.collection('users').doc('demo_client').set(demoClient, SetOptions(merge: true));
          state = const AppUser(
            id: 'demo_client',
            name: 'Олександр Спіян',
            role: UserRole.parent,
            phone: '+380685566322',
            loginId: 'client',
            avatarUrl: 'https://ui-avatars.com/api/?name=Oleksandr+Spiian&background=0284c7&color=ffffff',
          );
          await _syncRoleToPrefs(state);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('clientId', 'demo_client');
          try {
            if (FirebaseAuth.instance.currentUser == null) {
              await FirebaseAuth.instance.signInAnonymously();
            }
          } catch (_) {}
          return;
        } else if (login.startsWith('client')) {
          throw Exception('Клієнта з логіном $login не знайдено');
        }
      }

      if (login.contains('@')) {
        final emailSnap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: login).get();
        if (emailSnap.docs.isNotEmpty) {
          final userData = emailSnap.docs.first.data();
          final storedPassword = (userData['password'] as String?) ?? '1';
          if (!PasswordSecurityHelper.verifyPassword(password, storedPassword)) {
            throw Exception('Невірний пароль');
          }
          if (!PasswordSecurityHelper.isHashed(storedPassword)) {
            emailSnap.docs.first.reference.update({'password': PasswordSecurityHelper.hashPassword(password)}).catchError((_) {});
          }
          state = AppUser.fromJson(userData);
          await _syncRoleToPrefs(state);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('clientId', state!.id);
          try {
            if (FirebaseAuth.instance.currentUser == null) {
              await FirebaseAuth.instance.signInAnonymously();
            }
          } catch (_) {}
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

  String _normalizePhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('380') && digits.length >= 12) {
      return '+$digits';
    } else if (digits.startsWith('0') && digits.length == 10) {
      return '+38$digits';
    } else if (digits.length == 9) {
      return '+380$digits';
    }
    return phone.trim();
  }

  Future<AppUser> registerParentWithPhoneOrEmail({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    try {
      final rawLogin = phone.trim();
      if (rawLogin.isEmpty) {
        throw Exception('Введіть логін');
      }
      if (password.trim().length < 4) {
        throw Exception('Пароль має містити щонайменше 4 символи');
      }

      final rawDigits = rawLogin.replaceAll(RegExp(r'\D'), '');
      final isPhone = !rawLogin.contains('@') && rawDigits.length >= 9;

      String? normalizedPhone;
      String? userEmail;
      String? customLoginId;

      final allUsers = await FirebaseFirestore.instance.collection('users').get();

      if (isPhone) {
        normalizedPhone = _normalizePhone(rawLogin);
        final last9 = rawDigits.substring(rawDigits.length - 9);
        final duplicate = allUsers.docs.firstWhereOrNull((d) {
          final p = (d.data()['phone'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
          return p.endsWith(last9);
        });
        if (duplicate != null) {
          throw Exception('Користувач із таким номером вже існує в системі. Будь ласка, увійдіть.');
        }
      } else if (rawLogin.contains('@')) {
        userEmail = rawLogin.toLowerCase();
        final duplicate = allUsers.docs.firstWhereOrNull((d) {
          final e = (d.data()['email'] as String? ?? '').toLowerCase();
          return e == userEmail;
        });
        if (duplicate != null) {
          throw Exception('Користувач із таким email вже існує в системі. Будь ласка, увійдіть.');
        }
      } else {
        customLoginId = rawLogin.toLowerCase();
        final duplicate = allUsers.docs.firstWhereOrNull((d) {
          final l = (d.data()['loginId'] as String? ?? '').toLowerCase();
          return l == customLoginId;
        });
        if (duplicate != null) {
          throw Exception('Користувач із таким логіном вже існує в системі. Будь ласка, увійдіть.');
        }
      }

      // Calculate sequential loginId for CRM if not a custom login
      int maxClientNum = 0;
      for (var doc in allUsers.docs) {
        final loginId = doc.data()['loginId'] as String?;
        if (loginId != null && loginId.startsWith('client')) {
          final numStr = loginId.replaceAll('client', '');
          final num = int.tryParse(numStr);
          if (num != null && num > maxClientNum) {
            maxClientNum = num;
          }
        }
      }
      final sequentialLoginId = 'client${maxClientNum + 1}';
      final assignedLoginId = customLoginId ?? sequentialLoginId;

      // Create new user document
      final newDocRef = FirebaseFirestore.instance.collection('users').doc();
      final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
      final avatarInitials = parts.isNotEmpty
          ? (parts.length > 1 ? '${parts[0][0]}+${parts[1][0]}' : parts[0][0])
          : 'Client';

      final newClientData = {
        'id': newDocRef.id,
        'name': name.trim(),
        'role': 'parent',
        'phone': ?normalizedPhone,
        'loginId': assignedLoginId,
        'password': PasswordSecurityHelper.hashPassword(password.trim()),
        'email': ?userEmail,
        'avatarUrl': 'https://ui-avatars.com/api/?name=$avatarInitials&background=0284c7&color=ffffff',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await newDocRef.set(newClientData);

      final newUser = AppUser(
        id: newDocRef.id,
        name: name.trim(),
        role: UserRole.parent,
        phone: normalizedPhone,
        loginId: assignedLoginId,
        avatarUrl: 'https://ui-avatars.com/api/?name=$avatarInitials&background=0284c7&color=ffffff',
      );

      state = newUser;
      await _syncRoleToPrefs(state);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('clientId', newUser.id);
      await prefs.setBool('needsOnboarding', true);

      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
      } catch (_) {}

      return newUser;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoggingOut = true;
    try {
      state = null;
      await _syncRoleToPrefs(null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mockUserId');
      await prefs.remove('clientId');
      await prefs.remove('userName');
      await prefs.remove('cachedUserJson');
      await prefs.remove('needsOnboarding');
      await prefs.remove('userRole');

      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } catch (_) {}
    } finally {
      _isLoggingOut = false;
    }
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
      await _syncRoleToPrefs(state);
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

  Future<void> completeOnboarding(
    String name,
    String phone, {
    int? age,
    String? goal,
    String? level,
    bool isAdultOnly = false,
    List<Map<String, dynamic>>? children,
    String? childName,
    dynamic childAge,
  }) async {
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
      final newLoginId = (user.loginId != null && user.loginId!.isNotEmpty) ? user.loginId! : 'client${maxClientNum + 1}';

      // Update state
      final updatedUser = user.copyWith(
        name: name,
        phone: phone,
        loginId: newLoginId,
      );

      // Save user to Firestore including age, goal, level
      final userMap = updatedUser.toJson();
      if (age != null) {
        userMap['age'] = age;
      }
      if (goal != null && goal.isNotEmpty) {
        userMap['swimmingGoal'] = goal;
      }
      if (level != null && level.isNotEmpty) {
        userMap['swimmingLevel'] = level;
      }
      userMap['isAdultOnly'] = isAdultOnly;
      userMap['onboardingCompleted'] = true;
      await FirebaseFirestore.instance.collection('users').doc(updatedUser.id).set(userMap);

      // Save children if provided as list
      if (children != null && children.isNotEmpty) {
        for (var c in children) {
          final cName = (c['name'] as String?)?.trim();
          final cAge = c['age'] is int ? c['age'] as int : int.tryParse(c['age']?.toString() ?? '');
          final cGoal = (c['goal'] as String?)?.trim();
          if (cName != null && cName.isNotEmpty) {
            final childRef = FirebaseFirestore.instance.collection('children').doc();
            String childNotes = '';
            if (cAge != null && cGoal != null && cGoal.isNotEmpty) {
              childNotes = 'Вік: $cAge • Ціль: $cGoal';
            } else if (cGoal != null && cGoal.isNotEmpty) {
              childNotes = 'Ціль: $cGoal';
            } else if (cAge != null) {
              childNotes = 'Вік: $cAge';
            }

            final childData = <String, dynamic>{
              'id': childRef.id,
              'parentId': updatedUser.id,
              'name': cName,
              'level': 1,
              'xp': 0,
              'maxXp': 100,
              'colorHex': '0xFF40C4FF',
              'notes': childNotes,
            };
            if (cAge != null) {
              childData['age'] = cAge;
            }
            if (cGoal != null && cGoal.isNotEmpty) {
              childData['goal'] = cGoal;
            }
            await childRef.set(childData);
          }
        }
      } else if (childName != null && childName.trim().isNotEmpty) {
        // Fallback for single child
        final parsedAge = childAge is int ? childAge : int.tryParse(childAge?.toString() ?? '');
        final childRef = FirebaseFirestore.instance.collection('children').doc();
        final childData = <String, dynamic>{
          'id': childRef.id,
          'parentId': updatedUser.id,
          'name': childName.trim(),
          'level': 1,
          'xp': 0,
          'maxXp': 100,
          'colorHex': '0xFF40C4FF',
          'notes': parsedAge != null ? 'Вік: $parsedAge' : '',
        };
        if (parsedAge != null) {
          childData['age'] = parsedAge;
        }
        await childRef.set(childData);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('needsOnboarding');

      state = updatedUser;
      await _syncRoleToPrefs(state);
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
      await _syncRoleToPrefs(state);

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'avatarUrl': newUrl,
      });
    } catch (e) {
      debugPrint('Error deleting avatar: $e');
    }
  }
}

/// Guarantees that the default Admin profile exists in Firestore `users` collection.
Future<void> ensureAdminInFirestore() async {
  try {
    final docRef = FirebaseFirestore.instance.collection('users').doc('admin');
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set({
        'id': 'admin',
        'name': 'Адміністратор',
        'role': 'admin',
        'loginId': 'Admin',
        'password': '1',
        'phone': '+380 (99) 000-00-01',
        'adminSalary': 20000,
        'avatarUrl': 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = docSnap.data() ?? {};
      final role = (data['role'] as String?)?.toLowerCase();
      if (role != 'admin') {
        await docRef.update({'role': 'admin'});
      }
    }
  } catch (e) {
    debugPrint('Error in ensureAdminInFirestore: $e');
  }
}
