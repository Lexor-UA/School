import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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
  PaymentReceipt? _completedReceipt;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final tenancyState = ref.watch(tenancyControllerProvider);
    final activeBranch = tenancyState.effectiveBranch;
    final liveConfigAsync = ref.watch(branchPaymentConfigStreamProvider(widget.package.branchId));
    final paymentConfig = liveConfigAsync.value ??
        ref.watch(branchPaymentServiceProvider).getPaymentConfig(widget.package.branchId);

    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = math.max(mediaQuery.padding.bottom, 16.0) +
        (mediaQuery.viewInsets.bottom > 0 ? mediaQuery.viewInsets.bottom : 16.0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.92,
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

        // Header with Branch & Bank Transfer Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.landmark,
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'payment.bank_transfer_badge'.tr(),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                      widget.package.getLocalizedName(context.locale.languageCode),
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
                    text: _formatClassesCount(widget.package.classes),
                    currentTheme: currentTheme,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildMetaBadge(
                    icon: LucideIcons.clock,
                    text: 'payment.days_count'.tr(args: ['${widget.package.validityDays}']),
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

        // Bank Requisites Pod
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF071A2E),
                      Color(0xFF041220),
                    ]
                  : const [
                      Color(0xFFF8FAFC),
                      Color(0xFFF0F9FF),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.28) : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.landmark,
                        size: 16,
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'payment.requisites_title'.tr(),
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'payment.requisites_subtitle'.tr(),
                          style: TextStyle(
                            color: currentTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Requisite fields with individual copy actions
              _buildRequisiteItem(
                label: 'payment.recipient_label'.tr(),
                value: paymentConfig.legalEntityDetails['companyName'] ?? (isVienna ? 'CitySwim Vienna GmbH' : 'ТОВ "СітіСвім Україна"'),
                icon: LucideIcons.building,
                context: context,
                currentTheme: currentTheme,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildRequisiteItem(
                label: 'IBAN',
                value: paymentConfig.legalEntityDetails['iban'] ?? (isVienna ? 'AT893700000001234567' : 'UA82305299000002600123456789'),
                icon: LucideIcons.creditCard,
                isMonospace: true,
                isHighlight: true,
                context: context,
                currentTheme: currentTheme,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildRequisiteItem(
                label: paymentConfig.legalEntityDetails['taxIdLabel'] ?? (isVienna ? 'UID-Nummer' : 'ЄДРПОУ'),
                value: paymentConfig.legalEntityDetails['taxId'] ?? (isVienna ? 'ATU78945612' : '43892104'),
                icon: LucideIcons.fileText,
                context: context,
                currentTheme: currentTheme,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildRequisiteItem(
                label: 'payment.bank_label'.tr(),
                value: paymentConfig.legalEntityDetails['bankName'] ?? (isVienna ? 'Erste Bank AG' : 'АТ КБ "ПриватБанк"'),
                icon: LucideIcons.landmark,
                context: context,
                currentTheme: currentTheme,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildRequisiteItem(
                label: 'payment.amount_to_pay_label'.tr(),
                value: widget.package.formattedPricePretty,
                icon: LucideIcons.coins,
                isHighlight: true,
                context: context,
                currentTheme: currentTheme,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildRequisiteItem(
                label: 'payment.payment_purpose_label'.tr(),
                value: 'payment.payment_purpose_value'.tr(args: [
                  widget.package.getLocalizedName(context.locale.languageCode),
                  widget.childName ?? widget.clientName,
                ]),
                icon: LucideIcons.messageSquare,
                context: context,
                currentTheme: currentTheme,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              // Button: Copy all requisites
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyAllRequisites(context, paymentConfig, isVienna),
                  icon: Icon(
                    LucideIcons.copy,
                    size: 15,
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  ),
                  label: Text(
                    'payment.copy_all_requisites'.tr(),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
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
                  'payment.bank_transfer_info_banner'.tr(),
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
        const SizedBox(height: 20),

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

        // Action Button: "Я оплатив(ла) за реквізитами"
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
            onPressed: _isProcessing ? null : () => _handlePayment(paymentConfig),
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
                        const Icon(LucideIcons.sendHorizontal, color: Color(0xFF00E5FF), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'payment.i_have_paid_btn'.tr(),
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
        const SizedBox(height: 10),

        // Cancel / Pay later button
        Center(
          child: TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              'payment.pay_later_btn'.tr(),
              style: TextStyle(
                color: currentTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequisiteItem({
    required String label,
    required String value,
    required IconData icon,
    bool isMonospace = false,
    bool isHighlight = false,
    required BuildContext context,
    required dynamic currentTheme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C243C).withValues(alpha: 0.60) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.45) : const Color(0xFF38BDF8))
              : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
          width: isHighlight ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: isHighlight
                ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                SelectableText(
                  value,
                  style: TextStyle(
                    color: isHighlight
                        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                        : (isDark ? Colors.white : currentTheme.textPrimary),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: isMonospace ? 'monospace' : null,
                    letterSpacing: isMonospace ? 0.6 : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'common.copy'.tr(),
            icon: Icon(
              LucideIcons.copy,
              size: 15,
              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('payment.copied_field_msg'.tr(args: [label, value])),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  void _copyAllRequisites(BuildContext context, BranchPaymentConfig config, bool isVienna) {
    HapticFeedback.mediumImpact();
    final purpose = 'payment.payment_purpose_value'.tr(args: [
      widget.package.getLocalizedName(context.locale.languageCode),
      widget.childName ?? widget.clientName,
    ]);

    final text = StringBuffer()
      ..writeln(config.legalEntityDetails['companyName'] ?? '')
      ..writeln('IBAN: ${config.legalEntityDetails['iban'] ?? ''}')
      ..writeln('${config.legalEntityDetails['taxIdLabel'] ?? (isVienna ? 'UID-Nummer' : 'ЄДРПОУ')}: ${config.legalEntityDetails['taxId'] ?? ''}')
      ..writeln('${'payment.bank_label'.tr()}: ${config.legalEntityDetails['bankName'] ?? ''}')
      ..writeln('${'payment.amount_to_pay_label'.tr()}: ${widget.package.formattedPricePretty}')
      ..writeln('${'payment.payment_purpose_label'.tr()}: $purpose');

    Clipboard.setData(ClipboardData(text: text.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('payment.all_requisites_copied'.tr()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
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
    final isVienna = widget.package.branchId == 'vienna';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pending approval icon circle (Amber/Gold)
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Center(
            child: Icon(LucideIcons.clockAlert, color: Color(0xFFF59E0B), size: 30),
          ),
        ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 14),

        Text(
          'payment.verification_sent_title'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: currentTheme.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'payment.verification_sent_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: currentTheme.textSecondary,
            fontSize: 12.5,
            height: 1.35,
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
                    'payment.receipt_no'.tr(args: [receipt.receiptNumber]),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF00E5FF) : currentTheme.accentPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'payment.awaiting_verification_badge'.tr(),
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 1,
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFFE2E8F0),
              ),
              _buildReceiptRow('payment.payer'.tr(), receipt.clientName, currentTheme, isDark),
              if (receipt.childName != null)
                _buildReceiptRow('payment.student'.tr(), receipt.childName!, currentTheme, isDark),
              _buildReceiptRow(
                'payment.package'.tr(),
                SubscriptionPackageCatalog.localizeServiceName(receipt.packageName, context.locale.languageCode),
                currentTheme,
                isDark,
              ),
              _buildReceiptRow('payment.amount_label'.tr(), receipt.formattedAmount, currentTheme, isDark),
              _buildReceiptRow('payment.classes_count'.tr(), _formatClassesCount(receipt.classesCount), currentTheme, isDark),
              _buildReceiptRow('payment.payment_method_label'.tr(), 'payment.bank_transfer_method'.tr(), currentTheme, isDark),
              _buildReceiptRow('payment.transaction'.tr(), receipt.transactionId, currentTheme, isDark),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 1,
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFFE2E8F0),
              ),
              // Legal summary
              Text(
                'payment.service_provider_details'.tr(args: [receipt.legalDetails['companyName'] ?? '']),
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : currentTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'IBAN: ${receipt.legalDetails['iban'] ?? ''} • ${receipt.legalDetails['taxIdLabel'] ?? (isVienna ? 'UID-Nummer' : 'ЄДРПОУ')}: ${receipt.legalDetails['taxId'] ?? ''}',
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'payment.done'.tr(),
                style: const TextStyle(
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
    final lang = context.locale.languageCode;
    if (lang == 'de') {
      return count == 1 ? '1 Einheit' : '$count Einheiten';
    } else if (lang == 'en') {
      return count == 1 ? '1 class' : '$count classes';
    } else if (lang == 'ru') {
      final mod10 = count % 10;
      final mod100 = count % 100;
      if (mod10 == 1 && mod100 != 11) {
        return '$count занятие';
      } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
        return '$count занятия';
      } else {
        return '$count занятий';
      }
    }
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

  Future<void> _handlePayment(BranchPaymentConfig config) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();
    debugPrint('BranchPaymentModal: _handlePayment bank transfer invoked for package ${widget.package.name} (branch: ${widget.package.branchId})');

    try {
      final paymentService = ref.read(branchPaymentServiceProvider);
      final receipt = await paymentService.submitBankTransferPayment(
        branchId: widget.package.branchId,
        clientId: widget.clientId,
        clientName: widget.clientName,
        childId: widget.childId,
        childName: widget.childName,
        package: widget.package,
        customConfig: config,
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
            content: Text('payment.request_send_error'.tr(args: ['$e'])),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
