import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme_provider.dart';
import 'core/router/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/shared_prefs_provider.dart';
import 'package:swimming_school_app/core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable offline persistence, caching, and Crashlytics on mobile.
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    FirebaseCrashlytics.instance.log('CitySwim App initialized successfully');
  }
  
  await EasyLocalization.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(
        details.exception,
        details.stack,
        reason: 'ErrorWidget build failure: ${details.context?.toDescription()}',
        fatal: false,
      );
    }
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            kDebugMode ? details.exceptionAsString() : '',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

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
      child: ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const SwimmingSchoolApp(),
      ),
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

class SwimmingSchoolApp extends ConsumerStatefulWidget {
  const SwimmingSchoolApp({super.key});

  @override
  ConsumerState<SwimmingSchoolApp> createState() => _SwimmingSchoolAppState();
}

class _SwimmingSchoolAppState extends ConsumerState<SwimmingSchoolApp> {
  @override
  void initState() {
    super.initState();
    // Initialize push notifications after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);
    
    return MaterialApp.router(
      title: 'CitySwim',
      debugShowCheckedModeBanner: false,
      theme: themeConfig.toThemeData(),
      darkTheme: AppThemeConfig.darkOcean.toThemeData(),
      themeMode: themeConfig.isDark ? ThemeMode.dark : ThemeMode.light,
      scrollBehavior: CustomScrollBehavior(),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        // Base width on a standard device (e.g., iPhone 12/13/14 is ~390 logical pixels)
        double scale = mediaQueryData.size.width / 390.0;
        
        // Clamp scale to prevent text from being microscopic on extremely small devices or huge on tablets
        scale = scale.clamp(0.8, 1.05);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
