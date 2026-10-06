import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  completed,
  pending,
  failed,
  refunded;

  String get label {
    switch (this) {
      case PaymentStatus.completed:
        return 'Оплачено';
      case PaymentStatus.pending:
        return 'В обробці';
      case PaymentStatus.failed:
        return 'Відхилено';
      case PaymentStatus.refunded:
        return 'Повернуто';
    }
  }
}

/// Модель платіжної транзакції (ТЗ п. 20)
/// Зберігається в колекції `payments` із суворою прив'язкою до організації та філії.
@immutable
class PaymentTransaction {
  final String id;
  final String organizationId;
  final String branchId;
  final String clientId;
  final String clientName;
  final String? childId;
  final String? childName;
  final String packageId;
  final String packageName;
  final double amount;
  final String currency;
  final String currencySymbol;
  final String paymentGateway; // 'liqpay', 'stripe'
  final PaymentStatus status;
  final String transactionId;
  final String receiptNumber;
  final String paymentMethod;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const PaymentTransaction({
    required this.id,
    this.organizationId = 'cityswim',
    required this.branchId,
    required this.clientId,
    required this.clientName,
    this.childId,
    this.childName,
    required this.packageId,
    required this.packageName,
    required this.amount,
    required this.currency,
    required this.currencySymbol,
    required this.paymentGateway,
    this.status = PaymentStatus.completed,
    required this.transactionId,
    required this.receiptNumber,
    this.paymentMethod = 'card',
    required this.createdAt,
    this.metadata,
  });

  String get formattedAmount => '$amount $currencySymbol';

  Map<String, dynamic> toMap() => {
    'id': id,
    'organization_id': organizationId,
    'organizationId': organizationId,
    'branch_id': branchId,
    'branchId': branchId,
    'client_id': clientId,
    'clientId': clientId,
    'client_name': clientName,
    'clientName': clientName,
    if (childId != null) 'child_id': childId,
    if (childId != null) 'childId': childId,
    if (childName != null) 'child_name': childName,
    if (childName != null) 'childName': childName,
    'package_id': packageId,
    'packageId': packageId,
    'package_name': packageName,
    'packageName': packageName,
    'amount': amount,
    'currency': currency,
    'currency_symbol': currencySymbol,
    'currencySymbol': currencySymbol,
    'payment_gateway': paymentGateway,
    'status': status.name,
    'transaction_id': transactionId,
    'receipt_number': receiptNumber,
    'payment_method': paymentMethod,
    'created_at': Timestamp.fromDate(createdAt),
    if (metadata != null) 'metadata': metadata,
  };

  factory PaymentTransaction.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final statusStr = map['status'] as String? ?? 'completed';
    final parsedStatus = PaymentStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => PaymentStatus.completed,
    );

    return PaymentTransaction(
      id: id ?? map['id'] as String? ?? '',
      organizationId: map['organization_id'] as String? ?? map['organizationId'] as String? ?? 'cityswim',
      branchId: map['branch_id'] as String? ?? map['branchId'] as String? ?? 'kyiv',
      clientId: map['client_id'] as String? ?? map['clientId'] as String? ?? '',
      clientName: map['client_name'] as String? ?? map['clientName'] as String? ?? '',
      childId: map['child_id'] as String? ?? map['childId'] as String?,
      childName: map['child_name'] as String? ?? map['childName'] as String?,
      packageId: map['package_id'] as String? ?? map['packageId'] as String? ?? '',
      packageName: map['package_name'] as String? ?? map['packageName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'UAH',
      currencySymbol: map['currency_symbol'] as String? ?? map['currencySymbol'] as String? ?? '₴',
      paymentGateway: map['payment_gateway'] as String? ?? map['paymentGateway'] as String? ?? 'liqpay',
      status: parsedStatus,
      transactionId: map['transaction_id'] as String? ?? map['transactionId'] as String? ?? '',
      receiptNumber: map['receipt_number'] as String? ?? map['receiptNumber'] as String? ?? '',
      paymentMethod: map['payment_method'] as String? ?? map['paymentMethod'] as String? ?? 'card',
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
