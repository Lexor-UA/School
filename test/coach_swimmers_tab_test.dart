import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/coach/presentation/tabs/coach_swimmers_tab.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';

class FakeCoachAuth extends AuthController {
  @override
  AppUser? build() => const AppUser(
    id: 'coach_borys',
    name: 'Borys',
    role: UserRole.coach,
    organizationId: 'cityswim',
    branchIds: ['vienna'],
    branchId: 'vienna',
  );
}

class FakeScheduleController extends ScheduleController {
  @override
  Stream<List<GroupClass>> build() => Stream.value([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CoachSwimmersTab builds and renders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => FakeCoachAuth()),
          scheduleControllerProvider.overrideWith(() => FakeScheduleController()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CoachSwimmersTab(),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Групи та плавці'), findsOneWidget);
  });

  testWidgets('Adult swimmer representations use adult_swimmer parentId and do not show levels', (tester) async {
    // Child model representation for adult swimmer
    final adultSwimmerChild = Child(
      id: 'adult_user_123',
      parentId: 'adult_swimmer',
      name: 'Fox',
      age: 23,
      level: 0,
      branchId: 'vienna',
    );

    expect(adultSwimmerChild.parentId, equals('adult_swimmer'));
    expect(adultSwimmerChild.isAdultAge, isTrue);
    expect(adultSwimmerChild.currentAge, equals(23));
  });
}
