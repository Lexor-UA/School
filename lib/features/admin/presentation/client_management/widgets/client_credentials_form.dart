import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ClientCredentialsForm extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController loginIdController;
  final bool isDark;

  const ClientCredentialsForm({
    super.key,
    required this.passwordController,
    required this.loginIdController,
    required this.isDark,
  });

  @override
  State<ClientCredentialsForm> createState() => _ClientCredentialsFormState();
}

class _ClientCredentialsFormState extends State<ClientCredentialsForm> {
  bool _obscurePassword = false;

  void _resetPasswordToDefault() {
    setState(() {
      widget.passwordController.text = '1';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'Пароль скинуто до стандартного: 1',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _generateRandomPin() {
    final randomPin = (100000 + Random().nextInt(900000)).toString();
    setState(() {
      widget.passwordController.text = randomPin;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              LucideIcons.sparkles,
              color: Color(0xFF00E5FF),
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Згенеровано новий PIN: $randomPin',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyCredentials() {
    final login = widget.loginIdController.text.trim();
    final pass = widget.passwordController.text.trim();
    Clipboard.setData(ClipboardData(text: 'Логін: $login\nПароль: $pass'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.copy, color: Color(0xFF38BDF8), size: 18),
            SizedBox(width: 8),
            Text(
              'Дані для входу скопійовано в буфер обміну!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
              : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF003B73).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText:
                  'admin.clients_password_label'
                      .tr()
                      .replaceAll(':', '')
                      .trim()
                      .isEmpty
                  ? 'Пароль клієнта'
                  : 'admin.clients_password_label'
                        .tr()
                        .replaceAll(':', '')
                        .trim(),
              labelStyle: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                LucideIcons.keyRound,
                color: isDark
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFD97706),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  size: 20,
                ),
                tooltip: _obscurePassword
                    ? 'Показати пароль'
                    : 'Приховати пароль',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPasswordActionButton(
                      icon: LucideIcons.rotateCcw,
                      label: 'Скинути на "1"',
                      color: isDark
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFD97706),
                      onTap: _resetPasswordToDefault,
                      isDark: isDark,
                    ),
                    _buildPasswordActionButton(
                      icon: LucideIcons.sparkles,
                      label: 'Згенерувати PIN',
                      color: isDark
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF0284C7),
                      onTap: _generateRandomPin,
                      isDark: isDark,
                    ),
                    _buildPasswordActionButton(
                      icon: LucideIcons.copy,
                      label: 'Копіювати',
                      color: isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0EA5E9),
                      onTap: _copyCredentials,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.40)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Збережіть зміни, щоб оновити пароль у базі даних',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.45)
                              : const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.30),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
