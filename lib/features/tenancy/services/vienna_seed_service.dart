import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/utils/branch_timezone_helper.dart';

/// Результат заповнення тестових даних філії Відень
class ViennaSeedResult {
  final int usersCreated;
  final int childrenCreated;
  final int classesCreated;
  final int subscriptionsCreated;
  final bool isSuccess;
  final String? errorMessage;

  const ViennaSeedResult({
    this.usersCreated = 0,
    this.childrenCreated = 0,
    this.classesCreated = 0,
    this.subscriptionsCreated = 0,
    this.isSuccess = true,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'ViennaSeedResult(users: $usersCreated, children: $childrenCreated, '
        'classes: $classesCreated, subs: $subscriptionsCreated, success: $isSuccess)';
  }
}

/// Сервіс ініціалізації та наповнення інфраструктури філії CitySwim Vienna (ТЗ Етап 7)
///
/// Забезпечує автономне функціонування філії Відень:
/// 1. Локація: HappyLand (Sports Pool з доріжками Lane 1, Lane 2, Lane 5 та Wellenbecken).
/// 2. Персонал: Admin Vienna та австрійські тренери (Coach Maria Huber, Coach Stefan Gruber).
/// 3. Клієнти: Anna Müller, Lukas Weber та їхні діти (Maximilian, Sophie).
/// 4. Абонементи: активні абонементи у валюті EUR (€).
/// 5. Розклад: тренування у часовому поясі `Europe/Vienna` з правильним збереженням у UTC.
class ViennaSeedService {
  final FirebaseFirestore _firestore;

  ViennaSeedService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 1. ПЕРСОНАЛ ТА АДМІНІСТРАЦІЯ ВІДНЯ (Staff)
  // ---------------------------------------------------------------------------

  static const AppUser adminVienna = AppUser(
    id: 'admin_vienna',
    name: 'Admin Vienna',
    loginId: 'vienna.admin@cityswim.at',
    phone: '+43 1 234 5678',
    role: UserRole.admin,
    organizationId: 'cityswim',
    branchId: 'vienna',
    branchIds: ['vienna'],
  );

  static const AppUser coachMaria = AppUser(
    id: 'coach_maria',
    name: 'Coach Maria Huber',
    loginId: 'maria.huber@cityswim.at',
    phone: '+43 676 1234567',
    role: UserRole.coach,
    organizationId: 'cityswim',
    branchId: 'vienna',
    branchIds: ['vienna'],
  );

  static const AppUser coachStefan = AppUser(
    id: 'coach_stefan',
    name: 'Coach Stefan Gruber',
    loginId: 'stefan.gruber@cityswim.at',
    phone: '+43 676 7654321',
    role: UserRole.coach,
    organizationId: 'cityswim',
    branchId: 'vienna',
    branchIds: ['vienna'],
  );

  static List<AppUser> get viennaStaff => const [adminVienna, coachMaria, coachStefan];

  // ---------------------------------------------------------------------------
  // 2. КЛІЄНТИ ТА ДІТИ ВІДНЯ (Clients & Children)
  // ---------------------------------------------------------------------------

  static const AppUser clientAnna = AppUser(
    id: 'client_anna_vienna',
    name: 'Anna Müller',
    loginId: 'anna.mueller@example.at',
    phone: '+43 664 1122334',
    role: UserRole.parent,
    organizationId: 'cityswim',
    branchId: 'vienna',
    branchIds: ['vienna'],
  );

  static const AppUser clientLukas = AppUser(
    id: 'client_lukas_vienna',
    name: 'Lukas Weber',
    loginId: 'lukas.weber@example.at',
    phone: '+43 664 9988776',
    role: UserRole.parent,
    organizationId: 'cityswim',
    branchId: 'vienna',
    branchIds: ['vienna'],
  );

  static List<AppUser> get viennaClients => const [clientAnna, clientLukas];
  static List<AppUser> get allViennaUsers => [...viennaStaff, ...viennaClients];

  static const Child childMaximilian = Child(
    id: 'child_maximilian',
    name: 'Maximilian Müller',
    age: 7,
    parentId: 'client_anna_vienna',
    organizationId: 'cityswim',
    branchId: 'vienna',
  );

  static const Child childSophie = Child(
    id: 'child_sophie',
    name: 'Sophie Weber',
    age: 10,
    parentId: 'client_lukas_vienna',
    organizationId: 'cityswim',
    branchId: 'vienna',
  );

  static List<Child> get viennaChildren => const [childMaximilian, childSophie];

  // ---------------------------------------------------------------------------
  // 3. АБОНЕМЕНТИ ВІДНЯ (EUR €)
  // ---------------------------------------------------------------------------

  static Subscription get subAnna => Subscription(
        id: 'sub_anna_vienna',
        userId: 'client_anna_vienna',
        ownerName: 'Maximilian Müller',
        serviceName: '8 Einheiten pro Monat',
        totalClasses: 8,
        remainingClasses: 6,
        isActive: true,
        expiryDate: DateTime.now().add(const Duration(days: 25)),
        organizationId: 'cityswim',
        branchId: 'vienna',
        currency: 'EUR',
        currencySymbol: '€',
      );

  static Subscription get subLukas => Subscription(
        id: 'sub_lukas_vienna',
        userId: 'client_lukas_vienna',
        ownerName: 'Sophie Weber',
        serviceName: '4 Einheiten pro Monat',
        totalClasses: 4,
        remainingClasses: 3,
        isActive: true,
        expiryDate: DateTime.now().add(const Duration(days: 20)),
        organizationId: 'cityswim',
        branchId: 'vienna',
        currency: 'EUR',
        currencySymbol: '€',
      );

  static List<Subscription> get viennaSubscriptions => [subAnna, subLukas];

  // ---------------------------------------------------------------------------
  // 4. РОЗКЛАД ТА ЗАНЯТТЯ ВІДНЯ (GroupClass)
  // ---------------------------------------------------------------------------

  /// Генерація тестових занять Відня для вказаної дати (за замовчуванням сьогодні)
  static List<GroupClass> generateViennaClasses({DateTime? baseDate}) {
    final date = baseDate ?? DateTime.now();

    // 1. Дитяча група 6-8 років: 16:00 - 16:45 за місцевим часом Відня
    final localStart1 = DateTime(date.year, date.month, date.day, 16, 0);
    final localEnd1 = DateTime(date.year, date.month, date.day, 16, 45);
    final utcStart1 = BranchTimezoneHelper.toUtc(localStart1, 'vienna');
    final utcEnd1 = BranchTimezoneHelper.toUtc(localEnd1, 'vienna');

    final kinderClass = GroupClass(
      id: 'class_vienna_kinder_1',
      title: 'Kinder Schwimmkurs 6-8 J.',
      startTime: utcStart1,
      endTime: utcEnd1,
      coachId: coachMaria.id,
      coachName: coachMaria.name,
      maxCapacity: 6,
      enrolledChildIds: const ['child_maximilian'],
      category: 'Плавання',
      lane: 'Lane 1',
      organizationId: 'cityswim',
      branchId: 'vienna',
      timezone: 'Europe/Vienna',
      locationId: 'happyland',
      poolId: 'sports_pool',
    );

    // 2. Підліткова група 9-15 років: 17:00 - 17:45 за місцевим часом Відня
    final localStart2 = DateTime(date.year, date.month, date.day, 17, 0);
    final localEnd2 = DateTime(date.year, date.month, date.day, 17, 45);
    final utcStart2 = BranchTimezoneHelper.toUtc(localStart2, 'vienna');
    final utcEnd2 = BranchTimezoneHelper.toUtc(localEnd2, 'vienna');

    final jugendClass = GroupClass(
      id: 'class_vienna_jugend_1',
      title: 'Jugend Schwimmtraining 9-15 J.',
      startTime: utcStart2,
      endTime: utcEnd2,
      coachId: coachStefan.id,
      coachName: coachStefan.name,
      maxCapacity: 8,
      enrolledChildIds: const ['child_sophie'],
      category: 'Плавання',
      lane: 'Lane 2',
      organizationId: 'cityswim',
      branchId: 'vienna',
      timezone: 'Europe/Vienna',
      locationId: 'happyland',
      poolId: 'sports_pool',
    );

    // 3. Доросла група (техніка кролю): 19:00 - 20:00 за місцевим часом Відня
    final localStart3 = DateTime(date.year, date.month, date.day, 19, 0);
    final localEnd3 = DateTime(date.year, date.month, date.day, 20, 0);
    final utcStart3 = BranchTimezoneHelper.toUtc(localStart3, 'vienna');
    final utcEnd3 = BranchTimezoneHelper.toUtc(localEnd3, 'vienna');

    final adultClass = GroupClass(
      id: 'class_vienna_adult_1',
      title: 'Erwachsenen Kraultechnik',
      startTime: utcStart3,
      endTime: utcEnd3,
      coachId: coachStefan.id,
      coachName: coachStefan.name,
      maxCapacity: 10,
      enrolledChildIds: const [],
      category: 'Плавання',
      lane: 'Lane 5',
      organizationId: 'cityswim',
      branchId: 'vienna',
      timezone: 'Europe/Vienna',
      locationId: 'happyland',
      poolId: 'sports_pool',
    );

    return [kinderClass, jugendClass, adultClass];
  }

  // ---------------------------------------------------------------------------
  // 5. ЗБЕРЕЖЕННЯ В FIRESTORE (Ідемпотентне)
  // ---------------------------------------------------------------------------

  /// Повне заповнення бази даних Firestore тестовими даними Відня
  Future<ViennaSeedResult> seedViennaBranch() async {
    int usersCount = 0;
    int childrenCount = 0;
    int classesCount = 0;
    int subsCount = 0;

    try {
      // 1. Конфігурація філії Vienna в branch_configs
      await _firestore
          .collection('branch_configs')
          .doc('vienna')
          .set(BranchConfig.viennaConfig.toJson(), SetOptions(merge: true));

      // 2. Користувачі Відня (Адмін, Тренери, Клієнти)
      for (final user in allViennaUsers) {
        await _firestore.collection('users').doc(user.id).set(user.toJson(), SetOptions(merge: true));
        usersCount++;
      }

      // 3. Діти Відня
      for (final child in viennaChildren) {
        await _firestore.collection('children').doc(child.id).set(child.toJson(), SetOptions(merge: true));
        childrenCount++;
      }

      // 4. Абонементи Відня
      for (final sub in viennaSubscriptions) {
        await _firestore.collection('subscriptions').doc(sub.id).set(sub.toJson(), SetOptions(merge: true));
        subsCount++;
      }

      // 5. Заняття Відня
      final classes = generateViennaClasses();
      for (final c in classes) {
        await _firestore.collection('classes').doc(c.id).set(c.toJson(), SetOptions(merge: true));
        classesCount++;
      }

      debugPrint('Vienna branch successfully seeded: $usersCount users, $childrenCount children, '
          '$classesCount classes, $subsCount subscriptions.');

      return ViennaSeedResult(
        usersCreated: usersCount,
        childrenCreated: childrenCount,
        classesCreated: classesCount,
        subscriptionsCreated: subsCount,
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('Error seeding Vienna branch: $e');
      return ViennaSeedResult(
        usersCreated: usersCount,
        childrenCreated: childrenCount,
        classesCreated: classesCount,
        subscriptionsCreated: subsCount,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}
