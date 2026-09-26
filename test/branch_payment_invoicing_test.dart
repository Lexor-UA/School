import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/payment/models/branch_payment_config.dart';
import 'package:swimming_school_app/features/payment/models/payment_receipt.dart';
import 'package:swimming_school_app/features/payment/models/payment_transaction.dart';
import 'package:swimming_school_app/features/payment/services/branch_payment_service.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';

void main() {
  group('Stage 9: Branch Payment & Invoicing Architecture Tests (TZ Points 20, 21, 22)', () {
    late BranchPaymentService paymentService;

    setUp(() {
      paymentService = BranchPaymentService();
    });

    test('Kyiv payment config is isolated to LiqPay, UAH ₴, and Ukrainian legal entity', () {
      final config = BranchPaymentConfig.kyiv;

      expect(config.branchId, equals('kyiv'));
      expect(config.organizationId, equals('cityswim'));
      expect(config.provider, equals('liqpay'));
      expect(config.gatewayName, equals('LiqPay'));
      expect(config.currency, equals('UAH'));
      expect(config.currencySymbol, equals('₴'));
      expect(config.isTestMode, isTrue);
      expect(config.supportedMethods, containsAll(['card', 'apple_pay', 'google_pay']));

      // Перевірка реквізитів інвойсингу
      final legal = config.legalEntityDetails;
      expect(legal['companyName'], contains('СітіСвім Україна'));
      expect(legal['taxIdLabel'], equals('ЄДРПОУ'));
      expect(legal['taxId'], equals('43892104'));
      expect(legal['address'], contains('Київ'));
      expect(legal['iban'], startsWith('UA'));
    });

    test('Vienna payment config is isolated to Stripe, EUR €, and Austrian legal entity', () {
      final config = BranchPaymentConfig.vienna;

      expect(config.branchId, equals('vienna'));
      expect(config.organizationId, equals('cityswim'));
      expect(config.provider, equals('stripe'));
      expect(config.gatewayName, equals('Stripe'));
      expect(config.currency, equals('EUR'));
      expect(config.currencySymbol, equals('€'));
      expect(config.isTestMode, isTrue);
      expect(config.supportedMethods, containsAll(['card', 'apple_pay', 'google_pay', 'sepa']));

      // Перевірка австрійських реквізитів інвойсингу
      final legal = config.legalEntityDetails;
      expect(legal['companyName'], equals('CitySwim Vienna GmbH'));
      expect(legal['taxIdLabel'], equals('UID-Nummer'));
      expect(legal['taxId'], equals('ATU78945612'));
      expect(legal['address'], contains('Klosterneuburg'));
      expect(legal['iban'], startsWith('AT'));
      expect(legal['country'], equals('Österreich'));
    });

    test('BranchPaymentConfig.forBranch returns correct configuration dynamically', () {
      expect(BranchPaymentConfig.forBranch('kyiv').provider, equals('liqpay'));
      expect(BranchPaymentConfig.forBranch('vienna').provider, equals('stripe'));
      expect(BranchPaymentConfig.forBranch('unknown_branch').provider, equals('liqpay')); // default fallback
    });

    test('Successful Mock Payment in Kyiv generates LiqPay transaction and Ukrainian receipt', () async {
      final kyivPackage = SubscriptionPackageCatalog.getById('kyiv_month_8')!;
      expect(kyivPackage.branchId, equals('kyiv'));
      expect(kyivPackage.price, equals(3000));
      expect(kyivPackage.currency, equals('UAH'));

      final receipt = await paymentService.processMockPayment(
        branchId: 'kyiv',
        clientId: 'client_petro_kyiv',
        clientName: 'Петро Коваленко',
        childName: 'Богдан Коваленко',
        package: kyivPackage,
        paymentMethod: 'apple_pay',
        latency: Duration.zero,
      );

      expect(receipt.branchId, equals('kyiv'));
      expect(receipt.branchName, equals('CitySwim Kyiv'));
      expect(receipt.clientName, equals('Петро Коваленко'));
      expect(receipt.childName, equals('Богдан Коваленко'));
      expect(receipt.packageName, equals('8 занять на місяць'));
      expect(receipt.classesCount, equals(8));
      expect(receipt.amount, equals(3000.0));
      expect(receipt.currency, equals('UAH'));
      expect(receipt.currencySymbol, equals('₴'));
      expect(receipt.paymentGateway, equals('LiqPay'));
      expect(receipt.transactionId, startsWith('TX-KYIV-LIQPAY'));
      expect(receipt.receiptNumber, startsWith('REC-CS-UA'));
      expect(receipt.legalDetails['taxIdLabel'], equals('ЄДРПОУ'));
    });

    test('Successful Mock Payment in Vienna generates Stripe transaction and Austrian receipt', () async {
      final viennaPackage = SubscriptionPackageCatalog.getById('vienna_monat_8')!;
      expect(viennaPackage.branchId, equals('vienna'));
      expect(viennaPackage.price, equals(130));
      expect(viennaPackage.currency, equals('EUR'));

      final receipt = await paymentService.processMockPayment(
        branchId: 'vienna',
        clientId: 'client_anna_vienna',
        clientName: 'Anna Müller',
        childName: 'Maximilian Müller',
        package: viennaPackage,
        paymentMethod: 'card',
        latency: Duration.zero,
      );

      expect(receipt.branchId, equals('vienna'));
      expect(receipt.branchName, equals('CitySwim Vienna'));
      expect(receipt.clientName, equals('Anna Müller'));
      expect(receipt.childName, equals('Maximilian Müller'));
      expect(receipt.packageName, equals('8 Einheiten pro Monat'));
      expect(receipt.classesCount, equals(8));
      expect(receipt.amount, equals(130.0));
      expect(receipt.currency, equals('EUR'));
      expect(receipt.currencySymbol, equals('€'));
      expect(receipt.paymentGateway, equals('Stripe'));
      expect(receipt.transactionId, startsWith('TX-VIE-STRIPE'));
      expect(receipt.receiptNumber, startsWith('REC-CS-AT'));
      expect(receipt.legalDetails['taxIdLabel'], equals('UID-Nummer'));
      expect(receipt.legalDetails['taxId'], equals('ATU78945612'));
    });

    test('Security & Data Integrity: Cross-branch payment is strictly rejected', () async {
      final viennaPackage = SubscriptionPackageCatalog.getById('vienna_monat_8')!;

      // Спроба сплатити віденський пакет через київську філію повинна кидати ArgumentError
      expect(
        () => paymentService.processMockPayment(
          branchId: 'kyiv',
          clientId: 'client_123',
          clientName: 'Test Client',
          package: viennaPackage,
          latency: Duration.zero,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Крос-філіальний платіж заблоковано'),
        )),
      );

      final kyivPackage = SubscriptionPackageCatalog.getById('kyiv_month_8')!;

      // Спроба сплатити київський пакет через віденську філію повинна кидати ArgumentError
      expect(
        () => paymentService.processMockPayment(
          branchId: 'vienna',
          clientId: 'client_456',
          clientName: 'Test Client',
          package: kyivPackage,
          latency: Duration.zero,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Крос-філіальний платіж заблоковано'),
        )),
      );
    });

    test('PaymentReceipt.formatPlainText produces properly formatted receipt text with legal details', () {
      final config = BranchPaymentConfig.vienna;
      final transaction = PaymentTransaction(
        id: 'pay_test_001',
        organizationId: 'cityswim',
        branchId: 'vienna',
        clientId: 'client_anna',
        clientName: 'Anna Müller',
        childName: 'Maximilian Müller',
        packageId: 'vienna_monat_8',
        packageName: '8 Einheiten pro Monat',
        amount: 130.0,
        currency: 'EUR',
        currencySymbol: '€',
        paymentGateway: 'stripe',
        transactionId: 'TX-VIE-STRIPE-881234',
        receiptNumber: 'REC-CS-AT-12345',
        paymentMethod: 'apple_pay',
        createdAt: DateTime(2026, 9, 26, 12, 30),
      );

      final receipt = PaymentReceipt.fromTransaction(
        transaction: transaction,
        config: config,
        classesCount: 8,
        validityDays: 30,
      );

      final plainText = receipt.formatPlainText();

      expect(plainText, contains('CitySwim Vienna'));
      expect(plainText, contains('REC-CS-AT-12345'));
      expect(plainText, contains('TX-VIE-STRIPE-881234'));
      expect(plainText, contains('Stripe (Тестовий режим / Mock)'));
      expect(plainText, contains('Anna Müller'));
      expect(plainText, contains('Maximilian Müller'));
      expect(plainText, contains('130.0 €'));
      expect(plainText, contains('UID-Nummer: ATU78945612'));
      expect(plainText, contains('In der Au 1, 3400 Klosterneuburg'));
    });

    test('PaymentTransaction serialization to/from Map preserves all fields', () {
      final now = DateTime(2026, 9, 26, 10, 15);
      final transaction = PaymentTransaction(
        id: 'pay_sample_123',
        organizationId: 'cityswim',
        branchId: 'kyiv',
        clientId: 'user_999',
        clientName: 'Олена Сидоренко',
        childId: 'child_111',
        childName: 'Михайлик',
        packageId: 'kyiv_month_4',
        packageName: '4 заняття на місяць',
        amount: 1600.0,
        currency: 'UAH',
        currencySymbol: '₴',
        paymentGateway: 'liqpay',
        status: PaymentStatus.completed,
        transactionId: 'TX-KYIV-LIQPAY-998877',
        receiptNumber: 'REC-CS-UA-55443',
        paymentMethod: 'card',
        createdAt: now,
      );

      final map = transaction.toMap();
      expect(map['organization_id'], equals('cityswim'));
      expect(map['branch_id'], equals('kyiv'));
      expect(map['amount'], equals(1600.0));
      expect(map['status'], equals('completed'));

      final restored = PaymentTransaction.fromMap(map, id: 'pay_sample_123');
      expect(restored.id, equals('pay_sample_123'));
      expect(restored.branchId, equals('kyiv'));
      expect(restored.clientName, equals('Олена Сидоренко'));
      expect(restored.childName, equals('Михайлик'));
      expect(restored.amount, equals(1600.0));
      expect(restored.currency, equals('UAH'));
      expect(restored.currencySymbol, equals('₴'));
      expect(restored.status, equals(PaymentStatus.completed));
    });
  });
}

