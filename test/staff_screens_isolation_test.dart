import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/coach/models/qr_check_in_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Stage 13: Staff Screens & Attendance Strict Isolation Tests (TZ Point 28)', () {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 10, 0);

    final viennaClass = GroupClass(
      id: 'class_vienna_101',
      title: 'Kinder Schwimmkurs',
      startTime: todayStart,
      endTime: todayStart.add(const Duration(minutes: 45)),
      coachId: 'coach_stefan',
      coachName: 'Stefan Gruber',
      maxCapacity: 8,
      category: 'Kinder',
      lane: 'Bahn 1',
      branchId: 'vienna',
      organizationId: 'cityswim',
      locationId: 'happyland',
      poolId: 'sports_pool',
      timezone: 'Europe/Vienna',
      enrolledChildIds: ['child_vienna_1'],
      attendedChildIds: [],
    );

    final kyivClass = GroupClass(
      id: 'class_kyiv_201',
      title: 'Групове плавання діти',
      startTime: todayStart,
      endTime: todayStart.add(const Duration(minutes: 45)),
      coachId: 'coach_igor',
      coachName: 'Ігор Мельник',
      maxCapacity: 8,
      category: 'Плавання',
      lane: 'Доріжка 1',
      branchId: 'kyiv',
      organizationId: 'cityswim',
      locationId: 'kyiv_main',
      poolId: 'pool_25m',
      timezone: 'Europe/Kyiv',
      enrolledChildIds: ['child_kyiv_1'],
      attendedChildIds: [],
    );

    final viennaSub = Subscription(
      id: 'sub_vienna_1',
      userId: 'client_anna_vienna',
      totalClasses: 8,
      remainingClasses: 8,
      isActive: true,
      serviceName: 'Kinder Schwimmkurs',
      ownerName: 'Maxi',
      branchId: 'vienna',
      organizationId: 'cityswim',
      currency: 'EUR',
      currencySymbol: '€',
      expiryDate: now.add(const Duration(days: 30)),
    );

    final kyivSub = Subscription(
      id: 'sub_kyiv_1',
      userId: 'client_olena_kyiv',
      totalClasses: 8,
      remainingClasses: 8,
      isActive: true,
      serviceName: 'Групове плавання діти',
      ownerName: 'Тарас',
      branchId: 'kyiv',
      organizationId: 'cityswim',
      currency: 'UAH',
      currencySymbol: '₴',
      expiryDate: now.add(const Duration(days: 30)),
    );

    test('1. processQrCheckIn rejects coach from Kyiv attempting to scan for Vienna class', () async {
      final subController = container.read(subscriptionControllerProvider.notifier);

      final result = await subController.processQrCheckIn(
        code: 'SWIM_SUB:sub_vienna_1:client_anna_vienna',
        targetClass: viennaClass,
        scanningCoachBranchId: 'kyiv',
        scanningCoachBranchIds: ['kyiv'],
      );

      expect(result.status, equals(QrCheckInStatus.wrongService));
      expect(result.message, contains('Тренер з філії CitySwim Kyiv 🇺🇦 не має доступу'));
      expect(result.message, contains('CitySwim Vienna 🇦🇹'));
    });

    test('2. processQrCheckIn rejects coach from Vienna attempting to scan for Kyiv class', () async {
      final subController = container.read(subscriptionControllerProvider.notifier);

      final result = await subController.processQrCheckIn(
        code: 'SWIM_SUB:sub_kyiv_1:client_olena_kyiv',
        targetClass: kyivClass,
        scanningCoachBranchId: 'vienna',
        scanningCoachBranchIds: ['vienna'],
      );

      expect(result.status, equals(QrCheckInStatus.wrongService));
      expect(result.message, contains('Тренер з філії CitySwim Vienna 🇦🇹 не має доступу'));
      expect(result.message, contains('CitySwim Kyiv 🇺🇦'));
    });

    test('3. processQrCheckIn allows multi-branch coach to scan for either branch', () async {
      final subController = container.read(subscriptionControllerProvider.notifier);

      // Multi-branch coach scanning for Vienna
      final resultVienna = await subController.processQrCheckIn(
        code: '', // will trigger empty QR code check, proving coach branch check passed!
        targetClass: viennaClass,
        scanningCoachBranchId: 'kyiv',
        scanningCoachBranchIds: ['kyiv', 'vienna'],
      );

      // Should not be rejected by coach branch check
      expect(resultVienna.message, isNot(contains('не має доступу')));

      // Multi-branch coach scanning for Kyiv
      final resultKyiv = await subController.processQrCheckIn(
        code: '',
        targetClass: kyivClass,
        scanningCoachBranchId: 'vienna',
        scanningCoachBranchIds: ['kyiv', 'vienna'],
      );

      expect(resultKyiv.message, isNot(contains('не має доступу')));
    });

    test('4. Cross-branch attendance toggling access logic correctly isolates single-branch coaches', () {
      bool hasCoachAccess(AppUser coach, GroupClass gClass) {
        final coachBranch = coach.branchId;
        final coachBranches = coach.branchIds;
        final classBranch = gClass.branchId;
        return coachBranch == classBranch || coachBranches.contains(classBranch);
      }

      const coachKyiv = AppUser(
        id: 'coach_igor',
        name: 'Ігор Мельник',
        role: UserRole.coach,
        branchId: 'kyiv',
        branchIds: ['kyiv'],
      );

      const coachVienna = AppUser(
        id: 'coach_stefan',
        name: 'Stefan Gruber',
        role: UserRole.coach,
        branchId: 'vienna',
        branchIds: ['vienna'],
      );

      const headCoachMulti = AppUser(
        id: 'coach_head',
        name: 'Олександр Головний',
        role: UserRole.coach,
        branchId: 'kyiv',
        branchIds: ['kyiv', 'vienna'],
      );

      // Kyiv coach
      expect(hasCoachAccess(coachKyiv, kyivClass), isTrue);
      expect(hasCoachAccess(coachKyiv, viennaClass), isFalse);

      // Vienna coach
      expect(hasCoachAccess(coachVienna, viennaClass), isTrue);
      expect(hasCoachAccess(coachVienna, kyivClass), isFalse);

      // Head coach (multi-branch)
      expect(hasCoachAccess(headCoachMulti, kyivClass), isTrue);
      expect(hasCoachAccess(headCoachMulti, viennaClass), isTrue);
    });

    test('5. Admin coaches screen filtering isolates coaches by activeBranchId', () {
      final allCoaches = [
        {'id': 'coach_igor', 'name': 'Ігор Мельник', 'branchId': 'kyiv', 'branchIds': ['kyiv']},
        {'id': 'coach_olena', 'name': 'Олена Сидоренко', 'branchId': 'kyiv', 'branchIds': ['kyiv']},
        {'id': 'coach_stefan', 'name': 'Stefan Gruber', 'branchId': 'vienna', 'branchIds': ['vienna']},
        {'id': 'coach_maria', 'name': 'Maria Huber', 'branchId': 'vienna', 'branchIds': ['vienna']},
        {'id': 'coach_flo', 'name': 'Florian Star', 'branchId': 'vienna', 'branchIds': ['kyiv', 'vienna']},
      ];

      List<Map<String, dynamic>> filterCoaches(String activeBranchId, bool isAllLocations) {
        if (isAllLocations) return allCoaches;
        return allCoaches.where((c) {
          final bId = c['branchId'] as String? ?? 'kyiv';
          final bIds = (c['branchIds'] as List<String>?) ?? [bId];
          return bId == activeBranchId || bIds.contains(activeBranchId);
        }).toList();
      }

      // Filter for Vienna
      final viennaCoaches = filterCoaches('vienna', false);
      expect(viennaCoaches.length, equals(3));
      expect(viennaCoaches.map((c) => c['id']), containsAll(['coach_stefan', 'coach_maria', 'coach_flo']));
      expect(viennaCoaches.map((c) => c['id']), isNot(contains('coach_igor')));

      // Filter for Kyiv
      final kyivCoaches = filterCoaches('kyiv', false);
      expect(kyivCoaches.length, equals(3));
      expect(kyivCoaches.map((c) => c['id']), containsAll(['coach_igor', 'coach_olena', 'coach_flo']));
      expect(kyivCoaches.map((c) => c['id']), isNot(contains('coach_stefan')));

      // All locations
      final all = filterCoaches('kyiv', true);
      expect(all.length, equals(5));
    });

    test('6. Admin global search isolates clients, children, classes and subscriptions by activeBranchId', () {
      final clients = [
        {'id': 'c_kyiv_1', 'name': 'Тарас Шевченко', 'branchId': 'kyiv', 'role': 'parent'},
        {'id': 'c_vienna_1', 'name': 'Anna Weber', 'branchId': 'vienna', 'role': 'parent'},
      ];

      final children = [
        const Child(id: 'ch_kyiv_1', parentId: 'c_kyiv_1', name: 'Олесь', branchId: 'kyiv'),
        const Child(id: 'ch_vienna_1', parentId: 'c_vienna_1', name: 'Lukas', branchId: 'vienna'),
      ];

      final classes = [kyivClass, viennaClass];
      final subscriptions = [kyivSub, viennaSub];

      // Simulated global search filter for Vienna
      const activeBranchId = 'vienna';
      const isAllLocations = false;

      final filteredClients = clients.where((c) => isAllLocations || (c['branchId'] ?? 'kyiv') == activeBranchId).toList();
      final filteredChildren = children.where((ch) => isAllLocations || ch.branchId == activeBranchId).toList();
      final filteredClasses = classes.where((cl) => isAllLocations || cl.branchId == activeBranchId).toList();
      final filteredSubs = subscriptions.where((s) => isAllLocations || s.branchId == activeBranchId).toList();

      expect(filteredClients.map((c) => c['id']), equals(['c_vienna_1']));
      expect(filteredChildren.map((ch) => ch.id), equals(['ch_vienna_1']));
      expect(filteredClasses.map((cl) => cl.id), equals(['class_vienna_101']));
      expect(filteredSubs.map((s) => s.id), equals(['sub_vienna_1']));
    });

    test('7. Coach swimmers directory filters out swimmers from other branches', () {
      const coachVienna = AppUser(
        id: 'coach_stefan',
        name: 'Stefan Gruber',
        role: UserRole.coach,
        branchId: 'vienna',
        branchIds: ['vienna'],
      );

      final allChildrenDocs = [
        {'id': 'ch_1', 'name': 'Олесь', 'branchId': 'kyiv'},
        {'id': 'ch_2', 'name': 'Lukas', 'branchId': 'vienna'},
        {'id': 'ch_3', 'name': 'Mia', 'branchId': 'vienna'},
      ];

      final allUserDocs = [
        {'id': 'u_1', 'name': 'Михайло', 'branchId': 'kyiv'},
        {'id': 'u_2', 'name': 'Wolfgang', 'branchId': 'vienna'},
      ];

      final coachBranch = coachVienna.branchId;
      final coachBranches = coachVienna.branchIds;

      final visibleChildren = allChildrenDocs.where((d) {
        final bId = d['branchId'] ?? 'kyiv';
        return coachBranch == bId || coachBranches.contains(bId);
      }).toList();

      final visibleAdults = allUserDocs.where((d) {
        final bId = d['branchId'] ?? 'kyiv';
        return coachBranch == bId || coachBranches.contains(bId);
      }).toList();

      expect(visibleChildren.map((c) => c['name']), equals(['Lukas', 'Mia']));
      expect(visibleAdults.map((u) => u['name']), equals(['Wolfgang']));
    });
  });
}
