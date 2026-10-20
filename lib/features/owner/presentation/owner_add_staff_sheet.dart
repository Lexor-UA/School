import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class OwnerAddStaffSheet extends ConsumerStatefulWidget {
  final String initialBranchId;

  const OwnerAddStaffSheet({
    super.key,
    this.initialBranchId = 'kyiv',
  });

  @override
  ConsumerState<OwnerAddStaffSheet> createState() => _OwnerAddStaffSheetState();
}

class _OwnerAddStaffSheetState extends ConsumerState<OwnerAddStaffSheet> {
  late String _selectedRole; // 'coach' or 'admin'
  late String _selectedBranchId; // 'kyiv' or 'vienna'

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController(text: '1');

  late TextEditingController _rateGroupController;
  late TextEditingController _rateIndividualController;
  late TextEditingController _rateSplitController;
  late TextEditingController _adminSalaryController;

  bool _loginManuallyEdited = false;
  bool _obscurePassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = 'coach';
    _selectedBranchId = widget.initialBranchId == 'vienna' ? 'vienna' : 'kyiv';

    final isVienna = _selectedBranchId == 'vienna';
    _rateGroupController = TextEditingController(text: isVienna ? '45' : '400');
    _rateIndividualController = TextEditingController(text: isVienna ? '55' : '450');
    _rateSplitController = TextEditingController(text: isVienna ? '70' : '600');
    _adminSalaryController = TextEditingController(text: isVienna ? '1900' : '20000');

    _generateRandomPassword();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    _rateGroupController.dispose();
    _rateIndividualController.dispose();
    _rateSplitController.dispose();
    _adminSalaryController.dispose();
    super.dispose();
  }

  String _transliterate(String input) {
    const map = {
      'а': 'a', 'б': 'b', 'в': 'v', 'г': 'h', 'ґ': 'g', 'д': 'd', 'е': 'e',
      'є': 'ye', 'ж': 'zh', 'з': 'z', 'и': 'y', 'і': 'i', 'ї': 'yi', 'й': 'y',
      'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r',
      'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch',
      'ш': 'sh', 'щ': 'shch', 'ь': '', 'ю': 'yu', 'я': 'ya', 'ы': 'y', 'э': 'e',
      'ё': 'yo', 'ъ': '', 'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss',
    };
    final lower = input.trim().toLowerCase();
    final sb = StringBuffer();
    for (int i = 0; i < lower.length; i++) {
      final ch = lower[i];
      if (map.containsKey(ch)) {
        sb.write(map[ch]);
      } else if (RegExp(r'[a-z0-9]').hasMatch(ch)) {
        sb.write(ch);
      } else if (ch == ' ' || ch == '-' || ch == '_') {
        sb.write('_');
      }
    }
    return sb.toString().replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  void _onNameChanged(String value) {
    if (_loginManuallyEdited) return;
    final cleanSlug = _transliterate(value);
    final prefix = _selectedRole == 'admin' ? 'admin' : 'coach';
    if (cleanSlug.isEmpty) {
      _loginIdController.text = '';
    } else {
      final firstPart = cleanSlug.split('_').first;
      _loginIdController.text = '${prefix}_$firstPart';
    }
  }

  void _onBranchChanged(String branchId) {
    if (_selectedBranchId == branchId) return;
    final isVienna = branchId == 'vienna';
    setState(() {
      _selectedBranchId = branchId;
      _rateGroupController.text = isVienna ? '45' : '400';
      _rateIndividualController.text = isVienna ? '55' : '450';
      _rateSplitController.text = isVienna ? '70' : '600';
      _adminSalaryController.text = isVienna ? '1900' : '20000';
    });
  }

  void _onRoleChanged(String role) {
    if (_selectedRole == role) return;
    setState(() {
      _selectedRole = role;
      if (!_loginManuallyEdited && _nameController.text.trim().isNotEmpty) {
        _onNameChanged(_nameController.text);
      }
    });
  }

  void _generateRandomPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final rand = Random.secure();
    final generated = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = generated;
      _obscurePassword = false;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final loginId = _loginIdController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (name.isEmpty || loginId.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'owner.staff.add_fill_required'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final db = FirebaseFirestore.instance;

      // Verify loginId uniqueness
      final existingSnap = await db.collection('users').where('loginId', isEqualTo: loginId).get();
      if (existingSnap.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'owner.staff.login_taken_error'.tr(namedArgs: {'login': loginId});
          });
        }
        return;
      }

      final isCoach = _selectedRole == 'coach';
      final isVienna = _selectedBranchId == 'vienna';
      final currency = isVienna ? '€' : '₴';
      final docId = '${_selectedRole}_${DateTime.now().millisecondsSinceEpoch}';
      final avatarBg = isCoach ? '0284c7' : '10b981';
      final avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=$avatarBg&color=ffffff';

      final Map<String, dynamic> staffData = {
        'id': docId,
        'name': name,
        'role': _selectedRole,
        'phone': phone,
        'loginId': loginId,
        'password': password,
        'branchId': _selectedBranchId,
        'branchIds': [_selectedBranchId],
        'organizationId': 'cityswim',
        'currency': currency,
        'avatarUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (isCoach) {
        staffData['rateGroup'] = int.tryParse(_rateGroupController.text.trim()) ?? (isVienna ? 45 : 400);
        staffData['rateIndividual'] = int.tryParse(_rateIndividualController.text.trim()) ?? (isVienna ? 55 : 450);
        staffData['rateSplit'] = int.tryParse(_rateSplitController.text.trim()) ?? (isVienna ? 70 : 600);
      } else {
        staffData['adminSalary'] = int.tryParse(_adminSalaryController.text.trim()) ?? (isVienna ? 1900 : 20000);
        staffData['salaryType'] = 'monthly';
      }

      await db.collection('users').doc(docId).set(staffData);
      if (isCoach) {
        await db.collection('coaches').doc(docId).set(staffData);
      }

      final roleLabel = isCoach ? 'owner.role_coach'.tr() : 'owner.role_admin_full'.tr();
      final copyText = '🏊 City Swim — Доступ для персоналу\n'
          '👤 $name ($roleLabel)\n'
          '🔑 Логін: $loginId\n'
          '🔒 Пароль: $password';
      await Clipboard.setData(ClipboardData(text: copyText));

      final owner = ref.read(authControllerProvider);
      if (owner != null) {
        await logAdminAction(
          'Створено співробітника: $name ($roleLabel, логін: $loginId)',
          owner.id,
        );
      }

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('owner.staff.staff_created_and_copied'.tr(namedArgs: {
                    'name': name,
                    'login': loginId,
                  })),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.92;
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    final isCoach = _selectedRole == 'coach';
    final currencySymbol = _selectedBranchId == 'vienna' ? '€' : '₴';
    final accentColor = isCoach
        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
        : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669));

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF030D1B).withValues(alpha: 0.96) : const Color(0xFFF0F9FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? accentColor.withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.65) : const Color(0xFF003B73).withValues(alpha: 0.12),
            blurRadius: 36,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(3),
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
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                              ),
                              child: Icon(LucideIcons.userPlus, color: accentColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'owner.staff.add_staff_title'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            LucideIcons.x,
                            color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 18, 24, mediaQuery.viewInsets.bottom + 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Selector
                      Text(
                        'owner.staff.select_role_label'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSelectorChip(
                              selected: isCoach,
                              label: 'owner.role_coach'.tr(),
                              icon: LucideIcons.waves,
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              isDark: isDark,
                              onTap: () => _onRoleChanged('coach'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSelectorChip(
                              selected: !isCoach,
                              label: 'owner.role_admin_full'.tr(),
                              icon: LucideIcons.shieldCheck,
                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                              isDark: isDark,
                              onTap: () => _onRoleChanged('admin'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Branch Selector
                      Text(
                        'owner.staff.select_branch_label'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSelectorChip(
                              selected: _selectedBranchId == 'kyiv',
                              label: '🇺🇦 ${'branches.city_kyiv'.tr()}',
                              icon: LucideIcons.mapPin,
                              color: accentColor,
                              isDark: isDark,
                              onTap: () => _onBranchChanged('kyiv'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSelectorChip(
                              selected: _selectedBranchId == 'vienna',
                              label: '🇦🇹 ${'branches.city_vienna'.tr()}',
                              icon: LucideIcons.mapPin,
                              color: accentColor,
                              isDark: isDark,
                              onTap: () => _onBranchChanged('vienna'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Full Name & Phone
                      _buildInputField(
                        controller: _nameController,
                        label: 'owner.staff.name_label'.tr(),
                        hint: isCoach ? 'Іван Петренко' : 'Марія Коваленко',
                        icon: LucideIcons.user,
                        color: accentColor,
                        isDark: isDark,
                        onChanged: _onNameChanged,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _phoneController,
                        label: 'owner.staff.phone_label'.tr(),
                        hint: _selectedBranchId == 'vienna' ? '+43 676 0000000' : '+380 99 000 00 00',
                        icon: LucideIcons.phone,
                        color: accentColor,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 20),

                      // Credentials Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.keyRound, color: accentColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'owner.staff.credentials_title'.tr(),
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _generateRandomPassword,
                                  icon: Icon(LucideIcons.sparkles, size: 14, color: accentColor),
                                  label: Text(
                                    'owner.staff.generate_password_btn'.tr(),
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildInputField(
                              controller: _loginIdController,
                              label: 'owner.staff.login_label'.tr(),
                              hint: isCoach ? 'coach_ivan' : 'admin_maria',
                              icon: LucideIcons.userCheck,
                              color: accentColor,
                              isDark: isDark,
                              onChanged: (_) => _loginManuallyEdited = true,
                            ),
                            const SizedBox(height: 10),
                            _buildInputField(
                              controller: _passwordController,
                              label: 'owner.staff.password_label'.tr(),
                              hint: '••••••',
                              icon: LucideIcons.lock,
                              color: accentColor,
                              isDark: isDark,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 18,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Financial Rates
                      Text(
                        isCoach
                            ? 'owner.salary_sheet.coach_rates_title'.tr()
                            : 'owner.salary_sheet.admin_salary_title'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isCoach)
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _rateGroupController,
                                label: 'Групове ($currencySymbol)',
                                hint: '400',
                                icon: LucideIcons.users,
                                color: accentColor,
                                isDark: isDark,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInputField(
                                controller: _rateIndividualController,
                                label: 'Індив. ($currencySymbol)',
                                hint: '450',
                                icon: LucideIcons.user,
                                color: accentColor,
                                isDark: isDark,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInputField(
                                controller: _rateSplitController,
                                label: 'Спліт ($currencySymbol)',
                                hint: '600',
                                icon: LucideIcons.userCheck,
                                color: accentColor,
                                isDark: isDark,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        )
                      else
                        _buildInputField(
                          controller: _adminSalaryController,
                          label: 'owner.salary_sheet.fixed_salary_label'.tr(namedArgs: {'currency': currencySymbol}),
                          hint: '20000',
                          icon: LucideIcons.wallet,
                          color: accentColor,
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                        ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: isDark ? const Color(0xFF041221) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 6,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox.shrink()
                              : const Icon(LucideIcons.userCheck, size: 19),
                          label: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: isDark ? Colors.black : Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'owner.staff.create_staff_btn'.tr(),
                                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
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
      ),
    );
  }

  Widget _buildSelectorChip({
    required bool selected,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.22 : 0.14)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1)),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? color : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.28) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFBAE6FD),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  autocorrect: false,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ?suffixIcon,
        ],
      ),
    );
  }
}

/// Модальне вікно керування власним логіном та паролем Власника (`mock_owner`).
class OwnerSelfCredentialsSheet extends ConsumerStatefulWidget {
  const OwnerSelfCredentialsSheet({super.key});

  @override
  ConsumerState<OwnerSelfCredentialsSheet> createState() => _OwnerSelfCredentialsSheetState();
}

class _OwnerSelfCredentialsSheetState extends ConsumerState<OwnerSelfCredentialsSheet> {
  final _loginController = TextEditingController(text: 'owner');
  final _passwordController = TextEditingController(text: '1');
  bool _obscurePassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOwnerCredentials();
  }

  Future<void> _loadOwnerCredentials() async {
    try {
      await ensureOwnerInFirestore();
      final snap = await FirebaseFirestore.instance.collection('users').doc('mock_owner').get();
      if (!mounted || !snap.exists) return;
      final data = snap.data() ?? {};
      final dbLogin = (data['loginId'] as String?)?.trim() ?? 'owner';
      final dbPass = (data['password'] as String?)?.trim() ?? '1';
      setState(() {
        _loginController.text = dbLogin.isNotEmpty ? dbLogin : 'owner';
        if (dbPass.isNotEmpty && dbPass.length < 40) {
          _passwordController.text = dbPass;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final rand = Random.secure();
    final generated = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    HapticFeedback.lightImpact();
    setState(() {
      _passwordController.text = generated;
      _obscurePassword = false;
    });
  }

  Future<void> _save() async {
    final newLogin = _loginController.text.trim().toLowerCase();
    final newPassword = _passwordController.text.trim();
    if (newLogin.isEmpty || newPassword.isEmpty) {
      setState(() => _errorMessage = 'owner.staff.fill_credentials_error'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final dupSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('loginId', isEqualTo: newLogin)
          .get();
      final hasConflict = dupSnap.docs.any((d) => d.id != 'mock_owner');
      if (hasConflict) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'owner.staff.login_taken_error'.tr(namedArgs: {'login': newLogin});
          });
        }
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc('mock_owner').set({
        'id': 'mock_owner',
        'name': 'Owner',
        'role': 'owner',
        'loginId': newLogin,
        'password': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final copyText = '👑 City Swim — Доступ Власника\n'
          '🔑 Логін: $newLogin\n'
          '🔒 Пароль: $newPassword';
      await Clipboard.setData(ClipboardData(text: copyText));

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('owner.staff.owner_credentials_saved'.tr())),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
    final mediaQuery = MediaQuery.of(context);
    final isDark = ref.watch(appThemeControllerProvider).isDark;
    const amberColor = Color(0xFFFFB300);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF030D1B).withValues(alpha: 0.97) : const Color(0xFFF0F9FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: amberColor.withValues(alpha: 0.45),
          width: 1.3,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, mediaQuery.viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: amberColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: amberColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: amberColor.withValues(alpha: 0.45)),
                      ),
                      child: const Icon(LucideIcons.crown, color: amberColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'owner.staff.owner_credentials_title'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'owner.staff.owner_credentials_subtitle'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : const Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: amberColor.withValues(alpha: 0.35)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.userCheck, color: amberColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'owner.staff.login_label'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextField(
                              controller: _loginController,
                              autocorrect: false,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: amberColor.withValues(alpha: 0.35)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.lock, color: amberColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'owner.staff.password_label'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              autocorrect: false,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 18,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _generatePassword,
                      icon: const Icon(LucideIcons.sparkles, size: 15, color: amberColor),
                      label: Text(
                        'owner.staff.generate_password_btn'.tr(),
                        style: const TextStyle(color: amberColor, fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _loginController.text = 'owner';
                          _passwordController.text = '1';
                        });
                      },
                      icon: const Icon(LucideIcons.rotateCcw, size: 14, color: Colors.white60),
                      label: Text(
                        'owner.staff.reset_password_1_btn'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amberColor,
                      foregroundColor: const Color(0xFF090E18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _save,
                    icon: const Icon(LucideIcons.save, size: 18),
                    label: Text(
                      'owner.salary_sheet.save_settings'.tr(),
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
