import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';

final familyStreamProvider = StreamProvider<Family?>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('families')
      .where('parentIds', arrayContains: user.id)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    try {
      final family = Family.fromJson({'id': doc.id, ...doc.data()});
      // Check if any parent names need backfilling
      final hasMissingNames = family.parentIds.any(
        (id) => !family.parentNames.containsKey(id) || family.parentNames[id]!.trim().isEmpty,
      );
      if (hasMissingNames) {
        Future.microtask(() => ref.read(familyControllerProvider).syncFamilyParentNames(family));
      }
      return family;
    } catch (e) {
      debugPrint('Error parsing family document: $e');
      return null;
    }
  });
});

final familyControllerProvider = Provider<FamilyController>((ref) {
  return FamilyController(ref);
});

class FamilyController {
  final Ref _ref;
  FamilyController(this._ref);

  String _generateInviteCode() {
    final random = Random();
    final number = 100000 + random.nextInt(900000);
    return 'FAM-$number';
  }

  Future<void> syncFamilyParentNames(Family family) async {
    bool needsUpdate = false;
    final updatedNames = Map<String, String>.from(family.parentNames);
    final updatedPhones = Map<String, String>.from(family.parentPhones);

    for (final id in family.parentIds) {
      if (!updatedNames.containsKey(id) || updatedNames[id]!.trim().isEmpty) {
        try {
          final uDoc = await FirebaseFirestore.instance.collection('users').doc(id).get();
          if (uDoc.exists && uDoc.data() != null) {
            final n = uDoc.data()!['name'] as String? ?? '';
            final p = uDoc.data()!['phone'] as String? ?? '';
            if (n.trim().isNotEmpty) {
              updatedNames[id] = n.trim();
              needsUpdate = true;
            }
            if (p.trim().isNotEmpty && (!updatedPhones.containsKey(id) || updatedPhones[id]!.isEmpty)) {
              updatedPhones[id] = p.trim();
              needsUpdate = true;
            }
          }
        } catch (e) {
          debugPrint('Error fetching user info for family sync ($id): $e');
        }
      }
    }

    if (needsUpdate) {
      try {
        await FirebaseFirestore.instance.collection('families').doc(family.id).update({
          'parentNames': updatedNames,
          'parentPhones': updatedPhones,
        });
      } catch (e) {
        debugPrint('Error syncing family parent names: $e');
      }
    }
  }

  Future<Family?> getCurrentFamily() async {
    final user = _ref.read(authControllerProvider);
    if (user == null) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('families')
          .where('parentIds', arrayContains: user.id)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final family = Family.fromJson({'id': doc.id, ...doc.data()});
      await syncFamilyParentNames(family);
      return family;
    } catch (e) {
      debugPrint('Error getting current family: $e');
      return null;
    }
  }

  Future<Family> getOrCreateFamily() async {
    final user = _ref.read(authControllerProvider);
    if (user == null) {
      throw Exception('Користувач не авторизований');
    }

    final existing = await getCurrentFamily();
    if (existing != null) return existing;

    final docRef = FirebaseFirestore.instance.collection('families').doc();
    final inviteCode = _generateInviteCode();

    final userName = user.name.trim().isNotEmpty ? user.name.trim() : 'Клієнт';
    final parentNames = {user.id: userName};
    final parentPhones = <String, String>{};
    if (user.phone != null && user.phone!.trim().isNotEmpty) {
      parentPhones[user.id] = user.phone!.trim();
    }

    final newFamily = Family(
      id: docRef.id,
      primaryParentId: user.id,
      parentIds: [user.id],
      parentNames: parentNames,
      parentPhones: parentPhones,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );

    await docRef.set(newFamily.toJson());
    return newFamily;
  }

  Future<String?> joinFamily(String rawCode) async {
    final user = _ref.read(authControllerProvider);
    if (user == null) return 'Потрібно авторизуватися';

    var cleanCode = rawCode.trim().toUpperCase().replaceAll(' ', '');
    if (cleanCode.isEmpty) return 'Будь ласка, введіть код сім\'ї';
    if (!cleanCode.startsWith('FAM-')) {
      if (cleanCode.startsWith('FAM')) {
        cleanCode = 'FAM-${cleanCode.substring(3).replaceAll('-', '')}';
      } else {
        cleanCode = 'FAM-$cleanCode';
      }
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('families')
          .where('inviteCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return 'Код сім\'ї не знайдено. Перевірте код та спробуйте ще раз.';
      }

      final doc = snap.docs.first;
      final family = Family.fromJson({'id': doc.id, ...doc.data()});

      if (family.parentIds.contains(user.id)) {
        return 'Ви вже приєднані до цієї сім\'ї.';
      }

      if (family.parentIds.length >= 2) {
        return 'У цій родині вже є 2 батьків.';
      }

      // Check if current user is already in another family
      final myExistingFamily = await getCurrentFamily();
      if (myExistingFamily != null && myExistingFamily.id != family.id) {
        if (myExistingFamily.parentIds.length > 1) {
          return 'Ви вже є учасником іншої активної сім\'ї. Спочатку від\'єднайтеся від неї.';
        } else {
          // It was a solitary family, safely remove it
          await FirebaseFirestore.instance.collection('families').doc(myExistingFamily.id).delete();
        }
      }

      final updatedParentIds = [...family.parentIds, user.id];
      final updatedParentNames = Map<String, String>.from(family.parentNames);
      final updatedParentPhones = Map<String, String>.from(family.parentPhones);

      final myName = user.name.trim().isNotEmpty ? user.name.trim() : 'Партнер';
      updatedParentNames[user.id] = myName;
      if (user.phone != null && user.phone!.trim().isNotEmpty) {
        updatedParentPhones[user.id] = user.phone!.trim();
      }

      // Ensure all parents have verified names and phones from Firestore
      for (final pId in updatedParentIds) {
        if (!updatedParentNames.containsKey(pId) || updatedParentNames[pId]!.trim().isEmpty) {
          try {
            final uDoc = await FirebaseFirestore.instance.collection('users').doc(pId).get();
            if (uDoc.exists && uDoc.data() != null) {
              final n = uDoc.data()!['name'] as String? ?? '';
              final p = uDoc.data()!['phone'] as String? ?? '';
              if (n.trim().isNotEmpty) updatedParentNames[pId] = n.trim();
              if (p.trim().isNotEmpty && (!updatedParentPhones.containsKey(pId) || updatedParentPhones[pId]!.isEmpty)) {
                updatedParentPhones[pId] = p.trim();
              }
            }
          } catch (e) {
            debugPrint('Error retrieving parent info during join: $e');
          }
        }
      }

      await FirebaseFirestore.instance.collection('families').doc(family.id).update({
        'parentIds': updatedParentIds,
        'parentNames': updatedParentNames,
        'parentPhones': updatedParentPhones,
      });

      // Synchronize existing children of both parents
      final childrenSnap = await FirebaseFirestore.instance
          .collection('children')
          .where('parentId', whereIn: updatedParentIds)
          .get();

      for (final childDoc in childrenSnap.docs) {
        try {
          await childDoc.reference.update({
            'parentIds': updatedParentIds,
            'familyId': family.id,
          });
        } catch (e) {
          debugPrint('Error updating child ${childDoc.id} with parentIds: $e');
        }
      }

      return null; // Success
    } catch (e) {
      debugPrint('Error joining family: $e');
      return 'Помилка при підключенні: $e';
    }
  }

  Future<void> leaveOrUnlinkFamily({String? targetParentId}) async {
    final user = _ref.read(authControllerProvider);
    if (user == null) return;

    final family = await getCurrentFamily();
    if (family == null) return;

    final idToRemove = targetParentId ?? user.id;

    final updatedParentIds = family.parentIds.where((id) => id != idToRemove).toList();
    final updatedParentNames = Map<String, String>.from(family.parentNames)..remove(idToRemove);
    final updatedParentPhones = Map<String, String>.from(family.parentPhones)..remove(idToRemove);

    if (updatedParentIds.isEmpty) {
      await FirebaseFirestore.instance.collection('families').doc(family.id).delete();
    } else {
      await FirebaseFirestore.instance.collection('families').doc(family.id).update({
        'parentIds': updatedParentIds,
        'parentNames': updatedParentNames,
        'parentPhones': updatedParentPhones,
      });
    }
  }

  Future<({String? error, String? targetUserName})> invitePartnerByPhone(String rawPhone) async {
    final user = _ref.read(authControllerProvider);
    if (user == null) return (error: 'Потрібно авторизуватися', targetUserName: null);

    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length < 9) {
      return (error: 'Введіть коректний номер телефону (мінімум 9 цифр)', targetUserName: null);
    }

    final last9 = cleanDigits.length >= 9 
        ? cleanDigits.substring(cleanDigits.length - 9)
        : cleanDigits;

    try {
      // 1. Ensure current user has a family code to invite to
      final myFamily = await getOrCreateFamily();
      if (myFamily.isPaired) {
        return (error: 'У вас вже підключено сімейний акаунт.', targetUserName: null);
      }

      // 2. Find target partner in users
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      DocumentSnapshot? targetDoc;
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final phone = (data['phone'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
        if (phone.endsWith(last9)) {
          targetDoc = doc;
          break;
        }
      }

      if (targetDoc == null) {
        return (error: 'Користувача з таким номером не знайдено в базі додатку.', targetUserName: null);
      }

      final targetUserId = targetDoc.id;
      final targetData = targetDoc.data() as Map<String, dynamic>;
      final targetUserName = targetData['name'] as String? ?? 'Користувач';

      if (targetUserId == user.id) {
        return (error: 'Ви не можете надіслати запрошення самому собі.', targetUserName: null);
      }

      // 3. Check if target user is already in another paired family
      final partnerFamilySnap = await FirebaseFirestore.instance
          .collection('families')
          .where('parentIds', arrayContains: targetUserId)
          .limit(1)
          .get();

      if (partnerFamilySnap.docs.isNotEmpty) {
        final pFam = Family.fromJson({'id': partnerFamilySnap.docs.first.id, ...partnerFamilySnap.docs.first.data()});
        if (pFam.isPaired) {
          return (error: '$targetUserName вже перебуває в іншій активній сім\'ї.', targetUserName: null);
        }
      }

      // 4. Create an interactive notification in target user's notifications collection
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': targetUserId,
        'title': 'Запрошення до сім\'ї 👨‍👩‍👧',
        'message': '${user.name} запрошує вас об\'єднати акаунти у спільну сім\'ю для зручного керування дітьми та абонементами.',
        'timestamp': FieldValue.serverTimestamp(),
        'icon': 'heartHandshake',
        'iconColor': 0xFF10B981,
        'actionType': 'family_invite',
        'inviteCode': myFamily.inviteCode,
        'senderId': user.id,
        'senderName': user.name,
        'status': 'pending',
      });

      return (error: null, targetUserName: targetUserName);
    } catch (e) {
      debugPrint('Error inviting partner by phone: $e');
      return (error: 'Помилка надсилання запрошення: $e', targetUserName: null);
    }
  }

  Future<String?> respondToInvite(String notificationId, String inviteCode, bool accept) async {
    try {
      if (accept) {
        final error = await joinFamily(inviteCode);
        if (error != null) return error;

        await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({
          'status': 'accepted',
        });
        return null;
      } else {
        await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({
          'status': 'declined',
        });
        return null;
      }
    } catch (e) {
      debugPrint('Error responding to invite: $e');
      return 'Помилка обробки запрошення: $e';
    }
  }

  Future<String?> adminLinkParents(String parentAId, String parentBId) async {
    if (parentAId == parentBId) return 'Не можна об\'єднати один і той самий акаунт';

    try {
      // 1. Fetch both users
      final userADoc = await FirebaseFirestore.instance.collection('users').doc(parentAId).get();
      final userBDoc = await FirebaseFirestore.instance.collection('users').doc(parentBId).get();
      if (!userADoc.exists || !userBDoc.exists) return 'Клієнта не знайдено';

      final userA = userADoc.data()!;
      final userB = userBDoc.data()!;
      final nameA = userA['name'] as String? ?? 'Батько A';
      final nameB = userB['name'] as String? ?? 'Батько B';
      final phoneA = userA['phone'] as String? ?? '';
      final phoneB = userB['phone'] as String? ?? '';

      // 2. Remove solitary families if any
      final existingFamiliesSnap = await FirebaseFirestore.instance
          .collection('families')
          .where('parentIds', arrayContainsAny: [parentAId, parentBId])
          .get();

      String? targetFamilyId;
      for (final doc in existingFamiliesSnap.docs) {
        final data = doc.data();
        final pIds = List<String>.from(data['parentIds'] ?? []);
        if (pIds.length > 1 && (!pIds.contains(parentAId) || !pIds.contains(parentBId))) {
          // If already paired with someone else, error
          if ((pIds.contains(parentAId) && !pIds.contains(parentBId)) ||
              (pIds.contains(parentBId) && !pIds.contains(parentAId))) {
            return 'Один із клієнтів вже в іншій активній сім\'ї';
          }
        }
        if (targetFamilyId == null) {
          targetFamilyId = doc.id;
        } else {
          await doc.reference.delete();
        }
      }

      final docRef = targetFamilyId != null
          ? FirebaseFirestore.instance.collection('families').doc(targetFamilyId)
          : FirebaseFirestore.instance.collection('families').doc();

      final code = targetFamilyId != null && existingFamiliesSnap.docs.isNotEmpty
          ? (existingFamiliesSnap.docs.first.data()['inviteCode'] as String? ?? _generateInviteCode())
          : _generateInviteCode();

      final parentIds = [parentAId, parentBId];
      final parentNames = {parentAId: nameA, parentBId: nameB};
      final parentPhones = <String, String>{};
      if (phoneA.isNotEmpty) parentPhones[parentAId] = phoneA;
      if (phoneB.isNotEmpty) parentPhones[parentBId] = phoneB;

      final family = Family(
        id: docRef.id,
        primaryParentId: parentAId,
        parentIds: parentIds,
        parentNames: parentNames,
        parentPhones: parentPhones,
        inviteCode: code,
        createdAt: DateTime.now(),
      );

      await docRef.set(family.toJson());

      // 3. Update all children of both parents
      final childrenSnap = await FirebaseFirestore.instance
          .collection('children')
          .where('parentId', whereIn: parentIds)
          .get();

      for (final cDoc in childrenSnap.docs) {
        await cDoc.reference.update({
          'parentIds': parentIds,
          'familyId': docRef.id,
        });
      }

      return null;
    } catch (e) {
      debugPrint('Error linking parents: $e');
      return 'Помилка зв\'язування: $e';
    }
  }

  Future<void> adminUnlinkFamily(String familyId) async {
    try {
      await FirebaseFirestore.instance.collection('families').doc(familyId).delete();
    } catch (e) {
      debugPrint('Error unlinking family: $e');
    }
  }

  /// Automatically purges families whose parents no longer exist in the `users` collection.
  Future<int> cleanupOrphanedFamilies() async {
    try {
      final familiesSnap = await FirebaseFirestore.instance.collection('families').get();
      int cleanedCount = 0;
      for (final doc in familiesSnap.docs) {
        final data = doc.data();
        final parentIds = List<String>.from(data['parentIds'] ?? []);

        bool hasActiveParent = false;
        for (final pId in parentIds) {
          final uDoc = await FirebaseFirestore.instance.collection('users').doc(pId).get();
          if (uDoc.exists) {
            hasActiveParent = true;
            break;
          }
        }

        if (!hasActiveParent) {
          // No living parents exist in `users` collection!
          await doc.reference.delete();
          cleanedCount++;

          // Clean up any remaining children for this orphaned family
          final childrenSnap = await FirebaseFirestore.instance
              .collection('children')
              .where('familyId', isEqualTo: doc.id)
              .get();
          for (final cDoc in childrenSnap.docs) {
            await cDoc.reference.delete();
          }
        }
      }
      if (cleanedCount > 0) {
        debugPrint('[FamilyController] Cleaned up $cleanedCount orphaned families');
      }
      return cleanedCount;
    } catch (e) {
      debugPrint('Error cleaning up orphaned families: $e');
      return 0;
    }
  }
}
