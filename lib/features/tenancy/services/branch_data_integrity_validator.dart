import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';

/// Result of a data integrity or cross-branch validation check.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
  });

  static const valid = ValidationResult(isValid: true);

  factory ValidationResult.invalid(String message, [String? code]) =>
      ValidationResult(
        isValid: false,
        errorMessage: message,
        errorCode: code,
      );

  @override
  String toString() => isValid
      ? 'ValidationResult.valid'
      : 'ValidationResult.invalid($errorCode: $errorMessage)';
}

/// Central validator for multi-tenancy rules and data integrity guards across branches.
/// Enforces isolation between CitySwim Kyiv 🇺🇦 and CitySwim Vienna 🇦🇹.
class BranchDataIntegrityValidator {
  BranchDataIntegrityValidator._();

  static String _formatBranchName(String branchId) {
    switch (branchId.toLowerCase().trim()) {
      case 'vienna':
      case 'wien':
        return 'CitySwim Vienna 🇦🇹';
      case 'kyiv':
      case 'kiev':
        return 'CitySwim Kyiv 🇺🇦';
      default:
        return 'Філія ($branchId)';
    }
  }

  /// Rule 1: Attendance Deduction Guard (TZ Point 29).
  /// Enforces: subscription.branchId == groupClass.branchId == client.branchId.
  /// Prevents deducting a Kyiv subscription for a Vienna lesson or vice versa.
  static ValidationResult validateAttendanceDeduction({
    required Subscription subscription,
    required GroupClass groupClass,
    String? clientBranchId,
  }) {
    final subBranch = subscription.branchId.toLowerCase().trim();
    final classBranch = groupClass.branchId.toLowerCase().trim();

    if (subBranch != classBranch) {
      final subBranchName = _formatBranchName(subBranch);
      final classBranchName = _formatBranchName(classBranch);
      return ValidationResult.invalid(
        'Абонемент належить до філії $subBranchName, а заняття проводиться у $classBranchName. '
        'Списання заблоковано через міжфіліальну ізоляцію.',
        'BRANCH_MISMATCH_SUBSCRIPTION_CLASS',
      );
    }

    if (clientBranchId != null && clientBranchId.trim().isNotEmpty) {
      final clientBranch = clientBranchId.toLowerCase().trim();
      if (clientBranch != classBranch) {
        final clientBranchName = _formatBranchName(clientBranch);
        final classBranchName = _formatBranchName(classBranch);
        return ValidationResult.invalid(
          'Учень зареєстрований у філії $clientBranchName, а заняття проводиться у $classBranchName. '
          'Відмітка відвідуваності заблокована через міжфіліальну ізоляцію.',
          'BRANCH_MISMATCH_CLIENT_CLASS',
        );
      }
    }

    return ValidationResult.valid;
  }

  /// Rule 2: Coach Assignment Guard (TZ Point 30).
  /// Enforces: coach.branchId == branchId OR coach.branchIds.contains(branchId).
  /// Allows unassigned coach ('unassigned'). Multi-branch coaches can be assigned to multiple branches.
  static ValidationResult validateCoachAssignment({
    required AppUser? coach,
    required String branchId,
  }) {
    if (coach == null || coach.id == 'unassigned') {
      return ValidationResult.valid;
    }

    final targetBranch = branchId.toLowerCase().trim();
    final coachPrimaryBranch = coach.branchId.toLowerCase().trim();
    final coachSecondaryBranches =
        coach.branchIds.map((b) => b.toLowerCase().trim()).toSet();

    final hasPermission = coachPrimaryBranch == targetBranch ||
        coachSecondaryBranches.contains(targetBranch);

    if (!hasPermission) {
      final targetBranchName = _formatBranchName(targetBranch);
      final coachBranchName = _formatBranchName(coachPrimaryBranch);
      return ValidationResult.invalid(
        'Тренер ${coach.name} належить до філії $coachBranchName та не має доступу до проведення занять у $targetBranchName.',
        'COACH_BRANCH_MISMATCH',
      );
    }

    return ValidationResult.valid;
  }

  /// Rule 3: Location and Pool Integrity Guard (TZ Point 30).
  /// Enforces: locationId and poolId must belong to target branch structure in BranchConfig.
  static ValidationResult validateLocationAndPool({
    required String branchId,
    String? locationId,
    String? poolId,
  }) {
    final targetBranch = branchId.toLowerCase().trim();
    final config = BranchConfig.forBranch(targetBranch);

    if (locationId != null && locationId.trim().isNotEmpty) {
      final cleanLocId = locationId.trim();
      final hasLocation = config.locations.any((l) => l.id == cleanLocId);
      if (!hasLocation) {
        final branchName = _formatBranchName(targetBranch);
        return ValidationResult.invalid(
          'Локація "$cleanLocId" не належить до структури філії $branchName.',
          'INVALID_LOCATION_FOR_BRANCH',
        );
      }
    }

    if (poolId != null && poolId.trim().isNotEmpty) {
      final cleanPoolId = poolId.trim();
      final allPools = config.locations.expand((l) => l.pools).toList();
      final hasPool = allPools.any((p) => p.id == cleanPoolId);
      if (!hasPool) {
        final branchName = _formatBranchName(targetBranch);
        return ValidationResult.invalid(
          'Басейн "$cleanPoolId" не належить до філії $branchName.',
          'INVALID_POOL_FOR_BRANCH',
        );
      }
    }

    return ValidationResult.valid;
  }

  /// Rule 4: Client Booking Guard.
  /// Enforces: client.branchId == class.branchId == subscription.branchId.
  static ValidationResult validateClientBooking({
    required String clientBranchId,
    required String classBranchId,
    required String subscriptionBranchId,
  }) {
    final clBranch = clientBranchId.toLowerCase().trim();
    final clsBranch = classBranchId.toLowerCase().trim();
    final subBranch = subscriptionBranchId.toLowerCase().trim();

    if (subBranch != clsBranch) {
      final subName = _formatBranchName(subBranch);
      final clsName = _formatBranchName(clsBranch);
      return ValidationResult.invalid(
        'Абонемент належить до філії $subName, а тренування проводиться у $clsName. Запис заборонено.',
        'BOOKING_SUB_BRANCH_MISMATCH',
      );
    }

    if (clBranch.isNotEmpty && clBranch != clsBranch) {
      final clName = _formatBranchName(clBranch);
      final clsName = _formatBranchName(clsBranch);
      return ValidationResult.invalid(
        'Профіль клієнта належить до філії $clName. Для запису у $clsName оберіть відповідну філію.',
        'BOOKING_CLIENT_BRANCH_MISMATCH',
      );
    }

    return ValidationResult.valid;
  }
}
