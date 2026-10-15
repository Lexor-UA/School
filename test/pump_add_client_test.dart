import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/admin/presentation/add_client_sheet.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';

class FakeAuthController extends AuthController {
  @override
  AppUser? build() => null;
}

class TestAdminAssetLoader extends AssetLoader {
  const TestAdminAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final file = File('assets/translations/uk.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Test AddClientSheet full layout and rendering', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('uk'), Locale('en')],
        path: 'assets/translations',
        assetLoader: const TestAdminAssetLoader(),
        fallbackLocale: const Locale('uk'),
        startLocale: const Locale('uk'),
        saveLocale: false,
        useOnlyLangCode: true,
        child: ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(FakeAuthController.new),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const Scaffold(
                body: AddClientSheet(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final err = tester.takeException();
    expect(err, isNull);

    final titleFinder = find.text('Новий Клієнт');
    expect(titleFinder, findsOneWidget);
    
    // Check render box sizes
    final sheetFinder = find.byType(AddClientSheet);
    final renderBox = tester.renderObject(sheetFinder) as RenderBox;
    expect(renderBox.size.width, greaterThan(0));

    final textFieldFinders = find.byType(TextField);
    expect(textFieldFinders, findsWidgets);

    // Tap "+ Додати дитину (учня)" button
    final addChildBtn = find.text('+ Додати дитину (учня)');
    expect(addChildBtn, findsOneWidget);
    await tester.tap(addChildBtn);
    await tester.pumpAndSettle();

    expect(find.text('Учень #1'), findsOneWidget);
    expect(find.text('Юний плавець'), findsOneWidget);
    expect(find.text('Видалити'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5)); // 3 client fields + 2 child fields

    // Tap "Видалити" button
    await tester.tap(find.text('Видалити'));
    await tester.pumpAndSettle();
    expect(find.text('Учень #1'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(3));
  });
}
