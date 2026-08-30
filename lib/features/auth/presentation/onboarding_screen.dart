import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _childNameController = TextEditingController();
  final _childAgeController = TextEditingController();

  bool _addChild = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider);
    _nameController = TextEditingController(text: user?.name == 'New User' ? '' : user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _childNameController.dispose();
    _childAgeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).completeOnboarding(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        childName: _addChild ? _childNameController.text.trim() : null,
        childAge: _addChild ? _childAgeController.text.trim() : null,
      );
      if (mounted) {
        context.go('/parent');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка реєстрації: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/new_background.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: const Color(0xFF003B73)),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF001F3F).withValues(alpha: 0.8),
                  const Color(0xFF001F3F).withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Вітаємо!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
                            const SizedBox(height: 8),
                            Text(
                              'Розкажіть трохи про себе',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                            const SizedBox(height: 32),
                            
                            _buildTextField(
                              controller: _nameController,
                              icon: LucideIcons.user,
                              hint: 'Ваше ім\'я та прізвище',
                              validator: (v) => v == null || v.isEmpty ? 'Введіть ім\'я' : null,
                            ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: 0.1, end: 0),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _phoneController,
                              icon: LucideIcons.phone,
                              hint: 'Номер телефону',
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty ? 'Введіть телефон' : null,
                            ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideX(begin: 0.1, end: 0),
                            
                            const SizedBox(height: 24),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.baby, color: AppTheme.primaryBlue, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'Додати дитину?',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Switch(
                                    value: _addChild,
                                    activeColor: AppTheme.primaryBlue,
                                    onChanged: (v) => setState(() => _addChild = v),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideX(begin: 0.1, end: 0),
                            
                            if (_addChild) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _childNameController,
                                icon: LucideIcons.user,
                                hint: 'Ім\'я дитини',
                                validator: (v) => v == null || v.isEmpty ? 'Введіть ім\'я дитини' : null,
                              ).animate().fadeIn(duration: 400.ms),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _childAgeController,
                                icon: LucideIcons.calendar,
                                hint: 'Вік дитини (років)',
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty ? 'Введіть вік' : null,
                              ).animate().fadeIn(duration: 400.ms),
                            ],
                            
                            const SizedBox(height: 40),
                            
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Завершити реєстрацію',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                              ),
                            ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 28),
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (mounted) context.go('/');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
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
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
