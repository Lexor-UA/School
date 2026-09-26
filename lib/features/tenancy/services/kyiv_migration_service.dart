import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/organization.dart';
import '../models/branch.dart';
import '../models/branch_config.dart';

/// Результат виконання міграції філії Київ
class MigrationSummary {
  final int organizationsCreated;
  final int branchesCreated;
  final int branchConfigsCreated;
  final int classesUpdated;
  final int usersUpdated;
  final int subscriptionsUpdated;
  final int childrenUpdated;
  final int chatsUpdated;
  final int familiesUpdated;
  final bool isSuccess;
  final String? errorMessage;

  const MigrationSummary({
    this.organizationsCreated = 0,
    this.branchesCreated = 0,
    this.branchConfigsCreated = 0,
    this.classesUpdated = 0,
    this.usersUpdated = 0,
    this.subscriptionsUpdated = 0,
    this.childrenUpdated = 0,
    this.chatsUpdated = 0,
    this.familiesUpdated = 0,
    this.isSuccess = true,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'MigrationSummary(orgs: $organizationsCreated, branches: $branchesCreated, '
        'classes: $classesUpdated, users: $usersUpdated, subs: $subscriptionsUpdated, '
        'children: $childrenUpdated, chats: $chatsUpdated, families: $familiesUpdated, '
        'success: $isSuccess)';
  }
}

/// Сервіс безшовної міграції існуючих даних філії Київ (ТЗ Пункт 34)
///
/// Відповідає за:
/// 1. Ініціалізацію базових записів Organization (CitySwim) та Branches (Kyiv, Vienna).
/// 2. Безпечне оновлення legacy-документів без полів organizationId/branchId,
///    прив'язуючи їх до CitySwim Kyiv із 100% збереженням усіх існуючих полів.
class KyivMigrationService {
  final FirebaseFirestore _firestore;

  KyivMigrationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Перевірка та ініціалізація CitySwim, Kyiv та Vienna в Firestore
  Future<void> ensureOrganizationAndBranchesExist() async {
    try {
      // 1. Організація CitySwim
      final orgDoc = await _firestore.collection('organizations').doc(Organization.cityswim.id).get();
      if (!orgDoc.exists) {
        await _firestore
            .collection('organizations')
            .doc(Organization.cityswim.id)
            .set(Organization.cityswim.toJson());
        debugPrint('[KyivMigration] Initialized Organization: cityswim');
      }

      // 2. Філія Kyiv
      final kyivDoc = await _firestore.collection('branches').doc(Branch.kyiv.id).get();
      if (!kyivDoc.exists) {
        await _firestore
            .collection('branches')
            .doc(Branch.kyiv.id)
            .set(Branch.kyiv.toJson());
        debugPrint('[KyivMigration] Initialized Branch: kyiv');
      }

      // 3. Філія Vienna
      final viennaDoc = await _firestore.collection('branches').doc(Branch.vienna.id).get();
      if (!viennaDoc.exists) {
        await _firestore
            .collection('branches')
            .doc(Branch.vienna.id)
            .set(Branch.vienna.toJson());
        debugPrint('[KyivMigration] Initialized Branch: vienna');
      }

      // 4. Конфігурації басейнів та доріжок (Location -> Pool -> Lane)
      final kyivConfigDoc = await _firestore.collection('branch_configs').doc('kyiv').get();
      if (!kyivConfigDoc.exists) {
        await _firestore
            .collection('branch_configs')
            .doc('kyiv')
            .set(BranchConfig.kyivConfig.toJson());
      }

      final viennaConfigDoc = await _firestore.collection('branch_configs').doc('vienna').get();
      if (!viennaConfigDoc.exists) {
        await _firestore
            .collection('branch_configs')
            .doc('vienna')
            .set(BranchConfig.viennaConfig.toJson());
      }
    } catch (e) {
      debugPrint('[KyivMigration] Warning initializing org/branches (offline/test mode): $e');
    }
  }

  /// Пакетна міграція існуючих даних Києва без втрати будь-яких полів
  Future<MigrationSummary> migrateAllLegacyDataToKyiv() async {
    int classesCount = 0;
    int usersCount = 0;
    int subsCount = 0;
    int childrenCount = 0;
    int chatsCount = 0;
    int familiesCount = 0;

    try {
      await ensureOrganizationAndBranchesExist();

      // 1. Міграція занять (/classes)
      final classesSnap = await _firestore.collection('classes').get();
      WriteBatch classBatch = _firestore.batch();
      int batchOps = 0;

      for (final doc in classesSnap.docs) {
        final data = doc.data();
        if (data['branchId'] == null || data['organizationId'] == null) {
          classBatch.update(doc.reference, {
            'organizationId': 'cityswim',
            'branchId': 'kyiv',
            'timezone': data['timezone'] ?? 'Europe/Kyiv',
            'locationId': data['locationId'] ?? 'kyiv_main',
            'poolId': data['poolId'] ?? 'pool_25m',
          });
          classesCount++;
          batchOps++;
          if (batchOps >= 450) {
            await classBatch.commit();
            classBatch = _firestore.batch();
            batchOps = 0;
          }
        }
      }
      if (batchOps > 0) {
        await classBatch.commit();
      }

      // 2. Міграція користувачів (/users)
      final usersSnap = await _firestore.collection('users').get();
      WriteBatch userBatch = _firestore.batch();
      batchOps = 0;

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        if (data['branchId'] == null || data['organizationId'] == null || data['branchIds'] == null) {
          final isOwner = data['role'] == 'owner';
          userBatch.update(doc.reference, {
            'organizationId': 'cityswim',
            'branchId': data['branchId'] ?? 'kyiv',
            'branchIds': data['branchIds'] ?? (isOwner ? ['kyiv', 'vienna'] : ['kyiv']),
          });
          usersCount++;
          batchOps++;
          if (batchOps >= 450) {
            await userBatch.commit();
            userBatch = _firestore.batch();
            batchOps = 0;
          }
        }
      }
      if (batchOps > 0) {
        await userBatch.commit();
      }

      // 3. Міграція абонементів (/subscriptions)
      final subsSnap = await _firestore.collection('subscriptions').get();
      WriteBatch subBatch = _firestore.batch();
      batchOps = 0;

      for (final doc in subsSnap.docs) {
        final data = doc.data();
        if (data['branchId'] == null || data['organizationId'] == null) {
          subBatch.update(doc.reference, {
            'organizationId': 'cityswim',
            'branchId': 'kyiv',
            'currency': data['currency'] ?? 'UAH',
            'currencySymbol': data['currencySymbol'] ?? '₴',
          });
          subsCount++;
          batchOps++;
          if (batchOps >= 450) {
            await subBatch.commit();
            subBatch = _firestore.batch();
            batchOps = 0;
          }
        }
      }
      if (batchOps > 0) {
        await subBatch.commit();
      }

      // 4. Міграція дітей (/children)
      final childrenSnap = await _firestore.collection('children').get();
      WriteBatch childBatch = _firestore.batch();
      batchOps = 0;

      for (final doc in childrenSnap.docs) {
        final data = doc.data();
        if (data['branchId'] == null || data['organizationId'] == null) {
          childBatch.update(doc.reference, {
            'organizationId': 'cityswim',
            'branchId': 'kyiv',
          });
          childrenCount++;
          batchOps++;
          if (batchOps >= 450) {
            await childBatch.commit();
            childBatch = _firestore.batch();
            batchOps = 0;
          }
        }
      }
      if (batchOps > 0) {
        await childBatch.commit();
      }

      // 5. Міграція чатів (/chats)
      final chatsSnap = await _firestore.collection('chats').get();
      WriteBatch chatBatch = _firestore.batch();
      batchOps = 0;

      for (final doc in chatsSnap.docs) {
        final data = doc.data();
        if (data['branchId'] == null || data['organizationId'] == null) {
          chatBatch.update(doc.reference, {
            'organizationId': 'cityswim',
            'branchId': 'kyiv',
          });
          chatsCount++;
          batchOps++;
          if (batchOps >= 450) {
            await chatBatch.commit();
            chatBatch = _firestore.batch();
            batchOps = 0;
          }
        }
      }
      if (batchOps > 0) {
        await chatBatch.commit();
      }

      // 6. Міграція сімейних зв'язків (/family_connections)
      final famSnap = await _firestore.collection('family_connections').get();
      WriteBatch famBatch = _firestore.batch();
      batchOps = 0;

      for (final doc in famSnap.docs) {
        final data = doc.data();
        if (data['branchId'] == null || data['organizationId'] == null) {
          famBatch.update(doc.reference, {
            'organizationId': 'cityswim',
            'branchId': 'kyiv',
          });
          familiesCount++;
          batchOps++;
          if (batchOps >= 450) {
            await famBatch.commit();
            famBatch = _firestore.batch();
            batchOps = 0;
          }
        }
      }
      if (batchOps > 0) {
        await famBatch.commit();
      }

      debugPrint('[KyivMigration] Completed successfully: '
          'classes=$classesCount, users=$usersCount, subs=$subsCount, '
          'children=$childrenCount, chats=$chatsCount, families=$familiesCount');

      return MigrationSummary(
        classesUpdated: classesCount,
        usersUpdated: usersCount,
        subscriptionsUpdated: subsCount,
        childrenUpdated: childrenCount,
        chatsUpdated: chatsCount,
        familiesUpdated: familiesCount,
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('[KyivMigration] Error during migration: $e');
      return MigrationSummary(
        classesUpdated: classesCount,
        usersUpdated: usersCount,
        subscriptionsUpdated: subsCount,
        childrenUpdated: childrenCount,
        chatsUpdated: chatsCount,
        familiesUpdated: familiesCount,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}
