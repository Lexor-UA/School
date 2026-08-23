import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('uk'),
        Locale('en'),
        Locale('ru'),
        Locale('de')
      ],
      path: 'assets/translations', 
      fallbackLocale: const Locale('uk'),
      child: const ProviderScope(child: SwimmingSchoolApp()),
    ),
  );
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class SwimmingSchoolApp extends ConsumerWidget {
  const SwimmingSchoolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    
    return MaterialApp.router(
      title: 'CitySwim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Default to dark theme
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force dark mode
      scrollBehavior: CustomScrollBehavior(),
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
