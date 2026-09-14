import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class EditCoachSheet extends ConsumerStatefulWidget {
  final String coachId;
  final String initialName;
  final String initialPhone;
  final int initialRateGroup;
  final int initialRateIndividual;
  final int initialRateSplit;

  const EditCoachSheet({
    super.key,
    required this.coachId,
    required this.initialName,
    required this.initialPhone,
    this.initialRateGroup = 400,
    this.initialRateIndividual = 450,
    this.initialRateSplit = 600,
  });

  @override
  ConsumerState<EditCoachSheet> createState() => _EditCoachSheetState();
}

class _EditCoachSheetState extends ConsumerState<EditCoachSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _rateGroupController;
  late TextEditingController _rateIndividualController;
  late TextEditingController _rateSplitController;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _rateGroupController = TextEditingController(
      text: widget.initialRateGroup > 0 ? widget.initialRateGroup.toString() : '400',
    );
    _rateIndividualController = TextEditingController(
      text: widget.initialRateIndividual > 0 ? widget.initialRateIndividual.toString() : '450',
    );
    _rateSplitController = TextEditingController(
      text: widget.initialRateSplit > 0 ? widget.initialRateSplit.toString() : '600',
    );
  }

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
    
    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final rateGroup = int.tryParse(_rateGroupController.text.trim()) ?? 0;
    final rateIndividual = int.tryParse(_rateIndividualController.text.trim()) ?? 0;
    final rateSplit = int.tryParse(_rateSplitController.text.trim()) ?? 0;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.coachId);

      await userRef.update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'rateGroup': rateGroup,
        'rateIndividual': rateIndividual,
        'rateSplit': rateSplit,
      }).timeout(const Duration(seconds: 5));

      if (mounted) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Оновлено дані та ставки тренера "${_nameController.text.trim()}" (Група: $rateGroup ₴, Інд: $rateIndividual ₴, Спліт: $rateSplit ₴)', admin.id);
        }

        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('admin.edit_coach_success'.tr(), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
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

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF030D1B).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 32,
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
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, mediaQuery.viewInsets.bottom + 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('admin.add_client_name_hint'.tr(), LucideIcons.user, _nameController),
                      const SizedBox(height: 14),
                      _buildTextField('admin.add_client_phone_hint'.tr(), LucideIcons.phone, _phoneController, isNumber: true),
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
                          const Text(
                            'Ставки заробітної плати (ЗП)',
                            style: TextStyle(
                              color: Colors.white,
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
                      ),
                      const SizedBox(height: 10),
                      _buildRateField(
                        label: 'Індивідуальне тренування (грн / заняття)',
                        icon: LucideIcons.user,
                        controller: _rateIndividualController,
                        color: const Color(0xFFA855F7),
                      ),
                      const SizedBox(height: 10),
                      _buildRateField(
                        label: 'Спліт-тренування (2 учні) (грн / заняття)',
                        icon: LucideIcons.userCheck,
                        controller: _rateSplitController,
                        color: const Color(0xFFF59E0B),
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
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 10,
                        shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('admin.add_coach_save_btn'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _buildHeader(BuildContext context) {
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
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(LucideIcons.edit2, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'admin.edit_coach_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.blueAccent.withValues(alpha: 0.7)),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
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
              '₴ / зан',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
