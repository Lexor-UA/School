import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class AddCoachSheet extends ConsumerStatefulWidget {
  const AddCoachSheet({super.key});

  @override
  ConsumerState<AddCoachSheet> createState() => _AddCoachSheetState();
}

class _AddCoachSheetState extends ConsumerState<AddCoachSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isSuccess = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _generatedLogin;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
      // Generate coach login
      final usersSnap = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'coach')
          .get()
          .timeout(const Duration(seconds: 5));
          
      final coachCount = usersSnap.docs.length + 1;
      final generatedLogin = 'coach$coachCount';

      final userRef = FirebaseFirestore.instance.collection('users').doc();

      await userRef.set({
        'id': userRef.id,
        'name': _nameController.text.trim(),
        'role': 'coach',
        'phone': _phoneController.text.trim(),
        'loginId': generatedLogin,
        'avatarUrl': '',
      }).timeout(const Duration(seconds: 5));

      if (mounted) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Додано нового тренера "${_nameController.text.trim()}"', admin.id);
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF030D1B).withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: _isSuccess ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: const Icon(LucideIcons.check, color: Colors.greenAccent, size: 48),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          'admin.add_coach_success_title'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          _nameController.text,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Text('admin.add_client_credentials_title'.tr().toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.user, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 12),
                  Text('admin.clients_login_label'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(_generatedLogin ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.key, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 12),
                  Text('admin.clients_password_label'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(width: 6),
                  const Text('1', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(LucideIcons.userPlus, color: Colors.cyanAccent),
              const SizedBox(width: 12),
              Text('admin.add_coach_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField('admin.add_client_name_hint'.tr(), LucideIcons.user, _nameController),
          const SizedBox(height: 16),
          _buildTextField('admin.add_client_phone_hint'.tr(), LucideIcons.phone, _phoneController, isNumber: true),
          const SizedBox(height: 32),
          
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
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
                shadowColor: Colors.cyanAccent.withValues(alpha: 0.5),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text('admin.add_coach_save_btn'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
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
          prefixIcon: Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
