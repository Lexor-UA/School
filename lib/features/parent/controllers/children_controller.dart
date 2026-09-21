import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';

part 'children_controller.g.dart';

@riverpod
class ChildrenController extends _$ChildrenController {
  @override
  Stream<List<Child>> build() {
    final user = ref.watch(authControllerProvider);
    if (user == null) return Stream.value([]);

    final familyAsync = ref.watch(familyStreamProvider);
    final family = familyAsync.value;
    final parentIds = (family != null && family.parentIds.isNotEmpty)
        ? family.parentIds
        : [user.id];

    return FirebaseFirestore.instance
        .collection('children')
        .where('parentId', whereIn: parentIds)
        .snapshots()
        .map((snapshot) {
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
      throw ArgumentError('Діти від 16 років вважаються дорослими та реєструють власний окремий акаунт.');
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

    try {
      // 1. Clean up child from any scheduled classes
      final classesSnap = await FirebaseFirestore.instance
          .collection('classes')
          .where('enrolledChildIds', arrayContains: childId)
          .get();

      for (final doc in classesSnap.docs) {
        final data = doc.data();
        final enrolled = List<String>.from(data['enrolledChildIds'] ?? []);
        enrolled.remove(childId);
        final updates = <String, dynamic>{
          'enrolledChildIds': enrolled,
        };
        if (data['bookedSubscriptions'] is Map) {
          updates['bookedSubscriptions.$childId'] = FieldValue.delete();
        }
        await doc.reference.update(updates);
      }

      // 2. Delete child document
      await FirebaseFirestore.instance.collection('children').doc(childId).delete();
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
      throw ArgumentError('Діти від 16 років вважаються дорослими та реєструють власний окремий акаунт.');
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

  /// Випуск дитини (16+ років) у дорослий акаунт
  /// Переносить досягнення, рівень, XP та автоматично конвертує
  /// залишок дитячих абонементів у дорослий абонемент
  Future<String> graduateChildToAdult({
    required String childId,
    required String teenPhone,
    String? password,
    bool transferRemainingSubscriptions = true,
  }) async {
    // 1. Отримання даних дитини
    final childDoc = await FirebaseFirestore.instance.collection('children').doc(childId).get();
    if (!childDoc.exists || childDoc.data() == null) {
      throw Exception('Картку дитини не знайдено в базі даних');
    }

    final childData = Map<String, dynamic>.from(childDoc.data()!);
    childData['id'] = childDoc.id;
    final child = Child.fromJson(childData);

    if (!child.isAdultAge && (child.currentAge ?? 0) < 16) {
      throw Exception('Випуск у дорослий акаунт доступний лише для осіб віком від 16 років');
    }

    // 2. Валідація та нормалізація номеру телефону підлітка
    final cleanPhone = _normalizePhone(teenPhone);
    final rawDigits = cleanPhone.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.length < 9) {
      throw Exception('Введіть коректний номер телефону підлітка (мінімум 9 цифр)');
    }
    final last9 = rawDigits.substring(rawDigits.length - 9);

    // 3. Перевірка наявності користувача в колекції users
    final allUsers = await FirebaseFirestore.instance.collection('users').get();
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
      };

      // Якщо в існуючого користувача початковий рівень (1) та 0 XP, переносимо рівень дитини
      final existingLevel = existingData['level'] as int? ?? 1;
      final existingXp = existingData['xp'] as int? ?? 0;
      if (existingLevel <= 1 && existingXp == 0) {
        updates['level'] = child.level;
        updates['xp'] = child.xp;
        updates['maxXp'] = child.maxXp;
      }
      if (child.birthDate != null && existingData['birthDate'] == null) {
        updates['birthDate'] = child.birthDate!.toIso8601String();
      }
      if (child.currentAge != null && existingData['age'] == null) {
        updates['age'] = child.currentAge;
      }

      // Перенесення нагород
      if (child.achievements.isNotEmpty) {
        final existingAch = List<Map<String, dynamic>>.from(existingData['achievements'] ?? []);
        final existingIds = existingAch.map((a) => a['id']).toSet();
        for (final a in child.achievements) {
          if (!existingIds.contains(a.id)) {
            existingAch.add(a.toJson());
          }
        }
        updates['achievements'] = existingAch;
      }

      await FirebaseFirestore.instance.collection('users').doc(targetUserId).update(updates);
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
      final newDocRef = FirebaseFirestore.instance.collection('users').doc();
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
        'password': (password != null && password.trim().isNotEmpty) ? password.trim() : '1',
        'level': child.level,
        'xp': child.xp,
        'maxXp': child.maxXp,
        'achievements': child.achievements.map((a) => a.toJson()).toList(),
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

      await newDocRef.set(newUserData);
    }

    // 4. Автоматичний перенос залишку занять з дитячого абонементу на дорослий
    if (transferRemainingSubscriptions) {
      final parentUser = ref.read(authControllerProvider);
      final family = await ref.read(familyControllerProvider).getCurrentFamily();
      final parentIds = (family != null && family.parentIds.isNotEmpty)
          ? family.parentIds
          : (parentUser != null ? [parentUser.id] : [child.parentId]);

      final subsSnap = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', whereIn: parentIds)
          .where('isActive', isEqualTo: true)
          .get();

      int totalTransferredClasses = 0;
      for (final doc in subsSnap.docs) {
        final subData = Map<String, dynamic>.from(doc.data());
        final remaining = subData['remainingClasses'] as int? ?? 0;
        if (remaining <= 0) continue;

        final serviceName = (subData['serviceName'] as String? ?? '').toLowerCase();
        final isSplit = serviceName.contains('спліт') || serviceName.contains('split');
        final isAdult = serviceName.contains('доросл') || serviceName.contains('adult');

        // Якщо це дитячий абонемент (не спліт і не дорослий)
        if (!isSplit && !isAdult) {
          final isIndividual = serviceName.contains('індивідуал') || serviceName.contains('персон');
          final newAdultServiceName = isIndividual
              ? 'Індивідуальні заняття (дорослі)'
              : 'Групові заняття (дорослі 16+)';

          final newSubRef = FirebaseFirestore.instance.collection('subscriptions').doc();
          final expiry = subData['expiryDate'];

          final newSubData = <String, dynamic>{
            'id': newSubRef.id,
            'userId': targetUserId,
            'ownerName': child.name,
            'serviceName': newAdultServiceName,
            'totalClasses': remaining,
            'remainingClasses': remaining,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          };
          if (expiry != null) {
            newSubData['expiryDate'] = expiry;
          } else {
            newSubData['expiryDate'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
          }

          await newSubRef.set(newSubData);
          totalTransferredClasses += remaining;

          // Оновлюємо батьківський абонемент: списуємо перенесені заняття
          await doc.reference.update({
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
    final classesSnap = await FirebaseFirestore.instance
        .collection('classes')
        .where('enrolledChildIds', arrayContains: child.id)
        .get();

    for (final doc in classesSnap.docs) {
      final data = doc.data();
      final enrolled = List<String>.from(data['enrolledChildIds'] ?? []);
      enrolled.remove(child.id);

      final enrolledParents = List<String>.from(data['enrolledParentIds'] ?? []);
      if (!enrolledParents.contains(targetUserId)) {
        enrolledParents.add(targetUserId);
      }

      final updates = <String, dynamic>{
        'enrolledChildIds': enrolled,
        'enrolledParentIds': enrolledParents,
      };

      if (data['bookedSubscriptions'] is Map) {
        final booked = Map<String, dynamic>.from(data['bookedSubscriptions']);
        if (booked.containsKey(child.id)) {
          booked[targetUserId] = booked[child.id];
          booked.remove(child.id);
          updates['bookedSubscriptions'] = booked;
        }
      }
      await doc.reference.update(updates);
    }

    // 6. Архівування дитини та видалення з активних дітей
    await FirebaseFirestore.instance.collection('graduated_children').doc(child.id).set({
      ...childData,
      'graduatedToUserId': targetUserId,
      'graduatedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('children').doc(child.id).delete();

    // 7. Створення вітальних сповіщень
    final currentUser = ref.read(authControllerProvider);
    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': currentUser.id,
        'title': '🎓 Випуск у дорослий акаунт!',
        'message': 'Вітаємо! ${child.name} успішно випущено у дорослий акаунт. Номер для входу: $cleanPhone. Всі досягнення та залишок занять збережено.',
        'timestamp': FieldValue.serverTimestamp(),
        'icon': 'graduationCap',
        'iconColor': 0xFF10B981,
        'status': 'read',
      });
    }

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': targetUserId,
      'title': '🏊 Ласкаво просимо до дорослої спільноти!',
      'message': 'Вітаємо з випуском у дорослий акаунт! Твій рівень (${child.level}), накопичений досвід та заняття перенесені. Тобі відкриті дорослі та спліт-тренування!',
      'timestamp': FieldValue.serverTimestamp(),
      'icon': 'award',
      'iconColor': 0xFF0284C7,
      'status': 'unread',
    });

    return targetUserId;
  }
}
