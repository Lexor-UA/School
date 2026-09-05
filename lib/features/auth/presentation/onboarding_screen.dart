import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _ChildEntry {
  final TextEditingController nameController;
  final TextEditingController ageController;
  _ChildEntry({String? name, String? age})
      : nameController = TextEditingController(text: name),
        ageController = TextEditingController(text: age);

  void dispose() {
    nameController.dispose();
    ageController.dispose();
  }
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final List<_ChildEntry> _children = [];

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
    _ageController.dispose();
    for (var child in _children) {
      child.dispose();
    }
    super.dispose();
  }

  void _addChild() {
    setState(() {
      _children.add(_ChildEntry());
    });
  }

  void _removeChild(int index) {
    setState(() {
      _children[index].dispose();
      _children.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final clientAge = int.tryParse(_ageController.text.trim());
    final childrenData = _children
        .where((c) => c.nameController.text.trim().isNotEmpty)
        .map((c) => {
              'name': c.nameController.text.trim(),
              'age': int.tryParse(c.ageController.text.trim()),
            })
        .toList();

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).completeOnboarding(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        age: clientAge,
        children: childrenData.isNotEmpty ? childrenData : null,
      );
      if (mounted) {
        context.go('/parent');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('onboarding.registration_error'.tr(args: [e.toString()]))),
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
                            Text(
                              'onboarding.welcome'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
                            const SizedBox(height: 8),
                            Text(
                              'onboarding.tell_about_yourself'.tr(),
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
                              hint: 'onboarding.name_hint'.tr(),
                              validator: (v) => v == null || v.trim().isEmpty ? 'onboarding.name_error'.tr() : null,
                            ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: 0.1, end: 0),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _phoneController,
                              icon: LucideIcons.phone,
                              hint: 'onboarding.phone_hint'.tr(),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty ? 'onboarding.phone_error'.tr() : null,
                            ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideX(begin: 0.1, end: 0),
                            
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _ageController,
                              icon: LucideIcons.calendar,
                              hint: 'onboarding.age_hint'.tr(),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'onboarding.age_error'.tr();
                                final age = int.tryParse(v.trim());
                                if (age == null || age < 14 || age > 110) return 'onboarding.age_error'.tr();
                                return null;
                              },
                            ).animate().fadeIn(delay: 550.ms, duration: 600.ms).slideX(begin: 0.1, end: 0),
                            
                            const SizedBox(height: 24),

                            // Children Section
                            if (_children.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(LucideIcons.baby, color: Color(0xFF00E5FF), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'onboarding.children_title'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_children.length, (index) {
                                final child = _children[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${'parent.child_name'.tr().replaceAll("Ім'я дитини", "Дитина")} ${index + 1}',
                                            style: const TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _removeChild(index),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _buildTextField(
                                        controller: child.nameController,
                                        icon: LucideIcons.baby,
                                        hint: 'onboarding.child_name_hint'.tr(),
                                        validator: (v) => v == null || v.trim().isEmpty ? 'onboarding.child_name_error'.tr() : null,
                                      ),
                                      const SizedBox(height: 10),
                                      _buildTextField(
                                        controller: child.ageController,
                                        icon: LucideIcons.calendarDays,
                                        hint: 'onboarding.child_age_hint'.tr(),
                                        keyboardType: TextInputType.number,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'onboarding.child_age_error'.tr();
                                          final a = int.tryParse(v.trim());
                                          if (a == null || a < 1 || a > 25) return 'onboarding.child_age_error'.tr();
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],

                            // Add Child Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _addChild,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.baby, color: Color(0xFF00E5FF), size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        _children.isEmpty
                                            ? 'onboarding.add_child_btn'.tr()
                                            : 'onboarding.add_more_child_btn'.tr(),
                                        style: const TextStyle(
                                          color: Color(0xFF00E5FF),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                            const SizedBox(height: 32),
                            
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
                                    : Text(
                                        'onboarding.complete_registration'.tr(),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                              ),
                            ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
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
                  final router = GoRouter.of(context);
                  await ref.read(authControllerProvider.notifier).logout();
                  if (mounted) router.go('/');
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
