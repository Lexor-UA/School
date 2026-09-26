import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/subscription/models/subscription_package.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:swimming_school_app/features/tenancy/services/kyiv_migration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stage 3: Kyiv Migration & Zero Regression Tests', () {
    test('Legacy GroupClass without branch fields safely falls back to Kyiv and CitySwim', () {
      final legacyJson = {
        'id': 'legacy_class_101',
        'title': 'Групове плавання (діти 6-8)',
        'startTime': '2026-10-05T15:00:00.000',
        'endTime': '2026-10-05T15:45:00.000',
        'coachId': 'coach_oleksandr',
        'coachName': 'Олександр Ткач',
        'maxCapacity': 8,
        'enrolledChildIds': ['child_1', 'child_2'],
        'attendedChildIds': ['child_1'],
        'category': 'Плавання',
        'lane': 'Доріжка 2',
        // Notice: NO organizationId, NO branchId, NO timezone, NO locationId, NO poolId
      };

      final gClass = GroupClass.fromJson(legacyJson);

      expect(gClass.id, equals('legacy_class_101'));
      expect(gClass.title, equals('Групове плавання (діти 6-8)'));
      expect(gClass.coachId, equals('coach_oleksandr'));
      expect(gClass.enrolledChildIds, equals(['child_1', 'child_2']));
      expect(gClass.attendedChildIds, equals(['child_1']));
      expect(gClass.lane, equals('Доріжка 2'));

      // Verified fallback attributes
      expect(gClass.organizationId, equals('cityswim'));
      expect(gClass.branchId, equals('kyiv'));
      expect(gClass.timezone, equals('Europe/Kyiv'));
      expect(gClass.locationId, equals('kyiv_main'));
      expect(gClass.poolId, equals('pool_25m'));
    });

    test('Legacy AppUser without branch fields safely falls back to Kyiv and CitySwim', () {
      final legacyUserJson = {
        'id': 'legacy_user_202',
        'name': 'Оксана Петренко',
        'role': 'parent',
        'phone': '+380501234567',
        // NO organizationId, NO branchId, NO branchIds
      };

      final user = AppUser.fromJson(legacyUserJson);

      expect(user.id, equals('legacy_user_202'));
      expect(user.name, equals('Оксана Петренко'));
      expect(user.role, equals(UserRole.parent));
      expect(user.phone, equals('+380501234567'));

      // Verified fallback attributes
      expect(user.organizationId, equals('cityswim'));
      expect(user.branchId, equals('kyiv'));
      expect(user.branchIds, equals(['kyiv']));
    });

    test('Legacy Subscription without branch fields safely falls back to UAH and Kyiv', () {
      final legacySubJson = {
        'id': 'legacy_sub_303',
        'userId': 'legacy_user_202',
        'totalClasses': 8,
        'remainingClasses': 5,
        'isActive': true,
        'serviceName': 'Дитячий абонемент 6-8 років (8 тренувань)',
        'ownerName': 'Тимофій Петренко',
        // NO organizationId, NO branchId, NO currency, NO currencySymbol
      };

      final sub = Subscription.fromJson(legacySubJson);

      expect(sub.id, equals('legacy_sub_303'));
      expect(sub.totalClasses, equals(8));
      expect(sub.remainingClasses, equals(5));
      expect(sub.isActive, isTrue);
      expect(sub.serviceName, equals('Дитячий абонемент 6-8 років (8 тренувань)'));

      // Verified fallback attributes
      expect(sub.organizationId, equals('cityswim'));
      expect(sub.branchId, equals('kyiv'));
      expect(sub.currency, equals('UAH'));
      expect(sub.currencySymbol, equals('₴'));
    });

    test('Legacy Child, Family, and ChatDialog safely fall back to Kyiv', () {
      final legacyChildJson = {
        'id': 'ch_404',
        'parentId': 'parent_202',
        'name': 'Тимофій',
        'age': 7,
      };
      final child = Child.fromJson(legacyChildJson);
      expect(child.organizationId, equals('cityswim'));
      expect(child.branchId, equals('kyiv'));

      final legacyFamilyJson = {
        'id': 'fam_505',
        'primaryParentId': 'parent_202',
        'parentIds': ['parent_202'],
        'parentNames': {'parent_202': 'Оксана'},
        'inviteCode': 'KYIV77',
        'createdAt': '2026-01-01T10:00:00.000',
      };
      final family = Family.fromJson(legacyFamilyJson);
      expect(family.organizationId, equals('cityswim'));
      expect(family.branchId, equals('kyiv'));

      final legacyChatJson = {
        'id': 'chat_606',
        'clientId': 'parent_202',
        'clientName': 'Оксана',
        'lastMessage': 'Добрий день!',
        'lastMessageTime': '2026-09-01T12:00:00.000',
        'updatedAt': '2026-09-01T12:00:00.000',
      };
      final chat = ChatDialog.fromJson(legacyChatJson);
      expect(chat.organizationId, equals('cityswim'));
      expect(chat.branchId, equals('kyiv'));
    });

    test('Kyiv existing packages retain exact pricing and functionality (Zero Regression)', () {
      final kyivPackages = SubscriptionPackageCatalog.kyivPackages;

      expect(kyivPackages.isNotEmpty, isTrue);
      expect(kyivPackages.every((p) => p.branchId == 'kyiv'), isTrue);
      expect(kyivPackages.every((p) => p.currency == 'UAH'), isTrue);

      final pack8 = kyivPackages.firstWhere((p) => p.id == 'kyiv_child_6_8_8');
      expect(pack8.price, equals(1900));
      expect(pack8.classes, equals(8));
      expect(pack8.validityDays, equals(30));
      expect(pack8.formattedPrice, equals('1900 грн'));
    });

    test('MigrationSummary correctly reports stats and errors', () {
      const summary = MigrationSummary(
        organizationsCreated: 1,
        branchesCreated: 2,
        classesUpdated: 42,
        usersUpdated: 15,
        subscriptionsUpdated: 30,
        childrenUpdated: 20,
        chatsUpdated: 10,
        familiesUpdated: 8,
        isSuccess: true,
      );

      expect(summary.isSuccess, isTrue);
      expect(summary.classesUpdated, equals(42));
      expect(summary.usersUpdated, equals(15));
      expect(summary.toString().contains('classes: 42'), isTrue);
    });
  });
}
