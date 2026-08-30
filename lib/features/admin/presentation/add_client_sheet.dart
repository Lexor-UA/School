import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddClientSheet extends StatefulWidget {
  const AddClientSheet({super.key});

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _childNameController = TextEditingController();
  String _selectedGroup = 'Юніори (Батерфляй)';
  bool _isSuccess = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _generatedLogin;

  final List<String> _groups = [
    'Юніори (Батерфляй)',
    'Малюки (Основи)',
    'Підлітки Pro',
    'Дорослі',
  ];

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _childNameController.text.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Generate ClientX login
      final usersSnap = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'parent')
          .get()
          .timeout(const Duration(seconds: 5));
          
      final clientCount = usersSnap.docs.length + 1;
      final generatedLogin = 'client$clientCount';

      final userRef = FirebaseFirestore.instance.collection('users').doc();
      final childRef = FirebaseFirestore.instance.collection('children').doc();

      await userRef.set({
        'id': userRef.id,
        'name': _nameController.text,
        'role': 'parent',
        'phone': _phoneController.text,
        'loginId': generatedLogin,
        'avatarUrl': '',
      }).timeout(const Duration(seconds: 5));

      await childRef.set({
        'id': childRef.id,
        'parentId': userRef.id,
        'name': _childNameController.text,
        'colorHex': '0xFF40C4FF',
        'level': 1,
        'xp': 0,
        'maxXp': 100,
      }).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _generatedLogin = 'Client$clientCount';
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
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.4), blurRadius: 30)],
          ),
          child: const Icon(LucideIcons.check, color: Colors.greenAccent, size: 60),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text(
          'Клієнта додано!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          '${_nameController.text} та дитина ${_childNameController.text}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text('Дані для входу клієнта:', style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Логін: ${_generatedLogin ?? ""}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Пароль: 1', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFormState() {
    return Column(
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
        const Row(
          children: [
            Icon(LucideIcons.userPlus, color: Colors.cyanAccent),
            SizedBox(width: 12),
            Text('Новий Клієнт', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextField('Ім\'я та Прізвище', LucideIcons.user, _nameController),
        const SizedBox(height: 16),
        _buildTextField('Номер телефону', LucideIcons.phone, _phoneController, isNumber: true),
        const SizedBox(height: 16),
        _buildTextField('Ім\'я дитини', LucideIcons.baby, _childNameController),
        const SizedBox(height: 24),
        const Text('Група', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _groups.map((group) {
            final isSelected = group == _selectedGroup;
            return GestureDetector(
              onTap: () => setState(() => _selectedGroup = group),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  group,
                  style: TextStyle(
                    color: isSelected ? Colors.cyanAccent : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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
                : const Text('Зберегти', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
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
