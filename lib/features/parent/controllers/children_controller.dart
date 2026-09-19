import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
}
