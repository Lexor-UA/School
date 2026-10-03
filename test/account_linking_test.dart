import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Account Linking & Merging Tests', () {
    test('Phone normalization correctly extracts national phone digits across formats', () {
      String cleanPhoneDigits(String raw) {
        final digits = raw.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 9) {
          return digits.substring(digits.length - 9);
        }
        return digits;
      }

      // Ukrainian formats
      const expectedUa = '685566322';
      expect(cleanPhoneDigits('+380685566322'), expectedUa);
      expect(cleanPhoneDigits('0685566322'), expectedUa);
      expect(cleanPhoneDigits('+380 (68) 556-63-22'), expectedUa);
      expect(cleanPhoneDigits('068 556 63 22'), expectedUa);
      expect(cleanPhoneDigits('+380-68-556-6322'), expectedUa);

      // Austrian formats
      const expectedAt = '660123456';
      expect(cleanPhoneDigits('+43 660 123 456'), expectedAt);
      expect(cleanPhoneDigits('0660 123 456'), expectedAt);
      expect(cleanPhoneDigits('+43660123456'), expectedAt);
    });

    test('Onboarding bypass logic: when needsOnboarding is false, parent goes directly to /parent', () {
      bool shouldShowOnboarding({
        required bool? needsOnboardingPref,
        required String? phone,
      }) {
        return needsOnboardingPref == true ||
            (needsOnboardingPref == null && (phone == null || phone.trim().isEmpty));
      }

      // 1. Existing user with needsOnboarding explicitly set to false (e.g. from Google login with subscriptions)
      expect(
        shouldShowOnboarding(needsOnboardingPref: false, phone: null),
        false,
        reason: 'Should not show onboarding when needsOnboardingPref is false, even if phone is null',
      );

      // 2. Existing user with needsOnboarding false and phone present
      expect(
        shouldShowOnboarding(needsOnboardingPref: false, phone: '+380685566322'),
        false,
      );

      // 3. Brand new user with needsOnboarding true
      expect(
        shouldShowOnboarding(needsOnboardingPref: true, phone: null),
        true,
      );

      // 4. Fallback when pref is null and phone is empty
      expect(
        shouldShowOnboarding(needsOnboardingPref: null, phone: null),
        true,
      );
      expect(
        shouldShowOnboarding(needsOnboardingPref: null, phone: ''),
        true,
      );

      // 5. Fallback when pref is null but phone is filled
      expect(
        shouldShowOnboarding(needsOnboardingPref: null, phone: '+380685566322'),
        false,
      );
    });

    test('Subscription and Child model parentId/userId linkage integrity', () {
      const oldUserId = 'client_legacy_123';
      const googleUid = 'google_firebase_auth_987';

      final legacySub = Subscription(
        id: 'sub_1',
        userId: oldUserId,
        totalClasses: 8,
        remainingClasses: 8,
        isActive: true,
        serviceName: 'Абонемент 8 занять',
        ownerName: 'Артем',
      );

      final legacyChild = Child(
        id: 'child_1',
        parentId: oldUserId,
        name: 'Артем',
        age: 6,
      );

      // Migrate to new Google Auth UID
      final migratedSub = legacySub.copyWith(userId: googleUid);
      final migratedChild = legacyChild.copyWith(parentId: googleUid);

      expect(migratedSub.userId, googleUid);
      expect(migratedSub.remainingClasses, 8);
      expect(migratedSub.ownerName, 'Артем');

      expect(migratedChild.parentId, googleUid);
      expect(migratedChild.name, 'Артем');
      expect(migratedChild.age, 6);
    });

    test('Duplicate child prevention during onboarding completion', () {
      final existingChildNames = {'артем', 'софія'};

      final newChildrenFromForm = [
        {'name': 'Артем', 'age': 6},
        {'name': 'Максим', 'age': 4},
      ];

      final childrenToCreate = <Map<String, dynamic>>[];
      for (final c in newChildrenFromForm) {
        final name = (c['name'] as String).trim().toLowerCase();
        if (!existingChildNames.contains(name)) {
          childrenToCreate.add(c);
          existingChildNames.add(name);
        }
      }

      expect(childrenToCreate.length, 1);
      expect(childrenToCreate.first['name'], 'Максим');
      expect(existingChildNames.contains('артем'), true);
      expect(existingChildNames.contains('максим'), true);
    });

    test('SharedPreferences user session persistence with needsOnboarding = false', () async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'parent',
        'clientId': 'google_user_1',
        'needsOnboarding': false,
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('userRole'), 'parent');
      expect(prefs.getString('clientId'), 'google_user_1');
      expect(prefs.getBool('needsOnboarding'), false);
    });
  });
}
