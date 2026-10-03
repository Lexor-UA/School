import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/coach/models/coach_rating.dart';
import 'package:swimming_school_app/features/coach/controllers/coach_rating_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/completed_class_coach_rating_bar.dart';

class _FakeAuthController extends AuthController {
  final AppUser? _initialUser;
  _FakeAuthController(this._initialUser);

  @override
  AppUser? build() => _initialUser;
}

class _FakeChildrenController extends ChildrenController {
  final List<Child> _initial;
  _FakeChildrenController(this._initial);

  @override
  Stream<List<Child>> build() => Stream.value(_initial);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoachRating Model Tests', () {
    test('Creates CoachRating and converts to/from Map correctly', () {
      final now = DateTime(2026, 10, 3, 14, 0);
      final rating = CoachRating(
        id: 'class_1_client_1',
        classId: 'class_1',
        coachId: 'coach_42',
        coachName: 'Олександр Ковальчук',
        clientId: 'client_1',
        clientName: 'Марія Петренко',
        stars: 5,
        comment: 'Чудове заняття!',
        createdAt: now,
        updatedAt: now,
      );

      final map = rating.toMap();
      expect(map['classId'], 'class_1');
      expect(map['coachId'], 'coach_42');
      expect(map['coachName'], 'Олександр Ковальчук');
      expect(map['stars'], 5);
      expect(map['comment'], 'Чудове заняття!');

      final restored = CoachRating.fromMap(map, 'class_1_client_1');
      expect(restored.id, 'class_1_client_1');
      expect(restored.coachName, 'Олександр Ковальчук');
      expect(restored.stars, 5);
    });

    test('Clamps stars between 1 and 5', () {
      final now = DateTime.now();
      final ratingHigh = CoachRating(
        id: '1',
        classId: 'c1',
        coachId: 'coach1',
        coachName: 'Coach',
        clientId: 'cl1',
        clientName: 'Client',
        stars: 10,
        createdAt: now,
        updatedAt: now,
      );
      expect(ratingHigh.stars, 5);

      final ratingLow = CoachRating(
        id: '2',
        classId: 'c2',
        coachId: 'coach1',
        coachName: 'Coach',
        clientId: 'cl1',
        clientName: 'Client',
        stars: -3,
        createdAt: now,
        updatedAt: now,
      );
      expect(ratingLow.stars, 1);
    });
  });

  group('CoachRatingController & Providers Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Initial rating state is empty and default average is 5.0 with 0 reviews', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final avg = container.read(coachAverageRatingProvider('coach_1'));
      expect(avg.rating, 5.0);
      expect(avg.count, 0);

      final classRating = container.read(
        classRatingProvider((classId: 'class_99', clientId: 'client_99')),
      );
      expect(classRating, isNull);
    });

    test('rateCoach updates state and correctly computes coach average rating', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(coachRatingControllerProvider.notifier);

      // Client 1 rates 5 stars
      await notifier.rateCoach(
        classId: 'class_1',
        coachId: 'coach_10',
        coachName: 'Андрій Шевченко',
        clientId: 'client_1',
        clientName: 'Олена',
        stars: 5,
      );

      var ratingVal = container.read(
        classRatingProvider((classId: 'class_1', clientId: 'client_1')),
      );
      expect(ratingVal, 5);

      var avg = container.read(coachAverageRatingProvider('coach_10'));
      expect(avg.rating, 5.0);
      expect(avg.count, 1);

      // Client 2 rates same coach 4 stars for another class
      await notifier.rateCoach(
        classId: 'class_2',
        coachId: 'coach_10',
        coachName: 'Андрій Шевченко',
        clientId: 'client_2',
        clientName: 'Іван',
        stars: 4,
      );

      avg = container.read(coachAverageRatingProvider('coach_10'));
      expect(avg.rating, 4.5);
      expect(avg.count, 2);

      // Also verifies matching by coach name
      final avgByName = container.read(coachAverageRatingProvider('Андрій Шевченко'));
      expect(avgByName.rating, 4.5);
      expect(avgByName.count, 2);
    });

    test('Changing rating on same class updates existing review rather than duplicating', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(coachRatingControllerProvider.notifier);

      await notifier.rateCoach(
        classId: 'class_100',
        coachId: 'coach_5',
        coachName: 'Тетяна',
        clientId: 'client_1',
        clientName: 'Олена',
        stars: 3,
      );

      var avg = container.read(coachAverageRatingProvider('coach_5'));
      expect(avg.rating, 3.0);
      expect(avg.count, 1);

      // Client updates their rating from 3 to 5
      await notifier.rateCoach(
        classId: 'class_100',
        coachId: 'coach_5',
        coachName: 'Тетяна',
        clientId: 'client_1',
        clientName: 'Олена',
        stars: 5,
      );

      avg = container.read(coachAverageRatingProvider('coach_5'));
      expect(avg.rating, 5.0);
      expect(avg.count, 1); // still 1 review, not duplicated
    });
  });

  group('CompletedClassCoachRatingBar Attendance Verification Tests', () {
    testWidgets('Rating bar is shown when child was marked attended', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final classItem = GroupClass(
        id: 'class_1',
        title: 'Плавання для дітей',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        coachId: 'coach_1',
        coachName: 'Борис',
        maxCapacity: 6,
        category: 'Плавання',
        enrolledChildIds: const ['child_1'],
        attendedChildIds: const ['child_1'],
      );

      final client = AppUser(
        id: 'client_1',
        name: 'Олена',
        role: UserRole.parent,
        phone: '+380501112233',
      );

      final child = Child(
        id: 'child_1',
        name: 'Максим',
        birthDate: DateTime(2018, 5, 1),
        parentId: 'client_1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(() => _FakeAuthController(client)),
            childrenControllerProvider.overrideWith(() => _FakeChildrenController([child])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CompletedClassCoachRatingBar(
                classItem: classItem,
                currentTheme: AppThemeConfig.darkOcean,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Оцініть роботу тренера:'), findsOneWidget);
      expect(find.text('Борис'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
    });

    testWidgets('Rating bar is NOT shown when child was NOT marked attended', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final classItem = GroupClass(
        id: 'class_2',
        title: 'Junior Pro',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        coachId: 'coach_2',
        coachName: 'Borys',
        maxCapacity: 6,
        category: 'Плавання',
        enrolledChildIds: const ['child_99'], // other student
        attendedChildIds: const ['child_99'],
      );

      final client = AppUser(
        id: 'client_1',
        name: 'Олена',
        role: UserRole.parent,
        phone: '+380501112233',
      );

      final child = Child(
        id: 'child_1',
        name: 'Максим',
        birthDate: DateTime(2018, 5, 1),
        parentId: 'client_1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(() => _FakeAuthController(client)),
            childrenControllerProvider.overrideWith(() => _FakeChildrenController([child])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CompletedClassCoachRatingBar(
                classItem: classItem,
                currentTheme: AppThemeConfig.darkOcean,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Оцініть роботу тренера:'), findsNothing);
      expect(find.text('Borys'), findsNothing);
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    });
  });
}
