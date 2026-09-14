import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

        await userRef.update({
          'rateGroup': rateGroup,
          'rateIndividual': rateIndividual,
          'rateSplit': rateSplit,
        }).timeout(const Duration(seconds: 5));

        final owner = ref.read(authControllerProvider);
        if (owner != null) {
          await logAdminAction(
            'Власник оновив тарифи тренера "${widget.name}": Група $rateGroup ₴, Інд $rateIndividual ₴, Спліт $rateSplit ₴',
            owner.id,
          );
        }
      } else {
        final adminSalary = int.tryParse(_adminSalaryController.text.trim()) ?? 20000;

        await userRef.update({
          'adminSalary': adminSalary,
          'salaryType': 'monthly',
        }).timeout(const Duration(seconds: 5));

        final owner = ref.read(authControllerProvider);
        if (owner != null) {
          await logAdminAction(
            'Власник оновив оклад адміністратора "${widget.name}": $adminSalary ₴ / міс',
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

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF030D1B).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
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
              _buildHeader(context, isCoach),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, mediaQuery.viewInsets.bottom + 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Staff Identity Card
                      _buildStaffIdentityCard(isCoach),

                      const SizedBox(height: 24),

                      if (isCoach) ...[
                        // Coach Rate Section
                        _buildSectionHeader(
                          icon: LucideIcons.banknote,
                          title: 'Тарифна сітка тренера (ЗП)',
                          subtitle: 'Встановіть винагороду за кожне проведене тренування',
                          color: const Color(0xFF00E5FF),
                        ),
                        const SizedBox(height: 14),
                        _buildRateField(
                          label: 'Групове тренування (грн / зан)',
                          icon: LucideIcons.users,
                          controller: _rateGroupController,
                          color: const Color(0xFF00E5FF),
                        ),
                        const SizedBox(height: 12),
                        _buildRateField(
                          label: 'Індивідуальне тренування (грн / зан)',
                          icon: LucideIcons.user,
                          controller: _rateIndividualController,
                          color: const Color(0xFFA855F7),
                        ),
                        const SizedBox(height: 12),
                        _buildRateField(
                          label: 'Спліт-тренування (2 учні) (грн / зан)',
                          icon: LucideIcons.userCheck,
                          controller: _rateSplitController,
                          color: const Color(0xFFF59E0B),
                        ),
                      ] else ...[
                        // Admin Salary Section
                        _buildSectionHeader(
                          icon: LucideIcons.shieldCheck,
                          title: 'Фіксована ставка адміністратора',
                          subtitle: 'Щомісячний оклад співробітника',
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 14),
                        _buildRateField(
                          label: 'Фіксований оклад (грн / місяць)',
                          icon: LucideIcons.wallet,
                          controller: _adminSalaryController,
                          color: const Color(0xFF10B981),
                          unit: '₴ / міс',
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
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981),
                            foregroundColor: const Color(0xFF041221),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.4),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
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

  Widget _buildHeader(BuildContext context, bool isCoach) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
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
                color: Colors.white.withValues(alpha: 0.30),
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
                      color: (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.badgePercent,
                      color: isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Тарифи та оплата праці',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffIdentityCard(bool isCoach) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCoach
                    ? [const Color(0xFF00E5FF), const Color(0xFF0077B6)]
                    : [const Color(0xFF10B981), const Color(0xFF047857)],
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
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981)).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isCoach ? 'ТРЕНЕР' : 'АДМІНІСТРАТОР',
                        style: TextStyle(
                          color: isCoach ? const Color(0xFF00E5FF) : const Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.phone.isNotEmpty ? widget.phone : widget.loginId,
                        style: const TextStyle(color: Colors.white54, fontSize: 11.5),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
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
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white24),
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
              unit,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
