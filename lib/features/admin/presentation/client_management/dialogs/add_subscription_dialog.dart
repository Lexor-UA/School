import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

void showAddSubscriptionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String clientId,
  required String initialName,
  required List<Map<String, dynamic>> services,
  required List<String> availableOwners,
  String? preselectedOwner,
  List<Map<String, dynamic>>? familyMembers,
}) {
  final isDark = ref.read(appThemeControllerProvider).isDark;
  String selectedOwner = (preselectedOwner != null && availableOwners.contains(preselectedOwner))
      ? preselectedOwner
      : (availableOwners.isNotEmpty ? availableOwners.first : initialName);

  int? getOwnerAge(String name) {
    final m = familyMembers?.where((m) => m['name'] == name).firstOrNull;
    return m?['age'] as int?;
  }

  List<Map<String, dynamic>> getFilteredServices(String owner) {
    final isAdult = owner == initialName;
    final childAge = getOwnerAge(owner);

    return services.where((s) {
      final isServiceAdult = s['isAdult'] as bool?;
      final isSplit = s['isSplit'] as bool? ?? false;
      final isIndividual = s['isIndividual'] as bool? ?? false;

      if (isAdult) {
        return s['isAdult'] != false;
      }

      // Child
      if (isServiceAdult == true) return false;

      // Children <= 5 years: strictly individual subscriptions only
      if (childAge != null && childAge <= 5) {
        return isIndividual && !isSplit;
      }

      return true;
    }).toList();
  }

  final initialServices = getFilteredServices(selectedOwner);
  String selectedService = initialServices.isNotEmpty ? initialServices.first['name'] : services.first['name'];

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final availableServices = getFilteredServices(selectedOwner);
          if (!availableServices.any((s) => s['name'] == selectedService)) {
            selectedService = availableServices.first['name'];
          }
          final ownerAge = getOwnerAge(selectedOwner);

          final allSubs = ref.read(subscriptionControllerProvider).where((s) => s.userId == clientId).toList();
          final activeForOwner = allSubs.where((s) {
            final owner = (s.ownerName == null || s.ownerName!.isEmpty) ? initialName : s.ownerName!;
            return owner.trim() == selectedOwner.trim() && s.isActive && s.remainingClasses > 0;
          }).toList();
          final hasActiveSub = activeForOwner.isNotEmpty;
          final existingSub = hasActiveSub ? activeForOwner.first : null;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            title: Text(
              'admin.assign_subscription'.tr(),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Абонемент:',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      value: selectedService,
                      isExpanded: true,
                      icon: Icon(LucideIcons.chevronDown, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                      items: availableServices.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['name'],
                          child: Text(
                            s['name'],
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => selectedService = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Для кого:',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (availableOwners.isEmpty)
                  Text(
                    'Немає дітей, буде призначено на клієнта',
                    style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        value: selectedOwner,
                        isExpanded: true,
                        icon: Icon(LucideIcons.chevronDown, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                        items: availableOwners.map((owner) {
                          return DropdownMenuItem<String>(
                            value: owner,
                            child: Text(
                              owner,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedOwner = val;
                              final newAvailable = getFilteredServices(val);
                              if (!newAvailable.any((s) => s['name'] == selectedService)) {
                                selectedService = newAvailable.first['name'];
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                if (ownerAge != null && ownerAge <= 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'ℹ️ Для дітей до 6 років ($ownerAge р.) доступні лише персональні індивідуальні абонементи (групові та спліт — від 6 років).',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (hasActiveSub)
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD97706).withValues(alpha: 0.40),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'У "$selectedOwner" вже є активний абонемент (${existingSub?.serviceName ?? 'Абонемент'}, залишилось ${existingSub?.remainingClasses} занять). Новий абонемент замінить та деактивує попередній.',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'admin.cancel'.tr(),
                  style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  
                  final serviceDetails = services.firstWhere((s) => s['name'] == selectedService);
                  final classes = serviceDetails['classes'] as int;
                  final validityDays = serviceDetails['validityDays'] as int;
                  final expiry = DateTime.now().add(Duration(days: validityDays));
                  
                  final db = FirebaseFirestore.instance;
                  final batch = db.batch();

                  // Deactivate any previous active subscription for selectedOwner
                  final currentSubs = ref.read(subscriptionControllerProvider).where((s) => s.userId == clientId).toList();
                  for (final oldSub in currentSubs.where((s) {
                    final owner = (s.ownerName == null || s.ownerName!.isEmpty) ? initialName : s.ownerName!;
                    return owner.trim() == selectedOwner.trim() && s.isActive;
                  })) {
                    batch.update(db.collection('subscriptions').doc(oldSub.id), {'isActive': false});
                  }

                  final effectiveBranch = ref.read(effectiveBranchProvider);

                  final newSub = Subscription(
                    id: 'sub_${DateTime.now().microsecondsSinceEpoch}_${selectedOwner.hashCode}',
                    userId: clientId,
                    totalClasses: classes,
                    remainingClasses: classes,
                    isActive: true,
                    serviceName: selectedService,
                    expiryDate: expiry,
                    ownerName: selectedOwner,
                    organizationId: effectiveBranch.organizationId,
                    branchId: effectiveBranch.id,
                    currency: effectiveBranch.currencyCode,
                    currencySymbol: effectiveBranch.currencySymbol,
                  );
                  
                  try {
                    batch.set(db.collection('subscriptions').doc(newSub.id), newSub.toJson());
                    await batch.commit();
                    
                    final admin = ref.read(authControllerProvider);
                    if (admin != null) {
                      await logAdminAction('Призначено абонемент "${serviceDetails['name']}" для "$selectedOwner"', admin.id);
                    }
                  } catch (e) {
                    debugPrint('Error assigning sub: $e');
                  }
                },
                child: Text(
                  'admin.assign_btn'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
