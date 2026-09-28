import 'dart:math' as math;
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

class AddCoachSheet extends ConsumerStatefulWidget {
  const AddCoachSheet({super.key});

  @override
  ConsumerState<AddCoachSheet> createState() => _AddCoachSheetState();
}

class _AddCoachSheetState extends ConsumerState<AddCoachSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rateGroupController = TextEditingController(text: '400');
  final _rateIndividualController = TextEditingController(text: '450');
  final _rateSplitController = TextEditingController(text: '600');
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _generatedLogin;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rateGroupController.dispose();
    _rateIndividualController.dispose();
    _rateSplitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'admin.add_client_fill_required'.tr();
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'coach')
          .get()
          .timeout(const Duration(seconds: 15));
          
      int maxCoachNum = 0;
      for (var doc in usersSnap.docs) {
        final loginId = doc.data()['loginId'] as String?;
        if (loginId != null && loginId.startsWith('coach')) {
          final numStr = loginId.replaceAll('coach', '');
          final num = int.tryParse(numStr);
          if (num != null && num > maxCoachNum) {
            maxCoachNum = num;
          }
        }
      }
      final generatedLogin = 'coach${maxCoachNum + 1}';

      final userRef = FirebaseFirestore.instance.collection('users').doc();
      final rateGroup = int.tryParse(_rateGroupController.text.trim()) ?? 400;
      final rateIndividual = int.tryParse(_rateIndividualController.text.trim()) ?? 450;
      final rateSplit = int.tryParse(_rateSplitController.text.trim()) ?? 600;

      final activeBranchId = ref.read(tenancyControllerProvider).activeBranchId;

      await userRef.set({
        'id': userRef.id,
        'name': _nameController.text.trim(),
        'role': 'coach',
        'phone': _phoneController.text.trim(),
        'loginId': generatedLogin,
        'avatarUrl': '',
        'organizationId': 'cityswim',
        'branchId': activeBranchId,
        'branchIds': [activeBranchId],
        'rateGroup': rateGroup,
        'rateIndividual': rateIndividual,
        'rateSplit': rateSplit,
      }).timeout(const Duration(seconds: 15));

      if (mounted) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Додано нового тренера "${_nameController.text.trim()}" (Ставки: $rateGroup/$rateIndividual/$rateSplit ₴)', admin.id);
        }

        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _generatedLogin = generatedLogin;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = math.max(mediaQuery.viewInsets.bottom, mediaQuery.padding.bottom);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E32).withValues(alpha: 0.97) : null,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F1E32).withValues(alpha: 0.98),
                  const Color(0xFF070E1A).withValues(alpha: 0.99),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF0F9FF),
                ],
              ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
          left: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                : const Color(0xFF003B73).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 14, 22, bottomInset + 18),
            child: _isSuccess
                ? _buildSuccessState(currentTheme, isDark)
                : _buildFormState(currentTheme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(AppThemeConfig currentTheme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top drag handle & close button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 36),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.30) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : currentTheme.glassCardBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : currentTheme.cardBorder,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.x,
                    color: currentTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Glowing Success Icon
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
        const SizedBox(height: 18),

        Text(
          'admin.add_coach_success_title'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : currentTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 6),

        Text(
          _nameController.text.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 22),

        // Solid Oceanic Credentials Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2137) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'admin.add_client_credentials_title'.tr().toUpperCase(),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Clipboard.setData(ClipboardData(
                        text: '${'admin.clients_login_label'.tr()}${_generatedLogin ?? ""}\n${'admin.clients_password_label'.tr()}1',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(LucideIcons.checkCheck, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('admin.coaches_copied_msg'.tr(args: [_nameController.text.trim()])),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.50) : const Color(0xFFBAE6FD),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.copy,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'admin.clients_copy'.tr(),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.user, size: 15, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Text(
                        '${'admin.clients_login_label'.tr()}${_generatedLogin ?? ""}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1.2,
                    height: 20,
                    color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFCBD5E1),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.keyRound, size: 15, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 6),
                      Text(
                        '${'admin.clients_password_label'.tr()}1',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),
        const SizedBox(height: 24),

        // Sapphire VIP CTA: «Готово»
        SizedBox(
          width: double.infinity,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0E3D64), const Color(0xFF082038)]
                    : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF38BDF8),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCircle2, color: Color(0xFF00E5FF), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'admin.done'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08),
      ],
    );
  }

  Widget _buildFormState(AppThemeConfig currentTheme, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle & Close button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 36),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.30) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : currentTheme.glassCardBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : currentTheme.cardBorder,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      color: currentTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.30) : const Color(0xFFBAE6FD),
                  ),
                ),
                child: Icon(
                  LucideIcons.userPlus,
                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'admin.add_coach_title'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.white : currentTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Form fields
          _buildTextField('admin.add_client_name_hint'.tr(), LucideIcons.user, _nameController, currentTheme),
          const SizedBox(height: 14),
          _buildTextField('admin.add_client_phone_hint'.tr(), LucideIcons.phone, _phoneController, currentTheme, isNumber: true),
          const SizedBox(height: 22),

          // Section: Персональні ставки (ЗП)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Icon(LucideIcons.banknote, color: Color(0xFF10B981), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Ставки заробітної плати (ЗП)',
                style: TextStyle(
                  color: isDark ? Colors.white : currentTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRateField(
            label: 'Групове тренування (грн / заняття)',
            icon: LucideIcons.users,
            controller: _rateGroupController,
            color: const Color(0xFF00E5FF),
            currentTheme: currentTheme,
          ),
          const SizedBox(height: 10),
          _buildRateField(
            label: 'Індивідуальне тренування (грн / заняття)',
            icon: LucideIcons.user,
            controller: _rateIndividualController,
            color: const Color(0xFFA855F7),
            currentTheme: currentTheme,
          ),
          const SizedBox(height: 10),
          _buildRateField(
            label: 'Спліт-тренування (2 учні) (грн / заняття)',
            icon: LucideIcons.userCheck,
            controller: _rateSplitController,
            color: const Color(0xFFF59E0B),
            currentTheme: currentTheme,
          ),
          const SizedBox(height: 24),
          
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Помилка: $_errorMessage',
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Sapphire VIP CTA: Зберегти тренера
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: currentTheme.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.accentPrimary.withValues(alpha: isDark ? 0.45 : 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : () {
                  HapticFeedback.mediumImpact();
                  _submit();
                },
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.userPlus, color: Colors.white, size: 19),
                          const SizedBox(width: 8),
                          Text(
                            'admin.add_coach_save_btn'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, AppThemeConfig currentTheme, {bool isNumber = false}) {
    final isDark = currentTheme.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFCBD5E1),
          width: 1.1,
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            style: TextStyle(
              color: isDark ? Colors.white : currentTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.65) : currentTheme.textMuted,
                fontSize: 13.5,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                size: 19,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(LucideIcons.x, color: currentTheme.textSecondary, size: 16),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        controller.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRateField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
    required AppThemeConfig currentTheme,
  }) {
    final isDark = currentTheme.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.50),
          width: 1.2,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.14),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.30 : 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : currentTheme.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.4) : currentTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: isDark ? 0.45 : 0.35)),
            ),
            child: Text(
              '₴ / зан',
              style: TextStyle(
                color: isDark ? color : (color == const Color(0xFF00E5FF) ? const Color(0xFF0284C7) : color),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
