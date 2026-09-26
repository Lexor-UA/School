import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

class AddClientSheet extends ConsumerStatefulWidget {
  const AddClientSheet({super.key});

  @override
  ConsumerState<AddClientSheet> createState() => _AddClientSheetState();
}

class _ChildInputEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  void dispose() {
    nameController.dispose();
    ageController.dispose();
  }
}

class _AddClientSheetState extends ConsumerState<AddClientSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final List<_ChildInputEntry> _childrenEntries = [];
  
  bool _isSuccess = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _generatedLogin;
  String? _selectedBranchId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    for (var entry in _childrenEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addChildField() {
    setState(() {
      _childrenEntries.add(_ChildInputEntry());
    });
  }

  void _removeChildField(int index) {
    setState(() {
      _childrenEntries[index].dispose();
      _childrenEntries.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final validChildren = _childrenEntries.where((c) => c.nameController.text.trim().isNotEmpty).toList();
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'admin.add_client_fill_required'.tr();
      });
      return;
    }

    for (var child in validChildren) {
      final a = int.tryParse(child.ageController.text.trim());
      if (a == null || a < 1 || a > 15) {
        setState(() {
          _errorMessage = a != null && a > 15
              ? 'Вік дитини "${child.nameController.text.trim()}" не може перевищувати 15 років (від 16 років клієнт реєструється як дорослий)'
              : 'Вік дитини "${child.nameController.text.trim()}" має бути від 1 до 15 років';
        });
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clientAge = int.tryParse(_ageController.text.trim());

      final usersSnap = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'parent')
          .get()
          .timeout(const Duration(seconds: 15));
          
      int maxClientNum = 0;
      for (var doc in usersSnap.docs) {
        final loginId = doc.data()['loginId'] as String?;
        if (loginId != null && loginId.startsWith('client')) {
          final numStr = loginId.replaceAll('client', '');
          final num = int.tryParse(numStr);
          if (num != null && num > maxClientNum) {
            maxClientNum = num;
          }
        }
      }
      final generatedLogin = 'client${maxClientNum + 1}';

      final userRef = FirebaseFirestore.instance.collection('users').doc();
      final effectiveBranch = ref.read(effectiveBranchProvider);
      final branchId = _selectedBranchId ?? effectiveBranch.id;
      final organizationId = effectiveBranch.organizationId;

      final userData = <String, dynamic>{
        'id': userRef.id,
        'name': _nameController.text.trim(),
        'role': 'parent',
        'phone': _phoneController.text.trim(),
        'loginId': generatedLogin,
        'password': '1',
        'avatarUrl': '',
        'organizationId': organizationId,
        'branchId': branchId,
      };
      if (clientAge != null) {
        userData['age'] = clientAge;
      }

      await userRef.set(userData).timeout(const Duration(seconds: 15));

      for (var entry in validChildren) {
        final childRef = FirebaseFirestore.instance.collection('children').doc();
        final childAge = int.tryParse(entry.ageController.text.trim());
        final childData = <String, dynamic>{
          'id': childRef.id,
          'parentId': userRef.id,
          'name': entry.nameController.text.trim(),
          'colorHex': '0xFF40C4FF',
          'level': 1,
          'xp': 0,
          'maxXp': 100,
          'notes': childAge != null ? 'Вік: $childAge' : '',
          'organizationId': organizationId,
          'branchId': branchId,
        };
        if (childAge != null) {
          childData['age'] = childAge;
        }
        await childRef.set(childData).timeout(const Duration(seconds: 15));
      }

      if (mounted) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Додано нового клієнта "${_nameController.text.trim()}" ($generatedLogin)', admin.id);
        }
        ref.invalidate(adminDashboardProvider);
        setState(() {
          _isSuccess = true;
          _isLoading = false;
          _generatedLogin = generatedLogin;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Помилка збереження: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
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
          child: _isSuccess
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    mediaQuery.viewInsets.bottom + 24,
                  ),
                  child: _buildSuccessState(isDark: isDark),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, isDark: isDark),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          22,
                          16,
                          22,
                          mediaQuery.viewInsets.bottom + 24,
                        ),
                        child: _buildFormFields(isDark: isDark),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessState({required bool isDark}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF047857)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.50),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Center(
            child: Icon(LucideIcons.check, color: Colors.white, size: 36),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        Text(
          'admin.add_client_success_title'.tr(),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 6),
        Text(
          _nameController.text,
          style: TextStyle(
            color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF003B73).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'admin.add_client_credentials_title'.tr(),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '${'admin.clients_login_label'.tr()}${_generatedLogin ?? ""}\n${'admin.clients_password_label'.tr()}1'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('admin.add_client_copied'.tr()), duration: const Duration(seconds: 2)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                              : const Color(0xFFBAE6FD),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.copy,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'admin.clients_copy'.tr(),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    '${'admin.clients_login_label'.tr()}${_generatedLogin ?? ""}',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  ),
                  Text(
                    '${'admin.clients_password_label'.tr()}1',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                    : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Text(
                    'admin.done'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.userPlus, color: Colors.white, size: 21),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.add_client_title'.tr(),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'admin.add_client_subtitle'.tr(),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Icon(LucideIcons.x, color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569), size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields({required bool isDark}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Branch selector (Kyiv vs Vienna)
          _buildBranchSelector(isDark: isDark),
          const SizedBox(height: 16),
          _buildTextField('admin.add_client_name_hint'.tr() == 'admin.add_client_name_hint' ? "ПІБ або ім'я клієнта" : 'admin.add_client_name_hint'.tr(), LucideIcons.user, _nameController, isDark: isDark),
          const SizedBox(height: 14),
          _buildTextField('admin.add_client_phone_hint'.tr() == 'admin.add_client_phone_hint' ? 'Номер телефону' : 'admin.add_client_phone_hint'.tr(), LucideIcons.phone, _phoneController, isNumber: true, isDark: isDark),
          const SizedBox(height: 14),
          _buildTextField('admin.add_client_age_hint'.tr() == 'admin.add_client_age_hint' ? 'Вік клієнта (років)' : 'admin.add_client_age_hint'.tr(), LucideIcons.calendar, _ageController, isNumber: true, isDark: isDark),
          const SizedBox(height: 20),
          
          // Children Section (Prominent & Intuitive)
          if (_childrenEntries.isEmpty) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addChildField,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF00E5FF).withValues(alpha: 0.12),
                              const Color(0xFF0284C7).withValues(alpha: 0.16),
                            ]
                          : [
                              const Color(0xFFE0F2FE).withValues(alpha: 0.90),
                              const Color(0xFFF0F9FF),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.50),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.baby,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+ Додати дитину (учня)',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0369A1),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Прив\'язати юного плавця до анкети',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                                : const Color(0xFFBAE6FD),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.plus,
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.baby, color: Color(0xFF00E5FF), size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Діти / Учні (${_childrenEntries.length})',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addChildField,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                              : const Color(0xFF38BDF8).withValues(alpha: 0.60),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Ще дитина',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_childrenEntries.length, (index) {
              final entry = _childrenEntries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField('admin.add_client_child_name_hint'.tr() == 'admin.add_client_child_name_hint' ? "Ім'я дитини" : 'admin.add_client_child_name_hint'.tr(), LucideIcons.baby, entry.nameController, isDark: isDark),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildTextField('admin.add_client_child_age_hint'.tr() == 'admin.add_client_child_age_hint' ? 'Вік (р.)' : 'admin.add_client_child_age_hint'.tr(), LucideIcons.calendarDays, entry.ageController, isNumber: true, isDark: isDark),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFF43F5E).withValues(alpha: 0.15)
                            : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFF43F5E).withValues(alpha: 0.40)
                              : const Color(0xFFFECDD3),
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(LucideIcons.trash2, color: Color(0xFFE11D48), size: 18),
                        onPressed: () => _removeChildField(index),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.40)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Color(0xFFF43F5E), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF00D2FF), Color(0xFF0077B6)]
                    : const [Color(0xFF0284C7), Color(0xFF0369A1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF00B4D8) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
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
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.userCheck, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'admin.add_client_save_btn'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isNumber = false, required bool isDark}) {
    String displayHint = hint;
    if (displayHint == 'admin.add_client_age_hint' || displayHint.isEmpty) {
      displayHint = 'Вік клієнта (років)';
    } else if (displayHint == 'admin.add_client_child_age_hint') {
      displayHint = 'Вік (р.)';
    } else if (displayHint == 'admin.add_client_name_hint') {
      displayHint = "ПІБ або ім'я клієнта";
    } else if (displayHint == 'admin.add_client_phone_hint') {
      displayHint = 'Номер телефону';
    } else if (displayHint == 'admin.add_client_child_name_hint') {
      displayHint = "Ім'я дитини";
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: displayHint,
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.70) : const Color(0xFF94A3B8),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBranchSelector({required bool isDark}) {
    final effectiveBranch = ref.watch(effectiveBranchProvider);
    final activeId = _selectedBranchId ?? effectiveBranch.id;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBranchOption(
              branchId: 'kyiv',
              title: 'Київ',
              flag: '🇺🇦',
              subtitle: 'UAH ₴',
              isSelected: activeId == 'kyiv',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildBranchOption(
              branchId: 'vienna',
              title: 'Відень',
              flag: '🇦🇹',
              subtitle: 'EUR €',
              isSelected: activeId == 'vienna',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchOption({
    required String branchId,
    required String title,
    required String flag,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBranchId = branchId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: branchId == 'vienna'
                      ? (isDark
                          ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)])
                      : (isDark
                          ? [const Color(0xFF00E5FF), const Color(0xFF0077B6)]
                          : [const Color(0xFF0284C7), const Color(0xFF0369A1)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (branchId == 'vienna' ? const Color(0xFFDC2626) : const Color(0xFF0284C7))
                        .withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569)),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
