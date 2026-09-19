import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController _phoneController;
  final _ageController = TextEditingController();
  final List<_ChildEntry> _children = [];

  bool _isAdultOnly = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider);
    _nameController = TextEditingController(text: user?.name == 'New User' ? '' : user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _children.add(_ChildEntry());
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
    final childrenData = _isAdultOnly
        ? null
        : _children
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
        isAdultOnly: _isAdultOnly,
        children: childrenData != null && childrenData.isNotEmpty ? childrenData : null,
      );
      if (mounted) {
        context.go('/parent');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('onboarding.registration_error'.tr(args: [e.toString()])),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
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
                  const Color(0xFF001F3F).withValues(alpha: 0.96),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C223C).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
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
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
                            const SizedBox(height: 6),
                            Text(
                              'onboarding.tell_about_yourself'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 14.5,
                              ),
                            ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                            const SizedBox(height: 24),
                            
                            // Adult vs Children Segmented Switcher
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isAdultOnly = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: _isAdultOnly
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              LucideIcons.user,
                                              size: 16,
                                              color: _isAdultOnly ? Colors.white : Colors.white70,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Я плаваю сам',
                                              style: TextStyle(
                                                color: _isAdultOnly ? Colors.white : Colors.white70,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isAdultOnly = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: !_isAdultOnly
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              LucideIcons.baby,
                                              size: 16,
                                              color: !_isAdultOnly ? Colors.white : Colors.white70,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Для моїх дітей',
                                              style: TextStyle(
                                                color: !_isAdultOnly ? Colors.white : Colors.white70,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                            const SizedBox(height: 20),

                            _buildTextField(
                              controller: _nameController,
                              icon: LucideIcons.user,
                              hint: 'onboarding.name_hint'.tr(),
                              validator: (v) => v == null || v.trim().isEmpty ? 'onboarding.name_error'.tr() : null,
                            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                            
                            const SizedBox(height: 14),
                            
                            _buildTextField(
                              controller: _phoneController,
                              icon: LucideIcons.phone,
                              hint: 'onboarding.phone_hint'.tr(),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty ? 'onboarding.phone_error'.tr() : null,
                            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                            
                            const SizedBox(height: 14),

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
                            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                            
                            const SizedBox(height: 22),

                            // Children Section or Adult Note
                            if (_isAdultOnly) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                      ),
                                      child: const Icon(LucideIcons.sparkles, color: Color(0xFF00E5FF), size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Дорослий плавець',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Кабінет буде налаштовано для ваших індивідуальних та групових занять.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms),
                            ] else ...[
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
                                            'Дитина ${index + 1}',
                                            style: const TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          if (_children.length > 1)
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
                                        hint: '${'onboarding.child_age_hint'.tr()} (1-17)',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(2),
                                        ],
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'onboarding.child_age_error'.tr();
                                          final a = int.tryParse(v.trim());
                                          if (a == null || a < 1 || a > 17) return 'Вік дитини має бути від 1 до 17 років';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // Add Child Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _addChild,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                                        const Icon(LucideIcons.plus, color: Color(0xFF00E5FF), size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'onboarding.add_more_child_btn'.tr().replaceFirst(RegExp(r'^\+\s*'), ''),
                                          style: const TextStyle(
                                            color: Color(0xFF00E5FF),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 28),
                            
                            // Submit Button
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'onboarding.complete_registration'.tr(),
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
