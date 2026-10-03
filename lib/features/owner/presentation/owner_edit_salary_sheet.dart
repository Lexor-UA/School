import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class OwnerEditSalarySheet extends ConsumerStatefulWidget {
  final String staffId;
  final String name;
  final String role; // 'coach' or 'admin'
  final String phone;
  final String loginId;
  final int initialRateGroup;
  final int initialRateIndividual;
  final int initialRateSplit;
  final int initialAdminSalary;
  final String currencySymbol;

  const OwnerEditSalarySheet({
    super.key,
    required this.staffId,
    required this.name,
    required this.role,
    required this.phone,
    required this.loginId,
    this.initialRateGroup = 400,
    this.initialRateIndividual = 450,
    this.initialRateSplit = 600,
    this.initialAdminSalary = 20000,
    this.currencySymbol = '₴',
  });

  @override
  ConsumerState<OwnerEditSalarySheet> createState() => _OwnerEditSalarySheetState();
}

class _OwnerEditSalarySheetState extends ConsumerState<OwnerEditSalarySheet> {
  late TextEditingController _rateGroupController;
  late TextEditingController _rateIndividualController;
  late TextEditingController _rateSplitController;
  late TextEditingController _adminSalaryController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rateGroupController = TextEditingController(
      text: widget.initialRateGroup > 0 ? widget.initialRateGroup.toString() : '400',
    );
    _rateIndividualController = TextEditingController(
      text: widget.initialRateIndividual > 0 ? widget.initialRateIndividual.toString() : '450',
    );
    _rateSplitController = TextEditingController(
      text: widget.initialRateSplit > 0 ? widget.initialRateSplit.toString() : '600',
    );
    _adminSalaryController = TextEditingController(
      text: widget.initialAdminSalary > 0 ? widget.initialAdminSalary.toString() : '20000',
    );
  }

  @override
  void dispose() {
    _rateGroupController.dispose();
    _rateIndividualController.dispose();
    _rateSplitController.dispose();
    _adminSalaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.staffId);
      final isCoach = widget.role == 'coach';

      if (isCoach) {
        final rateGroup = int.tryParse(_rateGroupController.text.trim()) ?? 400;
        final rateIndividual = int.tryParse(_rateIndividualController.text.trim()) ?? 450;
        final rateSplit = int.tryParse(_rateSplitController.text.trim()) ?? 600;

        await userRef.set({
          'rateGroup': rateGroup,
          'rateIndividual': rateIndividual,
          'rateSplit': rateSplit,
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 15));

        final owner = ref.read(authControllerProvider);
        if (owner != null) {
          await logAdminAction(
            'Власник оновив тарифи тренера "${widget.name}": Група $rateGroup ₴, Інд $rateIndividual ₴, Спліт $rateSplit ₴',
            owner.id,
          );
        }
      } else {
        final adminSalary = int.tryParse(_adminSalaryController.text.trim()) ?? 20000;

        await userRef.set({
          'adminSalary': adminSalary,
          'salaryType': 'monthly',
          'role': 'admin',
          if (widget.staffId == 'admin' || widget.staffId == 'admin_vienna') ...{
            'name': widget.staffId == 'admin' ? 'Адміністратор' : 'Admin Vienna',
            'branchId': widget.staffId == 'admin' ? 'kyiv' : 'vienna',
            'phone': widget.staffId == 'admin' ? '+380 (99) 000-00-01' : '+43 1 234 5678',
            'loginId': widget.staffId == 'admin' ? 'Admin' : 'vienna.admin@cityswim.at',
            'currency': widget.staffId == 'admin' ? '₴' : '€',
            'avatarUrl': widget.staffId == 'admin' 
                ? 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff' 
                : 'https://ui-avatars.com/api/?name=Admin+Vienna&background=8b5cf6&color=ffffff',
          }
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 15));

        final owner = ref.read(authControllerProvider);
        if (owner != null) {
          await logAdminAction(
            'Власник оновив оклад адміністратора "${widget.name}": $adminSalary ${widget.currencySymbol} / міс',
            owner.id,
          );
        }
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
                  child: Text(
                    isCoach
                        ? 'Тарифи тренера успішно збережено!'
                        : 'Оклад адміністратора успішно збережено!',
                  ),
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
    final maxHeight = mediaQuery.size.height * 0.90;
    final isCoach = widget.role == 'coach';
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF030D1B).withValues(alpha: 0.96) : const Color(0xFFF0F9FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark
              ? (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.35)
              : const Color(0xFFBAE6FD),
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
              _buildHeader(context, isCoach, isDark, themeConfig),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, mediaQuery.viewInsets.bottom + 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Staff Identity Card
                      _buildStaffIdentityCard(isCoach, isDark, themeConfig),

                      const SizedBox(height: 24),

                      if (isCoach) ...[
                        // Coach Rate Section
                        _buildSectionHeader(
                          icon: LucideIcons.banknote,
                          title: 'Тарифна сітка тренера (ЗП)',
                          subtitle: 'Встановіть винагороду за кожне проведене тренування',
                          color: const Color(0xFF00E5FF),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildRateField(
                          label: 'Групове тренування (${widget.currencySymbol} / зан)',
                          icon: LucideIcons.users,
                          controller: _rateGroupController,
                          color: const Color(0xFF00E5FF),
                          unit: '${widget.currencySymbol} / зан',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildRateField(
                          label: 'Індивідуальне тренування (${widget.currencySymbol} / зан)',
                          icon: LucideIcons.user,
                          controller: _rateIndividualController,
                          color: const Color(0xFFA855F7),
                          unit: '${widget.currencySymbol} / зан',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildRateField(
                          label: 'Спліт-тренування (2 учні) (${widget.currencySymbol} / зан)',
                          icon: LucideIcons.userCheck,
                          controller: _rateSplitController,
                          color: const Color(0xFFF59E0B),
                          unit: '${widget.currencySymbol} / зан',
                          isDark: isDark,
                        ),
                      ] else ...[
                        // Admin Salary Section
                        _buildSectionHeader(
                          icon: LucideIcons.shieldCheck,
                          title: 'Фіксована ставка адміністратора',
                          subtitle: 'Щомісячний оклад співробітника',
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildRateField(
                          label: 'Фіксований оклад (${widget.currencySymbol} / місяць)',
                          icon: LucideIcons.wallet,
                          controller: _adminSalaryController,
                          color: const Color(0xFF10B981),
                          unit: '${widget.currencySymbol} / міс',
                          isDark: isDark,
                        ),
                      ],

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
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Save Button
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: isCoach
                              ? (isDark
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF0284C7), Color(0xFF00E5FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ))
                              : (isDark
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (isCoach ? const Color(0xFF0284C7) : const Color(0xFF059669))
                                  .withValues(alpha: isDark ? 0.4 : 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981))
                                : Colors.transparent,
                            foregroundColor: isDark ? const Color(0xFF041221) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: isDark ? 8 : 0,
                            shadowColor: isDark
                                ? (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: isDark ? Colors.black : Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Зберегти налаштування',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3),
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

  Widget _buildHeader(BuildContext context, bool isCoach, bool isDark, AppThemeConfig themeConfig) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
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
                color: isDark ? Colors.white.withValues(alpha: 0.30) : const Color(0xFF94A3B8),
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
                      color: isDark
                          ? (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.15)
                          : (isCoach ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.35)
                            : (isCoach ? const Color(0xFFBAE6FD) : const Color(0xFF86EFAC)),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.badgePercent,
                      color: isCoach
                          ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                          : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Тарифи та оплата праці',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFBAE6FD),
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: const Color(0xFF003B73).withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Center(
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

  Widget _buildStaffIdentityCard(bool isCoach, bool isDark, AppThemeConfig themeConfig) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFBAE6FD)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF003B73).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCoach
                    ? (isDark ? [const Color(0xFF00E5FF), const Color(0xFF0077B6)] : [const Color(0xFF06B6D4), const Color(0xFF0284C7)])
                    : (isDark ? [const Color(0xFF10B981), const Color(0xFF047857)] : [const Color(0xFF10B981), const Color(0xFF059669)]),
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCoach
                            ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.16) : const Color(0xFFE0F2FE))
                            : (isDark ? const Color(0xFF10B981).withValues(alpha: 0.16) : const Color(0xFFDCFCE7)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCoach
                              ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : const Color(0xFFBAE6FD))
                              : (isDark ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFF86EFAC)),
                        ),
                      ),
                      child: Text(
                        isCoach ? 'ТРЕНЕР' : 'АДМІНІСТРАТОР',
                        style: TextStyle(
                          color: isCoach
                              ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                              : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.phone.isNotEmpty ? widget.phone : widget.loginId,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    final effectiveColor = color == const Color(0xFF00E5FF)
        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
        : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? color.withValues(alpha: 0.15)
                    : (color == const Color(0xFF00E5FF) ? const Color(0xFFE0F2FE) : color.withValues(alpha: 0.10)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? color.withValues(alpha: 0.3)
                      : (color == const Color(0xFF00E5FF) ? const Color(0xFFBAE6FD) : color.withValues(alpha: 0.25)),
                ),
              ),
              child: Icon(icon, color: effectiveColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRateField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
    String unit = '₴ / зан',
    required bool isDark,
  }) {
    final effectiveColor = color == const Color(0xFF00E5FF)
        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
        : color;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.3) : const Color(0xFFBAE6FD),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF003B73).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.14)
                  : (color == const Color(0xFF00E5FF) ? const Color(0xFFE0F2FE) : color.withValues(alpha: 0.10)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: effectiveColor, size: 18),
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
                    color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.15)
                  : (color == const Color(0xFF00E5FF) ? const Color(0xFFE0F2FE) : color.withValues(alpha: 0.10)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? color.withValues(alpha: 0.35)
                    : (color == const Color(0xFF00E5FF) ? const Color(0xFFBAE6FD) : color.withValues(alpha: 0.25)),
              ),
            ),
            child: Text(
              unit,
              style: TextStyle(
                color: effectiveColor,
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
