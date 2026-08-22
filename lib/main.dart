import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: SwimmingSchoolApp()));
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
    );
  }
}
