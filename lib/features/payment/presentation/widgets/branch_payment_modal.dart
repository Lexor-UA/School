import 'dart:math' as math;
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
  String? _errorMessage;
  String _selectedMethod = 'card';
  PaymentReceipt? _completedReceipt;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final tenancyState = ref.watch(tenancyControllerProvider);
    final activeBranch = tenancyState.effectiveBranch;
    final paymentConfig = ref.watch(branchPaymentServiceProvider).getPaymentConfig(widget.package.branchId);

    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = math.max(mediaQuery.padding.bottom, 16.0) +
        (mediaQuery.viewInsets.bottom > 0 ? mediaQuery.viewInsets.bottom : 16.0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF0B2238),
                  Color(0xFF07192C),
                  Color(0xFF04101D),
                ]
              : const [
                  Colors.white,
                  Color(0xFFF0F9FF),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
              : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.20),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0C2642),
                      Color(0xFF071B30),
                    ]
                  : const [
                      Color(0xFFF0F9FF),
                      Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.28) : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
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
                        color: isDark ? Colors.white : currentTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    widget.package.formattedPricePretty,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      shadows: isDark
                          ? [
                              Shadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
            color: isDark ? const Color(0xFF082238) : currentTheme.accentPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.30) : currentTheme.accentPrimary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, color: isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Безпечний режим: реальні кошти не списуються. Після підтвердження абонемент буде миттєво активовано у філії $branchTitle, а ви отримаєте електронну квитанцію.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFE2E8F0) : currentTheme.textPrimary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Error display if payment failed
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.55 : 0.40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.20 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms).shake(duration: 350.ms, hz: 4),
        ],

        // Action Button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0E2E50), Color(0xFF081C32)]
                  : const [Color(0xFF0284C7), Color(0xFF0369A1)],
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.30 : 0.20),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.white60,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00E5FF),
                      strokeWidth: 2.5,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.checkCircle2, color: Color(0xFF00E5FF), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Підтвердити оплату (${widget.package.formattedPricePretty})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0E3860) : const Color(0xFFE0F2FE))
              : (isDark ? const Color(0xFF0B2540) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary)
                : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary).withValues(alpha: isDark ? 0.30 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? (isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary) : (isDark ? const Color(0xFF94A3B8) : currentTheme.textSecondary),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (isDark ? Colors.white : currentTheme.accentPrimary) : (isDark ? const Color(0xFFE2E8F0) : currentTheme.textPrimary),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
        color: isDark ? const Color(0xFF0F3152) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : currentTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0C2642),
                      Color(0xFF071B30),
                    ]
                  : const [
                      Color(0xFFF0F9FF),
                      Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.28) : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
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
                      color: isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    receipt.formattedAmount,
                    style: TextStyle(
                      color: isDark ? Colors.white : currentTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 1,
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFFE2E8F0),
              ),
              _buildReceiptRow('Платник', receipt.clientName, currentTheme, isDark),
              if (receipt.childName != null)
                _buildReceiptRow('Учень', receipt.childName!, currentTheme, isDark),
              _buildReceiptRow('Пакет', receipt.packageName, currentTheme, isDark),
              _buildReceiptRow('Кількість занять', _formatClassesCount(receipt.classesCount), currentTheme, isDark),
              _buildReceiptRow('Шлюз філії', receipt.paymentGateway, currentTheme, isDark),
              _buildReceiptRow('Транзакція', receipt.transactionId, currentTheme, isDark),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 1,
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFFE2E8F0),
              ),
              // Legal summary
              Text(
                'Реквізити надавача послуг (${receipt.legalDetails['companyName'] ?? ''}):',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : currentTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${receipt.legalDetails['taxIdLabel'] ?? 'Код'}: ${receipt.legalDetails['taxId'] ?? ''} • ${receipt.legalDetails['address'] ?? ''}',
                style: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : currentTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Close button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0E3D64), Color(0xFF082038)]
                  : const [Color(0xFF0284C7), Color(0xFF0369A1)],
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.30 : 0.20),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(receipt);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Готово',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatClassesCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return '$count заняття';
    } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return '$count заняття';
    } else {
      return '$count занять';
    }
  }

  Widget _buildReceiptRow(String label, String value, dynamic currentTheme, [bool isDark = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : currentTheme.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : currentTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();
    debugPrint('BranchPaymentModal: _handlePayment invoked for package ${widget.package.name} (branch: ${widget.package.branchId})');

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
    } catch (e, stack) {
      debugPrint('BranchPaymentModal: Payment error: $e\n$stack');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
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
