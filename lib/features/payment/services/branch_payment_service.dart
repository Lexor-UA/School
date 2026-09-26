import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/payment/models/branch_payment_config.dart';
import 'package:swimming_school_app/features/payment/models/payment_receipt.dart';
import 'package:swimming_school_app/features/payment/models/payment_transaction.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';

final branchPaymentServiceProvider = Provider<BranchPaymentService>((ref) {
  return BranchPaymentService();
});

/// Сервіс обробки платежів та інвойсингу для філій (ТЗ п. 20, 21, 22)
/// Працює у безпечному тестовому/емуляційному режимі (Mock Mode) без реальних списувань коштів.
class BranchPaymentService {
  final FirebaseFirestore? firestore;

  BranchPaymentService({this.firestore});

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  /// Отримати конфігурацію платіжного шлюзу для філії
  BranchPaymentConfig getPaymentConfig(String branchId) {
    return BranchPaymentConfig.forBranch(branchId);
  }

  /// Проведення безпечної тестової оплати пакетного абонемента
  /// 1. Перевіряє сувору приналежність пакета до поточної філії (захист від крос-філіальних оплат).
  /// 2. Емулює безпечну транзакцію шлюзу (LiqPay для Києва / Stripe для Відня).
  /// 3. Зберігає запис про платіж у колекції `payments`.
  /// 4. Створює та активує абонемент для учня у відповідній філії.
  /// 5. Повертає згенеровану електронну квитанцію (PaymentReceipt).
  Future<PaymentReceipt> processMockPayment({
    required String branchId,
    required String clientId,
    required String clientName,
    String? childId,
    String? childName,
    required SubscriptionPackage package,
    String paymentMethod = 'card',
    Duration latency = const Duration(milliseconds: 600),
  }) async {
    final config = getPaymentConfig(branchId);

    // 1. Сувора перевірка філіальної ізоляції
    if (package.branchId != branchId) {
      throw ArgumentError(
        'Крос-філіальний платіж заблоковано! Пакет "${package.name}" (ID: ${package.id}) '
        'належить до філії ${package.branchId}, а оплата ініційована у філії $branchId.',
      );
    }

    if (package.currency != config.currency) {
      throw ArgumentError(
        'Невідповідність валюти! Пакет передбачає оплату в ${package.currency}, '
        'а платіжний шлюз філії $branchId налаштовано на ${config.currency}.',
      );
    }

    // 2. Безпечна емуляція затримки мережевого запиту
    if (latency.inMilliseconds > 0) {
      await Future.delayed(latency);
    }

    // 3. Генерація унікальних ідентифікаторів
    final timestamp = DateTime.now();
    final epoch = timestamp.millisecondsSinceEpoch;
    final txPrefix = branchId == 'vienna' ? 'TX-VIE-STRIPE' : 'TX-KYIV-LIQPAY';
    final txId = '$txPrefix-${epoch.toString().substring(epoch.toString().length - 6)}';
    
    final recPrefix = branchId == 'vienna' ? 'REC-CS-AT' : 'REC-CS-UA';
    final recNumber = '$recPrefix-${epoch.toString().substring(epoch.toString().length - 5)}';

    final paymentDocId = 'pay_${epoch}_${package.id}';

    final transaction = PaymentTransaction(
      id: paymentDocId,
      organizationId: config.organizationId,
      branchId: branchId,
      clientId: clientId,
      clientName: clientName,
      childId: childId,
      childName: childName,
      packageId: package.id,
      packageName: package.name,
      amount: package.price.toDouble(),
      currency: config.currency,
      currencySymbol: config.currencySymbol,
      paymentGateway: config.provider,
      status: PaymentStatus.completed,
      transactionId: txId,
      receiptNumber: recNumber,
      paymentMethod: paymentMethod,
      createdAt: timestamp,
      metadata: {
        'classesCount': package.classes,
        'validityDays': package.validityDays,
        'isMockPayment': true,
        'isTestMode': config.isTestMode,
      },
    );

    // 4. Збереження транзакції в Firestore
    try {
      await _db.collection('payments').doc(transaction.id).set(transaction.toMap());
    } catch (e) {
      debugPrint('Notice: Firestore payments log skipped or offline: $e');
    }

    // 5. Активація абонемента для користувача
    final subId = 'sub_${epoch}_${(childName ?? clientName).hashCode}';
    final expiryDate = timestamp.add(Duration(days: package.validityDays));

    final newSubscription = Subscription(
      id: subId,
      userId: clientId,
      totalClasses: package.classes,
      remainingClasses: package.classes,
      isActive: true,
      serviceName: package.name,
      expiryDate: expiryDate,
      ownerName: childName ?? clientName,
      organizationId: config.organizationId,
      branchId: branchId,
      currency: config.currency,
      currencySymbol: config.currencySymbol,
    );

    try {
      await _db.collection('subscriptions').doc(newSubscription.id).set(newSubscription.toJson());
    } catch (e) {
      debugPrint('Notice: Firestore subscription activation skipped or offline: $e');
    }

    // 6. Формування та повернення електронної квитанції
    return PaymentReceipt.fromTransaction(
      transaction: transaction,
      config: config,
      classesCount: package.classes,
      validityDays: package.validityDays,
    );
  }
}
