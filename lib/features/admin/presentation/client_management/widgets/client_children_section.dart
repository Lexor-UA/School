import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/parent/presentation/graduate_child_sheet.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/dialogs/add_child_dialog.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/dialogs/edit_child_dialog.dart';

class ClientChildrenSection extends ConsumerWidget {
  final String clientId;
  final String clientName;
  final bool isDark;
  final List<String> parentIds;
  final Family? family;

  const ClientChildrenSection({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.isDark,
    required this.parentIds,
    required this.family,
  });

    void _deleteChild(BuildContext context, WidgetRef ref, String childId, String childName) {
      final isDark = ref.read(appThemeControllerProvider).isDark;
      showDialog(
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
            'admin.child_delete_title'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'admin.child_delete_confirm'.tr(namedArgs: {'name': childName}),
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF475569),
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
                backgroundColor: const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await FirebaseFirestore.instance
                      .collection('children')
                      .doc(childId)
                      .delete();
                  try {
                    final classesSnap = await FirebaseFirestore.instance
                        .collection('classes')
                        .where('enrolledChildIds', arrayContains: childId)
                        .get();
                    for (var doc in classesSnap.docs) {
                      final enrolled = List<String>.from(
                        doc.data()['enrolledChildIds'] ?? [],
                      );
                      enrolled.remove(childId);
                      await doc.reference.update({'enrolledChildIds': enrolled});
                    }
                  } catch (err) {
                    debugPrint('Error cleaning up classes for child: $err');
                  }
  
                  final admin = ref.read(authControllerProvider);
                  if (admin != null) {
                    await logAdminAction(
                      'Видалено дитину "$childName" клієнта "$clientName"',
                      admin.id,
                    );
                  }
                } catch (e) {
                  debugPrint('Error deleting child: $e');
                }
              },
              child: Text('admin.delete'.tr()),
            ),
          ],
        ),
      );
    }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildChildrenSection(context, ref);
  }

  Widget _buildChildrenSection(BuildContext context, WidgetRef ref) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.baby,
                      color: isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0284C7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'admin.add_client_children_title'.tr(),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => showAddChildDialog(
                  context: context,
                  ref: ref,
                  clientId: clientId,
                  initialName: clientName,
                  parentIds: parentIds,
                  family: family,
                ),
                icon: Icon(
                  LucideIcons.plus,
                  color: isDark
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF0284C7),
                  size: 15,
                ),
                label: Text(
                  'admin.add'.tr(),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF0284C7),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor:
                      (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                          .withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('children')
                .where('parentId', whereIn: parentIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
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
                  child: Center(
                    child: Text(
                      'admin.clients_no_children'.tr(),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }
  
              final children = snapshot.data!.docs;
              return Column(
                children: children.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cId = doc.id;
                  final cName = data['name'] ?? 'Дитина';
                  final cAge = data['age'] is int
                      ? data['age'] as int
                      : int.tryParse(data['age']?.toString() ?? '');
                  final childParentId = data['parentId'] as String?;
                  final isPartnerChild =
                      childParentId != null && childParentId != clientId;
                  final partnerName = family?.getOtherParentName(clientId);
  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                            : const Color(0xFFCBD5E1),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(
                                  0xFF003B73,
                                ).withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                                : const Color(0xFFE0F2FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🏊', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cName,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  if (isPartnerChild) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFA78BFA,
                                        ).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFA78BFA,
                                          ).withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        'Спільна (${partnerName ?? "партнер"})',
                                        style: const TextStyle(
                                          color: Color(0xFFA78BFA),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (cAge != null && cAge >= 16) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.5),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Text(
                                        '16+ Дорослий',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cAge != null
                                    ? '$cAge ${'admin.years_short'.tr()}'
                                    : 'Вік не вказано',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF0284C7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (cAge != null && cAge >= 16) ...[
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              final childObj = Child.fromJson({
                                'id': cId,
                                ...data,
                              });
                              GraduateChildSheet.show(context, childObj);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: isDark ? 0.25 : 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.5),
                                  width: 0.9,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🎓', style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Випустити',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          icon: Icon(
                            LucideIcons.pencil,
                            color: isDark
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF0284C7),
                            size: 16,
                          ),
                          tooltip: 'admin.edit'.tr(),
                          onPressed: () => showEditChildDialog(
                            context: context,
                            ref: ref,
                            initialName: clientName,
                            childId: cId,
                            currentName: cName,
                            currentAge: cAge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            color: Color(0xFFF43F5E),
                            size: 16,
                          ),
                          tooltip: 'admin.delete'.tr(),
                          onPressed: () => _deleteChild(context, ref, cId, cName),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      );
    }
}
