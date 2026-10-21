import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_subscription_tab.dart';
import 'package:swimming_school_app/shared/utils/app_snack_bar.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/completed_class_coach_rating_bar.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/utils/branch_timezone_helper.dart';
import 'package:swimming_school_app/features/parent/presentation/graduate_child_sheet.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:collection/collection.dart';

Future<bool?> _showCancelConfirmationDialog({
  required BuildContext context,
  required bool isDark,
  required String title,
  required String message,
  required String confirmButtonText,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0B2238),
                    Color(0xFF07192C),
                    Color(0xFF04101D),
                  ]
                : const [
                    Colors.white,
                    Color(0xFFF0F9FF),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFFBAE6FD),
            width: 1.3,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: isDark ? 0.45 : 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: isDark ? 0.30 : 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.alertTriangle,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                // "Назад" sapphire button
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(ctx, false);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0B2540) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.20),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'common.back'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF334155),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // "Скасувати" ruby button
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx, true);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF881337), Color(0xFF4C0519)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.85),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            confirmButtonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ParentEnrolledClassCard extends ConsumerWidget {
  final GroupClass c;
  final String targetChildId;
  final AppThemeConfig currentTheme;
  final AppUser? user;
  final List<Child> children;
  final Family? family;

  const ParentEnrolledClassCard({
    super.key,
    required this.c,
    required this.targetChildId,
    required this.currentTheme,
    required this.user,
    required this.children,
    this.family,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = this.user;
    final family = this.family;
    final isDark = currentTheme.isDark;
    final langCode = context.locale.languageCode;
    final meShort = 'parent.me_short'.tr();
    final partnerFallback = 'parent.partner'.tr();
    final localizedTitle = _getLocalizedClassTitle(c.title, langCode);
    final timeFormatted =
        "${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}";

    final partnerId = (user != null && family != null) ? family.getOtherParentId(user.id) : null;
    final partnerName = (user != null && family != null && partnerId != null)
        ? (family.getOtherParentName(user.id) ?? family.parentNames[partnerId] ?? partnerFallback)
        : null;

    final familyIds = {
      ?user?.id,
      ?partnerId,
      ...children.map((ch) => ch.id),
    };

    final relevantEnrolledIds = targetChildId != 'all'
        ? c.enrolledChildIds.where((id) => id == targetChildId).toList()
        : c.enrolledChildIds.where((id) => familyIds.contains(id)).toList();

    final enrolledMembers = relevantEnrolledIds.map((id) {
      if (user != null && id == user.id) {
        return (
          id: user.id,
          name: '${user.name} ($meShort)',
          isParent: true,
          color: currentTheme.accentPrimary,
        );
      }

      final child = children.where((ch) => ch.id == id).firstOrNull;
      if (child != null) {
        return (
          id: child.id,
          name: child.name,
          isParent: false,
          color: currentTheme.adaptColorForTheme(Color(int.tryParse(child.colorHex) ?? 0xFF10B981)),
        );
      }

      if (family != null && family.parentNames.containsKey(id) && family.parentNames[id]!.trim().isNotEmpty) {
        return (
          id: id,
          name: family.parentNames[id]!.trim(),
          isParent: true,
          color: currentTheme.adaptColorForTheme(const Color(0xFFA78BFA)),
        );
      }

      if (partnerId != null && id == partnerId && partnerName != null && partnerName.isNotEmpty) {
        return (
          id: id,
          name: partnerName,
          isParent: true,
          color: currentTheme.adaptColorForTheme(const Color(0xFFA78BFA)),
        );
      }

      if (family != null && family.parentIds.contains(id)) {
        final name = family.getOtherParentName(user?.id ?? '') ?? partnerName ?? partnerFallback;
        return (
          id: id,
          name: name,
          isParent: true,
          color: currentTheme.adaptColorForTheme(const Color(0xFFA78BFA)),
        );
      }

      if (partnerName != null && partnerName.isNotEmpty && partnerName != partnerFallback) {
        return (
          id: id,
          name: partnerName,
          isParent: true,
          color: currentTheme.adaptColorForTheme(const Color(0xFFA78BFA)),
        );
      }

      return (
        id: id,
        name: user?.name ?? meShort,
        isParent: true,
        color: currentTheme.adaptColorForTheme(const Color(0xFFA78BFA)),
      );
    }).toList();

    final unenrolledMembers = [
      if (user != null && !c.enrolledChildIds.contains(user.id) && !c.isChildOnly)
        (
          id: user.id,
          name: '${user.name} ($meShort)',
          isParent: true,
          color: currentTheme.accentPrimary,
        ),
      if (partnerId != null && partnerName != null && !c.enrolledChildIds.contains(partnerId) && !c.isChildOnly)
        (
          id: partnerId,
          name: partnerName,
          isParent: true,
          color: currentTheme.adaptColorForTheme(const Color(0xFFA78BFA)),
        ),
      ...children
          .where((ch) => !c.enrolledChildIds.contains(ch.id) && !c.isAdultOnly && c.isAgeCompatible(ch.ageAt(c.startTime)))
          .map((ch) => (
                id: ch.id,
                name: ch.name,
                isParent: false,
                color: currentTheme.adaptColorForTheme(Color(int.tryParse(ch.colorHex) ?? 0xFF10B981)),
              )),
    ];

    final freeSlots = c.maxCapacity - c.enrolledChildIds.length;
    final activeBranch = ref.watch(effectiveBranchProvider);
    final now = BranchTimezoneHelper.toBranchLocalTime(DateTime.now(), activeBranch.id);
    final isPast = c.branchStartTime.isBefore(now);
    final canEnrollMore = freeSlots > 0 && unenrolledMembers.isNotEmpty && !isPast;

    final relevantMemberIds = targetChildId != 'all'
        ? [targetChildId]
        : (relevantEnrolledIds.isNotEmpty ? relevantEnrolledIds : familyIds.toList());
    final wasAttended = c.attendedChildIds.any((id) => relevantMemberIds.contains(id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0B2238),
                      Color(0xFF07192C),
                      Color(0xFF04101D),
                    ]
                  : const [
                      Colors.white,
                      Color(0xFFF0F9FF),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.32) : const Color(0xFFBAE6FD),
              width: 1.3,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Time pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B2540) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12.5,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            timeFormatted,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Badge: Attended / Missed / Confirmed
                    Builder(
                      builder: (context) {
                        if (isPast) {
                          if (wasAttended) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                    : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF10B981).withValues(alpha: 0.50)
                                      : const Color(0xFFA7F3D0),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.checkCheck,
                                    size: 12,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'parent.status_attended'.tr(),
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF475569).withValues(alpha: 0.25)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF64748B).withValues(alpha: 0.40)
                                    : const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.userX,
                                  size: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'parent.status_missed'.tr(),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF10B981).withValues(alpha: 0.55)
                                  : const Color(0xFFA7F3D0),
                              width: 1.0,
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.20),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.checkCircle2,
                                size: 13,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'parent.booking_confirmed'.tr(),
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Action menu (Only visible for upcoming classes)
                    if (c.startTime.isAfter(DateTime.now()))
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0B2540) : Colors.white.withValues(alpha: 0.90),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.28) : const Color(0xFFBAE6FD),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.moreHorizontal,
                            color: isDark ? const Color(0xFF00E5FF) : currentTheme.textSecondary,
                            size: 16,
                          ),
                        ),
                        color: isDark ? const Color(0xFF0A243D) : Colors.white,
                        elevation: 14,
                        shadowColor: Colors.black.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                            width: 1.2,
                          ),
                        ),
                        onSelected: (value) async {
                          if (value == 'cancel') {
                            final nowInBranch = BranchTimezoneHelper.toBranchLocalTime(DateTime.now(), c.branchId);
                            final minutesUntilStart = c.branchStartTime.difference(nowInBranch).inMinutes;
                            if (minutesUntilStart < 300) {
                              AppSnackBar.showWarning(
                                context,
                                'parent.cancel_5h_cutoff_warn'.tr(),
                              );
                              return;
                            }
                            if (targetChildId != 'all') {
                              final matchedChild = children.where((ch) => ch.id == targetChildId).firstOrNull;
                              final targetCancelName = targetChildId == user?.id
                                  ? (user?.name ?? 'parent.cancel_target_self'.tr())
                                  : (targetChildId == partnerId
                                      ? (partnerName ?? 'parent.cancel_target_partner'.tr())
                                      : (matchedChild?.name ?? 'parent.cancel_target_child'.tr()));

                              final confirm = await _showCancelConfirmationDialog(
                                context: context,
                                isDark: isDark,
                                title: c.isSplit ? 'parent.cancel_split_title'.tr() : 'parent.cancel_booking_title'.tr(),
                                message: c.isSplit
                                    ? 'parent.cancel_split_confirm_msg'.tr()
                                    : 'parent.cancel_booking_confirm_msg'.tr(args: [targetCancelName, localizedTitle]),
                                confirmButtonText: c.isSplit ? 'parent.cancel_for_both_btn'.tr() : 'common.cancel'.tr(),
                              );
                              if (confirm == true) {
                                await ref.read(scheduleControllerProvider.notifier).cancelClass(c.id, targetChildId);
                              }
                            } else {
                              // On 'all' view: if split class, cancel both participants
                              if (c.isSplit) {
                                final bothNames = enrolledMembers
                                    .map((e) => e.name.replaceAll(' ($meShort)', '').replaceAll(' (Я)', ''))
                                    .join(' ${'common.and_conjunction'.tr()} ');
                                final confirm = await _showCancelConfirmationDialog(
                                  context: context,
                                  isDark: isDark,
                                  title: 'parent.cancel_split_title'.tr(),
                                  message: 'parent.cancel_split_named_confirm_msg'.tr(args: [bothNames]),
                                  confirmButtonText: 'parent.cancel_for_both_btn'.tr(),
                                );
                                if (confirm == true && enrolledMembers.isNotEmpty) {
                                  await ref.read(scheduleControllerProvider.notifier).cancelClass(c.id, enrolledMembers.first.id);
                                }
                              } else if (enrolledMembers.length == 1) {
                                final m = enrolledMembers.first;
                                final confirm = await _showCancelConfirmationDialog(
                                  context: context,
                                  isDark: isDark,
                                  title: 'parent.cancel_booking_title'.tr(),
                                  message: 'parent.cancel_booking_confirm_msg'.tr(args: [m.name, localizedTitle]),
                                  confirmButtonText: 'common.cancel'.tr(),
                                );
                                if (confirm == true) {
                                  await ref.read(scheduleControllerProvider.notifier).cancelClass(c.id, m.id);
                                }
                              } else if (enrolledMembers.length > 1) {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isDark
                                              ? const [
                                                  Color(0xFF0B2238),
                                                  Color(0xFF07192C),
                                                  Color(0xFF04101D),
                                                ]
                                              : const [
                                                  Colors.white,
                                                  Color(0xFFF0F9FF),
                                                ],
                                        ),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Container(
                                              width: 44,
                                              height: 4.5,
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.50) : Colors.black12,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'parent.whose_booking_to_cancel'.tr(),
                                            style: TextStyle(
                                              color: isDark ? Colors.white : currentTheme.textPrimary,
                                              fontSize: 17.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ...enrolledMembers.map((m) => Padding(
                                            padding: const EdgeInsets.only(bottom: 10),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () async {
                                                  Navigator.pop(ctx);
                                                  await ref.read(scheduleControllerProvider.notifier).cancelClass(c.id, m.id);
                                                },
                                                borderRadius: BorderRadius.circular(16),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF0A243D) : const Color(0xFFF0F9FF),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(
                                                      color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : m.color.withValues(alpha: 0.45),
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 36,
                                                        height: 36,
                                                        decoration: BoxDecoration(
                                                          color: m.color.withValues(alpha: 0.22),
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: m.color.withValues(alpha: 0.60),
                                                            width: 1.2,
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          m.isParent ? LucideIcons.user : LucideIcons.baby,
                                                          color: isDark ? Colors.white : m.color,
                                                          size: 17,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 14),
                                                      Text(
                                                        m.name,
                                                        style: TextStyle(
                                                          color: isDark ? Colors.white : currentTheme.textPrimary,
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        'common.cancel'.tr(),
                                                        style: const TextStyle(
                                                          color: Colors.redAccent,
                                                          fontSize: 13.5,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: isDark ? 0.18 : 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 14),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'parent.cancel_booking_menu'.tr(),
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  localizedTitle,
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (enrolledMembers.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...enrolledMembers.map((m) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: m.color.withValues(alpha: isDark ? 0.20 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: m.color.withValues(alpha: isDark ? 0.6 : 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                m.isParent ? LucideIcons.user : LucideIcons.baby,
                                size: 11,
                                color: m.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                m.name,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (canEnrollMore)
                        GestureDetector(
                          onTap: () => showChildPickerForQuickBooking(context, ref, c, user, children, family),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.plus,
                                  size: 11,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  unenrolledMembers.length == 1 && unenrolledMembers.first.isParent
                                      ? 'parent.add_adult_btn'.tr()
                                      : (c.isSplit ? 'parent.add_second_participant_btn'.tr() : 'parent.add_child_btn'.tr()),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (canEnrollMore) ...[
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showChildPickerForQuickBooking(context, ref, c, user, children, family),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF0284C7).withValues(alpha: 0.28),
                                    const Color(0xFF0369A1).withValues(alpha: 0.20),
                                  ]
                                : [
                                    const Color(0xFFE0F2FE),
                                    const Color(0xFFBAE6FD).withValues(alpha: 0.55),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.50)
                                : const Color(0xFF38BDF8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                                    : const Color(0xFF0284C7).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                c.isSplit ? LucideIcons.users : LucideIcons.userPlus,
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c.isSplit
                                        ? 'parent.free_2nd_spot_split'.tr()
                                        : 'parent.free_spots_label'.tr(args: [freeSlots.toString()]),
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    unenrolledMembers.length == 1
                                        ? (unenrolledMembers.first.id == user?.id
                                            ? 'parent.book_this_class'.tr()
                                            : (unenrolledMembers.first.isParent
                                                ? 'parent.book_partner_named'.tr(args: [
                                                    unenrolledMembers.first.name
                                                        .replaceAll(' ($meShort)', '')
                                                        .replaceAll(' (Я)', '')
                                                  ])
                                                : 'parent.book_child_named'.tr(args: [unenrolledMembers.first.name])))
                                        : (c.isSplit
                                            ? 'parent.book_2nd_participant'.tr()
                                            : 'parent.book_another_family_member'.tr()),
                                    style: TextStyle(
                                      color: currentTheme.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                                      : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.plus, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'parent.book_short_btn'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Meta row: Coach and lane
                Row(
                  children: [
                    if (c.coachName.isNotEmpty) ...[
                      Icon(
                        (c.coachName == 'Тренер не призначений' || c.coachName.toLowerCase().contains('не призначен'))
                            ? LucideIcons.clock
                            : LucideIcons.userCheck,
                        size: 13,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (c.coachName == 'Тренер не призначений' || c.coachName.toLowerCase().contains('не призначен'))
                            ? 'parent.trainer_assigning'.tr()
                            : 'parent.trainer_prefix'.tr(args: [c.coachName]),
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (c.coachName != 'Тренер не призначений' &&
                          !c.coachName.toLowerCase().contains('не призначен') &&
                          c.coachId.isNotEmpty &&
                          user != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            final childEnrolled = enrolledMembers.firstWhereOrNull((m) => !m.isParent);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParentChatScreen(
                                  dialogId: 'coach_${c.coachId}_client_${user.id}',
                                  recipientId: c.coachId,
                                  recipientName: c.coachName,
                                  coachId: c.coachId,
                                  coachName: c.coachName,
                                  clientId: user.id,
                                  clientName: user.name,
                                  childName: childEnrolled?.name,
                                  type: 'coach_client',
                                  title: c.coachName,
                                  subtitle: '${'common.coach_fallback'.tr()} • $localizedTitle',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                  .withValues(alpha: isDark ? 0.20 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                    .withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.messageCircle,
                                  size: 10,
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'parent.message_coach_btn'.tr(),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                    ],
                    if (c.lane.isNotEmpty && c.lane != 'Будь-яка') ...[
                      Icon(
                        LucideIcons.waves,
                        size: 13,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        BranchConfig.localizeLaneName(c.lane, langCode),
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isPast && wasAttended)
                  CompletedClassCoachRatingBar(
                    classItem: c,
                    currentTheme: currentTheme,
                  ),
              ],
            ),
          ),
        ),
    );
  }

}

String _formatSlotsCount(int count, [String? langCode]) {
  if (langCode == 'de') {
    return '$count ${count == 1 ? "Platz" : "Plätze"}';
  } else if (langCode == 'en') {
    return '$count ${count == 1 ? "spot" : "spots"}';
  } else if (langCode == 'ru') {
    return '$count ${count == 1 ? "место" : (count >= 2 && count <= 4 ? "места" : "мест")}';
  }
  return '$count ${count == 1 ? "місце" : (count >= 2 && count <= 4 ? "місця" : "місць")}';
}

String _getLocalizedClassTitle(String title, [String? langCode]) {
  if (title == 'Плавання для дорослих') return 'parent.class_adult_swimming'.tr();
  if (title == 'Дитяча група' || title == 'Дитяче плавання') return 'parent.class_kids_group'.tr();
  if (title == 'Спліт-тренування (2 особи)' || title.startsWith('Спліт-тренування')) return 'parent.class_split_training'.tr();
  if (title == 'Індивідуальні тренування для дорослих') return 'parent.service_individual_adult'.tr();
  if (title == 'Індивідуальні тренування для дітей') return 'parent.service_individual_child'.tr();
  if (langCode != null) {
    return SubscriptionPackageCatalog.localizeServiceName(title, langCode);
  }
  return title;
}

class ParentAvailableClassCard extends ConsumerWidget {
  final GroupClass c;
  final String targetChildId;
  final AppThemeConfig currentTheme;
  final AppUser? user;
  final List<Child> children;
  final Family? family;

  const ParentAvailableClassCard({
    super.key,
    required this.c,
    required this.targetChildId,
    required this.currentTheme,
    required this.user,
    required this.children,
    this.family,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = this.user;
    final family = this.family;
    final isDark = currentTheme.isDark;
    final timeFormatted =
        "${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}";
    final freeSlots = c.maxCapacity - c.enrolledChildIds.length;

    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
    final isAdultTarget = targetChildId == user?.id || (partnerId != null && targetChildId == partnerId);
    final targetChild = (!isAdultTarget && targetChildId != 'all') ? children.where((ch) => ch.id == targetChildId).firstOrNull : null;
    final childAge = targetChild?.ageAt(c.startTime) ?? targetChild?.currentAge;
    final bool isAgeMismatch = childAge != null && !c.isAgeCompatible(childAge);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0B2238),
                      Color(0xFF07192C),
                      Color(0xFF04101D),
                    ]
                  : const [
                      Colors.white,
                      Color(0xFFF0F9FF),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.32) : const Color(0xFFBAE6FD),
              width: 1.3,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Time pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFBAE6FD),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 11.5,
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  timeFormatted,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Free slots pill (grammatically correct & compact)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _formatSlotsCount(freeSlots, context.locale.languageCode),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Audience pill
                          if (c.isChildOnly || c.isAdultOnly || c.isSplit)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: c.isChildOnly
                                    ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.12)
                                    : (c.isAdultOnly
                                        ? const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.14)
                                        : const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.22 : 0.12)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: c.isChildOnly
                                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                      : (c.isAdultOnly
                                          ? const Color(0xFF818CF8).withValues(alpha: 0.5)
                                          : const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    c.isChildOnly
                                        ? LucideIcons.baby
                                        : (c.isAdultOnly
                                            ? LucideIcons.user
                                            : (c.isSplit ? LucideIcons.users : LucideIcons.waves)),
                                    size: 11,
                                    color: c.isChildOnly
                                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                        : (c.isAdultOnly
                                            ? (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5))
                                            : (c.isSplit
                                                ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                                                : (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488)))),
                                  ),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    c.isChildOnly
                                        ? 'parent.audience_kids'.tr()
                                        : (c.isAdultOnly
                                            ? 'parent.audience_adults'.tr()
                                            : (c.isSplit ? 'parent.audience_split'.tr() : 'parent.audience_general'.tr())),
                                    style: TextStyle(
                                      color: c.isChildOnly
                                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                          : (c.isAdultOnly
                                              ? (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5))
                                              : (c.isSplit
                                                  ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                                                  : (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488)))),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Age mismatch pill
                          if (isAgeMismatch && (c.ageRange != null || childAge <= 5))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.orangeAccent : const Color(0xFFD97706)).withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (isDark ? Colors.orangeAccent : const Color(0xFFD97706)).withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.triangleAlert, size: 11, color: isDark ? Colors.orangeAccent : const Color(0xFFD97706)),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    childAge <= 5
                                        ? 'parent.under6_individual_only_badge'.tr()
                                        : 'parent.group_age_range_badge'.tr(namedArgs: {
                                            'min': '${c.ageRange!.$1}',
                                            'max': '${c.ageRange!.$2}',
                                          }),
                                    style: TextStyle(
                                      color: isDark ? Colors.orangeAccent : const Color(0xFFD97706),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick booking action
                    GestureDetector(
                      onTap: () async {
                        if (c.isSplit && c.enrolledChildIds.isEmpty) {
                          showSplitBookingSheet(
                            context,
                            ref,
                            c,
                            user,
                            children,
                            family,
                            initialParticipantId: targetChildId != 'all' ? targetChildId : null,
                          );
                          return;
                        }
                        if (targetChildId != 'all') {
                          final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
                          final isAdultTarget = targetChildId == user?.id || (partnerId != null && targetChildId == partnerId);
                          if (!isAdultTarget && targetChild != null && (targetChild.isAdultAge || (childAge ?? 0) >= 16)) {
                            GraduateChildSheet.show(context, targetChild);
                            return;
                          }
                          if (isAdultTarget && c.isChildOnly) {
                            showChildPickerForQuickBooking(context, ref, c, user, children, family);
                            return;
                          }
                          if (!isAdultTarget && c.isAdultOnly) {
                            AppSnackBar.showWarning(context, 'parent.adult_only_class_warn'.tr());
                            return;
                          }
                          if (isAgeMismatch) {
                            if (childAge <= 5) {
                              AppSnackBar.showWarning(
                                context,
                                'parent.under6_individual_only'.tr(),
                              );
                              return;
                            }
                            final range = c.ageRange;
                            AppSnackBar.showWarning(
                              context,
                              'parent.child_age_mismatch_age'.tr(namedArgs: {
                                'age': '$childAge',
                                'min': '${range?.$1 ?? 0}',
                                'max': '${range?.$2 ?? 0}',
                              }),
                            );
                            return;
                          }
                          final res = await ref.read(scheduleControllerProvider.notifier).bookClass(c.id, targetChildId);
                          if (!context.mounted) return;
                          final bookedChild = children.where((ch) => ch.id == targetChildId).firstOrNull;
                          final partnerName = user != null ? (family?.getOtherParentName(user.id) ?? (partnerId != null ? family?.parentNames[partnerId] : null) ?? 'parent.partner'.tr()) : null;
                          final bookedName = targetChildId == user?.id ? user?.name : (targetChildId == partnerId ? partnerName : bookedChild?.name);
                          if (res.isSuccess) {
                            AppSnackBar.showSuccess(context, res.message);
                          } else {
                            AppSnackBar.showError(
                              context,
                              res.message,
                              action: res.status == BookingStatus.noSubscription
                                  ? SnackBarAction(
                                      label: 'parent.buy_action'.tr(),
                                      textColor: Colors.white,
                                      onPressed: () {
                                        if (bookedName != null) {
                                          ref.read(selectedSubscriptionOwnerProvider.notifier).setSelectedOwner(bookedName);
                                        }
                                        ref.read(parentTabProvider.notifier).setTab(2);
                                      },
                                    )
                                  : null,
                            );
                          }
                        } else {
                          showChildPickerForQuickBooking(context, ref, c, user, children, family);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                                : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.45),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFF0284C7).withValues(alpha: 0.22)),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'parent.sign_up_btn'.tr(),
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  _getLocalizedClassTitle(c.title, context.locale.languageCode),
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),

                // Meta row: Coach and lane
                Row(
                  children: [
                    if (c.coachName.isNotEmpty) ...[
                      Icon(
                        (c.coachName == 'Тренер не призначений' ||
                                c.coachName == 'schedule.coach_unassigned'.tr() ||
                                c.coachName.toLowerCase().contains('не призначен'))
                            ? LucideIcons.clock
                            : LucideIcons.user,
                        size: 13,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (c.coachName == 'Тренер не призначений' ||
                                c.coachName == 'schedule.coach_unassigned'.tr() ||
                                c.coachName.toLowerCase().contains('не призначен'))
                            ? 'parent.coach_assigning'.tr()
                            : 'parent.coach_prefix'.tr(namedArgs: {'name': c.coachName}),
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (c.lane.isNotEmpty && c.lane != 'Будь-яка') ...[
                      Icon(
                        LucideIcons.waves,
                        size: 13,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        BranchConfig.localizeLaneName(c.lane, context.locale.languageCode),
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

}

class ParentPastClassCard extends StatelessWidget {
  final GroupClass classItem;
  final AppThemeConfig currentTheme;

  const ParentPastClassCard({
    super.key,
    required this.classItem,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = currentTheme.isDark;
    final timeFormatted =
        "${classItem.startTime.hour.toString().padLeft(2, '0')}:${classItem.startTime.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF071828),
                      Color(0xFF05121F),
                    ]
                  : const [
                      Colors.white,
                      Color(0xFFF8FAFC),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Time pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormatted,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Completed status pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF475569).withValues(alpha: 0.20)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF64748B).withValues(alpha: 0.35)
                              : const Color(0xFFCBD5E1),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.history,
                            size: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'parent.status_completed'.tr(),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  _getLocalizedClassTitle(classItem.title, context.locale.languageCode),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : currentTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),

                // Meta row: Coach and lane
                Row(
                  children: [
                    if (classItem.coachName.isNotEmpty) ...[
                      Icon(
                        (classItem.coachName == 'Тренер не призначений' ||
                                classItem.coachName == 'schedule.coach_unassigned'.tr() ||
                                classItem.coachName.toLowerCase().contains('не призначен'))
                            ? LucideIcons.clock
                            : LucideIcons.user,
                        size: 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (classItem.coachName == 'Тренер не призначений' ||
                                classItem.coachName == 'schedule.coach_unassigned'.tr() ||
                                classItem.coachName.toLowerCase().contains('не призначен'))
                            ? 'parent.coach_assigning'.tr()
                            : 'parent.coach_prefix'.tr(namedArgs: {'name': classItem.coachName}),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (classItem.lane.isNotEmpty && classItem.lane != 'Будь-яка') ...[
                      Icon(
                        LucideIcons.waves,
                        size: 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        BranchConfig.localizeLaneName(classItem.lane, context.locale.languageCode),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}

void showChildPickerForQuickBooking(
  BuildContext context,
  WidgetRef ref,
    GroupClass c,
    AppUser? user,
    List<Child> children, [
    Family? family,
  ]) {
    if (c.isSplit && c.enrolledChildIds.isEmpty) {
      showSplitBookingSheet(context, ref, c, user, children, family);
      return;
    }
    final isDark = ref.read(appThemeControllerProvider).isDark;
    final currentTheme = ref.read(appThemeControllerProvider);

    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
    final partnerName = user != null
        ? (family?.getOtherParentName(user.id) ?? (partnerId != null ? family?.parentNames[partnerId] : null) ?? 'parent.partner'.tr())
        : null;

    final includeParent = user != null && !c.enrolledChildIds.contains(user.id) && !c.isChildOnly;
    final includePartner = partnerId != null &&
        partnerName != null &&
        !c.enrolledChildIds.contains(partnerId) &&
        !c.isChildOnly;
    final includeChildren = !c.isAdultOnly;
    final meSuffix = ' (${'parent.me_short'.tr()})';

    final availableMembers = [
      if (includeParent)
        (id: user.id, name: '${user.name}$meSuffix', rawName: user.name, isParent: true, color: currentTheme.accentPrimary),
      if (includePartner)
        (id: partnerId, name: partnerName, rawName: partnerName, isParent: true, color: currentTheme.adaptColorForTheme(const Color(0xFFA78BFA))),
      if (includeChildren)
        ...children
            .where((ch) => !c.enrolledChildIds.contains(ch.id))
            .where((ch) => c.isAgeCompatible(ch.ageAt(c.startTime)))
            .map((ch) {
              final age = ch.ageAt(c.startTime) ?? ch.currentAge;
              return (
                id: ch.id,
                name: age != null ? '${ch.name} ($age ${'parent.years_short'.tr()})' : ch.name,
                rawName: ch.name,
                isParent: false,
                color: currentTheme.adaptColorForTheme(Color(int.tryParse(ch.colorHex) ?? 0xFF10B981)),
              );
            }),
    ];

    if (availableMembers.isEmpty) {
      final adultAgeChild = children.firstWhereOrNull(
        (ch) => ch.isAdultAge || (ch.ageAt(c.startTime) ?? ch.currentAge ?? 0) >= 16,
      );
      if (adultAgeChild != null) {
        GraduateChildSheet.show(context, adultAgeChild);
        return;
      }
      final hasUnder6Only = children.isNotEmpty && children.every((ch) => (ch.currentAge ?? 0) <= 5);
      final msg = hasUnder6Only && (c.isGroup || c.isSplit)
          ? 'parent.under6_individual_only'.tr()
          : (c.ageRange != null
              ? 'parent.children_age_mismatch'.tr(namedArgs: {
                  'min': '${c.ageRange!.$1}',
                  'max': '${c.ageRange!.$2}',
                })
              : (c.isChildOnly
                  ? 'parent.child_only_class_warn'.tr()
                  : (c.isAdultOnly
                      ? 'parent.adult_only_class_warn'.tr()
                      : 'parent.all_family_already_enrolled'.tr())));
      AppSnackBar.showWarning(context, msg);
      return;
    }

    if (availableMembers.length == 1) {
      final m = availableMembers.first;
      if (!m.isParent) {
        final matchedChild = children.firstWhereOrNull((ch) => ch.id == m.id);
        if (matchedChild != null && (matchedChild.isAdultAge || (matchedChild.ageAt(c.startTime) ?? matchedChild.currentAge ?? 0) >= 16)) {
          GraduateChildSheet.show(context, matchedChild);
          return;
        }
      }
      ref.read(scheduleControllerProvider.notifier).bookClass(c.id, m.id).then((res) {
        if (!context.mounted) return;
        final msg = '${res.message} (${m.name})';
        if (res.isSuccess) {
          AppSnackBar.showSuccess(context, msg);
        } else {
          AppSnackBar.showError(
            context,
            msg,
            action: res.status == BookingStatus.noSubscription
                ? SnackBarAction(
                    label: 'parent.buy_action'.tr(),
                    textColor: Colors.white,
                    onPressed: () {
                      ref.read(selectedSubscriptionOwnerProvider.notifier).setSelectedOwner(m.rawName);
                      ref.read(parentTabProvider.notifier).setTab(2);
                    },
                  )
                : null,
          );
        }
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      Color(0xFF0B2238),
                      Color(0xFF07192C),
                      Color(0xFF04101D),
                    ]
                  : const [
                      Colors.white,
                      Color(0xFFF0F9FF),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
          ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'parent.book_for_whom_title'.tr(),
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getLocalizedClassTitle(c.title, context.locale.languageCode),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...availableMembers.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        if (!m.isParent) {
                          final matchedChild = children.firstWhereOrNull((ch) => ch.id == m.id);
                          if (matchedChild != null && (matchedChild.isAdultAge || (matchedChild.ageAt(c.startTime) ?? matchedChild.currentAge ?? 0) >= 16)) {
                            GraduateChildSheet.show(context, matchedChild);
                            return;
                          }
                        }
                        final res = await ref.read(scheduleControllerProvider.notifier).bookClass(c.id, m.id);
                        if (!context.mounted) return;
                        final msg = '${res.message} (${m.name})';
                        if (res.isSuccess) {
                          AppSnackBar.showSuccess(context, msg);
                        } else {
                          AppSnackBar.showError(
                            context,
                            msg,
                            action: res.status == BookingStatus.noSubscription
                                ? SnackBarAction(
                                    label: 'parent.buy_action'.tr(),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      ref.read(selectedSubscriptionOwnerProvider.notifier).setSelectedOwner(m.rawName);
                                      ref.read(parentTabProvider.notifier).setTab(2);
                                    },
                                  )
                                : null,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: m.color.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: m.color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                m.isParent ? LucideIcons.user : LucideIcons.baby,
                                color: m.color,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              m.name,
                              style: TextStyle(
                                color: currentTheme.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.chevronRight,
                              color: isDark ? Colors.white38 : Colors.black26,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
    );
  }

void showSplitBookingSheet(
  BuildContext context,
  WidgetRef ref,
    GroupClass c,
    AppUser? user,
    List<Child> children,
    Family? family, {
    String? initialParticipantId,
  }) {
    final isDark = ref.read(appThemeControllerProvider).isDark;
    final currentTheme = ref.read(appThemeControllerProvider);
    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
    final partnerName = user != null
        ? (family?.getOtherParentName(user.id) ?? (partnerId != null ? family?.parentNames[partnerId] : null) ?? 'parent.partner'.tr())
        : null;
    final meSuffix = ' (${'parent.me_short'.tr()})';

    final availableMembers = [
      if (user != null)
        (id: user.id, name: '${user.name}$meSuffix', isParent: true, color: currentTheme.accentPrimary),
      if (partnerId != null && partnerName != null)
        (id: partnerId, name: partnerName, isParent: true, color: currentTheme.adaptColorForTheme(const Color(0xFFA78BFA))),
      ...children
          .where((ch) => c.isAgeCompatible(ch.ageAt(c.startTime)))
          .map((ch) {
            final age = ch.ageAt(c.startTime) ?? ch.currentAge;
            return (
              id: ch.id,
              name: age != null ? '${ch.name} ($age ${'parent.years_short'.tr()})' : ch.name,
              isParent: false,
              color: currentTheme.adaptColorForTheme(Color(int.tryParse(ch.colorHex) ?? 0xFF10B981)),
            );
          }),
    ];

    if (availableMembers.length < 2) {
      AppSnackBar.showWarning(
        context,
        'parent.split_min_2_members_warn'.tr(),
      );
      return;
    }

    final List<String> selectedIds = [];
    if (initialParticipantId != null && availableMembers.any((m) => m.id == initialParticipantId)) {
      selectedIds.add(initialParticipantId);
    } else if (user != null) {
      selectedIds.add(user.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext sheetCtx, StateSetter setSheetState) {
            String? getMemberDisplayName(String id) {
              final m = availableMembers.where((m) => m.id == id).firstOrNull;
              return m?.name.replaceAll(meSuffix, '');
            }

            final isReady = selectedIds.length == 2;
            final buttonText = isReady
                ? 'parent.book_split_btn'.tr(namedArgs: {
                    'p1': getMemberDisplayName(selectedIds[0]) ?? '',
                    'p2': getMemberDisplayName(selectedIds[1]) ?? '',
                  })
                : (selectedIds.isEmpty
                    ? 'parent.select_2_participants'.tr()
                    : 'parent.select_2nd_participant'.tr());

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [
                            Color(0xFF0B2238),
                            Color(0xFF07192C),
                            Color(0xFF04101D),
                          ]
                        : const [
                            Colors.white,
                            Color(0xFFF0F9FF),
                          ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                    width: 1.2,
                  ),
                ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.users,
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'parent.split_booking_sheet_title'.tr(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getLocalizedClassTitle(c.title, context.locale.languageCode),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
                                : const Color(0xFF38BDF8),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 17,
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0369A1),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'parent.split_booking_sheet_info'.tr(),
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : const Color(0xFF0C4A6E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'parent.select_2_participants_ratio'.tr(namedArgs: {'count': '${selectedIds.length}'}),
                        style: TextStyle(
                          color: currentTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: availableMembers.map((m) {
                              final isSelected = selectedIds.contains(m.id);
                              final index = isSelected ? selectedIds.indexOf(m.id) : -1;
                              final badgeText = index == 0
                                  ? 'parent.participant_1'.tr()
                                  : (index == 1 ? 'parent.participant_2'.tr() : '');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setSheetState(() {
                                        if (isSelected) {
                                          selectedIds.remove(m.id);
                                        } else {
                                          if (selectedIds.length < 2) {
                                            selectedIds.add(m.id);
                                          } else {
                                            selectedIds[1] = m.id;
                                          }
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? m.color.withValues(alpha: isDark ? 0.22 : 0.12)
                                            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02)),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? (isDark ? const Color(0xFF00E5FF) : m.color)
                                              : (isDark ? Colors.white12 : Colors.black12),
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: m.color.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: m.isParent
                                                  ? Icon(LucideIcons.user, color: m.color, size: 20)
                                                  : Text(
                                                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                                      style: TextStyle(color: m.color, fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  m.name,
                                                  style: TextStyle(
                                                    color: currentTheme.textPrimary,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  m.isParent ? 'parent.adult_label'.tr() : 'parent.child_label'.tr(),
                                                  style: TextStyle(
                                                    color: m.isParent
                                                        ? (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1))
                                                        : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669)),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (index == 0
                                                        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                                        : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)))
                                                    .withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: index == 0
                                                      ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                                      : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                badgeText,
                                                style: TextStyle(
                                                  color: index == 0
                                                      ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                                      : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark ? Colors.white30 : Colors.black26,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: !isReady
                              ? null
                              : () async {
                                  Navigator.pop(sheetCtx);
                                  final p1 = selectedIds[0];
                                  final p2 = selectedIds[1];
                                  final res = await ref.read(scheduleControllerProvider.notifier).bookClass(
                                        c.id,
                                        p1,
                                        secondParticipantId: p2,
                                      );
                                  if (!context.mounted) return;
                                  if (res.isSuccess) {
                                    AppSnackBar.showSuccess(context, res.message);
                                  } else {
                                    AppSnackBar.showError(
                                      context,
                                      res.message,
                                      action: res.status == BookingStatus.noSubscription
                                          ? SnackBarAction(
                                              label: 'parent.buy_action'.tr(),
                                              textColor: Colors.white,
                                              onPressed: () {
                                                ref.read(parentTabProvider.notifier).setTab(2);
                                              },
                                            )
                                          : null,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReady
                                ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                : (isDark ? Colors.white10 : Colors.black12),
                            foregroundColor: isReady
                                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                : (isDark ? Colors.white38 : Colors.black38),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: isReady ? 4 : 0,
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            );
          },
        );
      },
    );
  }

