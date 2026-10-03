import 'dart:ui';
import 'dart:math' as math;
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
import 'package:swimming_school_app/features/auth/models/app_user.dart';
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
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomSafePadding = math.max(mediaQuery.padding.bottom, 16.0);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.92,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF0D223B).withValues(alpha: 0.98),
                  const Color(0xFF07192C).withValues(alpha: 0.98),
                  const Color(0xFF040E1A).withValues(alpha: 0.99),
                ]
              : [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF0F9FF).withValues(alpha: 0.98),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        border: Border.all(
          color: isDark
              ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
              : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFF0284C7).withValues(alpha: 0.14),
            blurRadius: 36,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: isDark ? const Color(0xFF001F3F).withValues(alpha: 0.60) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: _isSuccess
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    bottomInset + bottomSafePadding + 24,
                  ),
                  child: _buildSuccessState(isDark: isDark),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, isDark: isDark),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          22,
                          16,
                          22,
                          bottomInset + bottomSafePadding + 32,
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
    final effectiveBranch = ref.watch(effectiveBranchProvider);
    final activeId = _selectedBranchId ?? effectiveBranch.id;
    final isVienna = activeId == 'vienna';
    final branchName = isVienna ? 'Відень 🇦🇹' : 'Київ 🇺🇦';
    final clientName = _nameController.text.trim();
    final clientPhone = _phoneController.text.trim();
    final validChildren = _childrenEntries
        .where((c) => c.nameController.text.trim().isNotEmpty)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        // Success Animated Badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.60),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.50),
                blurRadius: 28,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Center(
            child: Icon(LucideIcons.check, color: Colors.white, size: 38),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(
          'admin.add_client_success_title'.tr().isNotEmpty && !'admin.add_client_success_title'.tr().startsWith('admin.')
              ? 'admin.add_client_success_title'.tr()
              : 'Клієнта успішно створено!',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 4),
        Text(
          'Акаунт активовано та готовий до входу',
          style: TextStyle(
            color: isDark ? const Color(0xFFA5F3FC).withValues(alpha: 0.85) : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 18),

        // Virtual Club Pass Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0D2847).withValues(alpha: 0.95),
                      const Color(0xFF061A2D).withValues(alpha: 0.98),
                    ]
                  : [
                      const Color(0xFFF0F9FF),
                      Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.45) : const Color(0xFFBAE6FD),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pass Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.waves, color: Color(0xFF00E5FF), size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SWIM SCHOOL PASS',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? (isVienna ? const Color(0xFFEF4444).withValues(alpha: 0.20) : const Color(0xFF00E5FF).withValues(alpha: 0.20))
                          : (isVienna ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? (isVienna ? const Color(0xFFEF4444).withValues(alpha: 0.40) : const Color(0xFF00E5FF).withValues(alpha: 0.40))
                            : (isVienna ? const Color(0xFFFCA5A5) : const Color(0xFFBAE6FD)),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      branchName,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                height: 1,
              ),
              const SizedBox(height: 12),

              // Client details
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (clientPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            clientPhone,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFA5F3FC).withValues(alpha: 0.8) : const Color(0xFF64748B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Children chips if any
              if (validChildren.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: validChildren.map((c) {
                    final cName = c.nameController.text.trim();
                    final cAge = c.ageController.text.trim();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.baby, size: 12, color: Color(0xFF00E5FF)),
                          const SizedBox(width: 4),
                          Text(
                            '$cName ($cAge р.)',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 14),

              // Credentials row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF071728).withValues(alpha: 0.85)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ЛОГІН',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _generatedLogin ?? '',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ПАРОЛЬ',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '1',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons: Copy Welcome & Copy credentials
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final childrenNames = validChildren.map((c) => c.nameController.text.trim()).toList();
                          final childrenLine = childrenNames.isNotEmpty ? '\nУчні: ${childrenNames.join(', ')}' : '';
                          final welcomeMsg = 'Вітаємо у Swim School ($branchName)! 🏊‍♂️\nВаш особистий кабінет активовано.$childrenLine\n\nДані для входу в додаток:\nЛогін: ${_generatedLogin ?? ""}\nПароль: 1\n\nЗавантажуйте додаток та слідкуйте за розкладом!';
                          Clipboard.setData(ClipboardData(text: welcomeMsg));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(LucideIcons.messageSquare, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Вітальне повідомлення скопійовано для Viber / Telegram')),
                                ],
                              ),
                              backgroundColor: const Color(0xFF0284C7),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                                : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                                  : const Color(0xFFBAE6FD),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.share2,
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Для Viber / Telegram',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(
                          text: 'Логін: ${_generatedLogin ?? ""}\nПароль: 1',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Дані входу скопійовано'),
                            backgroundColor: const Color(0xFF0284C7),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.20)
                                : const Color(0xFFBAE6FD),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.copy,
                              color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Копіювати',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: 20),

        // Done button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF00E5FF), Color(0xFF0088CC)]
                  : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.40 : 0.45),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Center(
                child: Text(
                  'admin.done'.tr().isNotEmpty && !'admin.done'.tr().startsWith('admin.')
                      ? 'admin.done'.tr()
                      : 'Готово',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
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
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
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
              height: 4.5,
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                      )
                    : null,
                color: isDark ? null : const Color(0xFFBAE6FD),
                borderRadius: BorderRadius.circular(3),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.userPlus, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.add_client_title'.tr().isNotEmpty && !'admin.add_client_title'.tr().startsWith('admin.')
                          ? 'admin.add_client_title'.tr()
                          : 'Новий Клієнт',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'admin.add_client_subtitle'.tr().isNotEmpty && !'admin.add_client_subtitle'.tr().startsWith('admin.')
                          ? 'admin.add_client_subtitle'.tr()
                          : 'Швидка реєстрація батьків та учнів',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFA5F3FC).withValues(alpha: 0.8) : const Color(0xFF64748B),
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
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F9FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Icon(
                      LucideIcons.x,
                      color: isDark ? Colors.white70 : const Color(0xFF0284C7),
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

  Widget _buildFormFields({required bool isDark}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branch selector (Kyiv vs Vienna)
        _buildBranchSelector(isDark: isDark),
        const SizedBox(height: 16),
        _buildTextField("ПІБ або ім'я клієнта", LucideIcons.user, _nameController, isDark: isDark),
        const SizedBox(height: 14),
        _buildTextField('Номер телефону', LucideIcons.phone, _phoneController, isNumber: true, isDark: isDark),
        const SizedBox(height: 14),
        _buildTextField('Вік клієнта (років)', LucideIcons.calendar, _ageController, isNumber: true, isDark: isDark),
        const SizedBox(height: 20),
        
        // Children Section (Prominent & Intuitive)
        if (_childrenEntries.isEmpty) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _addChildField();
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF0C2B48).withValues(alpha: 0.65),
                            const Color(0xFF061A2D).withValues(alpha: 0.75),
                          ]
                        : [
                            const Color(0xFFE0F2FE).withValues(alpha: 0.90),
                            const Color(0xFFF0F9FF),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                        : const Color(0xFFBAE6FD),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.16 : 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.baby,
                        color: Colors.white,
                        size: 20,
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
                              color: isDark ? Colors.white : const Color(0xFF0284C7),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Прив\'язати юного плавця до анкети',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFA5F3FC).withValues(alpha: 0.8) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                              : const Color(0xFFBAE6FD),
                          width: 1.2,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Icon(LucideIcons.baby, color: Color(0xFF00E5FF), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Діти / Учні (${_childrenEntries.length})',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _addChildField();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF00E5FF).withValues(alpha: 0.20),
                                const Color(0xFF0284C7).withValues(alpha: 0.25),
                              ]
                            : [
                                const Color(0xFFE0F2FE),
                                const Color(0xFFBAE6FD),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.50)
                            : const Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.20 : 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'Ще дитина',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0284C7),
                            fontWeight: FontWeight.w800,
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
            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF091C30).withValues(alpha: 0.70)
                    : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                      : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.06)
                        : const Color(0xFF0284C7).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.baby, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Учень #${index + 1}',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            'Юний плавець',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFA5F3FC).withValues(alpha: 0.8) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _removeChildField(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.40)
                                    : const Color(0xFFFCA5A5),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.trash2, color: Color(0xFFF87171), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Видалити',
                                  style: TextStyle(
                                    color: Color(0xFFF87171),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTextField("Ім'я дитини", LucideIcons.user, entry.nameController, isDark: isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildTextField('Вік (р.)', LucideIcons.calendarDays, entry.ageController, isNumber: true, isDark: isDark),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08, end: 0);
          }),
        ],

        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: Color(0xFFF43F5E), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF00E5FF), Color(0xFF0088CC)]
                  : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.40 : 0.45),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : () {
                HapticFeedback.mediumImpact();
                _submit();
              },
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: _isLoading 
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.userCheck, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'admin.add_client_save_btn'.tr().isNotEmpty && !'admin.add_client_save_btn'.tr().startsWith('admin.')
                                ? 'admin.add_client_save_btn'.tr()
                                : 'Зберегти клієнта',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
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

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isNumber = false,
    required bool isDark,
  }) {
    String displayHint = hint;
    if (displayHint == 'admin.add_client_age_hint' || displayHint.isEmpty) {
      displayHint = 'Вік клієнта (років)';
    } else if (displayHint == 'admin.add_client_child_age_hint') {
      displayHint = 'Вік (р.)';
    } else if (displayHint == 'admin.add_client_name_hint') {
      displayHint = "ПІБ або ім'я клієнта";
    } else if (displayHint == 'admin.add_client_phone_hint') {
      displayHint = 'Номер телефону';
    } else if (displayHint == 'admin.add_client_child_age_hint') {
      displayHint = "Вік (р.)";
    }

    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark
                  ? (hasFocus ? const Color(0xFF0C243C) : const Color(0xFF091C30).withValues(alpha: 0.65))
                  : (hasFocus ? const Color(0xFFF0F9FF) : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasFocus
                    ? const Color(0xFF00E5FF)
                    : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD)),
                width: hasFocus ? 1.6 : 1.2,
              ),
              boxShadow: [
                if (hasFocus)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  )
                else if (isDark)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.04),
                    blurRadius: 8,
                  )
                else
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.05),
                    blurRadius: 8,
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
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    icon,
                    color: hasFocus
                        ? const Color(0xFF00E5FF)
                        : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.circleX,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                        onPressed: () {
                          controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchSelector({required bool isDark}) {
    final effectiveBranch = ref.watch(effectiveBranchProvider);
    final user = ref.watch(authControllerProvider);
    final isOwner = user?.isOwnerOrSuperAdmin == true;
    final activeId = _selectedBranchId ?? effectiveBranch.id;

    if (!isOwner) {
      final isVienna = activeId == 'vienna';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF081829).withValues(alpha: 0.70) : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(isVienna ? '🇦🇹' : '🇺🇦', style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Філія реєстрації клієнта',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVienna ? 'CitySwim Відень (EUR €)' : 'CitySwim Київ (UAH ₴)',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Авто',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF081829).withValues(alpha: 0.70) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
          width: 1.2,
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
          const SizedBox(width: 6),
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
    final isVienna = branchId == 'vienna';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedBranchId = branchId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: isVienna
                      ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                      : [const Color(0xFF00E5FF), const Color(0xFF0077B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(
                  color: isVienna
                      ? const Color(0xFFFCA5A5).withValues(alpha: 0.60)
                      : const Color(0xFFBAE6FD).withValues(alpha: 0.60),
                  width: 1.2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isVienna ? const Color(0xFFEF4444) : const Color(0xFF00E5FF))
                        .withValues(alpha: isDark ? 0.40 : 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF0F172A)),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : (isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.70) : const Color(0xFF64748B)),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
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

