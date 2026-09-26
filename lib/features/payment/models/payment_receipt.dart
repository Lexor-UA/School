import 'package:flutter/foundation.dart';
import 'branch_payment_config.dart';
import 'payment_transaction.dart';

/// Модель електронного чека / інвойса з локальними реквізитами філії (ТЗ п. 20, 21)
@immutable
class PaymentReceipt {
  final String receiptNumber;
  final String branchId;
  final String branchName;
  final String clientName;
  final String? childName;
  final String packageName;
  final int classesCount;
  final int validityDays;
  final double amount;
  final String currency;
  final String currencySymbol;
  final String paymentGateway;
  final String paymentMethod;
  final String transactionId;
  final DateTime paidAt;
  final Map<String, String> legalDetails;

  const PaymentReceipt({
    required this.receiptNumber,
    required this.branchId,
    required this.branchName,
    required this.clientName,
    this.childName,
    required this.packageName,
    required this.classesCount,
    required this.validityDays,
    required this.amount,
    required this.currency,
    required this.currencySymbol,
    required this.paymentGateway,
    required this.paymentMethod,
    required this.transactionId,
    required this.paidAt,
    required this.legalDetails,
  });

  String get formattedAmount => '$amount $currencySymbol';

  /// Створення квитанції на основі транзакції та конфігурації філії
  factory PaymentReceipt.fromTransaction({
    required PaymentTransaction transaction,
    required BranchPaymentConfig config,
    int classesCount = 8,
    int validityDays = 30,
  }) {
    final branchTitle = transaction.branchId == 'vienna' ? 'CitySwim Vienna' : 'CitySwim Kyiv';
    
    return PaymentReceipt(
      receiptNumber: transaction.receiptNumber,
      branchId: transaction.branchId,
      branchName: branchTitle,
      clientName: transaction.clientName,
      childName: transaction.childName,
      packageName: transaction.packageName,
      classesCount: classesCount,
      validityDays: validityDays,
      amount: transaction.amount,
      currency: transaction.currency,
      currencySymbol: transaction.currencySymbol,
      paymentGateway: config.gatewayName,
      paymentMethod: transaction.paymentMethod,
      transactionId: transaction.transactionId,
      paidAt: transaction.createdAt,
      legalDetails: config.legalEntityDetails,
    );
  }

  /// Текстове представлення чека для експорту або показу
  String formatPlainText() {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('          $branchName');
    buffer.writeln('    ЕЛЕКТРОННА КВИТАНЦІЯ / BELEG');
    buffer.writeln('========================================');
    buffer.writeln('Квитанція №: $receiptNumber');
    buffer.writeln('Дата/Час:    ${paidAt.toIso8601String().replaceAll('T', ' ').substring(0, 19)}');
    buffer.writeln('Транзакція:  $transactionId');
    buffer.writeln('Шлюз:        $paymentGateway (Тестовий режим / Mock)');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Платник:     $clientName');
    if (childName != null && childName!.isNotEmpty) {
      buffer.writeln('Учень:       $childName');
    }
    buffer.writeln('Послуга:     $packageName');
    buffer.writeln('К-сть занять: $classesCount');
    buffer.writeln('Діє:         $validityDays днів');
    buffer.writeln('----------------------------------------');
    buffer.writeln('СУМА ДО СПЛАТИ: $formattedAmount');
    buffer.writeln('СТАТУС:      ОПЛАЧЕНО УСПІШНО (ТЕСТ)');
    buffer.writeln('========================================');
    buffer.writeln('Реквізити надавача послуг:');
    final companyName = legalDetails['companyName'] ?? '';
    final taxIdLabel = legalDetails['taxIdLabel'] ?? 'Код';
    final taxId = legalDetails['taxId'] ?? '';
    final address = legalDetails['address'] ?? '';
    final iban = legalDetails['iban'] ?? '';
    final bankName = legalDetails['bankName'] ?? '';

    if (companyName.isNotEmpty) buffer.writeln('  Організація: $companyName');
    if (taxId.isNotEmpty) buffer.writeln('  $taxIdLabel: $taxId');
    if (address.isNotEmpty) buffer.writeln('  Адреса:      $address');
    if (iban.isNotEmpty) buffer.writeln('  IBAN:        $iban');
    if (bankName.isNotEmpty) buffer.writeln('  Банк:        $bankName');
    buffer.writeln('========================================');
    return buffer.toString();
  }
}
