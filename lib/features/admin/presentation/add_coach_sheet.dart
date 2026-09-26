import 'dart:ui';
import 'package:flutter/material.dart';
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

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            Navigator.pop(context);
          }
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : currentTheme.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                : currentTheme.cardShadow,
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: _isSuccess ? _buildSuccessState(currentTheme) : _buildFormState(currentTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(AppThemeConfig currentTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: const Icon(LucideIcons.check, color: Color(0xFF10B981), size: 48),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          'admin.add_coach_success_title'.tr(),
          style: TextStyle(color: currentTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          _nameController.text,
          style: TextStyle(color: currentTheme.textSecondary, fontSize: 16),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: currentTheme.isDark
                ? Colors.white.withValues(alpha: 0.12)
                : currentTheme.glassCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: currentTheme.isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : currentTheme.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Text('admin.add_client_credentials_title'.tr().toUpperCase(), style: TextStyle(color: currentTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.user, color: currentTheme.accentPrimary, size: 18),
                  const SizedBox(width: 12),
                  Text('admin.clients_login_label'.tr(), style: TextStyle(color: currentTheme.textSecondary, fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(_generatedLogin ?? '', style: TextStyle(color: currentTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.key, color: currentTheme.accentPrimary, size: 18),
                  const SizedBox(width: 12),
                  Text('admin.clients_password_label'.tr(), style: TextStyle(color: currentTheme.textSecondary, fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('1', style: TextStyle(color: currentTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormState(AppThemeConfig currentTheme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: currentTheme.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(LucideIcons.userPlus, color: currentTheme.accentPrimary),
              const SizedBox(width: 12),
              Text(
                'admin.add_coach_title'.tr(),
                style: TextStyle(
                  color: currentTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField('admin.add_client_name_hint'.tr(), LucideIcons.user, _nameController, currentTheme),
          const SizedBox(height: 16),
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
                  color: currentTheme.textPrimary,
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
          const SizedBox(height: 26),
          
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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.accentPrimary,
                foregroundColor: currentTheme.isDark ? const Color(0xFF061426) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                shadowColor: currentTheme.accentPrimary.withValues(alpha: 0.4),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: currentTheme.isDark ? const Color(0xFF061426) : Colors.white, strokeWidth: 2))
                  : Text('admin.add_coach_save_btn'.tr(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
        color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFCBD5E1),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        style: TextStyle(color: currentTheme.textPrimary, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: currentTheme.textMuted),
          prefixIcon: Icon(icon, color: currentTheme.accentPrimary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
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
        color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
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
                    color: currentTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: currentTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: TextStyle(color: currentTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              '₴ / зан',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
