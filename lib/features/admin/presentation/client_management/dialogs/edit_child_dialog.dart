import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';

Future<void> showEditChildDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String initialName,
  required String childId,
  required String currentName,
  int? currentAge,
}) async {
  final isDark = ref.read(appThemeControllerProvider).isDark;
  final nameCtrl = TextEditingController(text: currentName);
  final ageCtrl = TextEditingController(text: currentAge?.toString() ?? '');

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
            Icon(LucideIcons.pencil, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 20),
            const SizedBox(width: 8),
            Text(
              'admin.child_edit_title'.tr(),
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
                prefixIcon: Icon(LucideIcons.baby, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 18),
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
                prefixIcon: Icon(LucideIcons.calendarDays, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 18),
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
              backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
                await FirebaseFirestore.instance.collection('children').doc(childId).update({
                  'name': name,
                  'age': age,
                  'notes': age != null ? 'Вік: $age' : '',
                });
                final admin = ref.read(authControllerProvider);
                if (admin != null) {
                  await logAdminAction('Оновлено дані дитини "$name" клієнта "$initialName"', admin.id);
                }
              } catch (e) {
                debugPrint('Error updating child: $e');
              }
            },
            child: Text('admin.save'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  } finally {
    nameCtrl.dispose();
    ageCtrl.dispose();
  }
}
