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
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/dialogs/add_subscription_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class ClientSubscriptionsSection extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final int? clientAge;
  final bool isDark;
  final List<String> parentIds;
  final Family? family;
  final List<Subscription> userSubs;

  final List<Map<String, dynamic>> services;
  const ClientSubscriptionsSection({
    super.key,
    required this.services,
    required this.clientId,
    required this.clientName,
    required this.clientAge,
    required this.isDark,
    required this.parentIds,
    required this.family,
    required this.userSubs,
  });

  @override
  ConsumerState<ClientSubscriptionsSection> createState() =>
      _ClientSubscriptionsSectionState();
}

class _ClientSubscriptionsSectionState
    extends ConsumerState<ClientSubscriptionsSection> {
  String _selectedSubOwner = '';

  @override
  void initState() {
    super.initState();
    _selectedSubOwner = widget.clientName;
  }

  void _updateSubscriptionClasses(Subscription sub, int delta) async {
    final newClasses = sub.remainingClasses + delta;
    if (newClasses < 0) return;

    try {
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(sub.id)
          .update({'remainingClasses': newClasses, 'isActive': newClasses > 0});

      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction(
          'Змінено залишок занять для "${widget.clientName}" (стало $newClasses)',
          admin.id,
        );
      }
    } catch (e) {
      debugPrint('Error updating subscription classes: $e');
    }
  }

  void _deleteSubscription(Subscription sub) async {
    final isDark = ref.read(appThemeControllerProvider).isDark;
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
          'admin.sub_delete_title'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Ви дійсно бажаєте видалити абонемент "${sub.serviceName ?? 'Абонемент'}" для ${sub.ownerName ?? widget.clientName}?',
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
            child: Text(
              'admin.delete'.tr(),
              style: const TextStyle(
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
      HapticFeedback.mediumImpact();
      // 1. Ensure staff auth doc is synced in Firestore
      await ref.read(authControllerProvider.notifier).syncCurrentAuthUserDoc();

      // 2. Perform deletion via controller (optimistic + Firestore)
      await ref
          .read(subscriptionControllerProvider.notifier)
          .deleteSubscription(sub.id);

      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction(
          'Видалено абонемент клієнта "${widget.clientName}"',
          admin.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.trash2, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Абонемент "${sub.serviceName ?? 'Абонемент'}" видалено',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF10B981), width: 1),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Помилка видалення: $e',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFF43F5E), width: 1),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final parentIds = widget.parentIds;
    final family = widget.family;
    final userSubs = widget.userSubs;
    final services = widget.services;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SUBSCRIPTION MANAGEMENT
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'admin.sub_management'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('children')
              .where('parentId', whereIn: parentIds)
              .snapshots(),
          builder: (context, snapshot) {
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

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                final cData = doc.data() as Map<String, dynamic>;
                final cName = (cData['name'] as String? ?? 'Дитина').trim();
                familyMembers.add({
                  'name': cName,
                  'isParent': false,
                  'age': cData['age'],
                });
                availableOwners.add(cName);
              }
            }

            String effectiveOwner =
                (_selectedSubOwner.isNotEmpty &&
                    availableOwners.contains(_selectedSubOwner))
                ? _selectedSubOwner
                : availableOwners.first;

            final memberSubs = userSubs.where((sub) {
              final owner = (sub.ownerName == null || sub.ownerName!.isEmpty)
                  ? widget.clientName
                  : sub.ownerName!;
              return owner.trim() == effectiveOwner.trim();
            }).toList();

            memberSubs.sort((a, b) {
              if (a.isActive && !b.isActive) return -1;
              if (!a.isActive && b.isActive) return 1;
              return 0;
            });

            final hasActiveSubForMember = memberSubs.any(
              (s) => s.isActive && s.remainingClasses > 0,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Family Member Switcher Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: familyMembers.map((member) {
                      final mName = member['name'] as String;
                      final isParent = member['isParent'] as bool;
                      final isSelected = effectiveOwner == mName;
                      final memberHasActive = userSubs.any((s) {
                        final owner =
                            (s.ownerName == null || s.ownerName!.isEmpty)
                            ? widget.clientName
                            : s.ownerName!;
                        return owner.trim() == mName.trim() &&
                            s.isActive &&
                            s.remainingClasses > 0;
                      });

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSubOwner = mName;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          (isDark
                                                  ? const Color(0xFF00E5FF)
                                                  : const Color(0xFF0EA5E9))
                                              .withValues(
                                                alpha: isDark ? 0.30 : 0.18,
                                              ),
                                          const Color(0xFF0284C7).withValues(
                                            alpha: isDark ? 0.20 : 0.10,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                            ? const Color(0xFF00E5FF)
                                            : const Color(0xFF0284C7))
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.12,
                                              )
                                            : const Color(0xFFCBD5E1)),
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              (isDark
                                                      ? const Color(0xFF00E5FF)
                                                      : const Color(0xFF0284C7))
                                                  .withValues(
                                                    alpha: isDark ? 0.25 : 0.15,
                                                  ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isParent
                                        ? LucideIcons.user
                                        : LucideIcons.baby,
                                    size: 15,
                                    color: isSelected
                                        ? (isDark
                                              ? const Color(0xFF00E5FF)
                                              : const Color(0xFF0284C7))
                                        : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    isParent ? '$mName (Клієнт)' : mName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF0369A1))
                                          : (isDark
                                                ? Colors.white70
                                                : const Color(0xFF334155)),
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (memberHasActive) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Subscription card(s) for selected member
                if (memberSubs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.creditCard,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Немає активного абонемента для $effectiveOwner',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Призначте 1 абонемент для цієї особи',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...memberSubs.map((sub) {
                    final isActive = sub.isActive;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isActive
                              ? const Color(
                                  0xFF10B981,
                                ).withValues(alpha: isDark ? 0.35 : 0.45)
                              : const Color(
                                  0xFFF43F5E,
                                ).withValues(alpha: isDark ? 0.35 : 0.45),
                          width: 1.1,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color:
                                      (isActive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF43F5E))
                                          .withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.serviceName ??
                                          'admin.cat_subscriptions'.tr(),
                                      style: TextStyle(
                                        color: isDark
                                            ? (isActive
                                                  ? Colors.white
                                                  : Colors.white70)
                                            : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Для: ${sub.ownerName ?? widget.clientName}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.65,
                                              )
                                            : const Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isActive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF43F5E))
                                          .withValues(
                                            alpha: isDark ? 0.18 : 0.12,
                                          ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        (isActive
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF43F5E))
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isActive
                                      ? 'admin.clients_status_active'.tr()
                                      : 'admin.clients_status_unpaid'.tr(),
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF43F5E),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (sub.expiryDate != null && sub.isActive)
                            Builder(
                              builder: (context) {
                                final daysLeft = sub.expiryDate!
                                    .difference(DateTime.now())
                                    .inDays;
                                if (daysLeft >= 0 && daysLeft <= 5) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '⚠️ Закінчується через $daysLeft ${daysLeft == 1 ? 'день' : 'днів'}',
                                      style: const TextStyle(
                                        color: Color(0xFFD97706),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${'parent.sub_left'.tr(args: ['${sub.remainingClasses}'])} (${sub.totalClasses})',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 30,
                                            height: 30,
                                          ),
                                      icon: const Icon(
                                        LucideIcons.minusCircle,
                                        color: Color(0xFFD97706),
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _updateSubscriptionClasses(sub, -1),
                                      tooltip: 'admin.tooltip_sub_minus'.tr(),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 30,
                                            height: 30,
                                          ),
                                      icon: Icon(
                                        LucideIcons.plusCircle,
                                        color: isDark
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFF0284C7),
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _updateSubscriptionClasses(sub, 1),
                                      tooltip: 'admin.tooltip_sub_plus'.tr(),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 30,
                                            height: 30,
                                          ),
                                      icon: const Icon(
                                        LucideIcons.refreshCw,
                                        color: Color(0xFFD97706),
                                        size: 16,
                                      ),
                                      onPressed: () =>
                                          _updateSubscriptionClasses(
                                            sub,
                                            -sub.remainingClasses,
                                          ),
                                      tooltip: 'admin.tooltip_sub_reset'.tr(),
                                    ),
                                    Container(
                                      height: 16,
                                      width: 1,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : const Color(0xFFCBD5E1),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 30,
                                            height: 30,
                                          ),
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        color: Color(0xFFF43F5E),
                                        size: 16,
                                      ),
                                      onPressed: () => _deleteSubscription(sub),
                                      tooltip: 'admin.delete'.tr(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      LucideIcons.plus,
                      color: isDark
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF059669),
                    ),
                    label: Text(
                      hasActiveSubForMember
                          ? 'Призначити новий абонемент (замінить поточний)'
                          : 'Призначити абонемент для "$effectiveOwner"',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? null : const Color(0xFFECFDF5),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF10B981),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => showAddSubscriptionDialog(
                      context: context,
                      ref: ref,
                      clientId: widget.clientId,
                      initialName: widget.clientName,
                      services: services,
                      availableOwners: availableOwners,
                      familyMembers: familyMembers,
                      preselectedOwner: effectiveOwner,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
