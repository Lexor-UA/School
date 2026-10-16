import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/shared/utils/password_security_helper.dart';

part 'children_controller.g.dart';

@riverpod
class ChildrenController extends _$ChildrenController {
  @override
  Stream<List<Child>> build() {
    final user = ref.watch(authControllerProvider);
    if (user == null) return Stream.value([]);

    final familyAsync = ref.watch(familyStreamProvider);
    final family = familyAsync.value;
    final parentIds = <String>{
      user.id,
      if (family != null) ...family.parentIds,
    }.toList();

    final query = parentIds.length == 1
        ? FirebaseFirestore.instance
            .collection('children')
            .where('parentId', isEqualTo: parentIds.first)
        : FirebaseFirestore.instance
            .collection('children')
            .where('parentId', whereIn: parentIds);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Child.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  Future<void> addChild(
    String name, {
    int? age,
    DateTime? birthDate,
    String? colorHex,
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    int? calculatedAge = age;
    if (birthDate != null) {
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        years--;
      }
      calculatedAge = years >= 0 ? years : 0;
    }

    if (calculatedAge != null && calculatedAge > 15) {
      throw ArgumentError('parent.child_age_over_15_err'.tr());
    }

    final family = await ref.read(familyControllerProvider).getCurrentFamily();
    final parentIds = (family != null && family.parentIds.isNotEmpty)
        ? family.parentIds
        : [user.id];

    final docRef = FirebaseFirestore.instance.collection('children').doc();
    final newChild = Child(
      id: docRef.id,
      parentId: user.id,
      name: name,
      age: calculatedAge,
      birthDate: birthDate,
      colorHex: colorHex ?? '0xFF40C4FF',
      organizationId: user.organizationId,
      branchId: user.branchId,
    );

    final childData = newChild.toJson();
    childData['parentIds'] = parentIds;
    if (family != null) {
      childData['familyId'] = family.id;
    }

    await docRef.set(childData);
  }

  Future<void> deleteChild(String childId) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    try {
      // 1. Clean up child from any scheduled classes
      final classesSnap = await db
          .collection('classes')
          .where('enrolledChildIds', arrayContains: childId)
          .get();

      for (final doc in classesSnap.docs) {
        final data = doc.data();
        final enrolled = List<String>.from(data['enrolledChildIds'] ?? []);
        enrolled.remove(childId);
        final attended = List<String>.from(data['attendedChildIds'] ?? []);
        attended.remove(childId);
        final updates = <String, dynamic>{
          'enrolledChildIds': enrolled,
          'attendedChildIds': attended,
        };
        if (data['bookedSubscriptions'] is Map) {
          final bookedMap = Map<String, dynamic>.from(data['bookedSubscriptions'] as Map);
          final bookedSubId = bookedMap[childId] as String?;
          bookedMap.remove(childId);
          updates['bookedSubscriptions'] = bookedMap;

          // Refund class pass to subscription if class is in the future
          if (bookedSubId != null) {
            DateTime? startTime;
            if (data['startTime'] is Timestamp) {
              startTime = (data['startTime'] as Timestamp).toDate();
            } else if (data['startTime'] is String) {
              startTime = DateTime.tryParse(data['startTime'] as String);
            }
            if (startTime == null || startTime.isAfter(DateTime.now())) {
              try {
                final subRef = db.collection('subscriptions').doc(bookedSubId);
                final subDoc = await subRef.get();
                if (subDoc.exists) {
                  final cur = subDoc.data()?['remainingClasses'] as int? ?? 0;
                  batch.update(subRef, {
                    'remainingClasses': cur + 1,
                    'isActive': true,
                  });
                }
              } catch (subErr) {
                debugPrint('Notice: refunding subscription on child delete: $subErr');
              }
            }
          }
        }
        final isCustomBooking = data['isCustomBooking'] == true || data['createdByRole'] == 'parent';
        if (enrolled.isEmpty && isCustomBooking) {
          batch.delete(doc.reference);
        } else {
          batch.update(doc.reference, updates);
        }
      }

      // Also clean up any past classes where child was in attendedChildIds
      try {
        final attendedSnap = await db
            .collection('classes')
            .where('attendedChildIds', arrayContains: childId)
            .get();
        for (final aDoc in attendedSnap.docs) {
          final aData = aDoc.data();
          final attList = List<String>.from(aData['attendedChildIds'] ?? []);
          attList.remove(childId);
          batch.update(aDoc.reference, {'attendedChildIds': attList});
        }
      } catch (_) {}

      // 2. Delete child document
      batch.delete(db.collection('children').doc(childId));
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting child $childId: $e');
      rethrow;
    }
  }

  Future<void> updateChild(
    String childId,
    String name, {
    int? age,
    DateTime? birthDate,
    String? colorHex,
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    int? calculatedAge = age;
    if (birthDate != null) {
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        years--;
      }
      calculatedAge = years >= 0 ? years : 0;
    }

    if (calculatedAge != null && calculatedAge > 15) {
      throw ArgumentError('parent.child_age_over_15_err'.tr());
    }

    final updates = <String, dynamic>{
      'name': name,
      'age': calculatedAge,
      'birthDate': birthDate?.toIso8601String(),
    };
    if (colorHex != null) {
      updates['colorHex'] = colorHex;
    }

    await FirebaseFirestore.instance.collection('children').doc(childId).update(updates);
  }

  String _normalizePhone(String phone, {String? branchId}) {
    final trimmed = phone.trim();
    String digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (trimmed.startsWith('+')) {
      return '+$digits';
    }
    if (branchId == 'vienna' || digits.startsWith('43')) {
      if (digits.startsWith('43') && digits.length >= 10) {
        return '+$digits';
      } else if (digits.startsWith('0') && digits.length >= 9) {
        return '+43${digits.substring(1)}';
      }
    }
    if (digits.startsWith('380') && digits.length >= 12) {
      return '+$digits';
    } else if (digits.startsWith('0') && digits.length == 10) {
      return '+38$digits';
    } else if (digits.length == 9) {
      return '+380$digits';
    }
    return trimmed;
  }

  /// Випуск дитини (16+ років) у дорослий акаунт
  /// Автоматично конвертує залишок дитячих абонементів цієї дитини у дорослий абонемент
  Future<String> graduateChildToAdult({
    required String childId,
    required String teenPhone,
    String? password,
    bool transferRemainingSubscriptions = true,
  }) async {
    final db = FirebaseFirestore.instance;
    // 1. Отримання даних дитини
    final childDoc = await db.collection('children').doc(childId).get();
    if (!childDoc.exists || childDoc.data() == null) {
      throw Exception('graduate.child_not_found_err'.tr());
    }

    final childData = Map<String, dynamic>.from(childDoc.data()!);
    childData['id'] = childDoc.id;
    final child = Child.fromJson(childData);

    if (!child.isAdultAge && (child.currentAge ?? 0) < 16) {
      throw Exception('graduate.age_under_16_err'.tr());
    }

    // 2. Валідація та нормалізація номеру телефону підлітка
    final cleanPhone = _normalizePhone(teenPhone, branchId: child.branchId);
    final rawDigits = cleanPhone.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.length < 9) {
      throw Exception('graduate.invalid_phone_err'.tr());
    }
    final last9 = rawDigits.substring(rawDigits.length - 9);
    final rawPassword = (password != null && password.trim().isNotEmpty) ? password.trim() : '1';
    final hashedPassword = PasswordSecurityHelper.hashPassword(rawPassword);

    final batch = db.batch();

    // 3. Перевірка наявності користувача в колекції users
    final allUsers = await db.collection('users').get();
    final existingUserDoc = allUsers.docs.firstWhereOrNull((d) {
      final p = (d.data()['phone'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
      return p.endsWith(last9);
    });

    String targetUserId;
    if (existingUserDoc != null) {
      // Користувач уже існує - оновлюємо та синхронізуємо
      targetUserId = existingUserDoc.id;
      final existingData = existingUserDoc.data();
      final updates = <String, dynamic>{
        'isAdultOnly': true,
        'graduatedFromChildId': child.id,
        'graduatedAt': FieldValue.serverTimestamp(),
        'password': hashedPassword,
        'branchId': existingData['branchId'] ?? child.branchId,
        'organizationId': existingData['organizationId'] ?? child.organizationId,
      };

      if (child.birthDate != null && existingData['birthDate'] == null) {
        updates['birthDate'] = child.birthDate!.toIso8601String();
      }
      if (child.currentAge != null && existingData['age'] == null) {
        updates['age'] = child.currentAge;
      }

      batch.update(db.collection('users').doc(targetUserId), updates);
    } else {
      // Створення нового дорослого користувача AppUser
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
      final assignedLoginId = 'client${maxClientNum + 1}';
      final newDocRef = db.collection('users').doc();
      targetUserId = newDocRef.id;

      final parts = child.name.trim().split(' ').where((s) => s.isNotEmpty).toList();
      final avatarInitials = parts.isNotEmpty
          ? (parts.length > 1 ? '${parts[0][0]}+${parts[1][0]}' : parts[0][0])
          : 'Adult';

      final newUserData = <String, dynamic>{
        'id': targetUserId,
        'name': child.name.trim(),
        'role': 'parent', // Повноправний дорослий клієнт
        'phone': cleanPhone,
        'loginId': assignedLoginId,
        'password': hashedPassword,
        'branchId': child.branchId,
        'organizationId': child.organizationId,
        'avatarUrl': 'https://ui-avatars.com/api/?name=$avatarInitials&background=0284c7&color=ffffff',
        'isAdultOnly': true,
        'graduatedFromChildId': child.id,
        'graduatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': true,
      };

      if (child.currentAge != null) {
        newUserData['age'] = child.currentAge;
      }
      if (child.birthDate != null) {
        newUserData['birthDate'] = child.birthDate!.toIso8601String();
      }

      batch.set(newDocRef, newUserData);
    }

    // 4. Автоматичний перенос залишку занять з дитячого абонементу цієї дитини на дорослий
    String? lastCreatedAdultSubId;
    if (transferRemainingSubscriptions) {
      final parentUser = ref.read(authControllerProvider);
      final family = await ref.read(familyControllerProvider).getCurrentFamily();
      final parentIds = (family != null && family.parentIds.isNotEmpty)
          ? family.parentIds
          : (parentUser != null ? [parentUser.id] : [child.parentId]);

      final allFamilyChildrenSnap = await db
          .collection('children')
          .where('parentId', whereIn: parentIds)
          .get();
      final familyChildrenCount = allFamilyChildrenSnap.docs.length;
      final targetChildName = child.name.trim().toLowerCase();

      final subsSnap = await db
          .collection('subscriptions')
          .where('userId', whereIn: parentIds)
          .where('isActive', isEqualTo: true)
          .get();

      int totalTransferredClasses = 0;
      for (final doc in subsSnap.docs) {
        final subData = Map<String, dynamic>.from(doc.data());
        final remaining = subData['remainingClasses'] as int? ?? 0;
        if (remaining <= 0) continue;

        final subOwner = (subData['ownerName'] as String? ?? '').trim().toLowerCase();
        final belongsToGraduatingChild = subOwner == targetChildName ||
            (subOwner == 'всі' && familyChildrenCount <= 1);
        if (!belongsToGraduatingChild) continue;

        final serviceName = (subData['serviceName'] as String? ?? '').toLowerCase();
        final isSplit = serviceName.contains('спліт') || serviceName.contains('split');
        final isAdult = serviceName.contains('доросл') || serviceName.contains('adult');

        // Якщо це дитячий абонемент (не спліт і не дорослий)
        if (!isSplit && !isAdult) {
          final isIndividual = serviceName.contains('індивідуал') || serviceName.contains('персон');
          final newAdultServiceName = isIndividual
              ? 'Індивідуальні заняття (дорослі)'
              : 'Групові заняття (дорослі 16+)';

          final newSubRef = db.collection('subscriptions').doc();
          lastCreatedAdultSubId = newSubRef.id;
          final expiry = subData['expiryDate'];

          final newSubData = <String, dynamic>{
            'id': newSubRef.id,
            'userId': targetUserId,
            'ownerName': child.name,
            'serviceName': newAdultServiceName,
            'totalClasses': remaining,
            'remainingClasses': remaining,
            'isActive': true,
            'organizationId': subData['organizationId'] ?? child.organizationId,
            'branchId': subData['branchId'] ?? child.branchId,
            'currency': subData['currency'] ?? (child.branchId == 'vienna' ? 'EUR' : 'UAH'),
            'currencySymbol': subData['currencySymbol'] ?? (child.branchId == 'vienna' ? '€' : '₴'),
            'createdAt': FieldValue.serverTimestamp(),
          };
          if (expiry != null) {
            newSubData['expiryDate'] = expiry;
          } else {
            newSubData['expiryDate'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
          }

          batch.set(newSubRef, newSubData);
          totalTransferredClasses += remaining;

          // Оновлюємо батьківський абонемент: списуємо перенесені заняття
          batch.update(doc.reference, {
            'remainingClasses': 0,
            'isActive': false,
            'notes': 'Залишок ($remaining занять) перенесено у дорослий акаунт ${child.name} ($targetUserId)',
          });
        }
      }
      if (totalTransferredClasses > 0) {
        debugPrint('Successfully transferred $totalTransferredClasses remaining classes to graduated adult account $targetUserId');
      }
    }

    // 5. Оновлення майбутніх занять у розкладі (classes)
    final classesSnap = await db
        .collection('classes')
        .where('enrolledChildIds', arrayContains: child.id)
        .get();

    for (final doc in classesSnap.docs) {
      final data = doc.data();
      final enrolled = List<String>.from(data['enrolledChildIds'] ?? []);
      final enrolledIdx = enrolled.indexOf(child.id);
      if (enrolledIdx != -1) {
        if (!enrolled.contains(targetUserId)) {
          enrolled[enrolledIdx] = targetUserId;
        } else {
          enrolled.removeAt(enrolledIdx);
        }
      }

      final attended = List<String>.from(data['attendedChildIds'] ?? []);
      final attendedIdx = attended.indexOf(child.id);
      if (attendedIdx != -1) {
        if (!attended.contains(targetUserId)) {
          attended[attendedIdx] = targetUserId;
        } else {
          attended.removeAt(attendedIdx);
        }
      }

      final updates = <String, dynamic>{
        'enrolledChildIds': enrolled,
        'attendedChildIds': attended,
      };

      if (data['bookedSubscriptions'] is Map) {
        final booked = Map<String, dynamic>.from(data['bookedSubscriptions']);
        if (booked.containsKey(child.id)) {
          booked[targetUserId] = lastCreatedAdultSubId ?? booked[child.id];
          booked.remove(child.id);
          updates['bookedSubscriptions'] = booked;
        }
      }
      batch.update(doc.reference, updates);
    }

    // 6. Архівування дитини та видалення з активних дітей
    batch.set(db.collection('graduated_children').doc(child.id), {
      ...childData,
      'graduatedToUserId': targetUserId,
      'graduatedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(db.collection('children').doc(child.id));

    // 7. Створення вітальних сповіщень
    final currentUser = ref.read(authControllerProvider);
    if (currentUser != null) {
      batch.set(db.collection('notifications').doc(), {
        'userId': currentUser.id,
        'title': 'graduate.parent_notif_title'.tr(),
        'message': 'graduate.parent_notif_msg'.tr(args: [child.name, cleanPhone]),
        'timestamp': FieldValue.serverTimestamp(),
        'icon': 'graduationCap',
        'iconColor': 0xFF10B981,
        'status': 'read',
      });
    }

    batch.set(db.collection('notifications').doc(), {
      'userId': targetUserId,
      'title': 'graduate.teen_notif_title'.tr(),
      'message': 'graduate.teen_notif_msg'.tr(),
      'timestamp': FieldValue.serverTimestamp(),
      'icon': 'award',
      'iconColor': 0xFF0284C7,
      'status': 'unread',
    });

    await batch.commit();

    return targetUserId;
  }
}
