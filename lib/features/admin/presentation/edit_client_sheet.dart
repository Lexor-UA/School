import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/admin/presentation/admin_booking_sheet.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/presentation/graduate_child_sheet.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_discount.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';

class EditClientSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String initialName;
  final String initialPhone;
  final int? initialAge;
  final String initialLoginId;
  final String? initialPassword;

  const EditClientSheet({
    super.key,
    required this.clientId,
    required this.initialName,
    required this.initialPhone,
    this.initialAge,
    required this.initialLoginId,
    this.initialPassword,
  });

  @override
  ConsumerState<EditClientSheet> createState() => _EditClientSheetState();
}

class _EditClientSheetState extends ConsumerState<EditClientSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _loginIdController;
  late TextEditingController _passwordController;
  bool _obscurePassword = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String _selectedSubOwner = '';

  List<Map<String, dynamic>> get _services {
    final effectiveBranch = ref.watch(effectiveBranchProvider);
    return SubscriptionPackageCatalog.getServicesMapForBranch(effectiveBranch.id);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _ageController = TextEditingController(text: widget.initialAge?.toString() ?? '');
    _loginIdController = TextEditingController(text: widget.initialLoginId);
    _passwordController = TextEditingController(text: widget.initialPassword ?? '1');
    _selectedSubOwner = widget.initialName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetPasswordToDefault() {
    setState(() {
      _passwordController.text = '1';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 18),
            SizedBox(width: 8),
            Text('Пароль скинуто до стандартного: 1', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _generateRandomPin() {
    final randomPin = (100000 + Random().nextInt(900000)).toString();
    setState(() {
      _passwordController.text = randomPin;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: Color(0xFF00E5FF), size: 18),
            const SizedBox(width: 8),
            Text('Згенеровано новий PIN: $randomPin', style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyCredentials() {
    final login = _loginIdController.text.trim();
    final pass = _passwordController.text.trim();
    Clipboard.setData(ClipboardData(
      text: 'Логін: $login\nПароль: $pass',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.copy, color: Color(0xFF38BDF8), size: 18),
            SizedBox(width: 8),
            Text('Дані для входу скопійовано в буфер обміну!', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty || 
        _loginIdController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Заповніть всі поля, включаючи пароль');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final age = int.tryParse(_ageController.text.trim());
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'loginId': _loginIdController.text.trim(),
        'password': _passwordController.text.trim(),
      };
      if (age != null) {
        updateData['age'] = age;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .set(updateData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Оновлено дані та пароль клієнта "${_nameController.text.trim()}"', admin.id);
        }
        
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is TimeoutException || msg.contains('TimeoutException')) {
          msg = 'Час очікування відповіді сервера вичерпано. Перевірте зʼєднання з інтернетом або спробуйте ще раз.';
        }
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
      }
    }
  }

  Future<void> _showAddChildDialog({List<String>? parentIds, Family? family}) async {
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
                    : [widget.clientId];
                final childRef = FirebaseFirestore.instance.collection('children').doc();
                final childData = <String, dynamic>{
                  'id': childRef.id,
                  'parentId': widget.clientId,
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
                  await logAdminAction('Додано дитину "$name" для клієнта "${widget.initialName}"', admin.id);
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

  Future<void> _showEditChildDialog(String childId, String currentName, int? currentAge) async {
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
                  await logAdminAction('Оновлено дані дитини "$name" клієнта "${widget.initialName}"', admin.id);
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

  void _deleteChild(String childId, String childName) {
    final isDark = ref.read(appThemeControllerProvider).isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.35)),
        ),
        title: Text(
          'admin.child_delete_title'.tr(),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'admin.child_delete_confirm'.tr(namedArgs: {'name': childName}),
          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('admin.cancel'.tr(), style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('children').doc(childId).delete();
                try {
                  final classesSnap = await FirebaseFirestore.instance
                      .collection('classes')
                      .where('enrolledChildIds', arrayContains: childId)
                      .get();
                  for (var doc in classesSnap.docs) {
                    final enrolled = List<String>.from(doc.data()['enrolledChildIds'] ?? []);
                    enrolled.remove(childId);
                    await doc.reference.update({'enrolledChildIds': enrolled});
                  }
                } catch (err) {
                  debugPrint('Error cleaning up classes for child: $err');
                }

                final admin = ref.read(authControllerProvider);
                if (admin != null) {
                  await logAdminAction('Видалено дитину "$childName" клієнта "${widget.initialName}"', admin.id);
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

  void _updateSubscriptionClasses(Subscription sub, int delta) async {
    final newClasses = sub.remainingClasses + delta;
    if (newClasses < 0) return;
    
    try {
      await FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).update({
        'remainingClasses': newClasses,
        'isActive': newClasses > 0,
      });
      
      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction('Змінено залишок занять для "${widget.initialName}" (стало $newClasses)', admin.id);
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
          side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.35)),
        ),
        title: Text(
          'admin.sub_delete_title'.tr(),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Ви дійсно бажаєте видалити абонемент "${sub.serviceName ?? 'Абонемент'}" для ${sub.ownerName ?? widget.initialName}?',
          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('admin.cancel'.tr(), style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('admin.delete'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).delete();
      
      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction('Видалено абонемент клієнта "${widget.initialName}"', admin.id);
      }
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
    }
  }

  void _showAddSubscriptionDialog(List<String> availableOwners, {String? preselectedOwner, List<Map<String, dynamic>>? familyMembers}) {
    final isDark = ref.read(appThemeControllerProvider).isDark;
    String selectedOwner = (preselectedOwner != null && availableOwners.contains(preselectedOwner))
        ? preselectedOwner
        : (availableOwners.isNotEmpty ? availableOwners.first : widget.initialName);

    int? getOwnerAge(String name) {
      final m = familyMembers?.where((m) => m['name'] == name).firstOrNull;
      return m?['age'] as int?;
    }

    List<Map<String, dynamic>> getFilteredServices(String owner) {
      final isAdult = owner == widget.initialName;
      final childAge = getOwnerAge(owner);

      return _services.where((s) {
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
    String selectedService = initialServices.isNotEmpty ? initialServices.first['name'] : _services.first['name'];

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

            final allSubs = ref.read(subscriptionControllerProvider).where((s) => s.userId == widget.clientId).toList();
            final activeForOwner = allSubs.where((s) {
              final owner = (s.ownerName == null || s.ownerName!.isEmpty) ? widget.initialName : s.ownerName!;
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
                    
                    final serviceDetails = _services.firstWhere((s) => s['name'] == selectedService);
                    final classes = serviceDetails['classes'] as int;
                    final validityDays = serviceDetails['validityDays'] as int;
                    final expiry = DateTime.now().add(Duration(days: validityDays));
                    
                    // Deactivate any previous active subscription for selectedOwner
                    final currentSubs = ref.read(subscriptionControllerProvider).where((s) => s.userId == widget.clientId).toList();
                    for (final oldSub in currentSubs.where((s) {
                      final owner = (s.ownerName == null || s.ownerName!.isEmpty) ? widget.initialName : s.ownerName!;
                      return owner.trim() == selectedOwner.trim() && s.isActive;
                    })) {
                      try {
                        await FirebaseFirestore.instance.collection('subscriptions').doc(oldSub.id).update({'isActive': false});
                      } catch (e) {
                        debugPrint('Error deactivating old sub: $e');
                      }
                    }

                    final effectiveBranch = ref.read(effectiveBranchProvider);

                    final newSub = Subscription(
                      id: 'sub_${DateTime.now().microsecondsSinceEpoch}_${selectedOwner.hashCode}',
                      userId: widget.clientId,
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
                      await FirebaseFirestore.instance.collection('subscriptions').doc(newSub.id).set(newSub.toJson());
                      
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
          side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.35)),
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
          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('admin.cancel'.tr(), style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Видалити', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.clientId);
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        final raw = userSnap.data()?['subscriptionDiscounts'] as List<dynamic>? ?? [];
        final updated = raw
            .whereType<Map>()
            .where((m) => m['id'] != discount.id)
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        await userRef.update({'subscriptionDiscounts': updated});
      }

      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction('Видалено персональну знижку для "${widget.initialName}"', admin.id);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting discount: $e');
    }
  }

  void _showAddDiscountDialog(List<String> availableOwners, List<Map<String, dynamic>> familyMembers) {
    final isDark = ref.read(appThemeControllerProvider).isDark;
    final currSymbol = ref.read(effectiveBranchProvider).currencySymbol;
    
    // Default selection
    String selectedOwner = 'all'; // 'all' or specific owner name
    String selectedService = 'all'; // 'all' or specific service name
    String discountMode = 'fixedPrice'; // 'fixedPrice' or 'percent'
    
    final priceController = TextEditingController();
    final percentController = TextEditingController();
    String? localError;

    int getBasePrice(String serviceName) {
      if (serviceName == 'all') return 0;
      final s = _services.firstWhere((e) => e['name'] == serviceName, orElse: () => {});
      return s['price'] as int? ?? 0;
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
                    previewPercent = ((basePrice - entered) * 100 / basePrice).round();
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
                  color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.40) : const Color(0xFFFDE68A),
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
                    child: const Icon(LucideIcons.tag, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Надати персональну знижку',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16.5,
                          ),
                        ),
                        Text(
                          'для клієнта "${widget.initialName}"',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
                      'Для кого діє знижка:',
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
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          isExpanded: true,
                          value: selectedOwner,
                          icon: Icon(LucideIcons.chevronDown, size: 18, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.users, size: 16, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                  const SizedBox(width: 8),
                                  const Text('Вся сім\'я (будь-хто з членів родини)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            ...familyMembers.map((m) {
                              final name = m['name'] as String;
                              final isParent = m['isParent'] as bool;
                              final age = m['age'];
                              return DropdownMenuItem(
                                value: name,
                                child: Row(
                                  children: [
                                    Icon(
                                      isParent ? LucideIcons.user : LucideIcons.baby,
                                      size: 16,
                                      color: isParent ? const Color(0xFF38BDF8) : const Color(0xFF34D399),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$name (${isParent ? "дорослий" : "дитина, $age р."})',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }),
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

                    // 2. Target Subscription
                    Text(
                      'Абонемент:',
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
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          isExpanded: true,
                          value: selectedService,
                          icon: Icon(LucideIcons.chevronDown, size: 18, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  const Text('Будь-який абонемент', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            ..._services.map((s) {
                              final name = s['name'] as String;
                              final price = s['price'] as int? ?? s['priceNum'] as int?;
                              return DropdownMenuItem(
                                value: name,
                                child: Text(
                                  '$name — ${price ?? 0} $currSymbol',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() {
                                selectedService = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (basePrice > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Базова вартість: $basePrice $currSymbol',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 3. Discount Mode Selector (Tabs)
                    Text(
                      'Спосіб розрахунку знижки:',
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
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => discountMode = 'fixedPrice'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: discountMode == 'fixedPrice'
                                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: discountMode == 'fixedPrice'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Нова ціна (грн)',
                                    style: TextStyle(
                                      color: discountMode == 'fixedPrice'
                                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                      fontSize: 12.5,
                                      fontWeight: discountMode == 'fixedPrice' ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => discountMode = 'percent'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: discountMode == 'percent'
                                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: discountMode == 'percent'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Відсоток (%)',
                                    style: TextStyle(
                                      color: discountMode == 'percent'
                                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                      fontSize: 12.5,
                                      fontWeight: discountMode == 'percent' ? FontWeight.w800 : FontWeight.w600,
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
                          labelText: 'Акційна ціна для клієнта',
                          labelStyle: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          suffixText: currSymbol,
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          prefixIcon: const Icon(LucideIcons.banknote, color: Color(0xFF10B981), size: 18),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
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
                          labelText: 'Відсоток знижки (1 - 99%)',
                          labelStyle: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          suffixText: '%',
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                          prefixIcon: const Icon(LucideIcons.percent, color: Color(0xFFF59E0B), size: 18),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                '-$pct%',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.sparkles, color: Color(0xFFF59E0B), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Попередній перегляд для клієнта:',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
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
                                    '$basePrice грн',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.redAccent,
                                      decorationThickness: 2,
                                      color: isDark ? Colors.white38 : Colors.grey,
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
                                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF059669),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (previewPercent != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
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
                                'Економія клієнта: $previewSavings $currSymbol',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ] else ...[
                            Text(
                              'Введіть значення знижки вище, щоб побачити фінальну вартість.',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF78350F),
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
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
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
                    style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    int discountedPrice = 0;
                    int discountPercent = 0;

                    if (discountMode == 'fixedPrice') {
                      final val = int.tryParse(priceController.text.trim());
                      if (val == null || val <= 0) {
                        setStateDialog(() => localError = 'Введіть коректну ціну в $currSymbol');
                        return;
                      }
                      if (basePrice > 0 && val >= basePrice) {
                        setStateDialog(() => localError = 'Акційна ціна має бути меншою за базову ($basePrice $currSymbol)');
                        return;
                      }
                      discountedPrice = val;
                      if (basePrice > 0) {
                        discountPercent = ((basePrice - val) * 100 / basePrice).round();
                      }
                    } else {
                      final val = int.tryParse(percentController.text.trim());
                      if (val == null || val < 1 || val > 99) {
                        setStateDialog(() => localError = 'Введіть відсоток знижки від 1 до 99%');
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

                      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.clientId);
                      await userRef.set({
                        'subscriptionDiscounts': FieldValue.arrayUnion([newDiscount.toJson()]),
                      }, SetOptions(merge: true));

                      final admin = ref.read(authControllerProvider);
                      if (admin != null) {
                        final desc = discountMode == 'fixedPrice'
                            ? '$discountedPrice $currSymbol'
                            : '-$discountPercent%';
                        await logAdminAction(
                          'Надано знижку ($desc) для "${widget.initialName}"',
                          admin.id,
                        );
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(LucideIcons.sparkles, color: Color(0xFFF59E0B), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Персональну знижку успішно збережено для ${widget.initialName}!'),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error adding discount: $e');
                    }
                  },
                  child: const Text('Зберегти знижку', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDiscountsSection({
    required bool isDark,
    required List<String> parentIds,
    required Family? family,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .where('parentId', whereIn: parentIds)
          .snapshots(),
      builder: (context, childSnap) {
        List<Map<String, dynamic>> familyMembers = [
          {'name': widget.initialName, 'isParent': true, 'age': widget.initialAge},
        ];
        List<String> availableOwners = [widget.initialName];

        if (family != null && family.isPaired) {
          final partnerName = family.getOtherParentName(widget.clientId);
          if (partnerName != null && partnerName.isNotEmpty && !availableOwners.contains(partnerName)) {
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
            familyMembers.add({
              'name': cName,
              'isParent': false,
              'age': cData['age'],
            });
            availableOwners.add(cName);
          }
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.clientId).snapshots(),
          builder: (context, userSnap) {
            final userData = userSnap.hasData ? userSnap.data!.data() as Map<String, dynamic>? : null;
            final rawDiscounts = userData?['subscriptionDiscounts'] as List<dynamic>? ?? [];
            final discounts = rawDiscounts
                .whereType<Map>()
                .map((m) => SubscriptionDiscount.fromJson(Map<String, dynamic>.from(m)))
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
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (discounts.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
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
                      onPressed: () => _showAddDiscountDialog(availableOwners, familyMembers),
                      icon: const Icon(LucideIcons.plus, size: 16, color: Color(0xFFF59E0B)),
                      label: const Text(
                        'Додати',
                        style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (discounts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.tag, size: 20, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Немає персональних знижок для цього клієнта.',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
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
                                  const Color(0xFFF59E0B).withValues(alpha: 0.14),
                                  const Color(0xFF1E293B).withValues(alpha: 0.60),
                                ]
                              : [
                                  Colors.white,
                                  const Color(0xFFFFFBEB),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.40),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.06),
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
                            child: const Icon(LucideIcons.tag, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isAllMembers
                                            ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                                            : const Color(0xFF10B981).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isAllMembers ? const Color(0xFF00E5FF) : const Color(0xFF10B981),
                                          width: 0.7,
                                        ),
                                      ),
                                      child: Text(
                                        isAllMembers ? "Вся сім'я" : discount.targetMember,
                                        style: TextStyle(
                                          color: isAllMembers ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)) : const Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
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
                                  isAllServices ? 'Будь-який абонемент' : discount.serviceName,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                            text: '${discount.originalPrice} грн  ',
                                            style: TextStyle(
                                              decoration: TextDecoration.lineThrough,
                                              decorationColor: Colors.redAccent,
                                              color: isDark ? Colors.white38 : Colors.grey,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                        TextSpan(
                                          text: '${discount.discountedPrice} ${ref.watch(effectiveBranchProvider).currencySymbol}',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF059669),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (discount.originalPrice > discount.discountedPrice) ...[
                                          TextSpan(
                                            text: ' (економія ${discount.originalPrice - discount.discountedPrice} ${ref.watch(effectiveBranchProvider).currencySymbol})',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
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
                                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF059669),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 17, color: Color(0xFFF43F5E)),
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


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.22),
                  const Color(0xFF0284C7).withValues(alpha: 0.26),
                  const Color(0xFF0A223D).withValues(alpha: 0.55),
                ]
              : [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF0F9FF).withValues(alpha: 0.98),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0xFF003B73).withValues(alpha: 0.35) : const Color(0xFF0284C7).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.20 : 0.08),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed Header (outside scroll view, full drag & dismiss zone)
              _buildHeader(context, isDark: isDark),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: mediaQuery.viewInsets.bottom + 24,
                    left: 24,
                    right: 24,
                    top: 16,
                  ),
                  child: _isSuccess ? _buildSuccessState(isDark: isDark) : _buildFormState(isDark: isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator with generous touch footprint
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.30) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blueAccent.withValues(alpha: 0.15) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.blueAccent.withValues(alpha: 0.3) : const Color(0xFFBAE6FD),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.pencil,
                      color: isDark ? Colors.blueAccent : const Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'admin.edit_client_title'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              // Frosted glass close button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormState({required bool isDark}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('families')
          .where('parentIds', arrayContains: widget.clientId)
          .snapshots(),
      builder: (context, familySnapshot) {
        Family? family;
        List<String> parentIds = [widget.clientId];
        if (familySnapshot.hasData && familySnapshot.data!.docs.isNotEmpty) {
          final doc = familySnapshot.data!.docs.first;
          family = Family.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>});
          if (family.parentIds.isNotEmpty) {
            parentIds = family.parentIds;
          }
        }

        final userSubs = ref.watch(subscriptionControllerProvider).where((s) => parentIds.contains(s.userId)).toList();
        
        return Column(
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'admin.add_client_name_hint'.tr(),
              icon: LucideIcons.user,
              isDark: isDark,
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _phoneController,
              label: 'admin.add_client_phone_hint'.tr(),
              icon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _ageController,
              label: 'Вік клієнта (років)',
              icon: LucideIcons.calendar,
              keyboardType: TextInputType.number,
              isDark: isDark,
            ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _loginIdController,
              label: '${'admin.clients_login_label'.tr()} (Client1)',
              icon: LucideIcons.key,
              isDark: isDark,
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
            const SizedBox(height: 16),

            // Password & Access Management Section
            _buildPasswordSection(isDark: isDark).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),
            const SizedBox(height: 32),

            // FAMILY ACCOUNT SECTION
            _buildFamilySection(isDark: isDark, family: family, parentIds: parentIds).animate().fadeIn(delay: 360.ms),
            const SizedBox(height: 32),

            // CHILDREN MANAGEMENT
            _buildChildrenSection(isDark: isDark, parentIds: parentIds, family: family).animate().fadeIn(delay: 380.ms),
            const SizedBox(height: 32),

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
              stream: FirebaseFirestore.instance.collection('children').where('parentId', whereIn: parentIds).snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> familyMembers = [
                  {'name': widget.initialName, 'isParent': true, 'age': widget.initialAge},
                ];
                List<String> availableOwners = [widget.initialName];

                if (family != null && family.isPaired) {
                  final partnerName = family.getOtherParentName(widget.clientId);
                  if (partnerName != null && partnerName.isNotEmpty && !availableOwners.contains(partnerName)) {
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

            String effectiveOwner = (_selectedSubOwner.isNotEmpty && availableOwners.contains(_selectedSubOwner))
                ? _selectedSubOwner
                : availableOwners.first;

            final memberSubs = userSubs.where((sub) {
              final owner = (sub.ownerName == null || sub.ownerName!.isEmpty) ? widget.initialName : sub.ownerName!;
              return owner.trim() == effectiveOwner.trim();
            }).toList();

            memberSubs.sort((a, b) {
              if (a.isActive && !b.isActive) return -1;
              if (!a.isActive && b.isActive) return 1;
              return 0;
            });

            final hasActiveSubForMember = memberSubs.any((s) => s.isActive && s.remainingClasses > 0);

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
                        final owner = (s.ownerName == null || s.ownerName!.isEmpty) ? widget.initialName : s.ownerName!;
                        return owner.trim() == mName.trim() && s.isActive && s.remainingClasses > 0;
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0EA5E9)).withValues(alpha: isDark ? 0.30 : 0.18),
                                          const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.10),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1)),
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.25 : 0.15),
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
                                    isParent ? LucideIcons.user : LucideIcons.baby,
                                    size: 15,
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    isParent ? '$mName (Клієнт)' : mName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? (isDark ? Colors.white : const Color(0xFF0369A1))
                                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.creditCard, color: isDark ? Colors.white38 : const Color(0xFF94A3B8), size: 36),
                        const SizedBox(height: 10),
                        Text(
                          'Немає активного абонемента для $effectiveOwner',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Призначте 1 абонемент для цієї особи',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.45)
                              : const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.35 : 0.45),
                          width: 1.1,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: (isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.06),
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
                                      sub.serviceName ?? 'admin.cat_subscriptions'.tr(),
                                      style: TextStyle(
                                        color: isDark
                                            ? (isActive ? Colors.white : Colors.white70)
                                            : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Для: ${sub.ownerName ?? widget.initialName}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: isDark ? 0.18 : 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isActive ? 'admin.clients_status_active'.tr() : 'admin.clients_status_unpaid'.tr(),
                                  style: TextStyle(
                                    color: isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
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
                                final daysLeft = sub.expiryDate!.difference(DateTime.now()).inDays;
                                if (daysLeft >= 0 && daysLeft <= 5) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '⚠️ Закінчується через $daysLeft ${daysLeft == 1 ? 'день' : 'днів'}',
                                      style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold),
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
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                                      icon: const Icon(LucideIcons.minusCircle, color: Color(0xFFD97706), size: 18),
                                      onPressed: () => _updateSubscriptionClasses(sub, -1),
                                      tooltip: 'admin.tooltip_sub_minus'.tr(),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                                      icon: Icon(LucideIcons.plusCircle, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 18),
                                      onPressed: () => _updateSubscriptionClasses(sub, 1),
                                      tooltip: 'admin.tooltip_sub_plus'.tr(),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                                      icon: const Icon(LucideIcons.refreshCw, color: Color(0xFFD97706), size: 16),
                                      onPressed: () => _updateSubscriptionClasses(sub, -sub.remainingClasses),
                                      tooltip: 'admin.tooltip_sub_reset'.tr(),
                                    ),
                                    Container(
                                      height: 16,
                                      width: 1,
                                      color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFCBD5E1),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                                      icon: const Icon(LucideIcons.trash2, color: Color(0xFFF43F5E), size: 16),
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
                    icon: Icon(LucideIcons.plus, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF059669)),
                    label: Text(
                      hasActiveSubForMember
                          ? 'Призначити новий абонемент (замінить поточний)'
                          : 'Призначити абонемент для "$effectiveOwner"',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? null : const Color(0xFFECFDF5),
                      side: BorderSide(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showAddSubscriptionDialog(availableOwners, preselectedOwner: effectiveOwner, familyMembers: familyMembers),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 32),
        // PERSONAL SUBSCRIPTION DISCOUNTS
        _buildDiscountsSection(isDark: isDark, parentIds: parentIds, family: family).animate().fadeIn(delay: 370.ms),
        
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'admin.client_classes'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: widget.clientId).snapshots(),
          builder: (context, childSnap) {
            List<String> allRelatedIds = [widget.clientId];
            Map<String, String> idToName = {widget.clientId: widget.initialName};
            if (childSnap.hasData) {
              for (var doc in childSnap.data!.docs) {
                allRelatedIds.add(doc.id);
                final cData = doc.data() as Map<String, dynamic>;
                idToName[doc.id] = (cData['name'] as String? ?? 'Дитина').trim();
              }
            }
            
            if (allRelatedIds.isEmpty) return const SizedBox.shrink();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes')
                .where('enrolledChildIds', arrayContainsAny: allRelatedIds)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
                .snapshots(),
              builder: (context, classSnap) {
                if (!classSnap.hasData || classSnap.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Немає активних записів',
                        style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                      ),
                    ),
                  );
                }

                final classes = classSnap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return GroupClass.fromJson(data);
                }).toList();
                
                classes.sort((a, b) => a.startTime.compareTo(b.startTime));

                return Column(
                  children: classes.map((session) {
                    final enrolledHere = session.enrolledChildIds.where((id) => allRelatedIds.contains(id)).toList();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.blueAccent.withValues(alpha: 0.3) : const Color(0xFFBAE6FD),
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF003B73).withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${DateFormat('dd.MM.yyyy').format(session.startTime)} о ${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.blueAccent.withValues(alpha: 0.2) : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? Colors.blueAccent.withValues(alpha: 0.4) : const Color(0xFFBAE6FD),
                                  ),
                                ),
                                child: Text(
                                  session.category,
                                  style: TextStyle(
                                    color: isDark ? Colors.blueAccent : const Color(0xFF0284C7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...enrolledHere.map((enrolledId) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    idToName[enrolledId] ?? 'Дитина',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        final targetName = idToName[enrolledId] ?? widget.initialName;
                                        final success = await ref.read(scheduleControllerProvider.notifier).cancelClass(
                                          session.id, 
                                          enrolledId,
                                          targetUserId: widget.clientId,
                                          targetOwnerName: targetName,
                                        );
                                        if (success && mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('admin.booking_cancelled_success'.tr(), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('${'common.error'.tr()}: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
                                          );
                                        }
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 24),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'admin.cancel_booking'.tr(),
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
        
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: widget.clientId).snapshots(),
          builder: (context, snapshot) {
            List<String> availableIds = [widget.clientId];
            List<String> availableNames = [widget.initialName];
            
            if (snapshot.hasData) {
              for (var d in snapshot.data!.docs) {
                availableIds.add(d.id);
                availableNames.add((d.data() as Map<String, dynamic>)['name'] as String? ?? 'Дитина');
              }
            }
            
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(LucideIcons.calendarPlus, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                label: Text(
                  'admin.book_class'.tr(),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? null : const Color(0xFFE0F2FE),
                  side: BorderSide(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => AdminBookingSheet(
                      clientId: widget.clientId,
                      clientName: widget.initialName,
                      availableIds: availableIds,
                      availableNames: availableNames,
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Помилка: $_errorMessage',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Submit Button (VisionOS Oceanic Gradient)
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.40),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00B4D8).withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _submit,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                    : Text(
                        'admin.add_client_save_btn'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 40),
      ],
    );
      },
    );
  }

  Widget _buildSuccessState({required bool isDark}) {
    final trText = 'admin.edit_client_success'.tr();
    final displayText = (trText == 'admin.edit_client_success' || trText.isEmpty)
        ? 'Дані клієнта оновлено!'
        : trText;
    return Column(
      children: [
        const Icon(LucideIcons.checkCircle, color: Color(0xFF10B981), size: 64).animate().scale().fadeIn(),
        const SizedBox(height: 24),
        Text(
          displayText,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
          size: 18,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordSection({required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF003B73).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: 'admin.clients_password_label'.tr().replaceAll(':', '').trim().isEmpty
                  ? 'Пароль клієнта'
                  : 'admin.clients_password_label'.tr().replaceAll(':', '').trim(),
              labelStyle: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                LucideIcons.keyRound,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  size: 20,
                ),
                tooltip: _obscurePassword ? 'Показати пароль' : 'Приховати пароль',
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPasswordActionButton(
                      icon: LucideIcons.rotateCcw,
                      label: 'Скинути на "1"',
                      color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                      onTap: _resetPasswordToDefault,
                      isDark: isDark,
                    ),
                    _buildPasswordActionButton(
                      icon: LucideIcons.sparkles,
                      label: 'Згенерувати PIN',
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      onTap: _generateRandomPin,
                      isDark: isDark,
                    ),
                    _buildPasswordActionButton(
                      icon: LucideIcons.copy,
                      label: 'Копіювати',
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9),
                      onTap: _copyCredentials,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 12,
                      color: isDark ? Colors.white.withValues(alpha: 0.40) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Збережіть зміни, щоб оновити пароль у базі даних',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.30), width: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenSection({
    required bool isDark,
    required List<String> parentIds,
    required Family? family,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.baby,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'admin.add_client_children_title'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAddChildDialog(parentIds: parentIds, family: family),
              icon: Icon(
                LucideIcons.plus,
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                size: 16,
              ),
              label: Text(
                'admin.add'.tr(),
                style: TextStyle(
                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('children').where('parentId', whereIn: parentIds).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
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
                final cAge = data['age'] is int ? data['age'] as int : int.tryParse(data['age']?.toString() ?? '');
                final childParentId = data['parentId'] as String?;
                final isPartnerChild = childParentId != null && childParentId != widget.clientId;
                final partnerName = family?.getOtherParentName(widget.clientId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.2) : const Color(0xFFCBD5E1),
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF003B73).withValues(alpha: 0.03),
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
                          color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.12) : const Color(0xFFE0F2FE),
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
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                if (isPartnerChild) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA78BFA).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFA78BFA).withValues(alpha: 0.4),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
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
                              cAge != null ? '$cAge ${'admin.years_short'.tr()}' : 'Вік не вказано',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                            final childObj = Child.fromJson({'id': cId, ...data});
                            GraduateChildSheet.show(context, childObj);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5),
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
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          size: 16,
                        ),
                        tooltip: 'admin.edit'.tr(),
                        onPressed: () => _showEditChildDialog(cId, cName, cAge),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Color(0xFFF43F5E), size: 16),
                        tooltip: 'admin.delete'.tr(),
                        onPressed: () => _deleteChild(cId, cName),
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

  Widget _buildFamilySection({
    required bool isDark,
    required Family? family,
    required List<String> parentIds,
  }) {
    final isPaired = family?.isPaired ?? false;
    final partnerName = family?.getOtherParentName(widget.clientId);
    final partnerPhone = family?.getOtherParentPhone(widget.clientId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.heartHandshake,
                  color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Сімейний зв\'язок (CRM)',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!isPaired)
              TextButton.icon(
                onPressed: () => _showLinkParentDialog(context, isDark: isDark, existingFamily: family),
                icon: Icon(
                  LucideIcons.userPlus,
                  color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                  size: 16,
                ),
                label: const Text(
                  'Зв\'язати в пару',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (isPaired && family != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.users, color: Color(0xFF10B981), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Партнер: ${partnerName ?? "Невідомо"}',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (partnerPhone != null && partnerPhone.isNotEmpty)
                              Text(
                                partnerPhone,
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        family.inviteCode,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Обидва батьки мають спільний доступ до дітей та абонементів.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmUnlinkFamily(family, isDark: isDark),
                      icon: const Icon(LucideIcons.userX, size: 14, color: Colors.redAccent),
                      label: const Text(
                        'Розірвати',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.userMinus,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Акаунт не має зв\'язку з другим із батьків',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (family != null)
                        Text(
                          'Код сім\'ї: ${family.inviteCode}',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black45,
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmUnlinkFamily(Family family, {required bool isDark}) async {
    final partnerName = family.getOtherParentName(widget.clientId) ?? 'партнера';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Розірвати зв\'язок?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Ви впевнені, що хочете розірвати сімейний зв\'язок клієнта "${widget.initialName}" з $partnerName? Спільний доступ до дітей та абонементів буде розділено.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Розірвати', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(familyControllerProvider).adminUnlinkFamily(family.id);
      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction('Розірвано сімейний зв\'язок клієнтів "${widget.initialName}" та "$partnerName"', admin.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сімейний зв\'язок успішно розірвано.'),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLinkParentDialog(BuildContext context, {required bool isDark, required Family? existingFamily}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        String searchQuery = '';
        String? selectedClientId;
        String? selectedClientName;
        bool isLinking = false;

        return StatefulBuilder(
          builder: (builderCtx, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.98),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.heartHandshake, color: Color(0xFF10B981), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Зв\'язати у спільну сім\'ю',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Клієнт: ${widget.initialName}',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search Box
                      TextField(
                        onChanged: (val) => setModalState(() => searchQuery = val.trim().toLowerCase()),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Пошук за ім\'ям або телефоном...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Client List
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'parent')
                              .snapshots(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final candidateDocs = userSnap.data!.docs.where((doc) {
                              if (doc.id == widget.clientId) return false;
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['name'] as String? ?? '').toLowerCase();
                              final phone = (data['phone'] as String? ?? '').toLowerCase();
                              if (searchQuery.isNotEmpty) {
                                return name.contains(searchQuery) || phone.contains(searchQuery);
                              }
                              return true;
                            }).toList();

                            if (candidateDocs.isEmpty) {
                              return Center(
                                child: Text(
                                  'Клієнтів не знайдено',
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                ),
                              );
                            }

                            return ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: candidateDocs.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 6),
                              itemBuilder: (context, idx) {
                                final doc = candidateDocs[idx];
                                final data = doc.data() as Map<String, dynamic>;
                                final cId = doc.id;
                                final cName = data['name'] as String? ?? 'Клієнт';
                                final cPhone = data['phone'] as String? ?? '';
                                final isSelected = selectedClientId == cId;

                                return InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      selectedClientId = cId;
                                      selectedClientName = cName;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12)
                                          : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF10B981)
                                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: isSelected
                                              ? const Color(0xFF10B981)
                                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                          child: Text(
                                            cName.isNotEmpty ? cName[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (cPhone.isNotEmpty)
                                                Text(
                                                  cPhone,
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white54 : Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: (selectedClientId == null || isLinking)
                              ? null
                              : () async {
                                  setModalState(() => isLinking = true);
                                  final error = await ref
                                      .read(familyControllerProvider)
                                      .adminLinkParents(widget.clientId, selectedClientId!);
                                  setModalState(() => isLinking = false);

                                  if (error != null) {
                                    if (builderCtx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } else {
                                    final admin = ref.read(authControllerProvider);
                                    if (admin != null) {
                                      await logAdminAction(
                                        'Об\'єднано у сім\'ю клієнтів "${widget.initialName}" та "$selectedClientName"',
                                        admin.id,
                                      );
                                    }
                                    if (modalCtx.mounted) {
                                      Navigator.pop(modalCtx);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Акаунти "${widget.initialName}" та "$selectedClientName" успішно об\'єднано у спільну сім\'ю!',
                                          ),
                                          backgroundColor: const Color(0xFF064E3B),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: isLinking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.heartHandshake, size: 18),
                          label: Text(
                            isLinking
                                ? 'Об\'єднання...'
                                : 'Об\'єднати з ${selectedClientName ?? "обраним клієнтом"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
