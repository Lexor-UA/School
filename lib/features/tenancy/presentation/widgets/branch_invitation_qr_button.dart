import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/tenancy/presentation/branch_invitation_qr_dialog.dart';

class BranchInvitationQrButton extends ConsumerWidget {
  final String? branchId;

  const BranchInvitationQrButton({
    super.key,
    this.branchId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          BranchInvitationQrDialog.show(context, branchId: branchId);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF00E5FF).withValues(alpha: 0.18),
                      const Color(0xFF0072FF).withValues(alpha: 0.10),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFE0F2FE),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                  : const Color(0xFF7DD3FC),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.20 : 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.qrCode,
                  size: 13,
                  color: Color(0xFF0B192C),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'QR рецепції',
                style: TextStyle(
                  color: currentTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
