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

  const EditCoachSheet({
    super.key,
    required this.coachId,
    required this.initialName,
    required this.initialPhone,
  });

  @override
  ConsumerState<EditCoachSheet> createState() => _EditCoachSheetState();
}

class _EditCoachSheetState extends ConsumerState<EditCoachSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

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
    
    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.coachId);

      await userRef.update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }).timeout(const Duration(seconds: 5));

      if (mounted) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Оновлено дані тренера "${_nameController.text.trim()}"', admin.id);
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF030D1B).withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: SingleChildScrollView(
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
                      const Icon(LucideIcons.edit2, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Text('admin.edit_coach_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
        ),
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
}
