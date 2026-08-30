import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EditClientSheet extends StatefulWidget {
  final String clientId;
  final String initialName;
  final String initialPhone;
  final String initialLoginId;

  const EditClientSheet({
    super.key,
    required this.clientId,
    required this.initialName,
    required this.initialPhone,
    required this.initialLoginId,
  });

  @override
  State<EditClientSheet> createState() => _EditClientSheetState();
}

class _EditClientSheetState extends State<EditClientSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _loginIdController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _loginIdController = TextEditingController(text: widget.initialLoginId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _loginIdController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty || _loginIdController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Заповніть всі поля');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.clientId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'loginId': _loginIdController.text.trim(),
      }).timeout(const Duration(seconds: 5));

      if (mounted) {
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
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark slate
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Row(
              children: [
                const Icon(LucideIcons.edit2, color: Colors.blueAccent),
                const SizedBox(width: 12),
                const Text(
                  'Редагувати клієнта',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_isSuccess)
              _buildSuccessState()
            else
              _buildFormState(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Ім\'я та Прізвище',
          icon: LucideIcons.user,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _phoneController,
          label: 'Номер телефону',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _loginIdController,
          label: 'Логін для входу (наприклад, Client1)',
          icon: LucideIcons.key,
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
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
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Зберегти зміни', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Icon(LucideIcons.checkCircle, color: Colors.greenAccent, size: 64).animate().scale().fadeIn(),
        const SizedBox(height: 24),
        const Text(
          'Дані оновлено!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}
