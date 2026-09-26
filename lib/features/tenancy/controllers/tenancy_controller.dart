import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/app_user.dart';
import '../models/organization.dart';
import '../models/branch.dart';

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

  @override
  TenancyState build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final savedBranchId = prefs.getString(_prefBranchKey);

    // Якщо користувач авторизований і не є Owner — він прив'язаний до своєї філії
    final userBranchId = ref.watch(currentUserBranchIdProvider);
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

  /// Перемикання поточної філії (для Owner)
  Future<void> switchBranch(String branchId) async {
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
    if (state.availableBranches.any((b) => b.id == branch.id)) return;
    final updatedList = [...state.availableBranches, branch];
    state = state.copyWith(availableBranches: updatedList);
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
