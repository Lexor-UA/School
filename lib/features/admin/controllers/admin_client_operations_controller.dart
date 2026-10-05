import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';

final adminClientOperationsProvider = Provider((ref) => AdminClientOperationsController(ref));

class AdminClientOperationsController {
  final Ref _ref;

  AdminClientOperationsController(this._ref);

  Future<void> deleteClientCompletely(String clientId, String clientName) async {
    final db = FirebaseFirestore.instance;
    final batches = <WriteBatch>[db.batch()];
    int operationCount = 0;

    void addOperation(void Function(WriteBatch batch) operation) {
      if (operationCount >= 490) {
        batches.add(db.batch());
        operationCount = 0;
      }
      operation(batches.last);
      operationCount++;
    }

    try {
      // 1. Check if client is part of any family
      final clientDoc = await db.collection('users').doc(clientId).get();
      final clientData = clientDoc.data();
      final directFamilyId = clientData?['familyId'] as String?;

      final List<DocumentSnapshot<Map<String, dynamic>>> familyDocs = [];

      if (directFamilyId != null && directFamilyId.isNotEmpty) {
        final fDoc = await db.collection('families').doc(directFamilyId).get();
        if (fDoc.exists) familyDocs.add(fDoc);
      }

      final snapByParentIds = await db
          .collection('families')
          .where('parentIds', arrayContains: clientId)
          .get();
      for (final doc in snapByParentIds.docs) {
        if (!familyDocs.any((f) => f.id == doc.id)) {
          familyDocs.add(doc);
        }
      }

      final snapByPrimary = await db
          .collection('families')
          .where('primaryParentId', isEqualTo: clientId)
          .get();
      for (final doc in snapByPrimary.docs) {
        if (!familyDocs.any((f) => f.id == doc.id)) {
          familyDocs.add(doc);
        }
      }

      String? survivingSpouseId;
      final List<String> affectedFamilyIds = [];

      for (final familyDoc in familyDocs) {
        affectedFamilyIds.add(familyDoc.id);
        final fData = familyDoc.data() ?? {};
        final parentIds = List<String>.from(fData['parentIds'] ?? []);
        parentIds.remove(clientId);

        final parentNames = Map<String, dynamic>.from(fData['parentNames'] ?? {});
        parentNames.remove(clientId);

        final parentPhones = Map<String, dynamic>.from(fData['parentPhones'] ?? {});
        parentPhones.remove(clientId);

        // Verify which surviving parent IDs actually still exist in `users`
        final List<String> activeSurvivingParentIds = [];
        for (final pId in parentIds) {
          final pUserDoc = await db.collection('users').doc(pId).get();
          if (pUserDoc.exists) {
            activeSurvivingParentIds.add(pId);
          }
        }

        if (activeSurvivingParentIds.isNotEmpty) {
          survivingSpouseId = activeSurvivingParentIds.first;
          final currentPrimary = fData['primaryParentId'] as String?;
          final newPrimary = (currentPrimary == clientId || !activeSurvivingParentIds.contains(currentPrimary))
              ? survivingSpouseId
              : currentPrimary;

          addOperation((batch) => batch.update(familyDoc.reference, {
            'parentIds': activeSurvivingParentIds,
            'parentNames': parentNames,
            'parentPhones': parentPhones,
            'primaryParentId': newPrimary,
          }));
        } else {
          addOperation((batch) => batch.delete(familyDoc.reference));
        }
      }

      // 2. Delete the user document
      addOperation((batch) => batch.delete(db.collection('users').doc(clientId)));

      // 3. Query all children linked by parentId, parentIds, or affected family IDs
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> childDocsMap = {};

      final cSnap1 = await db.collection('children').where('parentId', isEqualTo: clientId).get();
      for (final doc in cSnap1.docs) childDocsMap[doc.id] = doc;

      final cSnap2 = await db.collection('children').where('parentIds', arrayContains: clientId).get();
      for (final doc in cSnap2.docs) childDocsMap[doc.id] = doc;

      for (final fId in affectedFamilyIds) {
        final cSnapFam = await db.collection('children').where('familyId', isEqualTo: fId).get();
        for (final doc in cSnapFam.docs) childDocsMap[doc.id] = doc;
      }

      List<String> allRelatedIds = [clientId];
      for (final childDoc in childDocsMap.values) {
        final cData = childDoc.data() ?? {};
        final cParentIds = List<String>.from(cData['parentIds'] ?? []);
        cParentIds.remove(clientId);

        if (survivingSpouseId != null) {
          addOperation((batch) => batch.update(childDoc.reference, {
            'parentId': survivingSpouseId,
            'parentIds': cParentIds.isNotEmpty ? cParentIds : [survivingSpouseId!],
          }));
        } else {
          allRelatedIds.add(childDoc.id);
          addOperation((batch) => batch.delete(childDoc.reference));
        }
      }

      // 4. Clean up or transfer subscriptions
      final subsSnap = await db.collection('subscriptions').where('userId', isEqualTo: clientId).get();
      for (var doc in subsSnap.docs) {
        final sData = doc.data();
        final isChildOrSplit = sData['ownerName'] != null && sData['ownerName'] != clientName;
        if (survivingSpouseId != null && isChildOrSplit) {
          addOperation((batch) => batch.update(doc.reference, {'userId': survivingSpouseId}));
        } else {
          addOperation((batch) => batch.delete(doc.reference));
        }
      }

      for (final relId in allRelatedIds) {
        if (relId == clientId) continue;
        final childSubs = await db.collection('subscriptions').where('childId', isEqualTo: relId).get();
        for (final sDoc in childSubs.docs) {
          addOperation((batch) => batch.delete(sDoc.reference));
        }
      }

      // 5. Remove enrollments, attendance, and booked subscriptions from scheduled classes
      for (var i = 0; i < allRelatedIds.length; i += 30) {
        final chunk = allRelatedIds.sublist(i, i + 30 > allRelatedIds.length ? allRelatedIds.length : i + 30);
        
        final classesSnap = await db.collection('classes').where('enrolledChildIds', arrayContainsAny: chunk).get();
        for (var doc in classesSnap.docs) {
          final data = doc.data();
          List<dynamic> enrolled = List.from(data['enrolledChildIds'] ?? []);
          enrolled.removeWhere((id) => allRelatedIds.contains(id));
          List<dynamic> attended = List.from(data['attendedChildIds'] ?? []);
          attended.removeWhere((id) => allRelatedIds.contains(id));
          final bookedMap = Map<String, dynamic>.from(data['bookedSubscriptions'] as Map? ?? {});
          for (final relId in allRelatedIds) {
            bookedMap.remove(relId);
          }

          final isCustomBooking = data['isCustomBooking'] == true || data['createdByRole'] == 'parent';
          if (enrolled.isEmpty && isCustomBooking) {
            addOperation((batch) => batch.delete(doc.reference));
          } else {
            addOperation((batch) => batch.set(doc.reference, {
              'enrolledChildIds': enrolled,
              'attendedChildIds': attended,
              'bookedSubscriptions': bookedMap,
            }, SetOptions(merge: true)));
          }
        }

        final attendedSnap = await db.collection('classes').where('attendedChildIds', arrayContainsAny: chunk).get();
        for (var doc in attendedSnap.docs) {
          // If doc was already updated in the previous loop, this is redundant but harmless 
          // because it will just queue an identical update to the batch.
          final data = doc.data();
          List<dynamic> attended = List.from(data['attendedChildIds'] ?? []);
          attended.removeWhere((id) => allRelatedIds.contains(id));
          addOperation((batch) => batch.update(doc.reference, {
            'attendedChildIds': attended,
          }));
        }
      }

      // Commit all batches
      for (final batch in batches) {
        await batch.commit();
      }

      // Optimistically clean in-memory schedule and trigger refresh
      _ref.read(scheduleControllerProvider.notifier).removeParticipantsFromClasses(allRelatedIds);

      // 6. Purge any remaining orphaned families without active parents
      await _ref.read(familyControllerProvider).cleanupOrphanedFamilies();

    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }
}
