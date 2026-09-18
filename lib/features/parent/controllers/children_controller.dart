import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

part 'children_controller.g.dart';

@riverpod
class ChildrenController extends _$ChildrenController {
  @override
  Stream<List<Child>> build() {
    final user = ref.watch(authControllerProvider);
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('children')
        .where('parentId', isEqualTo: user.id)
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

    final docRef = FirebaseFirestore.instance.collection('children').doc();
    final newChild = Child(
      id: docRef.id,
      parentId: user.id,
      name: name,
      age: calculatedAge,
      birthDate: birthDate,
      colorHex: colorHex ?? '0xFF40C4FF',
    );

    await docRef.set(newChild.toJson());
  }

  Future<void> deleteChild(String childId) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    await FirebaseFirestore.instance.collection('children').doc(childId).delete();
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
