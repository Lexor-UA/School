import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/auth/presentation/role_selection_screen.dart';

class FakeAuthController extends AuthController {
  @override
  AppUser? build() => null;
}

class TestAssetLoader extends AssetLoader {
  const TestAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'auth': {
      'staff_portal': 'Вхід для співробітників',
      'login_google': 'Увійти через Google',
      'or': 'або',
      'tab_login': 'Увійти',
      'tab_register': 'Реєстрація',
      'role_coach': 'Тренер',
      'role_parent': 'Батьки',
      'role_admin': 'Адміністратор',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads role selection screen test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('uk'), Locale('en')],
        path: 'assets/translations',
        assetLoader: const TestAssetLoader(),
        fallbackLocale: const Locale('uk'),
        startLocale: const Locale('uk'),
        saveLocale: false,
        useOnlyLangCode: true,
        child: ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(FakeAuthController.new),
          ],
          child: const MaterialApp(
            home: RoleSelectionScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.byType(RoleSelectionScreen), findsOneWidget);
  });
}
