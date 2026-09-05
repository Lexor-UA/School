import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class AddClientSheet extends ConsumerStatefulWidget {
  const AddClientSheet({super.key});

  @override
  ConsumerState<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends ConsumerState<AddClientSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _childrenControllers = [];
  
  bool _isSuccess = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _generatedLogin;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (var controller in _childrenControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addChildField() {
    setState(() {
      _childrenControllers.add(TextEditingController());
    });
  }

  void _removeChildField(int index) {
    setState(() {
      _childrenControllers[index].dispose();
      _childrenControllers.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final validChildren = _childrenControllers.where((c) => c.text.trim().isNotEmpty).toList();
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Будь ласка, заповніть ім\'я та телефон.';
      });
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

      await userRef.set({
        'id': userRef.id,
        'name': _nameController.text.trim(),
        'role': 'parent',
        'phone': _phoneController.text.trim(),
        'loginId': generatedLogin,
        'avatarUrl': '',
      }).timeout(const Duration(seconds: 5));

      for (var childController in validChildren) {
        final childRef = FirebaseFirestore.instance.collection('children').doc();
        await childRef.set({
          'id': childRef.id,
          'parentId': userRef.id,
          'name': childController.text.trim(),
          'colorHex': '0xFF40C4FF',
          'level': 1,
          'xp': 0,
          'maxXp': 100,
        }).timeout(const Duration(seconds: 5));
      }

      if (mounted) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Додано нового клієнта "${_nameController.text.trim()}" ($generatedLogin)', admin.id);
        }
        ref.invalidate(adminDashboardProvider);
        setState(() {
          _isSuccess = true;
          _isLoading = false;
          _generatedLogin = generatedLogin;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Помилка збереження: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF13233C).withValues(alpha: 0.98),
            const Color(0xFF091424).withValues(alpha: 0.99),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              mediaQuery.viewInsets.bottom + 24,
            ),
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
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF047857)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.50),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Center(
            child: Icon(LucideIcons.check, color: Colors.white, size: 36),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        const Text(
          'Клієнта успішно створено!',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 6),
        Text(
          _nameController.text,
          style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.40)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Дані для входу в кабінет:', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'Логін: ${_generatedLogin ?? ""}\nПароль: 1'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Дані входу скопійовано!'), duration: Duration(seconds: 2)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.copy, color: Color(0xFF00E5FF), size: 12),
                          SizedBox(width: 4),
                          Text('Копіювати', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Логін: ${_generatedLogin ?? ""}', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16, fontWeight: FontWeight.bold)),
                  Container(width: 1, height: 16, color: Colors.white24),
                  const Text('Пароль: 1', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Готово', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
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
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.userPlus, color: Colors.white, size: 21),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Новий Клієнт',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Швидка реєстрація батьків та учнів',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(LucideIcons.x, color: Colors.white70, size: 17),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildTextField('Ім\'я та Прізвище', LucideIcons.user, _nameController),
          const SizedBox(height: 14),
          _buildTextField('Номер телефону', LucideIcons.phone, _phoneController, isNumber: true),
          const SizedBox(height: 20),
          
          if (_childrenControllers.isNotEmpty) ...[
            const Row(
              children: [
                Icon(LucideIcons.baby, color: Color(0xFF00E5FF), size: 16),
                SizedBox(width: 8),
                Text('Діти / Учні', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          
          ...List.generate(_childrenControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField('Ім\'я дитини', LucideIcons.baby, _childrenControllers[index]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.35)),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(LucideIcons.trash2, color: Color(0xFFF43F5E), size: 18),
                      onPressed: () => _removeChildField(index),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _addChildField,
              icon: const Icon(LucideIcons.plus, color: Color(0xFF00E5FF), size: 16),
              label: Text(
                _childrenControllers.isEmpty ? 'Додати дитину' : 'Додати ще дитину',
                style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.40)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Color(0xFFF43F5E), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 12),
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
                  color: const Color(0xFF00B4D8).withValues(alpha: 0.45),
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
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.userCheck, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Зберегти клієнта',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13.5),
          prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}
