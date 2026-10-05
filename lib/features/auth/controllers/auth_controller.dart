import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/shared/utils/password_security_helper.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  bool _isLoggingIn = false;
  bool _isLoggingOut = false;

  Branch _getEffectiveBranchSync() {
    try {
      final prefs = ref.read(sharedPrefsProvider);
      final branchId = prefs.getString('userBranchId') ?? prefs.getString('selected_branch_id');
      if (branchId != null) {
        final found = Branch.defaultBranches.firstWhereOrNull((b) => b.id == branchId);
        if (found != null) return found;
      }
    } catch (_) {}
    return Branch.kyiv;
  }

  @override
  AppUser? build() {

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
      if (_isLoggingOut || _isLoggingIn) return;
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
            await _ensureStaffFirebaseAuth(email: 'client.demo@cityswim.app', password: 'client123456');
            await _syncAuthUserDoc(state);
          } else if (savedRoleString == 'coach') {
            // Coach session restoration
            final coachId = mockUserId ?? clientId;
            if (coachId != null && coachId != 'mock_coach') {
              try {
                final doc = await FirebaseFirestore.instance.collection('users').doc(coachId).get();
                if (doc.exists) {
                  state = AppUser.fromJson(doc.data()!);
                  await _syncRoleToPrefs(state);
                  await _ensureCoachFirebaseAuth(coachId, state);
                  return;
                }
              } catch (_) {}
            }
            state = null;
            await _syncRoleToPrefs(null);
            await prefs.remove('mockUserId');
            await prefs.remove('clientId');
          } else if (savedRoleString == 'admin') {
            final mockUserId = prefs.getString('mockUserId');
            final savedBranch = prefs.getString('userBranchId') ?? prefs.getString('selected_branch_id');
            final isAdminVienna = mockUserId == 'admin_vienna' || savedBranch == 'vienna';
            final targetDocId = isAdminVienna ? 'admin_vienna' : 'admin';
            try {
              final doc = await FirebaseFirestore.instance.collection('users').doc(targetDocId).get();
              if (doc.exists) {
                state = AppUser.fromJson(doc.data()!);
              } else {
                state = isAdminVienna
                    ? const AppUser(
                        id: 'admin_vienna',
                        name: 'Адміністратор Відень',
                        role: UserRole.admin,
                        branchId: 'vienna',
                        branchIds: ['vienna'],
                        loginId: 'admin_vienna',
                        phone: '+43 1 234 5678',
                        avatarUrl: 'https://ui-avatars.com/api/?name=Admin+Vienna&background=8b5cf6&color=ffffff',
                      )
                    : const AppUser(
                        id: 'admin',
                        name: 'Адміністратор Київ',
                        role: UserRole.admin,
                        branchId: 'kyiv',
                        branchIds: ['kyiv'],
                        loginId: 'admin_kyiv',
                        phone: '+380 (99) 000-00-01',
                        avatarUrl: 'https://ui-avatars.com/api/?name=Admin+Kyiv&background=8b5cf6&color=ffffff',
                      );
              }
              await _syncRoleToPrefs(state);
            } catch (_) {
              state = isAdminVienna
                  ? const AppUser(id: 'admin_vienna', name: 'Адміністратор Відень', role: UserRole.admin, branchId: 'vienna', branchIds: ['vienna'])
                  : const AppUser(id: 'admin', name: 'Адміністратор Київ', role: UserRole.admin, branchId: 'kyiv', branchIds: ['kyiv']);
            }
            final staffEmail = isAdminVienna ? 'admin.vienna@cityswim.app' : 'admin.kyiv@cityswim.app';
            final staffPass = isAdminVienna ? 'vienna123456' : 'kyiv123456';
            await _ensureStaffFirebaseAuth(email: staffEmail, password: staffPass);
            await _syncAuthUserDoc(state);
          } else if (savedRoleString == 'owner') {
            state = const AppUser(
              id: 'mock_owner',
              name: 'Owner',
              role: UserRole.owner,
            );
            await _syncRoleToPrefs(state);
            await _ensureStaffFirebaseAuth(email: 'owner@cityswim.app', password: 'owner123456');
            await _syncAuthUserDoc(state);
          } else if (savedRoleString == 'parent' || clientId != null) {
            // Real client / parent session restoration!
            final targetId = clientId ?? mockUserId;
            if (targetId != null) {
              final isDemo = targetId == 'demo_client' || targetId == 'mock_active_client';
              final safeId = targetId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
              final clientEmail = isDemo ? 'client.demo@cityswim.app' : 'client.${safeId.isEmpty ? "parent" : safeId}@cityswim.app';
              await _ensureStaffFirebaseAuth(email: clientEmail, password: 'client123456');
              await _fetchUserFromFirestore(targetId, hasCachedState: state != null);
              await _syncAuthUserDoc(state);
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

        final role = savedRoleString != null
            ? (UserRole.values.firstWhereOrNull((e) => e.name == savedRoleString) ?? UserRole.parent)
            : UserRole.parent;

        if (state == null || state!.id != effectiveId) {
          final effectiveName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : (prefs.getString('userName') ?? 'Користувач');
          final effectivePhoto = user.photoURL ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(effectiveName)}&background=0284c7&color=ffffff';
          final effectiveBranch = _getEffectiveBranchSync();
          final branchId = prefs.getString('userBranchId') ?? effectiveBranch.id;

          state = AppUser(
            id: effectiveId,
            name: effectiveName,
            role: role,
            avatarUrl: effectivePhoto,
            branchId: branchId,
            branchIds: [branchId],
            organizationId: effectiveBranch.organizationId,
          );
          hasCachedState = true;
          await _syncRoleToPrefs(state);
        }

        await _fetchUserFromFirestore(effectiveId, hasCachedState: hasCachedState);
        _syncAuthUserDoc(state);
      }
    });
    return initialUser;
  }

  Future<void> syncCurrentAuthUserDoc() async {
    await _syncAuthUserDoc(state);
  }

  Future<void> _syncRoleToPrefs(AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString('userRole', user.role.name);
      await prefs.setString('clientId', user.id);
      await prefs.setString('userName', user.name);
      await prefs.setString('userBranchId', user.branchId);
      await prefs.setString('userOrgId', user.organizationId);
      try {
        await prefs.setString('cachedUserJson', jsonEncode(user.toJson()));
      } catch (e) {
        debugPrint('Error caching user json: $e');
      }
      _syncAuthUserDoc(user);
      if (!kIsWeb) {
        try {
          FirebaseCrashlytics.instance.setUserIdentifier(user.id);
          FirebaseCrashlytics.instance.setCustomKey('role', user.role.name);
          FirebaseCrashlytics.instance.setCustomKey('branchId', user.branchId);
          FirebaseCrashlytics.instance.setCustomKey('userName', user.name);
        } catch (_) {}
      }
    } else {
      await prefs.remove('userRole');
      await prefs.remove('clientId');
      await prefs.remove('userName');
      await prefs.remove('userBranchId');
      await prefs.remove('userOrgId');
      await prefs.remove('cachedUserJson');
      if (!kIsWeb) {
        try {
          FirebaseCrashlytics.instance.setUserIdentifier('guest');
          FirebaseCrashlytics.instance.setCustomKey('role', 'none');
          FirebaseCrashlytics.instance.setCustomKey('branchId', 'none');
          FirebaseCrashlytics.instance.setCustomKey('userName', 'guest');
        } catch (_) {}
      }
    }
  }

  Future<void> _syncAuthUserDoc(AppUser? user) async {
    if (user == null) return;
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final roleStr = user.role.name;
        final branch = (user.branchId.isNotEmpty) ? user.branchId : 'kyiv';
        final branchList = (user.branchIds.isNotEmpty) ? user.branchIds : [branch];
        await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
          'id': fbUser.uid,
          'role': roleStr,
          'branchId': branch,
          'branchIds': branchList,
          'name': user.name,
          if (user.phone != null && user.phone!.isNotEmpty) 'phone': user.phone,
          if (fbUser.email != null) 'email': fbUser.email,
          'aliasOf': user.id,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((e) {
          debugPrint('Error syncing auth user doc: $e');
        });
      }
    } catch (e) {
      debugPrint('Exception in _syncAuthUserDoc: $e');
    }
  }

  Future<void> _ensureStaffFirebaseAuth({
    required String email,
    required String password,
  }) async {
    try {
      if (FirebaseAuth.instance.currentUser?.email == email) {
        return;
      }
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (authEx) {
        debugPrint('Staff signIn error for $email: ${authEx.code}');
        if (authEx.code == 'user-not-found') {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (createErr) {
            debugPrint('Staff createUser error: $createErr');
          }
        } else if (authEx.code == 'invalid-credential' || authEx.code == 'wrong-password') {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } on FirebaseAuthException catch (createEx) {
            if (createEx.code == 'email-already-in-use') {
              final fallbacks = ['123456', 'cityswim123', 'admin123', 'coach123'];
              for (final altPass in fallbacks) {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: altPass,
                  );
                  break;
                } catch (_) {}
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Staff Firebase Auth sign-in exception: $e');
    }
  }

  Future<void> _ensureCoachFirebaseAuth(String login, AppUser? user) async {
    String coachEmail = 'coach.kyiv@cityswim.app';
    if (login.contains('maria')) {
      coachEmail = 'coach.maria@cityswim.app';
    } else if (login.contains('stefan')) {
      coachEmail = 'coach.stefan@cityswim.app';
    } else if (user?.branchId == 'vienna') {
      coachEmail = 'coach.vienna@cityswim.app';
    }
    await _ensureStaffFirebaseAuth(email: coachEmail, password: 'coach123456');
    await _syncAuthUserDoc(user);
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
        final data = doc.data()!;
        final hasOnboardingFlag = data['onboardingCompleted'] == true;
        final hasPhone = (data['phone'] as String?)?.trim().isNotEmpty == true;

        bool isCompleted = hasOnboardingFlag || hasPhone;
        if (!isCompleted) {
          try {
            final subsSnap = await FirebaseFirestore.instance
                .collection('subscriptions')
                .where('userId', isEqualTo: uid)
                .limit(1)
                .get();
            if (subsSnap.docs.isNotEmpty) {
              isCompleted = true;
              await FirebaseFirestore.instance.collection('users').doc(uid).set(
                {'onboardingCompleted': true},
                SetOptions(merge: true),
              );
            }
          } catch (_) {}
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needsOnboarding', !isCompleted);
        await _syncRoleToPrefs(state);
      } else {
        // If the user is authenticated in Firebase Auth, never drop session!
        final currentAuthUser = FirebaseAuth.instance.currentUser;
        if (currentAuthUser != null && currentAuthUser.uid == uid) {
          final prefs = await SharedPreferences.getInstance();
          final effectiveBranch = _getEffectiveBranchSync();
          final branchId = prefs.getString('userBranchId') ?? effectiveBranch.id;
          final name = (currentAuthUser.displayName != null && currentAuthUser.displayName!.trim().isNotEmpty)
              ? currentAuthUser.displayName!.trim()
              : (prefs.getString('userName') ?? 'Користувач');
          final avatar = currentAuthUser.photoURL ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=0284c7&color=ffffff';

          state = AppUser(
            id: uid,
            name: name,
            role: UserRole.parent,
            avatarUrl: avatar,
            branchId: branchId,
            branchIds: [branchId],
            organizationId: effectiveBranch.organizationId,
          );
          await _syncRoleToPrefs(state);
          return;
        }

        if (!_isLoggingIn) {
          // If we already have a cached state, do not drop session on transient cache miss
          if (!hasCachedState) {
            state = null;
            await _syncRoleToPrefs(null);
            try {
              await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 3));
              await GoogleSignIn.instance.signOut().timeout(const Duration(seconds: 3));
            } catch (_) {}
            return;
          } else {
            return;
          }
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        final effectiveBranch = _getEffectiveBranchSync();
        state = AppUser(
          id: uid,
          name: currentUser?.displayName ?? 'New User',
          role: UserRole.parent,
          branchId: effectiveBranch.id,
          branchIds: [effectiveBranch.id],
          organizationId: effectiveBranch.organizationId,
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
          await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 3));
        } catch (_) {}
      }
    }
  }

  String _cleanPhoneDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) {
      return digits.substring(digits.length - 9);
    }
    return digits;
  }

  Future<void> _migrateUserData({
    required String oldUserId,
    required String newUserId,
    Map<String, dynamic>? oldUserData,
  }) async {
    if (oldUserId == newUserId) return;
    final firestore = FirebaseFirestore.instance;
    debugPrint('Smart Account Linking: Migrating data from $oldUserId to $newUserId');

    try {
      final batch = firestore.batch();
      bool hasBatchOps = false;

      // 1. Subscriptions: userId == oldUserId -> update to newUserId
      final subsSnap = await firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: oldUserId)
          .get();
      for (final doc in subsSnap.docs) {
        batch.update(doc.reference, {'userId': newUserId});
        hasBatchOps = true;
      }

      // 2. Children: parentId == oldUserId -> update to newUserId
      final childrenSnap = await firestore
          .collection('children')
          .where('parentId', isEqualTo: oldUserId)
          .get();
      for (final doc in childrenSnap.docs) {
        batch.update(doc.reference, {'parentId': newUserId});
        hasBatchOps = true;
      }

      // 3. Notifications: userId == oldUserId -> update to newUserId
      final notifSnap = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: oldUserId)
          .get();
      for (final doc in notifSnap.docs) {
        batch.update(doc.reference, {'userId': newUserId});
        hasBatchOps = true;
      }

      // 4. Payments: clientId == oldUserId -> update to newUserId
      final paymentsSnap = await firestore
          .collection('payments')
          .where('clientId', isEqualTo: oldUserId)
          .get();
      for (final doc in paymentsSnap.docs) {
        batch.update(doc.reference, {'clientId': newUserId});
        hasBatchOps = true;
      }

      // 5. Families: parentIds contains oldUserId
      final famSnap = await firestore
          .collection('families')
          .where('parentIds', arrayContains: oldUserId)
          .get();
      for (final doc in famSnap.docs) {
        final data = doc.data();
        final parentIds = List<String>.from(data['parentIds'] ?? []);
        parentIds.remove(oldUserId);
        if (!parentIds.contains(newUserId)) {
          parentIds.add(newUserId);
        }

        final parentNames = Map<String, dynamic>.from(data['parentNames'] ?? {});
        if (parentNames.containsKey(oldUserId)) {
          final nameVal = parentNames.remove(oldUserId);
          parentNames[newUserId] = nameVal;
        }

        final parentPhones = Map<String, dynamic>.from(data['parentPhones'] ?? {});
        if (parentPhones.containsKey(oldUserId)) {
          final phoneVal = parentPhones.remove(oldUserId);
          parentPhones[newUserId] = phoneVal;
        }

        batch.update(doc.reference, {
          'parentIds': parentIds,
          'parentNames': parentNames,
          'parentPhones': parentPhones,
        });
        hasBatchOps = true;
      }

      // 6. Classes: enrolledChildIds contains oldUserId (for adult participants)
      final classesSnap = await firestore
          .collection('classes')
          .where('enrolledChildIds', arrayContains: oldUserId)
          .get();
      for (final doc in classesSnap.docs) {
        final data = doc.data();
        final enrolled = List<String>.from(data['enrolledChildIds'] ?? []);
        enrolled.remove(oldUserId);
        if (!enrolled.contains(newUserId)) {
          enrolled.add(newUserId);
        }
        batch.update(doc.reference, {'enrolledChildIds': enrolled});
        hasBatchOps = true;
      }

      // 7. Mark old user document as merged
      final oldUserRef = firestore.collection('users').doc(oldUserId);
      batch.set(oldUserRef, {
        'mergedInto': newUserId,
        'mergedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      }, SetOptions(merge: true));
      hasBatchOps = true;

      if (hasBatchOps) {
        await batch.commit();
      }
      debugPrint('Smart Account Linking: Successfully migrated data from $oldUserId to $newUserId');
    } catch (e) {
      debugPrint('Error migrating user data from $oldUserId to $newUserId: $e');
    }
  }

  Future<Map<String, dynamic>> _findOrMergeExistingClient({
    required String newUid,
    required String? email,
    required String? phone,
    required String name,
    required String avatarUrl,
    required String assignedBranchId,
    required String organizationId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(newUid);
    final userDocSnap = await userDocRef.get();

    String? foundOldUserId;
    Map<String, dynamic> mergedData = {};

    if (userDocSnap.exists) {
      mergedData = Map<String, dynamic>.from(userDocSnap.data()!);
    }

    // 1. If newUid doc does not exist, or exists but has 0 subscriptions, check for matching existing account
    final existingSubs = await firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: newUid)
        .limit(1)
        .get();

    final hasSubsUnderNewUid = existingSubs.docs.isNotEmpty;

    if (!userDocSnap.exists || !hasSubsUnderNewUid) {
      // Try to find matching user by email
      final cleanEmail = email?.trim().toLowerCase();
      if (cleanEmail != null && cleanEmail.isNotEmpty) {
        try {
          final querySnap = await firestore
              .collection('users')
              .where('email', isEqualTo: cleanEmail)
              .get();
          for (final doc in querySnap.docs) {
            if (doc.id != newUid && doc.data()['mergedInto'] == null) {
              foundOldUserId = doc.id;
              mergedData = {...doc.data(), ...mergedData};
              break;
            }
          }
        } catch (e) {
          debugPrint('Notice: Email user lookup error: $e');
        }
      }

      // Try to find matching user by phone if phone is provided
      if (foundOldUserId == null && phone != null && phone.trim().isNotEmpty) {
        final phoneDigits = _cleanPhoneDigits(phone);
        if (phoneDigits.length >= 7) {
          try {
            final querySnap = await firestore
                .collection('users')
                .where('phone', isEqualTo: phone.trim())
                .get();
            for (final doc in querySnap.docs) {
              if (doc.id != newUid && doc.data()['mergedInto'] == null) {
                foundOldUserId = doc.id;
                mergedData = {...doc.data(), ...mergedData};
                break;
              }
            }
          } catch (e) {
            debugPrint('Notice: Phone user lookup error: $e');
          }
        }
      }

      // If an existing account was found under a different ID, migrate everything!
      if (foundOldUserId != null && foundOldUserId != newUid) {
        await _migrateUserData(
          oldUserId: foundOldUserId,
          newUserId: newUid,
          oldUserData: mergedData,
        );
      }
    }

    // Determine final effective properties
    final existingName = (mergedData['name'] as String?)?.trim();
    final effectiveName = (existingName != null && existingName.isNotEmpty && existingName != 'New User' && existingName != 'Користувач')
        ? existingName
        : name;

    final existingAvatar = mergedData['avatarUrl'] as String?;
    final effectiveAvatar = (existingAvatar != null && existingAvatar.isNotEmpty && !existingAvatar.contains('ui-avatars.com'))
        ? existingAvatar
        : avatarUrl;

    // Check if subscriptions exist under newUid now (either migrated or existing)
    final checkSubs = await firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: newUid)
        .limit(1)
        .get();
    final hasActiveOrAnySubs = checkSubs.docs.isNotEmpty;

    final isCompleted = hasActiveOrAnySubs ||
        (mergedData['onboardingCompleted'] == true) ||
        (mergedData['phone'] != null && (mergedData['phone'] as String).trim().isNotEmpty);

    final safeUserData = <String, dynamic>{
      'id': newUid,
      'name': effectiveName,
      'role': 'parent',
      'avatarUrl': effectiveAvatar,
      if (email != null && email.isNotEmpty) 'email': email,
      if (mergedData['phone'] != null) 'phone': mergedData['phone'],
      if (mergedData['loginId'] != null) 'loginId': mergedData['loginId'],
      'branchId': (mergedData['branchId'] as String?) ?? assignedBranchId,
      'branchIds': mergedData['branchIds'] is List
          ? List<String>.from(mergedData['branchIds'])
          : [assignedBranchId],
      'organizationId': (mergedData['organizationId'] as String?) ?? organizationId,
      'onboardingCompleted': isCompleted,
      if (mergedData['age'] != null) 'age': mergedData['age'],
      if (mergedData['swimmingGoal'] != null) 'swimmingGoal': mergedData['swimmingGoal'],
      if (mergedData['swimmingLevel'] != null) 'swimmingLevel': mergedData['swimmingLevel'],
      if (mergedData['isAdultOnly'] != null) 'isAdultOnly': mergedData['isAdultOnly'],
      'mergedFrom': ?foundOldUserId,
      if (!userDocSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    await userDocRef.set(safeUserData, SetOptions(merge: true));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('needsOnboarding', !isCompleted);

    return safeUserData;
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
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: kIsWeb ? null : '720928546774-fm9fipmt88b2uqp2n5cbogq6r0gg1l1u.apps.googleusercontent.com',
      );
      
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await GoogleSignIn.instance.attemptLightweightAuthentication() ??
            await GoogleSignIn.instance.authenticate();
      } catch (authErr) {
        final errStr = authErr.toString();
        final isNetworkOrTokenErr = errStr.contains('-1017') ||
            errStr.contains('org.openid.appauth.general') ||
            errStr.contains('Connection error') ||
            errStr.contains('Network') ||
            errStr.contains('network_error') ||
            errStr.contains('kCFErrorDomainCFNetwork');
        if (isNetworkOrTokenErr) {
          debugPrint('Retrying Google Sign In after network token error: $authErr');
          await GoogleSignIn.instance.signOut().catchError((_) {});
          await Future.delayed(const Duration(milliseconds: 1000));
          await GoogleSignIn.instance.initialize(
            clientId: clientId,
            serverClientId: kIsWeb ? null : '720928546774-fm9fipmt88b2uqp2n5cbogq6r0gg1l1u.apps.googleusercontent.com',
          );
          googleUser = await GoogleSignIn.instance.authenticate();
        } else {
          rethrow;
        }
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final effectiveBranch = _getEffectiveBranchSync();
        final assignedBranchId = prefs.getString('userBranchId') ?? effectiveBranch.id;

        final googleName = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
            ? fbUser.displayName!.trim()
            : (googleUser.displayName != null && googleUser.displayName!.trim().isNotEmpty
                ? googleUser.displayName!.trim()
                : 'Користувач');
        final googlePhoto = fbUser.photoURL ?? googleUser.photoUrl;
        final googleEmail = fbUser.email ?? googleUser.email;

        final defaultAvatar = (googlePhoto != null && googlePhoto.isNotEmpty)
            ? googlePhoto
            : '';

        final finalUserData = await _findOrMergeExistingClient(
          newUid: fbUser.uid,
          email: googleEmail,
          phone: fbUser.phoneNumber,
          name: googleName,
          avatarUrl: defaultAvatar,
          assignedBranchId: assignedBranchId,
          organizationId: effectiveBranch.organizationId,
        );

        state = AppUser.fromJson(finalUserData);
        await _syncRoleToPrefs(state);
        await prefs.setString('clientId', fbUser.uid);
      }
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      rethrow;
    } finally {
      _isLoggingIn = false;
    }
  }

  Future<void> signInWithApple() async {
    try {
      _isLoggingIn = true;
      
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'city.swim.school.signin',
          redirectUri: Uri.parse('https://city-swim.firebaseapp.com/__/auth/handler'),
        ),
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = userCredential.user;
      
      if (fbUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final effectiveBranch = _getEffectiveBranchSync();
        final assignedBranchId = prefs.getString('userBranchId') ?? effectiveBranch.id;

        final appleName = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
            ? fbUser.displayName!.trim()
            : (appleCredential.givenName != null ? '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim() : 'Користувач Apple');
            
        final appleEmail = fbUser.email ?? appleCredential.email;
        final defaultAvatar = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(appleName)}&background=000000&color=ffffff';

        final finalUserData = await _findOrMergeExistingClient(
          newUid: fbUser.uid,
          email: appleEmail,
          phone: fbUser.phoneNumber,
          name: appleName,
          avatarUrl: defaultAvatar,
          assignedBranchId: assignedBranchId,
          organizationId: effectiveBranch.organizationId,
        );

        state = AppUser.fromJson(finalUserData);
        await _syncRoleToPrefs(state);
        await prefs.setString('clientId', fbUser.uid);
      }
    } catch (e) {
      debugPrint('Error during Apple Sign In: $e');
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
      final isKyivAdmin = login == 'admin' ||
          login == 'admin_kyiv' ||
          login == 'admin@cityswim.com' ||
          login == 'admin@gmail.com' ||
          login == 'admin.kyiv@cityswim.com';
      final isViennaAdmin = login == 'admin_vienna' ||
          login == 'vienna.admin@cityswim.at' ||
          login == 'admin.vienna@cityswim.com';

      if (isKyivAdmin || isViennaAdmin) {
        final targetDocId = isViennaAdmin ? 'admin_vienna' : 'admin';
        final targetBranchId = isViennaAdmin ? 'vienna' : 'kyiv';
        final targetCurrency = isViennaAdmin ? '€' : '₴';
        final docRef = FirebaseFirestore.instance.collection('users').doc(targetDocId);
        try {
          final docSnap = await docRef.get();
          final storedPassword = (docSnap.data()?['password'] as String?) ?? '1';
          final isValidPassword = PasswordSecurityHelper.verifyPassword(password, storedPassword) ||
              (isKyivAdmin && (password == 'kyiv123' || password == '1')) ||
              (isViennaAdmin && (password == 'vienna123' || password == '1'));

          if (!isValidPassword) {
            throw Exception('Невірний пароль');
          }
          if (!PasswordSecurityHelper.isHashed(storedPassword) && password != '1') {
            docRef.update({'password': PasswordSecurityHelper.hashPassword(password)}).catchError((_) {});
          }

          if (docSnap.exists) {
            final data = docSnap.data()!;
            state = AppUser(
              id: targetDocId,
              name: (data['name'] as String?) ?? (isViennaAdmin ? 'Адміністратор Відень' : 'Адміністратор Київ'),
              role: UserRole.admin,
              branchId: targetBranchId,
              branchIds: [targetBranchId],
              phone: data['phone'] as String?,
              loginId: (data['loginId'] as String?) ?? (isViennaAdmin ? 'admin_vienna' : 'admin_kyiv'),
              avatarUrl: (data['avatarUrl'] as String?) ??
                  'https://ui-avatars.com/api/?name=${isViennaAdmin ? 'Admin+Vienna' : 'Admin+Kyiv'}&background=8b5cf6&color=ffffff',
            );
          } else {
            final adminData = {
              'id': targetDocId,
              'name': isViennaAdmin ? 'Адміністратор Відень' : 'Адміністратор Київ',
              'role': 'admin',
              'loginId': isViennaAdmin ? 'admin_vienna' : 'admin_kyiv',
              'password': isViennaAdmin ? 'vienna123' : 'kyiv123',
              'phone': isViennaAdmin ? '+43 1 234 5678' : '+380 (99) 000-00-01',
              'branchId': targetBranchId,
              'branchIds': [targetBranchId],
              'currency': targetCurrency,
              'adminSalary': isViennaAdmin ? 1900 : 20000,
              'avatarUrl':
                  'https://ui-avatars.com/api/?name=${isViennaAdmin ? 'Admin+Vienna' : 'Admin+Kyiv'}&background=8b5cf6&color=ffffff',
              'createdAt': FieldValue.serverTimestamp(),
            };
            await docRef.set(adminData).catchError((_) {});
            state = AppUser(
              id: targetDocId,
              name: isViennaAdmin ? 'Адміністратор Відень' : 'Адміністратор Київ',
              role: UserRole.admin,
              branchId: targetBranchId,
              branchIds: [targetBranchId],
              phone: isViennaAdmin ? '+43 1 234 5678' : '+380 (99) 000-00-01',
              loginId: isViennaAdmin ? 'admin_vienna' : 'admin_kyiv',
              avatarUrl:
                  'https://ui-avatars.com/api/?name=${isViennaAdmin ? 'Admin+Vienna' : 'Admin+Kyiv'}&background=8b5cf6&color=ffffff',
            );
          }
        } catch (e) {
          if (e.toString().contains('Невірний пароль')) rethrow;
          debugPrint('Firestore admin check error, using local fallback: $e');
          final isValidFallback = (isKyivAdmin && (password == 'kyiv123' || password == '1')) ||
              (isViennaAdmin && (password == 'vienna123' || password == '1'));
          if (!isValidFallback) {
            throw Exception('Невірний пароль');
          }
          state = AppUser(
            id: targetDocId,
            name: isViennaAdmin ? 'Адміністратор Відень' : 'Адміністратор Київ',
            role: UserRole.admin,
            branchId: targetBranchId,
            branchIds: [targetBranchId],
            phone: isViennaAdmin ? '+43 1 234 5678' : '+380 (99) 000-00-01',
            loginId: isViennaAdmin ? 'admin_vienna' : 'admin_kyiv',
            avatarUrl:
                'https://ui-avatars.com/api/?name=${isViennaAdmin ? 'Admin+Vienna' : 'Admin+Kyiv'}&background=8b5cf6&color=ffffff',
          );
        }
        await _syncRoleToPrefs(state);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mockUserId', targetDocId);
        await prefs.setString('clientId', targetDocId);
        await prefs.setString('userBranchId', targetBranchId);
        await prefs.setString('selected_branch_id', targetBranchId);
        final staffEmail = isViennaAdmin ? 'admin.vienna@cityswim.app' : 'admin.kyiv@cityswim.app';
        final staffPass = isViennaAdmin ? 'vienna123456' : 'kyiv123456';
        await _ensureStaffFirebaseAuth(email: staffEmail, password: staffPass);
        await _syncAuthUserDoc(state);
        if (isKyivAdmin) {
          ensureAdminInFirestore().catchError((_) {});
          ensureDefaultCoachInFirestore().catchError((_) {});
        }
        return;
      } else if (login == 'owner' || login == 'owner@cityswim.com' || login == 'owner@gmail.com') {
        final docRef = FirebaseFirestore.instance.collection('users').doc('mock_owner');
        try {
          final docSnap = await docRef.get();
          final storedPassword = (docSnap.data()?['password'] as String?) ?? '1';
          if (!PasswordSecurityHelper.verifyPassword(password, storedPassword)) {
            throw Exception('Невірний пароль');
          }
          if (!PasswordSecurityHelper.isHashed(storedPassword)) {
            docRef.update({'password': PasswordSecurityHelper.hashPassword(password)}).catchError((_) {});
          }
        } catch (e) {
          if (e.toString().contains('Невірний пароль')) rethrow;
          debugPrint('Firestore owner check error, using local fallback: $e');
          if (password != '1') {
            throw Exception('Невірний пароль');
          }
        }
        state = const AppUser(id: 'mock_owner', name: 'Owner', role: UserRole.owner);
        await _syncRoleToPrefs(state);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mockUserId', 'mock_owner');
        await prefs.setString('clientId', 'mock_owner');
        await _ensureStaffFirebaseAuth(email: 'owner@cityswim.app', password: 'owner123456');
        await _syncAuthUserDoc(state);
        return;
      } else if (login == 'coach' || login == 'coach1' || login == 'тренер' || login == 'coach@cityswim.com' || login == 'coach@gmail.com' || login.startsWith('coach') || login.contains('coach') || login.endsWith('@cityswim.at') || login.contains('maria') || login.contains('stefan')) {
        try {
          var usersSnap = await FirebaseFirestore.instance.collection('users').where('loginId', isEqualTo: login).get();
          if (usersSnap.docs.isEmpty) {
            if (login == 'maria' || login == 'coach_maria' || login.contains('maria')) {
              final mDoc = await FirebaseFirestore.instance.collection('users').doc('coach_maria').get();
              if (mDoc.exists) {
                usersSnap = await FirebaseFirestore.instance.collection('users').where('id', isEqualTo: 'coach_maria').get();
              }
            } else if (login == 'stefan' || login == 'coach_stefan' || login.contains('stefan')) {
              final sDoc = await FirebaseFirestore.instance.collection('users').doc('coach_stefan').get();
              if (sDoc.exists) {
                usersSnap = await FirebaseFirestore.instance.collection('users').where('id', isEqualTo: 'coach_stefan').get();
              }
            }
          }
          if (usersSnap.docs.isEmpty && (login == 'coach' || login == 'coach1' || login == 'тренер' || login.startsWith('coach'))) {
            final fallbackDoc = await FirebaseFirestore.instance.collection('users').doc('default_coach').get();
            if (fallbackDoc.exists) {
              final userData = fallbackDoc.data()!;
              final storedPassword = (userData['password'] as String?) ?? '1';
              if (!PasswordSecurityHelper.verifyPassword(password, storedPassword)) {
                throw Exception('Невірний пароль');
              }
              state = AppUser.fromJson(userData);
              await _syncRoleToPrefs(state);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('clientId', state!.id);
              await prefs.setString('mockUserId', state!.id);
              await _ensureCoachFirebaseAuth(login, state);
              return;
            } else {
              final defaultCoachData = {
                'id': 'default_coach',
                'name': 'Олена Коваль',
                'role': 'coach',
                'loginId': 'coach',
                'password': '1',
                'phone': '+380 (99) 000-00-02',
                'branchId': 'kyiv',
                'branchIds': ['kyiv'],
                'organizationId': 'cityswim',
                'rateGroup': 400,
                'rateIndividual': 450,
                'rateSplit': 600,
                'avatarUrl': 'https://ui-avatars.com/api/?name=Olena+Koval&background=0284c7&color=ffffff',
                'createdAt': FieldValue.serverTimestamp(),
              };
              await FirebaseFirestore.instance.collection('users').doc('default_coach').set(defaultCoachData, SetOptions(merge: true));
              if (password != '1') {
                throw Exception('Невірний пароль');
              }
              state = const AppUser(
                id: 'default_coach',
                name: 'Олена Коваль',
                role: UserRole.coach,
                phone: '+380 (99) 000-00-02',
                loginId: 'coach',
                branchId: 'kyiv',
                branchIds: ['kyiv'],
                organizationId: 'cityswim',
                avatarUrl: 'https://ui-avatars.com/api/?name=Olena+Koval&background=0284c7&color=ffffff',
              );
              await _syncRoleToPrefs(state);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('clientId', state!.id);
              await prefs.setString('mockUserId', state!.id);
              await _ensureCoachFirebaseAuth(login, state);
              return;
            }
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
            await prefs.setString('mockUserId', state!.id);
            await _ensureCoachFirebaseAuth(login, state);
            return;
          } else {
            throw Exception('Тренера з логіном $login не знайдено');
          }
        } catch (e) {
          if (e.toString().contains('Невірний пароль')) rethrow;
          debugPrint('Firestore coach check error, using local fallback: $e');
          if (password != '1') {
            throw Exception('Невірний пароль');
          }
          if (login.contains('maria')) {
            state = const AppUser(
              id: 'coach_maria',
              name: 'Coach Maria Huber',
              role: UserRole.coach,
              phone: '+43 676 1234567',
              loginId: 'maria.huber@cityswim.at',
              branchId: 'vienna',
              branchIds: ['vienna'],
              organizationId: 'cityswim',
              avatarUrl: 'https://ui-avatars.com/api/?name=Maria+Huber&background=00e5ff&color=000000',
            );
          } else if (login.contains('stefan')) {
            state = const AppUser(
              id: 'coach_stefan',
              name: 'Coach Stefan Gruber',
              role: UserRole.coach,
              phone: '+43 676 7654321',
              loginId: 'stefan.gruber@cityswim.at',
              branchId: 'vienna',
              branchIds: ['vienna'],
              organizationId: 'cityswim',
              avatarUrl: 'https://ui-avatars.com/api/?name=Stefan+Gruber&background=0284c7&color=ffffff',
            );
          } else {
            state = const AppUser(
              id: 'default_coach',
              name: 'Олена Коваль',
              role: UserRole.coach,
              phone: '+380 (99) 000-00-02',
              loginId: 'coach',
              branchId: 'kyiv',
              branchIds: ['kyiv'],
              organizationId: 'cityswim',
              avatarUrl: 'https://ui-avatars.com/api/?name=Olena+Koval&background=0284c7&color=ffffff',
            );
          }
          await _syncRoleToPrefs(state);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('clientId', state!.id);
          await prefs.setString('mockUserId', state!.id);
          await _ensureCoachFirebaseAuth(login, state);
          return;
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
              final safeId = state!.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
              final clientEmail = 'client.${safeId.isEmpty ? "parent" : safeId}@cityswim.app';
              await _ensureStaffFirebaseAuth(email: clientEmail, password: 'client123456');
            }
            await _syncAuthUserDoc(state);
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
            'branchId': 'kyiv',
            'branchIds': ['kyiv'],
            'organizationId': 'cityswim',
            'createdAt': FieldValue.serverTimestamp(),
          };
          await FirebaseFirestore.instance.collection('users').doc('demo_client').set(demoClient, SetOptions(merge: true));
          state = const AppUser(
            id: 'demo_client',
            name: 'Олександр Спіян',
            role: UserRole.parent,
            phone: '+380685566322',
            loginId: 'client',
            branchId: 'kyiv',
            branchIds: ['kyiv'],
            organizationId: 'cityswim',
            avatarUrl: 'https://ui-avatars.com/api/?name=Oleksandr+Spiian&background=0284c7&color=ffffff',
          );
          await _syncRoleToPrefs(state);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('clientId', 'demo_client');
          try {
            await _ensureStaffFirebaseAuth(email: 'client.demo@cityswim.app', password: 'client123456');
            await _syncAuthUserDoc(state);
          } catch (_) {}
          return;
        } else if (login.startsWith('client')) {
          throw Exception('Клієнта з логіном $login не знайдено');
        }
      }

      if (login.contains('@')) {
        UserCredential? fbAuthCred;
        try {
          fbAuthCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );
        } on FirebaseAuthException catch (authEx) {
          debugPrint('FirebaseAuth.signInWithEmailAndPassword returned: ${authEx.code}');
          // If the password was wrong in Firebase Auth, check if Firestore holds a legacy account
          final emailSnap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: login).get();
          if (emailSnap.docs.isNotEmpty) {
            final userData = emailSnap.docs.first.data();
            final storedPassword = (userData['password'] as String?) ?? '1';
            if (PasswordSecurityHelper.verifyPassword(password, storedPassword)) {
              if (!PasswordSecurityHelper.isHashed(storedPassword)) {
                emailSnap.docs.first.reference.update({'password': PasswordSecurityHelper.hashPassword(password)}).catchError((_) {});
              }
              state = AppUser.fromJson(userData);
              await _syncRoleToPrefs(state);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('clientId', state!.id);
              return;
            } else {
              throw Exception('Невірний пароль');
            }
          }

          if (authEx.code == 'wrong-password' || authEx.code == 'invalid-credential') {
            throw Exception('Невірний email або пароль');
          } else if (authEx.code == 'user-not-found') {
            throw Exception('Користувача з такою електронною поштою не знайдено');
          } else if (authEx.code == 'user-disabled') {
            throw Exception('Акаунт заблоковано');
          } else if (authEx.code == 'too-many-requests') {
            throw Exception('Забагато невдалих спроб. Будь ласка, спробуйте пізніше');
          }
        } catch (e) {
          debugPrint('General error during email login: $e');
        }

        if (fbAuthCred?.user != null) {
          final fbUser = fbAuthCred!.user!;
          var userDoc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
          if (!userDoc.exists) {
            final emailQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: login).get();
            if (emailQuery.docs.isNotEmpty) {
              userDoc = emailQuery.docs.first;
            }
          }

          if (userDoc.exists && userDoc.data() != null) {
            state = AppUser.fromJson(userDoc.data()!);
          } else {
            final effectiveBranch = _getEffectiveBranchSync();
            final defaultName = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
                ? fbUser.displayName!.trim()
                : 'Клієнт';
            final parts = defaultName.split(' ').where((s) => s.isNotEmpty).toList();
            final avatarInitials = parts.isNotEmpty
                ? (parts.length > 1 ? '${parts[0][0]}+${parts[1][0]}' : parts[0][0])
                : 'Client';
            final newUserData = {
              'id': fbUser.uid,
              'name': defaultName,
              'role': 'parent',
              'email': fbUser.email ?? login,
              'avatarUrl': fbUser.photoURL ?? 'https://ui-avatars.com/api/?name=$avatarInitials&background=0284c7&color=ffffff',
              'createdAt': FieldValue.serverTimestamp(),
              'branchId': effectiveBranch.id,
              'branchIds': [effectiveBranch.id],
              'organizationId': effectiveBranch.organizationId,
            };
            await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set(newUserData, SetOptions(merge: true));
            state = AppUser.fromJson(newUserData);
          }

          await _syncRoleToPrefs(state);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('clientId', state!.id);
          return;
        }

        // Final fallback: Check Firestore document by email if not signed into Firebase Auth
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
              await _ensureStaffFirebaseAuth(email: login, password: password);
            }
            await _syncAuthUserDoc(state);
          } catch (_) {}
          return;
        } else {
          throw Exception('Користувача з такою електронною поштою не знайдено');
        }
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
    String? branchId,
  }) async {
    try {
      final userEmail = (email ?? phone).trim().toLowerCase();
      if (userEmail.isEmpty || !userEmail.contains('@') || !userEmail.contains('.')) {
        throw Exception('Будь ласка, введіть коректну електронну пошту (email)');
      }
      if (password.trim().length < 6) {
        throw Exception('Пароль має містити щонайменше 6 символів');
      }

      // 1. Create user in Firebase Auth FIRST (handles duplicate validation natively)
      UserCredential authCredential;
      try {
        authCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: userEmail,
          password: password.trim(),
        );
      } on FirebaseAuthException catch (authEx) {
        if (authEx.code == 'email-already-in-use') {
          throw Exception('Користувач із таким email вже зареєстрований у системі. Будь ласка, увійдіть.');
        } else if (authEx.code == 'weak-password') {
          throw Exception('Пароль занадто простий. Введіть щонайменше 6 символів.');
        } else if (authEx.code == 'invalid-email') {
          throw Exception('Некоректний формат email.');
        } else {
          debugPrint('FirebaseAuth createUser error: $authEx');
          throw Exception(authEx.message ?? 'Помилка реєстрації у Firebase Auth');
        }
      } catch (e) {
        debugPrint('Generic auth error in createUserWithEmailAndPassword: $e');
        rethrow;
      }

      final fbUser = authCredential.user;
      if (fbUser == null) {
        throw Exception('Не вдалося створити профіль авторизації');
      }

      final effectiveUserId = fbUser.uid;
      try {
        await fbUser.updateDisplayName(name.trim());
      } catch (_) {}

      final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
      final avatarInitials = parts.isNotEmpty
          ? (parts.length > 1 ? '${parts[0][0]}+${parts[1][0]}' : parts[0][0])
          : 'Client';

      final effectiveBranch = _getEffectiveBranchSync();
      final effectiveBranchId = branchId ?? effectiveBranch.id;

      final newClientData = {
        'id': effectiveUserId,
        'name': name.trim(),
        'role': 'parent',
        'loginId': userEmail,
        'password': PasswordSecurityHelper.hashPassword(password.trim()),
        'email': userEmail,
        'avatarUrl': 'https://ui-avatars.com/api/?name=$avatarInitials&background=0284c7&color=ffffff',
        'createdAt': FieldValue.serverTimestamp(),
        'branchId': effectiveBranchId,
        'branchIds': [effectiveBranchId],
        'organizationId': effectiveBranch.organizationId,
      };

      // 2. Since the user is now authenticated and request.auth.uid == effectiveUserId, this writes directly with full permissions
      await FirebaseFirestore.instance.collection('users').doc(effectiveUserId).set(newClientData);

      final newUser = AppUser(
        id: effectiveUserId,
        name: name.trim(),
        role: UserRole.parent,
        loginId: userEmail,
        avatarUrl: 'https://ui-avatars.com/api/?name=$avatarInitials&background=0284c7&color=ffffff',
        branchId: effectiveBranchId,
        branchIds: [effectiveBranchId],
        organizationId: effectiveBranch.organizationId,
      );

      state = newUser;
      await _syncRoleToPrefs(state);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('clientId', newUser.id);
      await prefs.setBool('needsOnboarding', true);

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
        await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 3));
      } catch (_) {}
      try {
        await GoogleSignIn.instance.signOut().timeout(const Duration(seconds: 3));
      } catch (_) {}
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> updateAvatar(Uint8List bytes, {VoidCallback? onSuccess, void Function(String)? onError}) async {
    final currentAuthUser = FirebaseAuth.instance.currentUser;
    final effectiveId = state?.id ?? currentAuthUser?.uid;
    if (effectiveId == null) {
      if (onError != null) onError('Не вдалося визначити профіль користувача');
      return;
    }

    final user = state;
    try {
      final base64String = base64Encode(bytes);
      final newUrl = 'data:image/jpeg;base64,$base64String';

      // Оптимістичне оновлення для миттєвого відображення
      if (user != null) {
        state = user.copyWith(avatarBytes: bytes);
      }

      // Update Firestore with SetOptions(merge: true) to never fail
      await FirebaseFirestore.instance.collection('users').doc(effectiveId).set({
        'avatarUrl': newUrl,
      }, SetOptions(merge: true));

      // Update local state permanently
      if (user != null) {
        state = user.copyWith(avatarUrl: newUrl, avatarBytes: null);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final effectiveBranch = _getEffectiveBranchSync();
        state = AppUser(
          id: effectiveId,
          name: currentAuthUser?.displayName ?? (prefs.getString('userName') ?? 'Користувач'),
          role: UserRole.parent,
          avatarUrl: newUrl,
          branchId: effectiveBranch.id,
          branchIds: [effectiveBranch.id],
          organizationId: effectiveBranch.organizationId,
        );
      }
      await _syncRoleToPrefs(state);
      debugPrint('Successfully uploaded and updated avatar!');
      if (onSuccess != null) onSuccess();
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (onError != null) onError(e.toString());
      if (user != null && state?.id == user.id) {
        state = user;
      }
    }
  }

  Future<void> completeOnboarding(
    String name,
    String phone, {
    String? branchId,
    int? age,
    String? goal,
    String? level,
    bool isAdultOnly = false,
    List<Map<String, dynamic>>? children,
    String? childName,
    dynamic childAge,
  }) async {
    try {
      AppUser user;
      final currentAuthUser = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final effectiveBranch = _getEffectiveBranchSync();

      if (state != null) {
        user = state!;
      } else {
        final clientId = prefs.getString('clientId') ?? currentAuthUser?.uid;
        if (clientId == null) {
          debugPrint('Cannot complete onboarding: no user ID found');
          return;
        }
        final assignedBranchId = branchId ?? (prefs.getString('userBranchId') ?? effectiveBranch.id);
        final photo = currentAuthUser?.photoURL ??
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=0284c7&color=ffffff';
        user = AppUser(
          id: clientId,
          name: name,
          role: UserRole.parent,
          avatarUrl: photo,
          branchId: assignedBranchId,
          branchIds: [assignedBranchId],
          organizationId: effectiveBranch.organizationId,
        );
      }
      final assignedBranchId = branchId ?? (user.branchId.isNotEmpty ? user.branchId : effectiveBranch.id);
      final organizationId = effectiveBranch.organizationId;
      
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
        branchId: assignedBranchId,
        branchIds: [assignedBranchId],
        organizationId: organizationId,
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
      userMap['branchId'] = assignedBranchId;
      userMap['branchIds'] = [assignedBranchId];
      userMap['organizationId'] = organizationId;
      // Smart Account Linking by Phone:
      // If an existing client was created by an admin (or previous login) with this phone number,
      // migrate all their subscriptions, children, families, and payments to this account!
      final cleanDigits = _cleanPhoneDigits(phone);
      if (cleanDigits.length >= 7) {
        try {
          DocumentSnapshot<Map<String, dynamic>>? existingClientDoc;
          for (final doc in usersSnap.docs) {
            if (doc.id != updatedUser.id && doc.data()['mergedInto'] == null) {
              final otherPhone = doc.data()['phone'] as String?;
              if (otherPhone != null && _cleanPhoneDigits(otherPhone) == cleanDigits) {
                existingClientDoc = doc;
                break;
              }
            }
          }

          if (existingClientDoc != null) {
            final oldId = existingClientDoc.id;
            final oldData = existingClientDoc.data()!;
            debugPrint('Smart Account Linking: Found existing user $oldId by phone $phone, migrating to ${updatedUser.id}');
            await _migrateUserData(
              oldUserId: oldId,
              newUserId: updatedUser.id,
              oldUserData: oldData,
            );

            // Copy loginId if old user had one
            final oldLoginId = oldData['loginId'] as String?;
            if (oldLoginId != null && oldLoginId.isNotEmpty) {
              userMap['loginId'] = oldLoginId;
            }
          }
        } catch (e) {
          debugPrint('Notice: Error checking existing user by phone during onboarding: $e');
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(updatedUser.id).set(userMap, SetOptions(merge: true));

      // Check existing children for this parent to prevent duplicates
      final existingChildrenSnap = await FirebaseFirestore.instance
          .collection('children')
          .where('parentId', isEqualTo: updatedUser.id)
          .get();
      final existingChildNames = existingChildrenSnap.docs
          .map((d) => (d.data()['name'] as String?)?.trim().toLowerCase())
          .whereType<String>()
          .toSet();

      // Save children if provided as list
      if (children != null && children.isNotEmpty) {
        for (var c in children) {
          final cName = (c['name'] as String?)?.trim();
          if (cName == null || cName.isEmpty) continue;
          if (existingChildNames.contains(cName.toLowerCase())) {
            debugPrint('Child "$cName" already exists for parent, skipping duplicate creation');
            continue;
          }
          final cAge = c['age'] is int ? c['age'] as int : int.tryParse(c['age']?.toString() ?? '');
          final cGoal = (c['goal'] as String?)?.trim();
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
          existingChildNames.add(cName.toLowerCase());
        }
      } else if (childName != null && childName.trim().isNotEmpty) {
        final cName = childName.trim();
        if (!existingChildNames.contains(cName.toLowerCase())) {
          final parsedAge = childAge is int ? childAge : int.tryParse(childAge?.toString() ?? '');
          final childRef = FirebaseFirestore.instance.collection('children').doc();
          final childData = <String, dynamic>{
            'id': childRef.id,
            'parentId': updatedUser.id,
            'name': cName,
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
      }

      await prefs.setBool('needsOnboarding', false);

      await prefs.setString('selected_branch_id', assignedBranchId);
      await prefs.setString('userBranchId', assignedBranchId);

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

      await FirebaseFirestore.instance.collection('users').doc(user.id).set({
        'avatarUrl': newUrl,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error deleting avatar: $e');
    }
  }

  /// Зміна активної філії для клієнта (Київ / Відень) зі збереженням суворої філіальної ізоляції
  Future<void> updateClientBranch(String newBranchId) async {
    if (state == null) return;
    final user = state!;
    final prefs = ref.read(sharedPrefsProvider);

    final updatedBranchIds = user.branchIds.contains(newBranchId)
        ? user.branchIds
        : [...user.branchIds, newBranchId];

    final updatedUser = user.copyWith(
      branchId: newBranchId,
      branchIds: updatedBranchIds,
    );

    // Оптимістичне локальне оновлення
    state = updatedUser;
    await prefs.setString('selected_branch_id', newBranchId);
    await prefs.setString('userBranchId', newBranchId);
    await _syncRoleToPrefs(updatedUser);

    // Оновлення в Firestore для користувача та його дітей
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set({
        'branchId': newBranchId,
        'branchIds': updatedBranchIds,
      }, SetOptions(merge: true));

      final childrenSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('parentId', isEqualTo: user.id)
          .get();
      for (final doc in childrenSnapshot.docs) {
        await doc.reference.update({'branchId': newBranchId});
      }
    } catch (e) {
      debugPrint('Error updating branch in Firestore: $e');
    }
  }
}

/// Guarantees that the default Admin profile exists in Firestore `users` collection.
Future<void> ensureAdminInFirestore() async {
  try {
    if (Firebase.apps.isEmpty) return;
    final firestore = FirebaseFirestore.instance;

    // 1. Адміністратор Києва
    final docRef = firestore.collection('users').doc('admin');
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set({
        'id': 'admin',
        'name': 'Адміністратор Київ',
        'role': 'admin',
        'loginId': 'admin_kyiv',
        'password': '1',
        'phone': '+380 (99) 000-00-01',
        'branchId': 'kyiv',
        'branchIds': ['kyiv'],
        'currency': '₴',
        'adminSalary': 20000,
        'salaryType': 'monthly',
        'rateGroup': 400,
        'rateIndividual': 450,
        'rateSplit': 600,
        'avatarUrl': 'https://ui-avatars.com/api/?name=Admin+Kyiv&background=8b5cf6&color=ffffff',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = docSnap.data() ?? {};
      final role = (data['role'] as String?)?.toLowerCase();
      final updates = <String, dynamic>{};
      if (role != 'admin') updates['role'] = 'admin';
      if (data['branchId'] == null) updates['branchId'] = 'kyiv';
      if (data['currency'] == null) updates['currency'] = '₴';
      if (data['adminSalary'] == null) updates['adminSalary'] = 20000;
      if (data['name'] == 'Адміністратор' || data['name'] == null) updates['name'] = 'Адміністратор Київ';
      if (data['loginId'] == 'Admin' || data['loginId'] == null) updates['loginId'] = 'admin_kyiv';
      if (updates.isNotEmpty) {
        await docRef.set(updates, SetOptions(merge: true));
      }
    }

    // 2. Адміністратор Відня
    final viennaRef = firestore.collection('users').doc('admin_vienna');
    final viennaSnap = await viennaRef.get();
    if (!viennaSnap.exists) {
      await viennaRef.set({
        'id': 'admin_vienna',
        'name': 'Адміністратор Відень',
        'role': 'admin',
        'loginId': 'admin_vienna',
        'password': '1',
        'phone': '+43 1 234 5678',
        'branchId': 'vienna',
        'branchIds': ['vienna'],
        'currency': '€',
        'adminSalary': 1900,
        'salaryType': 'monthly',
        'rateGroup': 25,
        'rateIndividual': 35,
        'rateSplit': 45,
        'avatarUrl': 'https://ui-avatars.com/api/?name=Admin+Vienna&background=8b5cf6&color=ffffff',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final vData = viennaSnap.data() ?? {};
      final vRole = (vData['role'] as String?)?.toLowerCase();
      final vUpdates = <String, dynamic>{};
      if (vRole != 'admin') vUpdates['role'] = 'admin';
      if (vData['branchId'] == null) vUpdates['branchId'] = 'vienna';
      if (vData['currency'] == null) vUpdates['currency'] = '€';
      if (vData['adminSalary'] == null) vUpdates['adminSalary'] = 1900;
      if (vData['name'] == 'Admin Vienna' || vData['name'] == null) vUpdates['name'] = 'Адміністратор Відень';
      if (vData['loginId'] == 'vienna.admin@cityswim.at' || vData['loginId'] == null) vUpdates['loginId'] = 'admin_vienna';
      if (vUpdates.isNotEmpty) {
        await viennaRef.set(vUpdates, SetOptions(merge: true));
      }
    }
  } catch (e) {
    debugPrint('Error in ensureAdminInFirestore: $e');
  }
}

/// Guarantees that the default Coach profile exists in Firestore `users` collection.
Future<void> ensureDefaultCoachInFirestore() async {
  try {
    if (Firebase.apps.isEmpty) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc('default_coach');
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set({
        'id': 'default_coach',
        'name': 'Олена Коваль',
        'role': 'coach',
        'loginId': 'coach',
        'password': '1',
        'phone': '+380 (99) 000-00-02',
        'branchId': 'kyiv',
        'branchIds': ['kyiv'],
        'organizationId': 'cityswim',
        'rateGroup': 400,
        'rateIndividual': 450,
        'rateSplit': 600,
        'avatarUrl': 'https://ui-avatars.com/api/?name=Olena+Koval&background=0284c7&color=ffffff',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final d = docSnap.data() ?? {};
      if (d['role'] != 'coach' || d['branchId'] == null) {
        await docRef.set({
          'role': 'coach',
          'branchId': 'kyiv',
          'branchIds': ['kyiv'],
        }, SetOptions(merge: true));
      }
    }

    // Ensure Vienna coaches exist in Firestore
    final mariaRef = FirebaseFirestore.instance.collection('users').doc('coach_maria');
    final mariaSnap = await mariaRef.get();
    if (!mariaSnap.exists) {
      await mariaRef.set({
        'id': 'coach_maria',
        'name': 'Coach Maria Huber',
        'role': 'coach',
        'loginId': 'maria.huber@cityswim.at',
        'password': '1',
        'phone': '+43 676 1234567',
        'branchId': 'vienna',
        'branchIds': ['vienna'],
        'organizationId': 'cityswim',
        'rateGroup': 45,
        'rateIndividual': 55,
        'rateSplit': 70,
        'avatarUrl': 'https://ui-avatars.com/api/?name=Maria+Huber&background=00e5ff&color=000000',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final d = mariaSnap.data() ?? {};
      if (d['role'] != 'coach' || d['branchId'] != 'vienna') {
        await mariaRef.set({
          'role': 'coach',
          'branchId': 'vienna',
          'branchIds': ['vienna'],
        }, SetOptions(merge: true));
      }
    }

    final stefanRef = FirebaseFirestore.instance.collection('users').doc('coach_stefan');
    final stefanSnap = await stefanRef.get();
    if (!stefanSnap.exists) {
      await stefanRef.set({
        'id': 'coach_stefan',
        'name': 'Coach Stefan Gruber',
        'role': 'coach',
        'loginId': 'stefan.gruber@cityswim.at',
        'password': '1',
        'phone': '+43 676 7654321',
        'branchId': 'vienna',
        'branchIds': ['vienna'],
        'organizationId': 'cityswim',
        'rateGroup': 45,
        'rateIndividual': 55,
        'rateSplit': 70,
        'avatarUrl': 'https://ui-avatars.com/api/?name=Stefan+Gruber&background=0284c7&color=ffffff',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final d = stefanSnap.data() ?? {};
      if (d['role'] != 'coach' || d['branchId'] != 'vienna') {
        await stefanRef.set({
          'role': 'coach',
          'branchId': 'vienna',
          'branchIds': ['vienna'],
        }, SetOptions(merge: true));
      }
    }

    await ensureDefaultClassesForCoachInFirestore();
  } catch (e) {
    debugPrint('Error in ensureDefaultCoachInFirestore: $e');
  }
}

Future<void> ensureDefaultClassesForCoachInFirestore() async {
  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firestore = FirebaseFirestore.instance;

    // Check if there are already classes for today for Coach Olena Koval
    final existingTodaySnap = await firestore
        .collection('classes')
        .where('coachId', isEqualTo: 'default_coach')
        .limit(10)
        .get();

    bool hasTodayClass = false;
    for (final doc in existingTodaySnap.docs) {
      final data = doc.data();
      DateTime? startTime;
      if (data['startTime'] is Timestamp) {
        startTime = (data['startTime'] as Timestamp).toDate();
      } else if (data['startTime'] is String) {
        startTime = DateTime.tryParse(data['startTime']);
      }
      if (startTime != null &&
          startTime.year == today.year &&
          startTime.month == today.month &&
          startTime.day == today.day) {
        hasTodayClass = true;
        break;
      }
    }
    if (hasTodayClass) return;

    // Ensure sample children exist for attendees list
    await firestore.collection('children').doc('demo_child_1').set({
      'id': 'demo_child_1',
      'name': 'Максим Бондаренко',
      'age': 8,
      'birthDate': DateTime(now.year - 8, 5, 12).toIso8601String(),
      'parentId': 'mock_active_client',
      'branchId': 'kyiv',
      'skillLevel': 'Початківець',
      'medicalCertificate': true,
    }, SetOptions(merge: true));

    await firestore.collection('children').doc('demo_child_2').set({
      'id': 'demo_child_2',
      'name': 'Софія Мельник',
      'age': 9,
      'birthDate': DateTime(now.year - 9, 8, 20).toIso8601String(),
      'parentId': 'mock_active_client',
      'branchId': 'kyiv',
      'skillLevel': 'Середній',
      'medicalCertificate': true,
    }, SetOptions(merge: true));

    await firestore.collection('children').doc('demo_child_3').set({
      'id': 'demo_child_3',
      'name': 'Артем Шевченко',
      'age': 7,
      'birthDate': DateTime(now.year - 7, 3, 15).toIso8601String(),
      'parentId': 'mock_active_client',
      'branchId': 'kyiv',
      'skillLevel': 'Початківець',
      'medicalCertificate': true,
    }, SetOptions(merge: true));

    // Ensure sample subscription exists
    await firestore.collection('subscriptions').doc('demo_sub_1').set({
      'id': 'demo_sub_1',
      'userId': 'mock_active_client',
      'childId': 'demo_child_1',
      'clientName': 'Андрій',
      'type': 'Стандарт (8 занять)',
      'totalClasses': 8,
      'remainingClasses': 7,
      'isActive': true,
      'branchId': 'kyiv',
      'expiryDate': now.add(const Duration(days: 30)).toIso8601String(),
      'purchaseDate': now.subtract(const Duration(days: 2)).toIso8601String(),
    }, SetOptions(merge: true));

    // Seed 2 classes for today:
    // 1. Group class at 10:00 - 11:00
    final class1Time = DateTime(today.year, today.month, today.day, 10, 0);
    final class1Id = 'class_olena_${class1Time.millisecondsSinceEpoch}';
    await firestore.collection('classes').doc(class1Id).set({
      'id': class1Id,
      'title': 'Групове плавання: Дельфіни',
      'category': 'Групове',
      'startTime': class1Time.toIso8601String(),
      'endTime': class1Time.add(const Duration(hours: 1)).toIso8601String(),
      'coachId': 'default_coach',
      'coachName': 'Олена Коваль',
      'lane': 'Доріжка 2',
      'maxCapacity': 8,
      'enrolledChildIds': ['demo_child_1', 'demo_child_2', 'demo_child_3'],
      'attendedChildIds': ['demo_child_1'],
      'branchId': 'kyiv',
      'organizationId': 'cityswim',
      'timezone': 'Europe/Kyiv',
      'locationId': 'kyiv_main',
      'poolId': 'pool_25m',
    }, SetOptions(merge: true));

    // 2. Individual training at 16:00 - 17:00
    final class2Time = DateTime(today.year, today.month, today.day, 16, 0);
    final class2Id = 'class_olena_${class2Time.millisecondsSinceEpoch}';
    await firestore.collection('classes').doc(class2Id).set({
      'id': class2Id,
      'title': 'Індивідуальне тренування: Техніка брасу',
      'category': 'Індивідуальне',
      'startTime': class2Time.toIso8601String(),
      'endTime': class2Time.add(const Duration(hours: 1)).toIso8601String(),
      'coachId': 'default_coach',
      'coachName': 'Олена Коваль',
      'lane': 'Доріжка 1',
      'maxCapacity': 1,
      'enrolledChildIds': ['demo_child_2'],
      'attendedChildIds': [],
      'branchId': 'kyiv',
      'organizationId': 'cityswim',
      'timezone': 'Europe/Kyiv',
      'locationId': 'kyiv_main',
      'poolId': 'pool_25m',
    }, SetOptions(merge: true));

    debugPrint('Successfully seeded demo today classes for Coach Olena Koval');
  } catch (e) {
    debugPrint('Error in ensureDefaultClassesForCoachInFirestore: $e');
  }
}
