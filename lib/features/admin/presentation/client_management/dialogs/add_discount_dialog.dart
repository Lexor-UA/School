import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_discount.dart';

Future<void> showAddDiscountDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String currSymbol,
  required String clientId,
  required String initialName,
  required List<Map<String, dynamic>> services,
  required List<String> availableOwners,
  required List<Map<String, dynamic>> familyMembers,
}) async {
  final isDark = ref.read(appThemeControllerProvider).isDark;
  // Default selection
  String selectedOwner = 'all'; // 'all' or specific owner name
  String selectedService = 'all'; // 'all' or specific service name
  String discountMode = 'fixedPrice'; // 'fixedPrice' or 'percent'

  final priceController = TextEditingController();
  final percentController = TextEditingController();
  String? localError;

  int getBasePrice(String serviceName) {
    if (serviceName == 'all') return 0;
    final s = services.firstWhere(
      (e) => e['name'] == serviceName,
      orElse: () => {},
    );
    if (s.isEmpty) return 0;
    if (s['priceNum'] is num) return (s['priceNum'] as num).toInt();
    if (s['price'] is num) return (s['price'] as num).toInt();
    if (s['price'] is String) {
      return int.tryParse((s['price'] as String).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return 0;
  }

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final basePrice = getBasePrice(selectedService);

          // Compute live preview
          int? previewPrice;
          int? previewSavings;
          int? previewPercent;

          if (discountMode == 'fixedPrice') {
            final entered = int.tryParse(priceController.text.trim());
            if (entered != null && entered > 0) {
              previewPrice = entered;
              if (basePrice > 0) {
                previewSavings = basePrice - entered;
                if (basePrice > 0) {
                  previewPercent = ((basePrice - entered) * 100 / basePrice)
                      .round();
                }
              }
            }
          } else {
            final pct = int.tryParse(percentController.text.trim());
            if (pct != null && pct > 0 && pct < 100) {
              previewPercent = pct;
              if (basePrice > 0) {
                previewPrice = (basePrice * (100 - pct) / 100).round();
                previewSavings = basePrice - previewPrice;
              }
            }
          }

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.40)
                    : const Color(0xFFFDE68A),
                width: 1.4,
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.tag,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'admin.grant_personal_discount_title'.tr(),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                        ),
                      ),
                      Text(
                        'admin.for_client_subtitle'.tr(namedArgs: {'client': initialName}),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Target Member
                  Text(
                    'admin.discount_target_label'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        isExpanded: true,
                        value: selectedOwner,
                        icon: Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF0284C7),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.users,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'admin.whole_family_option'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...(() {
                            final seen = <String>{};
                            final uniqueMembers = familyMembers.where((m) {
                              final n = m['name']?.toString() ?? '';
                              return n.isNotEmpty && seen.add(n);
                            }).toList();
                            return uniqueMembers.map((m) {
                              final name = m['name'] as String;
                              final isParent = m['isParent'] as bool? ?? false;
                              final age = m['age'];
                              return DropdownMenuItem(
                                value: name,
                                child: Row(
                                  children: [
                                    Icon(
                                      isParent
                                          ? LucideIcons.user
                                          : LucideIcons.baby,
                                      size: 16,
                                      color: isParent
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF34D399),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$name (${isParent ? 'admin.adult_role_lower'.tr() : 'admin.child_role_with_age'.tr(namedArgs: {'age': '${age ?? ''}'})})',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            });
                          })(),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedOwner = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Discount Mode Selector (Tabs)
                  Text(
                    'admin.discount_calc_mode_label'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setStateDialog(
                              () => discountMode = 'fixedPrice',
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: discountMode == 'fixedPrice'
                                    ? (isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: discountMode == 'fixedPrice'
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'admin.new_price_tab'.tr(namedArgs: {'symbol': currSymbol}),
                                  style: TextStyle(
                                    color: discountMode == 'fixedPrice'
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))
                                        : (isDark
                                              ? Colors.white54
                                              : const Color(0xFF64748B)),
                                    fontSize: 12.5,
                                    fontWeight: discountMode == 'fixedPrice'
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setStateDialog(() => discountMode = 'percent'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: discountMode == 'percent'
                                    ? (isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: discountMode == 'percent'
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'admin.percent_tab'.tr(),
                                  style: TextStyle(
                                    color: discountMode == 'percent'
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))
                                        : (isDark
                                              ? Colors.white54
                                              : const Color(0xFF64748B)),
                                    fontSize: 12.5,
                                    fontWeight: discountMode == 'percent'
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Input Field according to Mode
                  if (discountMode == 'fixedPrice') ...[
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'admin.promo_price_input_label'.tr(),
                        labelStyle: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                        suffixText: currSymbol,
                        suffixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.banknote,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      onChanged: (_) => setStateDialog(() => localError = null),
                    ),
                  ] else ...[
                    TextField(
                      controller: percentController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'admin.discount_percent_input_label'.tr(),
                        labelStyle: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                        suffixText: '%',
                        suffixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.percent,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      onChanged: (_) => setStateDialog(() => localError = null),
                    ),
                    const SizedBox(height: 8),
                    // Quick Preset Chips for Percent
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [10, 15, 20, 25, 30, 50].map((pct) {
                        return GestureDetector(
                          onTap: () {
                            percentController.text = '$pct';
                            setStateDialog(() => localError = null);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              '-$pct%',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF00E5FF)
                                    : const Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 5. Live Interactive Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                const Color(0xFFD97706).withValues(alpha: 0.08),
                              ]
                            : [
                                const Color(0xFFFFFBEB),
                                const Color(0xFFFEF3C7),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(
                          0xFFF59E0B,
                        ).withValues(alpha: isDark ? 0.35 : 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.sparkles,
                              color: Color(0xFFF59E0B),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'admin.discount_preview_title'.tr(),
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFF92400E),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (previewPrice != null || previewPercent != null) ...[
                          Row(
                            children: [
                              if (basePrice > 0) ...[
                                Text(
                                  '$basePrice $currSymbol',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.redAccent,
                                    decorationThickness: 2,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (previewPrice != null) ...[
                                Text(
                                  '$previewPrice $currSymbol',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF00E5FF)
                                        : const Color(0xFF059669),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (previewPercent != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    '-$previewPercent%',
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (previewSavings != null && previewSavings > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'admin.client_savings_label'.tr(namedArgs: {'amount': '$previewSavings', 'symbol': currSymbol}),
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            'admin.enter_discount_value_hint'.tr(),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF78350F),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (localError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      localError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'admin.cancel'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () async {
                  int discountedPrice = 0;
                  int discountPercent = 0;

                  if (discountMode == 'fixedPrice') {
                    final val = int.tryParse(priceController.text.trim());
                    if (val == null || val <= 0) {
                      setStateDialog(
                        () =>
                            localError = 'admin.enter_valid_price_error'.tr(namedArgs: {'symbol': currSymbol}),
                      );
                      return;
                    }
                    if (basePrice > 0 && val >= basePrice) {
                      setStateDialog(
                        () => localError =
                            'admin.promo_price_less_than_base_error'.tr(namedArgs: {'base': '$basePrice', 'symbol': currSymbol}),
                      );
                      return;
                    }
                    discountedPrice = val;
                    if (basePrice > 0) {
                      discountPercent = ((basePrice - val) * 100 / basePrice)
                          .round();
                    }
                  } else {
                    final val = int.tryParse(percentController.text.trim());
                    if (val == null || val < 1 || val > 99) {
                      setStateDialog(
                        () =>
                            localError = 'admin.enter_valid_percent_error'.tr(),
                      );
                      return;
                    }
                    discountPercent = val;
                    if (basePrice > 0) {
                      discountedPrice = (basePrice * (100 - val) / 100).round();
                    }
                  }

                  Navigator.pop(ctx);

                  try {
                    final newDiscount = SubscriptionDiscount(
                      id: 'disc_${DateTime.now().microsecondsSinceEpoch}',
                      serviceName: selectedService,
                      targetMember: selectedOwner,
                      discountType: discountMode,
                      originalPrice: basePrice,
                      discountedPrice: discountedPrice,
                      discountPercent: discountPercent,
                      createdAt: DateTime.now(),
                    );

                    final userRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(clientId);
                    await userRef.set({
                      'subscriptionDiscounts': FieldValue.arrayUnion([
                        newDiscount.toJson(),
                      ]),
                    }, SetOptions(merge: true));

                    final admin = ref.read(authControllerProvider);
                    if (admin != null) {
                      final desc = discountMode == 'fixedPrice'
                          ? '$discountedPrice $currSymbol'
                          : '-$discountPercent%';
                      await logAdminAction(
                        'admin.log_discount_granted'.tr(namedArgs: {'desc': desc, 'client': initialName}),
                        admin.id,
                      );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'admin.personal_discount_saved_msg'.tr(namedArgs: {'client': initialName}),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error adding discount: $e');
                  }
                },
                child: Text(
                  'admin.save_discount_btn'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
