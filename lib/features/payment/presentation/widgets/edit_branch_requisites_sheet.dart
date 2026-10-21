import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/payment/services/branch_payment_service.dart';

/// Віджет-лист для перегляду та редагування банківських реквізитів філій (Київ / Відень)
/// Доступний для Адміністратора та Власника
class EditBranchRequisitesSheet extends ConsumerStatefulWidget {
  final String? initialBranchId;

  const EditBranchRequisitesSheet({
    super.key,
    this.initialBranchId,
  });

  static Future<void> show(BuildContext context, {String? initialBranchId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditBranchRequisitesSheet(initialBranchId: initialBranchId),
    );
  }

  @override
  ConsumerState<EditBranchRequisitesSheet> createState() => _EditBranchRequisitesSheetState();
}

class _EditBranchRequisitesSheetState extends ConsumerState<EditBranchRequisitesSheet> {
  late String _selectedBranchId;
  late TextEditingController _companyController;
  late TextEditingController _taxIdController;
  late TextEditingController _taxIdLabelController;
  late TextEditingController _ibanController;
  late TextEditingController _bankNameController;
  late TextEditingController _addressController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = widget.initialBranchId ?? 'kyiv';
    _companyController = TextEditingController();
    _taxIdController = TextEditingController();
    _taxIdLabelController = TextEditingController();
    _ibanController = TextEditingController();
    _bankNameController = TextEditingController();
    _addressController = TextEditingController();

    _loadConfigForBranch(_selectedBranchId);
  }

  void _loadConfigForBranch(String branchId) {
    final config = ref.read(branchPaymentServiceProvider).getPaymentConfig(branchId);
    final details = config.legalEntityDetails;
    _companyController.text = details['companyName'] ?? '';
    _taxIdController.text = details['taxId'] ?? '';
    _taxIdLabelController.text = details['taxIdLabel'] ?? (branchId == 'vienna' ? 'UID-Nummer' : 'ЄДРПОУ');
    _ibanController.text = details['iban'] ?? '';
    _bankNameController.text = details['bankName'] ?? '';
    _addressController.text = details['address'] ?? '';
  }

  @override
  void dispose() {
    _companyController.dispose();
    _taxIdController.dispose();
    _taxIdLabelController.dispose();
    _ibanController.dispose();
    _bankNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final company = _companyController.text.trim();
    final iban = _ibanController.text.trim().replaceAll(' ', '');
    final bankName = _bankNameController.text.trim();
    final taxId = _taxIdController.text.trim();
    final taxLabel = _taxIdLabelController.text.trim();
    final address = _addressController.text.trim();

    if (company.isEmpty || iban.isEmpty) {
      setState(() {
        _errorMessage = 'payment.req_fill_company_iban_error'.tr();
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final baseConfig = ref.read(branchPaymentServiceProvider).getPaymentConfig(_selectedBranchId);
      final updatedDetails = Map<String, String>.from(baseConfig.legalEntityDetails);
      updatedDetails['companyName'] = company;
      updatedDetails['iban'] = iban;
      updatedDetails['bankName'] = bankName;
      updatedDetails['taxId'] = taxId;
      updatedDetails['taxIdLabel'] = taxLabel.isNotEmpty ? taxLabel : (_selectedBranchId == 'vienna' ? 'UID-Nummer' : 'ЄДРПОУ');
      updatedDetails['address'] = address;

      final updatedConfig = baseConfig.copyWith(legalEntityDetails: updatedDetails);
      await ref.read(branchPaymentServiceProvider).savePaymentConfig(updatedConfig);

      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction(
          'Оновлено банківські реквізити філії $_selectedBranchId (IBAN: $iban)',
          admin.id,
        );
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('payment.req_saved_success'.tr()),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
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

    // Listen to live config stream updates without mutating controllers on every build
    ref.listen(branchPaymentConfigStreamProvider(_selectedBranchId), (prev, next) {
      next.whenData((cfg) {
        if (!_isSaving && _companyController.text.isEmpty && _ibanController.text.isEmpty) {
          final d = cfg.legalEntityDetails;
          _companyController.text = d['companyName'] ?? '';
          _taxIdController.text = d['taxId'] ?? '';
          _taxIdLabelController.text = d['taxIdLabel'] ?? (_selectedBranchId == 'vienna' ? 'UID-Nummer' : 'ЄДРПОУ');
          _ibanController.text = d['iban'] ?? '';
          _bankNameController.text = d['bankName'] ?? '';
          _addressController.text = d['address'] ?? '';
        }
      });
    });

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.90),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF030D1B).withValues(alpha: 0.96) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.60) : const Color(0xFF003B73).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFFBAE6FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                                    : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.landmark, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'payment.req_sheet_title'.tr(),
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'payment.req_sheet_subtitle'.tr(),
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Branch Selector Pills (Kyiv / Vienna)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A2238) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildBranchTab(
                            id: 'kyiv',
                            label: '🇺🇦 CitySwim Kyiv (UAH ₴)',
                            isSelected: _selectedBranchId == 'kyiv',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildBranchTab(
                            id: 'vienna',
                            label: '🇦🇹 CitySwim Wien (EUR €)',
                            isSelected: _selectedBranchId == 'vienna',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 4, 20, mediaQuery.viewInsets.bottom + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.40)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],

                    _buildField(
                      label: 'payment.req_company_field'.tr(),
                      controller: _companyController,
                      icon: LucideIcons.building,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            label: 'payment.req_tax_id_field'.tr(),
                            controller: _taxIdController,
                            icon: LucideIcons.fileText,
                            currentTheme: currentTheme,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            label: 'payment.req_tax_label_field'.tr(),
                            controller: _taxIdLabelController,
                            icon: LucideIcons.tag,
                            currentTheme: currentTheme,
                            isDark: isDark,
                            hint: _selectedBranchId == 'vienna' ? 'UID-Nummer' : 'ЄДРПОУ',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildField(
                      label: 'payment.req_iban_field'.tr(),
                      controller: _ibanController,
                      icon: LucideIcons.creditCard,
                      currentTheme: currentTheme,
                      isDark: isDark,
                      isMonospace: true,
                      hint: _selectedBranchId == 'vienna' ? 'AT893700000001234567' : 'UA82305299000002600123456789',
                    ),
                    const SizedBox(height: 12),

                    _buildField(
                      label: 'payment.req_bank_name_field'.tr(),
                      controller: _bankNameController,
                      icon: LucideIcons.landmark,
                      currentTheme: currentTheme,
                      isDark: isDark,
                      hint: _selectedBranchId == 'vienna' ? 'Erste Bank' : 'АТ КБ "ПриватБанк"',
                    ),
                    const SizedBox(height: 12),

                    _buildField(
                      label: 'payment.req_address_field'.tr(),
                      controller: _addressController,
                      icon: LucideIcons.mapPin,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 22),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                                : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.35 : 0.22),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isSaving ? null : _save,
                            child: Center(
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.check, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'payment.req_save_btn'.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchTab({
    required String id,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () {
        if (_selectedBranchId != id) {
          setState(() {
            _selectedBranchId = id;
            _errorMessage = null;
          });
          _loadConfigForBranch(id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: isSelected
              ? Border.all(
                  color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.40 : 0.35),
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                  : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required AppThemeConfig currentTheme,
    required bool isDark,
    bool isMonospace = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF051526) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
