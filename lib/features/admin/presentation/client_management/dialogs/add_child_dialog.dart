import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';

Future<void> showAddChildDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String clientId,
  required String initialName,
  List<String>? parentIds,
  Family? family,
}) async {
  final isDark = ref.read(appThemeControllerProvider).isDark;
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();

  try {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.baby, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), size: 22),
            const SizedBox(width: 8),
            Text(
              'admin.child_add_title'.tr(),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'admin.child_name'.tr(),
                labelStyle: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                prefixIcon: Icon(LucideIcons.baby, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), size: 18),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'admin.child_age'.tr(),
                labelStyle: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                prefixIcon: Icon(LucideIcons.calendarDays, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), size: 18),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'admin.cancel'.tr(),
              style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final age = int.tryParse(ageCtrl.text.trim());
              if (name.isEmpty) return;
              if (age != null && (age < 1 || age > 15)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(age > 15
                        ? 'Вік дитини не може перевищувати 15 років (від 16 років клієнт реєструється як дорослий)'
                        : 'Вік дитини має бути від 1 до 15 років'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                final effectiveParentIds = parentIds != null && parentIds.isNotEmpty
                    ? parentIds
                    : [clientId];
                final childRef = FirebaseFirestore.instance.collection('children').doc();
                final childData = <String, dynamic>{
                  'id': childRef.id,
                  'parentId': clientId,
                  'parentIds': effectiveParentIds,
                  if (family != null) 'familyId': family.id,
                  'name': name,
                  'colorHex': '0xFF40C4FF',
                  'level': 1,
                  'xp': 0,
                  'maxXp': 100,
                  'notes': age != null ? 'Вік: $age' : '',
                };
                if (age != null) {
                  childData['age'] = age;
                }
                await childRef.set(childData);
                final admin = ref.read(authControllerProvider);
                if (admin != null) {
                  await logAdminAction('Додано дитину "$name" для клієнта "$initialName"', admin.id);
                }
              } catch (e) {
                debugPrint('Error adding child: $e');
              }
            },
            child: Text('admin.add'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  } finally {
    nameCtrl.dispose();
    ageCtrl.dispose();
  }
}
