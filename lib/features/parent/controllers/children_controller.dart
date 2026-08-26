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

  Future<void> addChild(String name, String colorHex) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('children').doc();
    final newChild = Child(
      id: docRef.id,
      parentId: user.id,
      name: name,
      colorHex: colorHex,
    );

    await docRef.set(newChild.toJson());
  }
}
