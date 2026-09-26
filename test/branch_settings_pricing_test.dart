import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/tenancy/utils/branch_timezone_helper.dart';
import 'package:swimming_school_app/shared/utils/currency_formatter.dart';

void main() {
  group('Stage 6: Branch Timezone & DST Calculation Tests (TZ Point 11)', () {
    test('Standard winter time: Kyiv is UTC+2, Vienna is UTC+1', () {
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0, 0);

      expect(BranchTimezoneHelper.isDaylightSavingTime(winterDate), isFalse);

      final kyivOffset = BranchTimezoneHelper.getUtcOffset(winterDate, 'kyiv');
      final viennaOffset = BranchTimezoneHelper.getUtcOffset(winterDate, 'vienna');

      expect(kyivOffset, equals(const Duration(hours: 2)));
      expect(viennaOffset, equals(const Duration(hours: 1)));

      final kyivTime = BranchTimezoneHelper.toBranchLocalTime(winterDate, 'kyiv');
      final viennaTime = BranchTimezoneHelper.toBranchLocalTime(winterDate, 'vienna');

      expect(kyivTime.hour, equals(14));
      expect(viennaTime.hour, equals(13));
    });

    test('Summer daylight saving time: Kyiv is UTC+3, Vienna is UTC+2', () {
      final summerDate = DateTime.utc(2026, 7, 15, 12, 0, 0);

      expect(BranchTimezoneHelper.isDaylightSavingTime(summerDate), isTrue);

      final kyivOffset = BranchTimezoneHelper.getUtcOffset(summerDate, 'kyiv');
      final viennaOffset = BranchTimezoneHelper.getUtcOffset(summerDate, 'vienna');

      expect(kyivOffset, equals(const Duration(hours: 3)));
      expect(viennaOffset, equals(const Duration(hours: 2)));

      final kyivTime = BranchTimezoneHelper.toBranchLocalTime(summerDate, 'kyiv');
      final viennaTime = BranchTimezoneHelper.toBranchLocalTime(summerDate, 'vienna');

      expect(kyivTime.hour, equals(15));
      expect(viennaTime.hour, equals(14));
    });

    test('TZ Point 11 requirement: Vienna coach sees 17:00 Vienna time for class regardless of admin device timezone', () {
      // Vienna class at 17:00 Vienna local time in summer (UTC+2) -> stored as 15:00 UTC
      final classUtcStart = DateTime.utc(2026, 6, 10, 15, 0, 0);
      final classUtcEnd = DateTime.utc(2026, 6, 10, 15, 45, 0);

      final viennaClass = GroupClass(
        id: 'class_vienna_1',
        title: 'Kinder 6-8 HappyLand',
        startTime: classUtcStart,
        endTime: classUtcEnd,
        coachId: 'coach_maria',
        coachName: 'Coach Maria',
        maxCapacity: 6,
        category: 'Плавання',
        lane: 'Lane 1',
        organizationId: 'cityswim',
        branchId: 'vienna',
        timezone: 'Europe/Vienna',
        locationId: 'happyland',
        poolId: 'sports_pool',
      );

      // In Vienna local time, this is 17:00 - 17:45
      expect(viennaClass.formatBranchTime(), equals('17:00'));
      expect(viennaClass.formatBranchTimeRange(), equals('17:00 - 17:45'));

      // If queried for Kyiv timezone, the exact same moment is 18:00
      final kyivFormatted = BranchTimezoneHelper.formatTime(viennaClass.startTime, branchId: 'kyiv');
      expect(kyivFormatted, equals('18:00'));
    });

    test('toUtc accurately converts branch local time to UTC for storage', () {
      final viennaLocalSummer = DateTime(2026, 6, 15, 17, 0, 0);
      final utcFromVienna = BranchTimezoneHelper.toUtc(viennaLocalSummer, 'vienna');
      expect(utcFromVienna.hour, equals(15));

      final kyivLocalWinter = DateTime(2026, 12, 10, 10, 0, 0);
      final utcFromKyiv = BranchTimezoneHelper.toUtc(kyivLocalWinter, 'kyiv');
      expect(utcFromKyiv.hour, equals(8));
    });
  });

  group('Stage 6: Subscription Packages Catalog & Pricing Tests (TZ Point 13 & 14)', () {
    test('Kyiv packages contain exact core pricing tiers from TZ Point 13', () {
      final kyivCore = SubscriptionPackageCatalog.getCorePackages('kyiv');
      expect(kyivCore.length, equals(6));

      final trial = kyivCore.firstWhere((p) => p.id == 'kyiv_trial');
      expect(trial.price, equals(0));
      expect(trial.currency, equals('UAH'));
      expect(trial.currencySymbol, equals('₴'));
      expect(trial.classes, equals(1));

      final single = kyivCore.firstWhere((p) => p.id == 'kyiv_single');
      expect(single.price, equals(450));
      expect(single.classes, equals(1));

      final month4 = kyivCore.firstWhere((p) => p.id == 'kyiv_month_4');
      expect(month4.price, equals(1600));
      expect(month4.classes, equals(4));

      final month8 = kyivCore.firstWhere((p) => p.id == 'kyiv_month_8');
      expect(month8.price, equals(3000));
      expect(month8.classes, equals(8));

      final month12 = kyivCore.firstWhere((p) => p.id == 'kyiv_month_12');
      expect(month12.price, equals(4200));
      expect(month12.classes, equals(12));

      final individual = kyivCore.firstWhere((p) => p.id == 'kyiv_individual');
      expect(individual.price, equals(800));
      expect(individual.isIndividual, isTrue);

      expect(kyivCore.every((p) => p.branchId == 'kyiv'), isTrue);
      expect(kyivCore.every((p) => p.currency == 'UAH'), isTrue);
    });

    test('Vienna packages contain exact core pricing tiers from TZ Point 14', () {
      final viennaCore = SubscriptionPackageCatalog.getCorePackages('vienna');
      expect(viennaCore.length, equals(6));

      final schnupper = viennaCore.firstWhere((p) => p.id == 'vienna_schnuppertraining');
      expect(schnupper.price, equals(0));
      expect(schnupper.currency, equals('EUR'));
      expect(schnupper.currencySymbol, equals('€'));
      expect(schnupper.classes, equals(1));

      final einzelstunde = viennaCore.firstWhere((p) => p.id == 'vienna_einzelstunde');
      expect(einzelstunde.price, equals(25));
      expect(einzelstunde.classes, equals(1));

      final monat4 = viennaCore.firstWhere((p) => p.id == 'vienna_monat_4');
      expect(monat4.price, equals(75));
      expect(monat4.classes, equals(4));

      final monat8 = viennaCore.firstWhere((p) => p.id == 'vienna_monat_8');
      expect(monat8.price, equals(130));
      expect(monat8.classes, equals(8));

      final monat12 = viennaCore.firstWhere((p) => p.id == 'vienna_monat_12');
      expect(monat12.price, equals(180));
      expect(monat12.classes, equals(12));

      final einzelunterricht = viennaCore.firstWhere((p) => p.id == 'vienna_einzelunterricht');
      expect(einzelunterricht.price, equals(60));
      expect(einzelunterricht.isIndividual, isTrue);

      expect(viennaCore.every((p) => p.branchId == 'vienna'), isTrue);
      expect(viennaCore.every((p) => p.currency == 'EUR'), isTrue);
      expect(viennaCore.every((p) => p.currencySymbol == '€'), isTrue);
    });

    test('Packages support multi-language localizations (de, en, uk)', () {
      final viennaPass = SubscriptionPackageCatalog.getById('vienna_monat_8');
      expect(viennaPass, isNotNull);
      expect(viennaPass!.getLocalizedName('de'), equals('8 Einheiten pro Monat'));
      expect(viennaPass.getLocalizedName('en'), equals('8 Lessons / Month'));
      expect(viennaPass.getLocalizedName('uk'), contains('8 занять на місяць'));

      final kyivPass = SubscriptionPackageCatalog.getById('kyiv_month_8');
      expect(kyivPass, isNotNull);
      expect(kyivPass!.getLocalizedName('uk'), equals('8 занять на місяць'));
      expect(kyivPass.getLocalizedName('en'), equals('8 Lessons / Month'));
      expect(kyivPass.getLocalizedName('de'), equals('8 Einheiten / Monat'));
    });
  });

  group('Stage 6: CurrencyFormatter Tests (TZ Point 8, 13, 14, 26)', () {
    test('UAH formatting displays amount with thousands separator and ₴ symbol', () {
      expect(CurrencyFormatter.format(124500, currencyCode: 'UAH'), equals('124 500 ₴'));
      expect(CurrencyFormatter.format(3000, currencyCode: 'UAH'), equals('3 000 ₴'));
      expect(CurrencyFormatter.format(0, currencyCode: 'UAH'), equals('0 ₴'));
    });

    test('EUR formatting displays amount with thousands separator and € symbol', () {
      expect(CurrencyFormatter.format(14850, currencyCode: 'EUR'), equals('14 850 €'));
      expect(CurrencyFormatter.format(130, currencyCode: 'EUR'), equals('130 €'));
      expect(CurrencyFormatter.format(0, currencyCode: 'EUR'), equals('0 €'));
    });

    test('formatForBranch maps correctly by branchId', () {
      expect(CurrencyFormatter.formatForBranch(124500, 'kyiv'), equals('124 500 ₴'));
      expect(CurrencyFormatter.formatForBranch(14850, 'vienna'), equals('14 850 €'));
    });

    test('formatDual strictly preserves distinct currencies without summation', () {
      final dual = CurrencyFormatter.formatDual(kyivAmount: 124500, viennaAmount: 14850);
      expect(dual, equals('124 500 ₴ • 14 850 €'));
      expect(dual, isNot(contains('139'))); // NEVER summed!
    });
  });

  group('Stage 6: Cross-Branch Subscription Rejection Rule (TZ Point 15, 27)', () {
    final kyivSub = Subscription(
      id: 'sub_kyiv_123',
      userId: 'user_taras',
      totalClasses: 8,
      remainingClasses: 6,
      isActive: true,
      serviceName: '8 занять на місяць',
      organizationId: 'cityswim',
      branchId: 'kyiv',
      currency: 'UAH',
      currencySymbol: '₴',
    );

    final viennaSub = Subscription(
      id: 'sub_vienna_456',
      userId: 'user_anna',
      totalClasses: 8,
      remainingClasses: 7,
      isActive: true,
      serviceName: '8 Einheiten pro Monat',
      organizationId: 'cityswim',
      branchId: 'vienna',
      currency: 'EUR',
      currencySymbol: '€',
    );

    final kyivClass = GroupClass(
      id: 'class_kyiv_1',
      title: 'Групове тренування 6-8 р.',
      startTime: DateTime.now().add(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
      coachId: 'coach_igor',
      coachName: 'Ігор Тренер',
      maxCapacity: 8,
      category: 'Плавання',
      organizationId: 'cityswim',
      branchId: 'kyiv',
      timezone: 'Europe/Kyiv',
    );

    final viennaClass = GroupClass(
      id: 'class_vienna_2',
      title: 'Kinder Schwimmkurs 6-8 J.',
      startTime: DateTime.now().add(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
      coachId: 'coach_maria',
      coachName: 'Coach Maria',
      maxCapacity: 8,
      category: 'Плавання',
      organizationId: 'cityswim',
      branchId: 'vienna',
      timezone: 'Europe/Vienna',
    );

    test('Kyiv subscription is strictly valid for Kyiv class and invalid for Vienna class', () {
      expect(kyivSub.branchId == kyivClass.branchId, isTrue);
      expect(kyivSub.branchId == viennaClass.branchId, isFalse);
    });

    test('Vienna subscription is strictly valid for Vienna class and invalid for Kyiv class', () {
      expect(viennaSub.branchId == viennaClass.branchId, isTrue);
      expect(viennaSub.branchId == kyivClass.branchId, isFalse);
    });
  });
}
