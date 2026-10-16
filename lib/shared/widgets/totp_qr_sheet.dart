import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/utils/totp_security_helper.dart';

/// Віджет QR-коду та секретного ключа Google Authenticator (TOTP).
class TotpQrSetupBox extends StatefulWidget {
  final String loginId;
  final String displayName;
  final String secret;
  final bool isDark;
  final Color accentColor;
  final bool compact;

  const TotpQrSetupBox({
    super.key,
    required this.loginId,
    required this.displayName,
    required this.secret,
    this.isDark = true,
    this.accentColor = const Color(0xFFFFB300),
    this.compact = false,
  });

  @override
  State<TotpQrSetupBox> createState() => _TotpQrSetupBoxState();
}

class _TotpQrSetupBoxState extends State<TotpQrSetupBox> {
  bool _copied = false;

  void _copySecret() {
    HapticFeedback.selectionClick();
    final rawSecret = widget.secret.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    Clipboard.setData(ClipboardData(text: rawSecret));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanSecret = widget.secret.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final formattedSecret = TotpSecurityHelper.formatSecretForDisplay(cleanSecret);
    final otpUri = TotpSecurityHelper.buildOtpAuthUri(
      accountName: widget.loginId.isNotEmpty ? widget.loginId : widget.displayName,
      secret: cleanSecret,
    );

    final textPrimary = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = widget.isDark ? Colors.white70 : const Color(0xFF475569);

    return Container(
      padding: EdgeInsets.all(widget.compact ? 14 : 18),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.38),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.shieldCheck,
                  color: widget.accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'auth.totp_setup_title'.tr(),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'auth.totp_setup_subtitle'.tr(),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: otpUri,
              version: QrVersions.auto,
              size: widget.compact ? 156 : 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0A192F),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0A192F),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'auth.totp_manual_key_label'.tr(),
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _copySecret,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.32)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _copied
                      ? const Color(0xFF10B981)
                      : widget.accentColor.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      formattedSecret,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _copied
                          ? const Color(0xFF10B981).withValues(alpha: 0.20)
                          : widget.accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? LucideIcons.check : LucideIcons.copy,
                          size: 14,
                          color: _copied ? const Color(0xFF10B981) : widget.accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'auth.totp_copied'.tr() : 'auth.totp_copy_btn'.tr(),
                          style: TextStyle(
                            color: _copied ? const Color(0xFF10B981) : widget.accentColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Картка керування Google Authenticator (2FA) для співробітника в кабінеті Власника або Адміністратора.
class TotpStaffManagementCard extends ConsumerStatefulWidget {
  final String staffId;
  final String loginId;
  final String displayName;
  final String role;
  final Color accentColor;

  const TotpStaffManagementCard({
    super.key,
    required this.staffId,
    required this.loginId,
    required this.displayName,
    required this.role,
    this.accentColor = const Color(0xFF00E5FF),
  });

  @override
  ConsumerState<TotpStaffManagementCard> createState() => _TotpStaffManagementCardState();
}

class _TotpStaffManagementCardState extends ConsumerState<TotpStaffManagementCard> {
  bool _showQrExpanded = false;
  bool _isResetting = false;

  Future<String> _ensureSecretExists(Map<String, dynamic>? data) async {
    final existing = (data?['totpSecret'] as String?)?.trim() ?? '';
    if (existing.isNotEmpty) return existing;

    final generated = TotpSecurityHelper.generateBase32Secret();
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(widget.staffId).set({
      'id': widget.staffId,
      if ((data?['loginId'] as String?)?.isNotEmpty != true && widget.loginId.isNotEmpty)
        'loginId': widget.loginId,
      if ((data?['name'] as String?)?.isNotEmpty != true && widget.displayName.isNotEmpty)
        'name': widget.displayName,
      if ((data?['role'] as String?)?.isNotEmpty != true && widget.role.isNotEmpty)
        'role': widget.role,
      'totpSecret': generated,
      'totpEnabled': false,
    }, SetOptions(merge: true));

    if (widget.role == 'coach') {
      await db.collection('coaches').doc(widget.staffId).set({
        'id': widget.staffId,
        'totpSecret': generated,
        'totpEnabled': false,
      }, SetOptions(merge: true)).catchError((_) {});
    }
    return generated;
  }

  Future<void> _resetTotp() async {
    HapticFeedback.mediumImpact();
    setState(() => _isResetting = true);
    try {
      final newSecret = TotpSecurityHelper.generateBase32Secret();
      final db = FirebaseFirestore.instance;
      await db.collection('users').doc(widget.staffId).set({
        'totpSecret': newSecret,
        'totpEnabled': false,
      }, SetOptions(merge: true));

      if (widget.role == 'coach') {
        await db.collection('coaches').doc(widget.staffId).set({
          'totpSecret': newSecret,
          'totpEnabled': false,
        }, SetOptions(merge: true)).catchError((_) {});
      }

      if (mounted) {
        setState(() {
          _isResetting = false;
          _showQrExpanded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.totp_reset_success'.tr(namedArgs: {'name': widget.displayName})),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.staffId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final totpEnabled = data?['totpEnabled'] == true;
        final secret = (data?['totpSecret'] as String?)?.trim() ?? '';
        final effectiveLogin = (data?['loginId'] as String?)?.trim().isNotEmpty == true
            ? (data!['loginId'] as String).trim()
            : widget.loginId;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0A192F).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: isDark ? 0.30 : 0.40),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.shieldCheck,
                      color: widget.accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Authenticator (2FA)',
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${'admin.clients_login_label'.tr()}$effectiveLogin',
                          style: TextStyle(
                            color: themeConfig.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: totpEnabled
                          ? const Color(0xFF10B981).withValues(alpha: 0.16)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: totpEnabled
                            ? const Color(0xFF10B981).withValues(alpha: 0.45)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      totpEnabled ? 'auth.totp_status_active'.tr() : 'auth.totp_status_pending'.tr(),
                      style: TextStyle(
                        color: totpEnabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.accentColor,
                        side: BorderSide(color: widget.accentColor.withValues(alpha: 0.45)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        if (secret.isEmpty) {
                          await _ensureSecretExists(data);
                        }
                        if (mounted) {
                          setState(() => _showQrExpanded = !_showQrExpanded);
                        }
                      },
                      icon: Icon(_showQrExpanded ? LucideIcons.eyeOff : LucideIcons.qrCode, size: 16),
                      label: Text(
                        _showQrExpanded ? 'auth.totp_hide_qr_btn'.tr() : 'auth.totp_show_qr_btn'.tr(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onPressed: _isResetting ? null : _resetTotp,
                    icon: const Icon(LucideIcons.refreshCw, size: 15),
                    label: Text(
                      'auth.totp_reset_btn'.tr(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (_showQrExpanded && secret.isNotEmpty) ...[
                const SizedBox(height: 14),
                TotpQrSetupBox(
                  loginId: effectiveLogin,
                  displayName: widget.displayName,
                  secret: secret,
                  isDark: isDark,
                  accentColor: widget.accentColor,
                  compact: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Модальне вікно перегляду QR-коду Google Authenticator.
class TotpQrSheet {
  static Future<void> show(
    BuildContext context, {
    required String staffId,
    required String loginId,
    required String displayName,
    required String role,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF0A192F).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TotpStaffManagementCard(
                  staffId: staffId,
                  loginId: loginId,
                  displayName: displayName,
                  role: role,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
