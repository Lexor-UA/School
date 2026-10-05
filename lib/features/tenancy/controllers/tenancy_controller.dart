import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/app_user.dart';
import '../models/organization.dart';
import '../models/branch.dart';
import '../models/branch_config.dart';
import '../../subscription/models/subscription_package.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Провайдер філії поточного авторизованого користувача (якщо не Owner)
final currentUserBranchIdProvider = Provider<String?>((ref) {
  try {
    final user = ref.watch(authControllerProvider);
    if (user != null && user.role != UserRole.owner) {
      return user.branchId;
    }
    final prefs = ref.watch(sharedPrefsProvider);
    final cachedBranchId = prefs.getString('userBranchId');
    if (cachedBranchId != null) {
      final cachedRole = prefs.getString('userRole');
      if (cachedRole != null && cachedRole != 'owner') {
        return cachedBranchId;
      }
    }
  } catch (_) {
    // Безпечний fallback для тестів або відсутності Firebase
  }
  return null;
});

/// Стан системи Multi-Tenancy
class TenancyState {
  final Organization organization;
  final List<Branch> availableBranches;
  final Branch? activeBranch; // null коли увімкнено 'All Locations'
  final bool isAllLocations;

  const TenancyState({
    required this.organization,
    required this.availableBranches,
    required this.activeBranch,
    this.isAllLocations = false,
  });

  /// ID активної філії або null для All Locations
  String? get activeBranchId => activeBranch?.id;

  /// Чи увімкнено режим «Всі локації» (Owner mode)
  bool get isAllLocationsSelected => isAllLocations;

  /// Безпечне отримання поточної філії (якщо All Locations — повертає Kyiv для уникнення NPE)
  Branch get effectiveBranch =>
      activeBranch ??
      availableBranches.firstWhereOrNull((b) => b.id == 'kyiv') ??
      (availableBranches.isNotEmpty ? availableBranches.first : Branch.kyiv);

  /// Поточний символ валюти: ₴, € або ₴ / €
  String get currencySymbol {
    if (isAllLocations) return '₴ / €';
    return activeBranch?.currencySymbol ?? '₴';
  }

  /// Поточний код валюти: UAH, EUR або UAH / EUR
  String get currencyCode {
    if (isAllLocations) return 'UAH / EUR';
    return activeBranch?.currency ?? 'UAH';
  }

  /// Поточна таймзона: Europe/Kyiv, Europe/Vienna
  String get timezone => activeBranch?.timezone ?? 'Europe/Kyiv';

  TenancyState copyWith({
    Organization? organization,
    List<Branch>? availableBranches,
    Branch? activeBranch,
    bool? isAllLocations,
    bool clearActiveBranch = false,
  }) {
    return TenancyState(
      organization: organization ?? this.organization,
      availableBranches: availableBranches ?? this.availableBranches,
      activeBranch: clearActiveBranch ? null : (activeBranch ?? this.activeBranch),
      isAllLocations: isAllLocations ?? this.isAllLocations,
    );
  }
}

/// Контролер управління мультитенантністю (Riverpod 3 Notifier)
class TenancyNotifier extends Notifier<TenancyState> {
  static const String _prefBranchKey = 'selected_branch_id';
  StreamSubscription? _branchesSub;

  @override
  TenancyState build() {
    ref.onDispose(() {
      _branchesSub?.cancel();
    });

    _initFirestoreBranches();

    final prefs = ref.watch(sharedPrefsProvider);
    final savedBranchId = prefs.getString(_prefBranchKey);

    // Пряма перевірка філії користувача для уникнення каскадного invalidateSelf під час білду віджетів
    String? userBranchId;
    try {
      final user = ref.watch(authControllerProvider);
      if (user != null && user.role != UserRole.owner) {
        userBranchId = user.branchId;
      } else {
        final cachedBranchId = prefs.getString('userBranchId');
        final cachedRole = prefs.getString('userRole');
        if (cachedBranchId != null && cachedRole != 'owner') {
          userBranchId = cachedBranchId;
        }
      }
    } catch (_) {}

    if (userBranchId != null) {
      final userBranch = Branch.defaultBranches.firstWhereOrNull((b) => b.id == userBranchId) ?? Branch.kyiv;
      return TenancyState(
        organization: Organization.cityswim,
        availableBranches: Branch.defaultBranches,
        activeBranch: userBranch,
        isAllLocations: false,
      );
    }

    // Для Owner (або неавторизованого стану) перевіряємо збережений вибір
    if (savedBranchId == 'all') {
      return TenancyState(
        organization: Organization.cityswim,
        availableBranches: Branch.defaultBranches,
        activeBranch: null,
        isAllLocations: true,
      );
    } else if (savedBranchId != null) {
      final target = Branch.defaultBranches.firstWhereOrNull((b) => b.id == savedBranchId);
      if (target != null) {
        return TenancyState(
          organization: Organization.cityswim,
          availableBranches: Branch.defaultBranches,
          activeBranch: target,
          isAllLocations: false,
        );
      }
    }

    // За замовчуванням стартуємо з Kyiv
    return TenancyState(
      organization: Organization.cityswim,
      availableBranches: Branch.defaultBranches,
      activeBranch: Branch.kyiv,
      isAllLocations: false,
    );
  }

  /// Ініціалізація та слухання колекції філій у Firestore в реальному часі
  void _initFirestoreBranches() {
    try {
      final firestore = FirebaseFirestore.instance;
      _branchesSub?.cancel();
      _branchesSub = firestore.collection('branches').snapshots().listen((snapshot) {
        if (snapshot.docs.isEmpty) return;

        final Map<String, Branch> branchMap = {
          for (final b in Branch.defaultBranches) b.id: b,
        };

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            final branch = Branch.fromJson(data);
            branchMap[branch.id] = branch;

            // Реєстрація конфігурацій басейнів та абонементів
            BranchConfig.forBranch(branch.id, branch.name, branch.city);
            SubscriptionPackageCatalog.getPackagesForBranch(branch.id, branch.currency, branch.currencySymbol);
          } catch (e) {
            debugPrint('[TenancyNotifier] Помилка парсингу філії: $e');
          }
        }

        final updatedList = branchMap.values.toList();
        Branch? nextActive = state.activeBranch;
        if (state.activeBranch != null) {
          nextActive = branchMap[state.activeBranch!.id] ?? state.activeBranch;
        }

        state = state.copyWith(
          availableBranches: updatedList,
          activeBranch: nextActive,
        );
      }, onError: (err) {
        debugPrint('[TenancyNotifier] Помилка стріму філій Firestore: $err');
      });
    } catch (e) {
      debugPrint('[TenancyNotifier] Firestore недоступний (offline/test mode): $e');
    }
  }

  /// Перемикання поточної філії (тільки для Owner або SuperAdmin)
  Future<void> switchBranch(String branchId) async {
    try {
      final user = ref.read(authControllerProvider);
      if (user != null && !user.isOwnerOrSuperAdmin) {
        // Адміністратори та співробітники жорстко прив'язані до своєї філії
        return;
      }
    } catch (_) {}

    final prefs = ref.read(sharedPrefsProvider);

    if (branchId == 'all') {
      await prefs.setString(_prefBranchKey, 'all');
      state = state.copyWith(
        isAllLocations: true,
        clearActiveBranch: true,
      );
      return;
    }

    final targetBranch = state.availableBranches.firstWhereOrNull((b) => b.id == branchId);
    if (targetBranch != null) {
      await prefs.setString(_prefBranchKey, targetBranch.id);
      state = state.copyWith(
        activeBranch: targetBranch,
        isAllLocations: false,
      );
    }
  }

  /// Аліас для вибору філії (наприклад при реєстрації чи переході за deep link)
  Future<void> selectBranch(String branchId) => switchBranch(branchId);

  /// Додавання нової філії (для масштабування майбутнього AquatixLab)
  void registerBranch(Branch branch) {
    if (state.availableBranches.any((b) => b.id == branch.id)) {
      updateBranchInMemory(branch);
      return;
    }
    final updatedList = [...state.availableBranches, branch];
    state = state.copyWith(availableBranches: updatedList);
  }

  /// Оновлення філії в локальному стані
  void updateBranchInMemory(Branch branch) {
    final updatedList = state.availableBranches
        .map((b) => b.id == branch.id ? branch : b)
        .toList();
    if (!updatedList.any((b) => b.id == branch.id)) {
      updatedList.add(branch);
    }
    state = state.copyWith(availableBranches: updatedList);
  }

  /// Створення нової філії та автоматичне створення її адміністратора та конфігурації басейнів у Firestore
  Future<void> createBranch(
    Branch branch, {
    int? adminSalary,
    String? adminName,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Запис філії у Firestore
      await firestore
          .collection('branches')
          .doc(branch.id)
          .set(branch.toJson());

      // 2. Автоматичне створення окремої конфігурації басейну та локації для філії
      final branchConfig = BranchConfig.createDefault(
        branchId: branch.id,
        branchName: branch.name,
        city: branch.city,
      );
      await firestore
          .collection('branch_configs')
          .doc(branch.id)
          .set(branchConfig.toJson(), SetOptions(merge: true));
      BranchConfig.registerConfig(branchConfig);

      // 3. Ініціалізація каталогу абонементів для валюти філії
      SubscriptionPackageCatalog.getPackagesForBranch(branch.id, branch.currency, branch.currencySymbol);

      // 4. Автоматичне створення адміністратора нової філії у колекції 'users'
      final adminDocId = 'admin_${branch.id}';
      final isEuro = branch.currency == 'EUR';
      final defaultSalary = branch.currency == 'UAH' ? 20000 : 1800;

      await firestore.collection('users').doc(adminDocId).set({
        'id': adminDocId,
        'name': (adminName != null && adminName.trim().isNotEmpty)
            ? adminName.trim()
            : 'Адміністратор ${branch.name}',
        'role': 'admin',
        'branchId': branch.id,
        'branchIds': [branch.id],
        'phone': '',
        'loginId': 'admin.${branch.id}@cityswim.at',
        'currency': branch.currencySymbol,
        'adminSalary': adminSalary ?? defaultSalary,
        'salaryType': 'monthly',
        'rateGroup': isEuro ? 25 : 400,
        'rateIndividual': isEuro ? 35 : 450,
        'rateSplit': isEuro ? 45 : 600,
        'avatarUrl': 'https://ui-avatars.com/api/?name=Admin+${Uri.encodeComponent(branch.name)}&background=8b5cf6&color=ffffff',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5. Оновлення локального стану
      registerBranch(branch);
    } catch (e) {
      rethrow;
    }
  }

  /// Оновлення параметрів існуючої філії
  Future<void> updateBranch(
    Branch branch, {
    int? adminSalary,
    String? adminName,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Оновлення документа філії у Firestore
      await firestore
          .collection('branches')
          .doc(branch.id)
          .set(branch.toJson(), SetOptions(merge: true));

      // 2. Оновлення даних адміністратора (якщо змінювалися)
      final adminDocId = 'admin_${branch.id}';
      final adminRef = firestore.collection('users').doc(adminDocId);
      final adminSnap = await adminRef.get();
      if (adminSnap.exists) {
        final updates = <String, dynamic>{
          'currency': branch.currencySymbol,
        };
        if (adminSalary != null) updates['adminSalary'] = adminSalary;
        if (adminName != null && adminName.trim().isNotEmpty) {
          updates['name'] = adminName.trim();
        }
        await adminRef.set(updates, SetOptions(merge: true));
      }

      // 3. Оновлення конфігурацій
      BranchConfig.forBranch(branch.id, branch.name, branch.city);
      SubscriptionPackageCatalog.getPackagesForBranch(branch.id, branch.currency, branch.currencySymbol);

      // 4. Оновлення локального списку філій
      final updatedList = state.availableBranches
          .map((b) => b.id == branch.id ? branch : b)
          .toList();
      if (!updatedList.any((b) => b.id == branch.id)) {
        updatedList.add(branch);
      }

      Branch? nextActive = state.activeBranch;
      if (state.activeBranch?.id == branch.id) {
        nextActive = branch;
      }

      state = state.copyWith(
        availableBranches: updatedList,
        activeBranch: nextActive,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Видалення філії зі всіма її налаштуваннями
  Future<void> deleteBranch(String branchId) async {
    // 1. Захист системних базових філій
    if (branchId == 'kyiv' || branchId == 'vienna') {
      throw Exception('Неможливо видалити базову системну філію ($branchId). Вона є кореневою для додатку.');
    }

    final target = state.availableBranches.firstWhereOrNull((b) => b.id == branchId);
    if (target != null && target.isProtected) {
      throw Exception('Філія "${target.name}" захищена від видалення. Щоб видалити, спочатку вимкніть захист у картці філії.');
    }

    try {
      try {
        final firestore = FirebaseFirestore.instance;

        // 2. Видалення з Firestore
        await firestore.collection('branches').doc(branchId).delete();
        await firestore.collection('branch_configs').doc(branchId).delete();
        await firestore.collection('users').doc('admin_$branchId').delete();
      } catch (firestoreErr) {
        debugPrint('[TenancyNotifier] Помилка видалення з Firestore (offline/test mode): $firestoreErr');
      }

      // 3. Очищення кешів
      BranchConfig.removeConfig(branchId);
      SubscriptionPackageCatalog.removeCustomPackages(branchId);

      // 4. Оновлення локального стану
      final updatedList = state.availableBranches.where((b) => b.id != branchId).toList();
      Branch? nextActive = state.activeBranch;
      if (state.activeBranch?.id == branchId) {
        nextActive = updatedList.firstWhereOrNull((b) => b.id == 'kyiv') ??
            (updatedList.isNotEmpty ? updatedList.first : Branch.kyiv);
      }

      state = state.copyWith(
        availableBranches: updatedList,
        activeBranch: nextActive,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Гарантує наявність адміністраторів для дефолтних філій (Київ та Відень) у Firestore
  Future<void> ensureDefaultBranchAdminsExist() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Адміністратор Києва
      final kyivAdminRef = firestore.collection('users').doc('admin');
      final kyivSnap = await kyivAdminRef.get();
      if (!kyivSnap.exists) {
        await kyivAdminRef.set({
          'id': 'admin',
          'name': 'Адміністратор',
          'role': 'admin',
          'branchId': 'kyiv',
          'branchIds': ['kyiv'],
          'phone': '+380 (99) 000-00-01',
          'loginId': 'Admin',
          'currency': '₴',
          'adminSalary': 20000,
          'salaryType': 'monthly',
          'rateGroup': 400,
          'rateIndividual': 450,
          'rateSplit': 600,
          'avatarUrl': 'https://ui-avatars.com/api/?name=Admin&background=db2777&color=ffffff',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = kyivSnap.data() ?? {};
        final role = (data['role'] as String?)?.toLowerCase();
        final updates = <String, dynamic>{};
        if (role != 'admin') updates['role'] = 'admin';
        if (data['branchId'] == null) updates['branchId'] = 'kyiv';
        if (data['currency'] == null) updates['currency'] = '₴';
        if (data['adminSalary'] == null) updates['adminSalary'] = 20000;
        if (updates.isNotEmpty) {
          await kyivAdminRef.set(updates, SetOptions(merge: true));
        }
      }

      // 2. Адміністратор Відня
      final viennaAdminRef = firestore.collection('users').doc('admin_vienna');
      final viennaSnap = await viennaAdminRef.get();
      if (!viennaSnap.exists) {
        await viennaAdminRef.set({
          'id': 'admin_vienna',
          'name': 'Admin Vienna',
          'role': 'admin',
          'branchId': 'vienna',
          'branchIds': ['vienna'],
          'phone': '+43 1 234 5678',
          'loginId': 'vienna.admin@cityswim.at',
          'currency': '€',
          'adminSalary': 1900,
          'salaryType': 'monthly',
          'rateGroup': 25,
          'rateIndividual': 35,
          'rateSplit': 45,
          'avatarUrl': 'https://ui-avatars.com/api/?name=Vienna+Admin&background=8b5cf6&color=ffffff',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = viennaSnap.data() ?? {};
        final role = (data['role'] as String?)?.toLowerCase();
        final updates = <String, dynamic>{};
        if (role != 'admin') updates['role'] = 'admin';
        if (data['branchId'] == null) updates['branchId'] = 'vienna';
        if (data['currency'] == null) updates['currency'] = '€';
        if (data['adminSalary'] == null) updates['adminSalary'] = 1900;
        if (updates.isNotEmpty) {
          await viennaAdminRef.set(updates, SetOptions(merge: true));
        }
      }
    } catch (_) {
      // Безпечно ігноруємо при відсутності мережі або в тестах
    }
  }
}

/// Головний провайдер системи мультитенантності
final tenancyControllerProvider =
    NotifierProvider<TenancyNotifier, TenancyState>(() => TenancyNotifier());

/// Провайдер поточної активної філії (може бути null, якщо обрано 'All Locations')
final activeBranchProvider = Provider<Branch?>((ref) {
  return ref.watch(tenancyControllerProvider).activeBranch;
});

/// Провайдер гарантованої поточної філії (не null, fallback на Kyiv)
final effectiveBranchProvider = Provider<Branch>((ref) {
  return ref.watch(tenancyControllerProvider).effectiveBranch;
});

/// Провайдер прапорця режиму «Всі локації» (для Owner)
final isAllLocationsSelectedProvider = Provider<bool>((ref) {
  return ref.watch(tenancyControllerProvider).isAllLocations;
});

/// Провайдер активного символу валюти ('₴', '€' або '₴ / €')
final activeCurrencySymbolProvider = Provider<String>((ref) {
  return ref.watch(tenancyControllerProvider).currencySymbol;
});

/// Провайдер активного коду валюти ('UAH', 'EUR' або 'UAH / EUR')
final activeCurrencyCodeProvider = Provider<String>((ref) {
  return ref.watch(tenancyControllerProvider).currencyCode;
});

/// Провайдер активної таймзони ('Europe/Kyiv', 'Europe/Vienna')
final activeTimezoneProvider = Provider<String>((ref) {
  return ref.watch(tenancyControllerProvider).timezone;
});

/// Провайдер доступних філій
final availableBranchesProvider = Provider<List<Branch>>((ref) {
  return ref.watch(tenancyControllerProvider).availableBranches;
});
