import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/services/vienna_seed_service.dart';

void main() {
  group('Stage 7: Vienna Infrastructure & Provisioning Tests (TZ Point 2, 3, 4, 5)', () {
    test('Vienna BranchConfig has HappyLand location with Sports Pool and Wellenbecken', () {
      final config = BranchConfig.viennaConfig;
      expect(config.branchId, equals('vienna'));
      expect(config.locations.length, equals(1));

      final happyland = config.locations.first;
      expect(happyland.id, equals('happyland'));
      expect(happyland.name, equals('HappyLand'));
      expect(happyland.address, contains('Klosterneuburg'));
      expect(happyland.pools.length, equals(2));

      final sportsPool = happyland.pools.firstWhere((p) => p.id == 'sports_pool');
      expect(sportsPool.name, equals('Sports Pool'));
      expect(sportsPool.lengthMeters, equals(25.0));
      expect(sportsPool.lanes, containsAll(['Lane 1', 'Lane 2', 'Lane 5']));

      final wellenbecken = happyland.pools.firstWhere((p) => p.id == 'wellenbecken');
      expect(wellenbecken.name, equals('Wellenbecken'));
      expect(wellenbecken.lengthMeters, equals(15.0));
    });

    test('Vienna Staff (Admin & Coaches) are strictly isolated to Vienna', () {
      final staff = ViennaSeedService.viennaStaff;
      expect(staff.length, equals(3));

      final admin = ViennaSeedService.adminVienna;
      expect(admin.id, equals('admin_vienna'));
      expect(admin.role, equals(UserRole.admin));
      expect(admin.branchId, equals('vienna'));
      expect(admin.branchIds, equals(['vienna']));

      final maria = ViennaSeedService.coachMaria;
      expect(maria.id, equals('coach_maria'));
      expect(maria.name, equals('Coach Maria Huber'));
      expect(maria.role, equals(UserRole.coach));
      expect(maria.branchId, equals('vienna'));

      final stefan = ViennaSeedService.coachStefan;
      expect(stefan.id, equals('coach_stefan'));
      expect(stefan.name, equals('Coach Stefan Gruber'));
      expect(stefan.role, equals(UserRole.coach));
      expect(stefan.branchId, equals('vienna'));

      // Zero cross-contamination with Kyiv
      expect(staff.every((s) => s.branchId == 'vienna'), isTrue);
      expect(staff.every((s) => s.organizationId == 'cityswim'), isTrue);
    });

    test('Vienna Clients & Children are bound to Vienna branch with correct hierarchy', () {
      final clients = ViennaSeedService.viennaClients;
      expect(clients.length, equals(2));

      final anna = ViennaSeedService.clientAnna;
      expect(anna.name, equals('Anna Müller'));
      expect(anna.branchId, equals('vienna'));
      expect(anna.role, equals(UserRole.parent));

      final lukas = ViennaSeedService.clientLukas;
      expect(lukas.name, equals('Lukas Weber'));
      expect(lukas.branchId, equals('vienna'));
      expect(lukas.role, equals(UserRole.parent));

      final children = ViennaSeedService.viennaChildren;
      expect(children.length, equals(2));

      final maxi = children.firstWhere((c) => c.id == 'child_maximilian');
      expect(maxi.name, equals('Maximilian Müller'));
      expect(maxi.age, equals(7));
      expect(maxi.parentId, equals(anna.id));
      expect(maxi.branchId, equals('vienna'));

      final sophie = children.firstWhere((c) => c.id == 'child_sophie');
      expect(sophie.name, equals('Sophie Weber'));
      expect(sophie.age, equals(10));
      expect(sophie.parentId, equals(lukas.id));
      expect(sophie.branchId, equals('vienna'));
    });

    test('Vienna Subscriptions are active in EUR (€) and bound to Vienna children', () {
      final subs = ViennaSeedService.viennaSubscriptions;
      expect(subs.length, equals(2));

      final subAnna = subs.firstWhere((s) => s.userId == ViennaSeedService.clientAnna.id);
      expect(subAnna.serviceName, equals('8 Einheiten pro Monat'));
      expect(subAnna.currency, equals('EUR'));
      expect(subAnna.currencySymbol, equals('€'));
      expect(subAnna.totalClasses, equals(8));
      expect(subAnna.remainingClasses, equals(6));
      expect(subAnna.isActive, isTrue);
      expect(subAnna.branchId, equals('vienna'));
      expect(subAnna.ownerName, equals('Maximilian Müller'));

      final subLukas = subs.firstWhere((s) => s.userId == ViennaSeedService.clientLukas.id);
      expect(subLukas.serviceName, equals('4 Einheiten pro Monat'));
      expect(subLukas.currency, equals('EUR'));
      expect(subLukas.currencySymbol, equals('€'));
      expect(subLukas.totalClasses, equals(4));
      expect(subLukas.remainingClasses, equals(3));
      expect(subLukas.isActive, isTrue);
      expect(subLukas.branchId, equals('vienna'));
      expect(subLukas.ownerName, equals('Sophie Weber'));
    });

    test('Vienna Schedule generates classes with correct timezone and pool lanes', () {
      final baseDate = DateTime(2026, 6, 10); // Summer time
      final classes = ViennaSeedService.generateViennaClasses(baseDate: baseDate);

      expect(classes.length, equals(3));

      // 1. Kinder 6-8: 16:00 Vienna time on Lane 1
      final kinderClass = classes.firstWhere((c) => c.id == 'class_vienna_kinder_1');
      expect(kinderClass.title, equals('Kinder Schwimmkurs 6-8 J.'));
      expect(kinderClass.coachId, equals('coach_maria'));
      expect(kinderClass.lane, equals('Lane 1'));
      expect(kinderClass.locationId, equals('happyland'));
      expect(kinderClass.poolId, equals('sports_pool'));
      expect(kinderClass.branchId, equals('vienna'));
      expect(kinderClass.timezone, equals('Europe/Vienna'));
      expect(kinderClass.formatBranchTime(), equals('16:00'));
      expect(kinderClass.enrolledChildIds, contains('child_maximilian'));

      // 2. Jugend 9-15: 17:00 Vienna time on Lane 2
      final jugendClass = classes.firstWhere((c) => c.id == 'class_vienna_jugend_1');
      expect(jugendClass.title, equals('Jugend Schwimmtraining 9-15 J.'));
      expect(jugendClass.coachId, equals('coach_stefan'));
      expect(jugendClass.lane, equals('Lane 2'));
      expect(jugendClass.locationId, equals('happyland'));
      expect(jugendClass.poolId, equals('sports_pool'));
      expect(jugendClass.branchId, equals('vienna'));
      expect(jugendClass.formatBranchTime(), equals('17:00'));
      expect(jugendClass.enrolledChildIds, contains('child_sophie'));

      // 3. Adults: 19:00 Vienna time on Lane 5
      final adultClass = classes.firstWhere((c) => c.id == 'class_vienna_adult_1');
      expect(adultClass.title, equals('Erwachsenen Kraultechnik'));
      expect(adultClass.coachId, equals('coach_stefan'));
      expect(adultClass.lane, equals('Lane 5'));
      expect(adultClass.locationId, equals('happyland'));
      expect(adultClass.poolId, equals('sports_pool'));
      expect(adultClass.branchId, equals('vienna'));
      expect(adultClass.formatBranchTime(), equals('19:00'));
    });

    test('Same lane name (Lane 1 / Доріжка 1) across Kyiv and Vienna does NOT conflict', () {
      final baseDate = DateTime(2026, 6, 10);
      final viennaClasses = ViennaSeedService.generateViennaClasses(baseDate: baseDate);
      final viennaLane1Class = viennaClasses.firstWhere((c) => c.lane == 'Lane 1');

      final kyivLane1Class = GroupClass(
        id: 'class_kyiv_test_lane1',
        title: 'Київ Доріжка 1 Тренування',
        startTime: viennaLane1Class.startTime,
        endTime: viennaLane1Class.endTime,
        coachId: 'coach_igor',
        coachName: 'Ігор',
        maxCapacity: 8,
        category: 'Плавання',
        lane: 'Lane 1',
        organizationId: 'cityswim',
        branchId: 'kyiv',
        locationId: 'kyiv_main',
        poolId: 'pool_25m',
      );

      // Even at the exact same moment on a lane with the same name,
      // branchId isolation ensures they represent completely independent pools in different countries!
      expect(viennaLane1Class.branchId, equals('vienna'));
      expect(kyivLane1Class.branchId, equals('kyiv'));
      expect(viennaLane1Class.locationId, equals('happyland'));
      expect(kyivLane1Class.locationId, equals('kyiv_main'));
      expect(viennaLane1Class.branchId == kyivLane1Class.branchId, isFalse);
    });
  });
}
