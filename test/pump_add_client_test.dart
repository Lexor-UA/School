import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/admin/presentation/add_client_sheet.dart';

class TestAdminAssetLoader extends AssetLoader {
  const TestAdminAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'admin.add_client_title': 'Новий Клієнт',
    'admin.add_client_subtitle': 'Швидка реєстрація батьків та учнів',
    'admin.add_client_save_btn': 'Зберегти клієнта',
    'admin': {
      'add_client_title': 'Новий Клієнт',
      'add_client_subtitle': 'Швидка реєстрація батьків та учнів',
      'add_client_save_btn': 'Зберегти клієнта',
    },
  };
}

void main() {
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
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddClientSheet(),
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
