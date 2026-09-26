import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/payment/models/branch_payment_config.dart';
import 'package:swimming_school_app/features/payment/models/payment_receipt.dart';
import 'package:swimming_school_app/features/payment/services/branch_payment_service.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

/// Преміальний модальний діалог тестової оплати абонемента за ТЗ (Етап 9)
/// Гарантує повну ізоляцію шлюзів (LiqPay для Києва, Stripe для Відня)
/// у безпечному тестовому режимі без реальних списувань коштів.
class BranchPaymentModal extends ConsumerStatefulWidget {
  final SubscriptionPackage package;
  final String clientId;
  final String clientName;
  final String? childId;
  final String? childName;
  final VoidCallback? onPaymentSuccess;

  const BranchPaymentModal({
    super.key,
    required this.package,
    required this.clientId,
    required this.clientName,
    this.childId,
    this.childName,
    this.onPaymentSuccess,
  });

  static Future<PaymentReceipt?> show({
    required BuildContext context,
    required SubscriptionPackage package,
    required String clientId,
    required String clientName,
    String? childId,
    String? childName,
    VoidCallback? onPaymentSuccess,
  }) {
    return showModalBottomSheet<PaymentReceipt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BranchPaymentModal(
        package: package,
        clientId: clientId,
        clientName: clientName,
        childId: childId,
        childName: childName,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  ConsumerState<BranchPaymentModal> createState() => _BranchPaymentModalState();
}

class _BranchPaymentModalState extends ConsumerState<BranchPaymentModal> {
  bool _isProcessing = false;
  String _selectedMethod = 'card';
  PaymentReceipt? _completedReceipt;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final tenancyState = ref.watch(tenancyControllerProvider);
    final activeBranch = tenancyState.effectiveBranch;
    final paymentConfig = ref.watch(branchPaymentServiceProvider).getPaymentConfig(widget.package.branchId);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF061426).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _completedReceipt != null
            ? _buildReceiptView(context, _completedReceipt!, currentTheme, isDark)
            : _buildCheckoutView(context, currentTheme, isDark, activeBranch, paymentConfig),
      ),
    );
  }

  Widget _buildCheckoutView(
    BuildContext context,
    dynamic currentTheme,
    bool isDark,
    dynamic activeBranch,
    BranchPaymentConfig paymentConfig,
  ) {
    final isVienna = widget.package.branchId == 'vienna';
    final branchFlag = isVienna ? '🇦🇹' : '🇺🇦';
    final branchTitle = isVienna ? 'CitySwim Vienna' : 'CitySwim Kyiv';
    final gatewayBadge = paymentConfig.gatewayName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
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
        const SizedBox(height: 18),

        // Header with Branch & Safe Mock Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F2640) : const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(branchFlag, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        branchTitle,
                        style: TextStyle(
                          color: currentTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Mock Payment (Тест)',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Package Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.package.name,
                      style: TextStyle(
                        color: currentTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    widget.package.formattedPricePretty,
                    style: TextStyle(
                      color: currentTheme.accentPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetaBadge(
                    icon: LucideIcons.calendar,
                    text: '${widget.package.classes} занять',
                    currentTheme: currentTheme,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildMetaBadge(
                    icon: LucideIcons.clock,
                    text: '${widget.package.validityDays} днів',
                    currentTheme: currentTheme,
                    isDark: isDark,
                  ),
                  if (widget.childName != null) ...[
                    const SizedBox(width: 8),
                    _buildMetaBadge(
                      icon: LucideIcons.user,
                      text: widget.childName!,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Payment Gateway Selector
        Text(
          'Платіжний провайдер філії ($gatewayBadge)',
          style: TextStyle(
            color: currentTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildMethodButton(
                id: 'apple_pay',
                icon: LucideIcons.smartphone,
                label: 'Apple Pay',
                isDark: isDark,
                currentTheme: currentTheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMethodButton(
                id: 'google_pay',
                icon: LucideIcons.qrCode,
                label: 'Google Pay',
                isDark: isDark,
                currentTheme: currentTheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMethodButton(
                id: 'card',
                icon: LucideIcons.creditCard,
                label: 'Картка',
                isDark: isDark,
                currentTheme: currentTheme,
              ),
            ),
            if (isVienna) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodButton(
                  id: 'sepa',
                  icon: LucideIcons.landmark,
                  label: 'SEPA / EPS',
                  isDark: isDark,
                  currentTheme: currentTheme,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // Information banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: currentTheme.accentPrimary.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: currentTheme.accentPrimary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, color: currentTheme.accentPrimary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Безпечний режим: реальні кошти не списуються. Після підтвердження абонемент буде миттєво активовано у філії $branchTitle, а ви отримаєте електронну квитанцію.',
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Action Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: currentTheme.accentPrimary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Підтвердити оплату (${widget.package.formattedPricePretty})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodButton({
    required String id,
    required IconData icon,
    required String label,
    required bool isDark,
    required dynamic currentTheme,
  }) {
    final isSelected = _selectedMethod == id;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMethod = id);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? currentTheme.accentPrimary.withValues(alpha: isDark ? 0.22 : 0.14)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? currentTheme.accentPrimary
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? currentTheme.accentPrimary : currentTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? currentTheme.accentPrimary : currentTheme.textPrimary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String text,
    required dynamic currentTheme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: currentTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: currentTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptView(
    BuildContext context,
    PaymentReceipt receipt,
    dynamic currentTheme,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Success animation circle
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withValues(alpha: 0.18),
            border: Border.all(color: const Color(0xFF10B981), width: 2),
          ),
          child: const Center(
            child: Icon(LucideIcons.check, color: Color(0xFF10B981), size: 32),
          ),
        ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 14),

        Text(
          'Оплату успішно здійснено!',
          style: TextStyle(
            color: currentTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Абонемент активовано у філії ${receipt.branchName}',
          style: TextStyle(
            color: currentTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),

        // Receipt Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Квитанція № ${receipt.receiptNumber}',
                    style: TextStyle(
                      color: currentTheme.accentPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    receipt.formattedAmount,
                    style: TextStyle(
                      color: currentTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              _buildReceiptRow('Платник', receipt.clientName, currentTheme),
              if (receipt.childName != null)
                _buildReceiptRow('Учень', receipt.childName!, currentTheme),
              _buildReceiptRow('Пакет', receipt.packageName, currentTheme),
              _buildReceiptRow('Кількість занять', '${receipt.classesCount} тренувань', currentTheme),
              _buildReceiptRow('Шлюз філії', receipt.paymentGateway, currentTheme),
              _buildReceiptRow('Транзакція', receipt.transactionId, currentTheme),
              const Divider(height: 18),
              // Legal summary
              Text(
                'Реквізити надавача послуг (${receipt.legalDetails['companyName'] ?? ''}):',
                style: TextStyle(
                  color: currentTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${receipt.legalDetails['taxIdLabel'] ?? 'Код'}: ${receipt.legalDetails['taxId'] ?? ''} • ${receipt.legalDetails['address'] ?? ''}',
                style: TextStyle(
                  color: currentTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Close button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(receipt);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: currentTheme.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Готово',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, dynamic currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: currentTheme.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: currentTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final paymentService = ref.read(branchPaymentServiceProvider);
      final receipt = await paymentService.processMockPayment(
        branchId: widget.package.branchId,
        clientId: widget.clientId,
        clientName: widget.clientName,
        childId: widget.childId,
        childName: widget.childName,
        package: widget.package,
        paymentMethod: _selectedMethod,
      );

      HapticFeedback.heavyImpact();
      widget.onPaymentSuccess?.call();

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _completedReceipt = receipt;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка платежу: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
