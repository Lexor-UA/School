import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class GraduateChildSheet extends ConsumerStatefulWidget {
  final Child child;

  const GraduateChildSheet({
    super.key,
    required this.child,
  });

  static Future<bool?> show(BuildContext context, Child child) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (context) => GraduateChildSheet(child: child),
    );
  }

  @override
  ConsumerState<GraduateChildSheet> createState() => _GraduateChildSheetState();
}

class _GraduateChildSheetState extends ConsumerState<GraduateChildSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: '1');
  bool _obscurePassword = true;
  bool _transferSubscriptions = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatAge(int age) {
    if (age % 10 == 1 && age % 100 != 11) return '$age рік';
    if (age % 10 >= 2 && age % 10 <= 4 && (age % 100 < 10 || age % 100 >= 20)) {
      return '$age роки';
    }
    return '$age років';
  }

  int _calculateRemainingChildSessions(WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionControllerProvider);
    final user = ref.watch(authControllerProvider);
    final family = ref.watch(familyStreamProvider).value;
    final relevantUserIds = <String>{
      if (user != null) user.id,
      if (family != null) ...family.parentIds,
    };

    int sum = 0;
    for (final sub in subscriptions) {
      if (sub.isActive && relevantUserIds.contains(sub.userId) && sub.isChildSubscription) {
        sum += sub.remainingClasses;
      }
    }
    return sum;
  }

  Future<void> _submit() async {
    final rawPhone = _phoneController.text.trim();
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 9) {
      setState(() {
        _errorMessage = 'Введіть коректний номер телефону (наприклад: 067 123 45 67)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(childrenControllerProvider.notifier).graduateChildToAdult(
            childId: widget.child.id,
            teenPhone: rawPhone,
            password: _passwordController.text.trim(),
            transferRemainingSubscriptions: _transferSubscriptions,
          );

      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    final textColor = themeConfig.textPrimary;
    final textSubColor = themeConfig.textSecondary;
    final accentColor = themeConfig.accentPrimary;

    final childColor = Color(int.tryParse(widget.child.colorHex) ?? 0xFF00E5FF);
    final ageText = widget.child.currentAge != null
        ? _formatAge(widget.child.currentAge!)
        : '16 років';
    final remainingChildSessions = _calculateRemainingChildSessions(ref);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1929) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 36,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Content or Success View
              Flexible(
                child: _isSuccess
                    ? _buildSuccessView(context, isDark, textColor, textSubColor)
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Header with Graduation Badge
                            _buildHeader(isDark, textColor, textSubColor),
                            const SizedBox(height: 18),

                            // 2. Child Summary Card (XP, Level, Badges)
                            _buildChildSummaryCard(
                              widget.child,
                              childColor,
                              ageText,
                              isDark,
                              textColor,
                              textSubColor,
                            ),
                            const SizedBox(height: 16),

                            // 3. Subscription Balance Transfer Card
                            _buildSubscriptionTransferCard(
                              remainingChildSessions,
                              isDark,
                              textColor,
                              textSubColor,
                            ),
                            const SizedBox(height: 18),

                            // 4. Input Fields (Phone & Password)
                            _buildCredentialsInputSection(
                              isDark,
                              textColor,
                              textSubColor,
                              accentColor,
                            ),
                            const SizedBox(height: 18),

                            // 5. Unlocked Adult Privileges List
                            _buildAdultPrivileges(isDark, textColor, textSubColor),
                            const SizedBox(height: 20),

                            // Error text
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 6. Action Button
                            _buildActionButton(isDark),
                            const SizedBox(height: 24),
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

  Widget _buildHeader(bool isDark, Color textColor, Color subColor) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(LucideIcons.graduationCap, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Випуск у дорослий акаунт',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Переведення 16-річного плавця у самостійний статус',
                style: TextStyle(
                  color: subColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildSummaryCard(
    Child child,
    Color childColor,
    String ageText,
    bool isDark,
    Color textColor,
    Color subColor,
  ) {
    final initial = child.name.isNotEmpty ? child.name[0].toUpperCase() : 'П';
    final progress = child.maxXp > 0 ? (child.xp / child.maxXp).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ]
              : [
                  const Color(0xFFF1F5F9),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFFCBD5E1),
          width: 1.1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: childColor,
                  boxShadow: [
                    BoxShadow(
                      color: childColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            child.name,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '$ageText 🎓',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Рівень плавця ${child.level} • ${child.achievements.length} нагород',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // XP Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
                    minHeight: 7,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${child.xp}/${child.maxXp} XP',
                style: TextStyle(
                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTransferCard(
    int remainingSessions,
    bool isDark,
    Color textColor,
    Color subColor,
  ) {
    final hasSessions = remainingSessions > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasSessions
              ? [
                  const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.08),
                  const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.08 : 0.03),
                ]
              : [
                  Colors.white.withValues(alpha: isDark ? 0.04 : 0.4),
                  Colors.white.withValues(alpha: isDark ? 0.02 : 0.2),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasSessions
              ? const Color(0xFF0284C7).withValues(alpha: isDark ? 0.45 : 0.35)
              : (isDark ? Colors.white12 : Colors.black12),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasSessions
                      ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                      : (isDark ? Colors.white10 : Colors.black12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    hasSessions ? LucideIcons.sparkles : LucideIcons.checkCheck,
                    color: hasSessions ? const Color(0xFF38BDF8) : subColor,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Конвертація занять',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      hasSessions
                          ? 'Залишок: $remainingSessions ${remainingSessions == 1 ? "заняття" : "занять"}'
                          : 'Всі заняття використано',
                      style: TextStyle(
                        color: hasSessions ? const Color(0xFF38BDF8) : subColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSessions)
                Switch.adaptive(
                  value: _transferSubscriptions,
                  activeThumbColor: const Color(0xFF00E5FF),
                  activeTrackColor: const Color(0xFF0284C7),
                  onChanged: (val) {
                    setState(() => _transferSubscriptions = val);
                  },
                ),
            ],
          ),
          if (hasSessions) ...[
            const SizedBox(height: 8),
            Text(
              _transferSubscriptions
                  ? '✅ $remainingSessions занять дитячого абонементу будуть автоматично перенесені на новий дорослий абонемент підлітка «Групові заняття (дорослі 16+)».'
                  : 'Заняття залишаться на балансі батьківського профілю для інших членів родини.',
              style: TextStyle(
                color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCredentialsInputSection(
    bool isDark,
    Color textColor,
    Color subColor,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дані для входу нового дорослого:',
          style: TextStyle(
            color: textColor,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // Phone Input
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Номер телефону підлітка *',
            hintText: '+380 (99) 000-00-00',
            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
            labelStyle: TextStyle(color: subColor, fontSize: 13),
            prefixIcon: Icon(LucideIcons.phone, color: isDark ? const Color(0xFF00E5FF) : accentColor, size: 18),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Password Input
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Пароль для входу',
            hintText: 'Введіть або залиште 1 для швидкого входу',
            labelStyle: TextStyle(color: subColor, fontSize: 13),
            prefixIcon: Icon(LucideIcons.lock, color: isDark ? const Color(0xFF00E5FF) : accentColor, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                color: subColor,
                size: 18,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdultPrivileges(bool isDark, Color textColor, Color subColor) {
    final privileges = [
      (LucideIcons.compass, 'Самостійний запис на дорослі тренування у розкладі'),
      (LucideIcons.users, 'Доступ до спліт-занять (право брати друга чи дружину)'),
      (LucideIcons.award, 'Повне збереження рівня плавця, нагород та накопичених XP'),
      (LucideIcons.shieldCheck, 'Власне керування сім\'єю та абонементами'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: privileges.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(p.$1, size: 14, color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.$2,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.45),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.graduationCap, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Випустити у дорослий акаунт',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subColor,
  ) {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : '1';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(LucideIcons.check, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '🎉 Вітаємо з випуском!',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Акаунт для ${widget.child.name} успішно створено. Усі нагороди, рівень плавця та заняття перенесені!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subColor,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Credentials Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                width: 1.1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Номер для входу:', style: TextStyle(color: subColor, fontSize: 13)),
                    Text(phone, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Пароль:', style: TextStyle(color: subColor, fontSize: 13)),
                    Text(password, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Copy Button
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Логін: $phone\nПароль: $password'));
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Дані для входу скопійовано!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(LucideIcons.copy, size: 16),
            label: const Text('Скопіювати дані для входу'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
              side: BorderSide(
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : const Color(0xFF0284C7),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),

          // Finish Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Завершити',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
