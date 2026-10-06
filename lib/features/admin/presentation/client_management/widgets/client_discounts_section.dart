import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_discount.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/dialogs/add_discount_dialog.dart';

class ClientDiscountsSection extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final int? clientAge;
  final bool isDark;
  final List<String> parentIds;
  final Family? family;
  final List<Map<String, dynamic>> services;

  const ClientDiscountsSection({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.clientAge,
    required this.isDark,
    required this.parentIds,
    required this.family,
    required this.services,
  });

  @override
  ConsumerState<ClientDiscountsSection> createState() =>
      _ClientDiscountsSectionState();
}

class _ClientDiscountsSectionState
    extends ConsumerState<ClientDiscountsSection> {
  void _deleteDiscount(SubscriptionDiscount discount) async {
    final isDark = ref.read(appThemeControllerProvider).isDark;
    final targetDesc = discount.targetMember == 'all'
        ? "всієї сім'ї"
        : 'клієнта "${discount.targetMember}"';
    final serviceDesc = discount.serviceName == 'all'
        ? 'будь-який абонемент'
        : '"${discount.serviceName}"';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
          ),
        ),
        title: Text(
          'Видалити персональну знижку?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Ви дійсно бажаєте видалити знижку на $serviceDesc для $targetDesc?',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'admin.cancel'.tr(),
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Видалити',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId);
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        final raw =
            userSnap.data()?['subscriptionDiscounts'] as List<dynamic>? ?? [];
        final updated = raw
            .whereType<Map>()
            .where((m) => m['id'] != discount.id)
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        await userRef.update({'subscriptionDiscounts': updated});
      }

      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction(
          'Видалено персональну знижку для "${widget.clientName}"',
          admin.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(LucideIcons.checkCheck, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Персональну знижку видалено'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting discount: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final parentIds = widget.parentIds;
    final family = widget.family;
    final services = widget.services;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .where('parentId', whereIn: parentIds.isNotEmpty ? parentIds : ['__empty__'])
          .snapshots(),
      builder: (context, childSnap) {
        List<Map<String, dynamic>> familyMembers = [
          {
            'name': widget.clientName,
            'isParent': true,
            'age': widget.clientAge,
          },
        ];
        List<String> availableOwners = [widget.clientName];

        if (family != null && family.isPaired) {
          final partnerName = family.getOtherParentName(widget.clientId);
          if (partnerName != null &&
              partnerName.isNotEmpty &&
              !availableOwners.contains(partnerName)) {
            familyMembers.add({
              'name': partnerName,
              'isParent': true,
              'age': null,
            });
            availableOwners.add(partnerName);
          }
        }

        if (childSnap.hasData && childSnap.data!.docs.isNotEmpty) {
          for (var doc in childSnap.data!.docs) {
            final cData = doc.data() as Map<String, dynamic>;
            final cName = (cData['name'] as String? ?? 'Дитина').trim();
            if (!availableOwners.contains(cName)) {
              familyMembers.add({
                'name': cName,
                'isParent': false,
                'age': cData['age'],
              });
              availableOwners.add(cName);
            }
          }
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .snapshots(),
          builder: (context, userSnap) {
            final userData = userSnap.hasData
                ? userSnap.data!.data() as Map<String, dynamic>?
                : null;
            final rawDiscounts =
                userData?['subscriptionDiscounts'] as List<dynamic>? ?? [];
            final discounts = rawDiscounts
                .whereType<Map>()
                .map(
                  (m) => SubscriptionDiscount.fromJson(
                    Map<String, dynamic>.from(m),
                  ),
                )
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Персональні знижки',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (discounts.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${discounts.length}',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => showAddDiscountDialog(
                        context: context,
                        ref: ref,
                        currSymbol: ref
                            .read(effectiveBranchProvider)
                            .currencySymbol,
                        clientId: widget.clientId,
                        initialName: widget.clientName,
                        services: services,
                        availableOwners: availableOwners,
                        familyMembers: familyMembers,
                      ),
                      icon: const Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      label: const Text(
                        'Додати',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (discounts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.tag,
                          size: 20,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Немає персональних знижок для цього клієнта.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...discounts.map((discount) {
                    final isAllServices = discount.serviceName == 'all';
                    final isAllMembers = discount.targetMember == 'all';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.14),
                                  const Color(
                                    0xFF1E293B,
                                  ).withValues(alpha: 0.60),
                                ]
                              : [Colors.white, const Color(0xFFFFFBEB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: isDark ? 0.35 : 0.40),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: isDark ? 0.12 : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAllMembers
                                            ? const Color(
                                                0xFF00E5FF,
                                              ).withValues(alpha: 0.18)
                                            : const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isAllMembers
                                              ? const Color(0xFF00E5FF)
                                              : const Color(0xFF10B981),
                                          width: 0.7,
                                        ),
                                      ),
                                      child: Text(
                                        isAllMembers
                                            ? "Вся сім'я"
                                            : discount.targetMember,
                                        style: TextStyle(
                                          color: isAllMembers
                                              ? (isDark
                                                    ? const Color(0xFF00E5FF)
                                                    : const Color(0xFF0284C7))
                                              : const Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.4),
                                          width: 0.7,
                                        ),
                                      ),
                                      child: Text(
                                        discount.discountType == 'fixedPrice'
                                            ? 'Фіксована ціна'
                                            : '-${discount.discountPercent}%',
                                        style: const TextStyle(
                                          color: Color(0xFFF87171),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  isAllServices
                                      ? 'Будь-який абонемент'
                                      : discount.serviceName,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                if (discount.discountType == 'fixedPrice') ...[
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        if (discount.originalPrice > 0) ...[
                                          TextSpan(
                                            text:
                                                '${discount.originalPrice} грн  ',
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: Colors.redAccent,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.grey,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                        TextSpan(
                                          text:
                                              '${discount.discountedPrice} ${ref.watch(effectiveBranchProvider).currencySymbol}',
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFF00E5FF)
                                                : const Color(0xFF059669),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (discount.originalPrice >
                                            discount.discountedPrice) ...[
                                          TextSpan(
                                            text:
                                                ' (економія ${discount.originalPrice - discount.discountedPrice} ${ref.watch(effectiveBranchProvider).currencySymbol})',
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF34D399)
                                                  : const Color(0xFF059669),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '-${discount.discountPercent}% від вартості абонемента',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF00E5FF)
                                          : const Color(0xFF059669),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 17,
                              color: Color(0xFFF43F5E),
                            ),
                            onPressed: () => _deleteDiscount(discount),
                            tooltip: 'Видалити знижку',
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}
