import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';

import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/widgets/client_children_section.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/widgets/client_subscriptions_section.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/widgets/client_header.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/widgets/client_discounts_section.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/widgets/client_branch_selector.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/widgets/client_credentials_form.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/widgets/client_family_section.dart';
import 'package:swimming_school_app/features/admin/presentation/client_management/widgets/client_classes_section.dart';

class EditClientSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String initialName;
  final String initialPhone;
  final int? initialAge;
  final String initialLoginId;
  final String? initialPassword;
  final String? initialBranchId;

  const EditClientSheet({
    super.key,
    required this.clientId,
    required this.initialName,
    required this.initialPhone,
    this.initialAge,
    required this.initialLoginId,
    this.initialPassword,
    this.initialBranchId,
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
  late String _selectedBranchId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  List<Map<String, dynamic>> get _services {
    final effectiveBranch = ref.watch(effectiveBranchProvider);
    return SubscriptionPackageCatalog.getServicesMapForBranch(
      effectiveBranch.id,
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _ageController = TextEditingController(
      text: widget.initialAge?.toString() ?? '',
    );
    _loginIdController = TextEditingController(text: widget.initialLoginId);
    _passwordController = TextEditingController(
      text: widget.initialPassword ?? '1',
    );
    _selectedBranchId = widget.initialBranchId ?? 'kyiv';
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
        'branchId': _selectedBranchId,
        'branchIds': [_selectedBranchId],
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
          final branchChanged =
              widget.initialBranchId != null &&
              widget.initialBranchId != _selectedBranchId;
          final branchNote = branchChanged
              ? ' (філію змінено на ${_selectedBranchId == 'vienna' ? 'Відень 🇦🇹' : 'Київ 🇺🇦'})'
              : '';
          await logAdminAction(
            'Оновлено дані та пароль клієнта "${_nameController.text.trim()}"$branchNote',
            admin.id,
          );
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
          msg =
              'Час очікування відповіді сервера вичерпано. Перевірте зʼєднання з інтернетом або спробуйте ще раз.';
        }
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
      }
    }
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
                  const Color(0xFF0F1E32).withValues(alpha: 0.96),
                  const Color(0xFF070E1A).withValues(alpha: 0.98),
                ]
              : [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF0F9FF).withValues(alpha: 0.98),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF003B73).withValues(alpha: 0.35)
                : const Color(0xFF0284C7).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: const Color(
              0xFF00E5FF,
            ).withValues(alpha: isDark ? 0.20 : 0.08),
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
              ClientHeader(isDark: isDark),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom:
                        max(
                          mediaQuery.viewInsets.bottom,
                          mediaQuery.padding.bottom,
                        ) +
                        24,
                    left: 24,
                    right: 24,
                    top: 16,
                  ),
                  child: _isSuccess
                      ? _buildSuccessState(isDark: isDark)
                      : _buildFormState(isDark: isDark),
                ),
              ),
            ],
          ),
        ),
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
          family = Family.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
          if (family.parentIds.isNotEmpty) {
            parentIds = family.parentIds;
          }
        }

        final userSubs = ref
            .watch(subscriptionControllerProvider)
            .where((s) => parentIds.contains(s.userId))
            .toList();

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
            ClientCredentialsForm(
              passwordController: _passwordController,
              loginIdController: _loginIdController,
              isDark: isDark,
            ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),
            const SizedBox(height: 24),

            // Branch Assignment Section
            ClientBranchSelector(
              selectedBranchId: _selectedBranchId,
              onBranchChanged: (id) => setState(() => _selectedBranchId = id),
              isDark: isDark,
            ).animate().fadeIn(delay: 355.ms).slideX(begin: -0.1),
            const SizedBox(height: 32),

            // FAMILY ACCOUNT SECTION
            ClientFamilySection(
              clientId: widget.clientId,
              clientName: widget.initialName,
              initialBranchId: widget.initialBranchId,
              family: family,
              parentIds: parentIds,
              isDark: isDark,
            ).animate().fadeIn(delay: 360.ms),
            const SizedBox(height: 32),

            // CHILDREN MANAGEMENT
            ClientChildrenSection(
              clientId: widget.clientId,
              clientName: widget.initialName,
              isDark: isDark,
              parentIds: parentIds,
              family: family,
            ).animate().fadeIn(delay: 380.ms),
            const SizedBox(height: 32),

            ClientSubscriptionsSection(
              clientId: widget.clientId,
              clientName: widget.initialName,
              clientAge: widget.initialAge,
              isDark: isDark,
              parentIds: parentIds,
              family: family,
              userSubs: userSubs,
              services: _services,
            ),

            const SizedBox(height: 32),
            // PERSONAL SUBSCRIPTION DISCOUNTS
            ClientDiscountsSection(
              clientId: widget.clientId,
              clientName: widget.initialName,
              clientAge: widget.initialAge,
              isDark: isDark,
              parentIds: parentIds,
              family: family,
              services: _services,
            ).animate().fadeIn(delay: 370.ms),

            const SizedBox(height: 32),
            ClientClassesSection(
              clientId: widget.clientId,
              clientName: widget.initialName,
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
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
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                'admin.add_client_save_btn'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms)
                .scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildSuccessState({required bool isDark}) {
    final trText = 'admin.edit_client_success'.tr();
    final displayText =
        (trText == 'admin.edit_client_success' || trText.isEmpty)
        ? 'Дані клієнта оновлено!'
        : trText;
    return Column(
      children: [
        const Icon(
          LucideIcons.checkCircle,
          color: Color(0xFF10B981),
          size: 64,
        ).animate().scale().fadeIn(),
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
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : const Color(0xFF64748B),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
          size: 18,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : const Color(0xFFBAE6FD),
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
}
