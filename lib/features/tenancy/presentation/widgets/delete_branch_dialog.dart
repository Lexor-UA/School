import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/tenancy/presentation/widgets/edit_branch_sheet.dart';

class DeleteBranchDialog extends ConsumerStatefulWidget {
  final Branch branch;

  const DeleteBranchDialog({
    super.key,
    required this.branch,
  });

  static Future<void> show(BuildContext context, Branch branch) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteBranchDialog(branch: branch),
    );
  }

  @override
  ConsumerState<DeleteBranchDialog> createState() => _DeleteBranchDialogState();
}

class _DeleteBranchDialogState extends ConsumerState<DeleteBranchDialog> {
  bool _isConfirmed = false;
  bool _isLoading = false;

  Future<void> _handleDelete() async {
    if (!_isConfirmed || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(tenancyControllerProvider.notifier)
          .deleteBranch(widget.branch.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Філію "${widget.branch.name}" успішно видалено!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка видалення: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    final isProtected = widget.branch.isProtected || widget.branch.isSystemDefault;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isProtected
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.redAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon Header
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isProtected
                    ? Colors.amber.withValues(alpha: 0.15)
                    : Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isProtected ? LucideIcons.shieldCheck : LucideIcons.alertTriangle,
                color: isProtected ? Colors.amber : Colors.redAccent,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            isProtected ? 'Філія захищена від видалення' : 'Видалення філії',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Branch Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.branch.flagEmoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  widget.branch.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' (${widget.branch.city})',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (isProtected) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.lock, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.branch.isSystemDefault
                          ? 'Це базова системна філія. Вона забезпечує кореневу роботу додатку та не може бути видалена.'
                          : 'Ця філія наразі захищена від випадкового видалення. Щоб видалити її, спочатку вимкніть захист у вікні редагування.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.amber.shade200
                            : Colors.amber.shade900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ви точно впевнені, що хочете видалити цю філію зі всіма її даними?',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Будуть видалені всі басейни та доріжки цієї філії\n'
                    '• Будуть скасовані розклад та конфігурація занять\n'
                    '• Обліковий запис адміністратора філії буде вилучено',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Checkbox confirmation
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isConfirmed = !_isConfirmed),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isConfirmed,
                        activeColor: Colors.redAccent,
                        onChanged: (val) =>
                            setState(() => _isConfirmed = val ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'Я підтверджую безповоротне видалення філії та всіх її даних',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (isProtected && !widget.branch.isSystemDefault)
          TextButton.icon(
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: const Text('Вимкнути захист'),
            onPressed: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => EditBranchSheet(branch: widget.branch),
              );
            },
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Скасувати',
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!isProtected)
          ElevatedButton.icon(
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.trash2, size: 16),
            label: const Text('Видалити назавжди'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.redAccent.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: _isConfirmed && !_isLoading ? _handleDelete : null,
          ),
      ],
    );
  }
}
