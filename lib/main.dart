import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'screens/role_selection_screen.dart';
import 'controllers/theme_controller.dart';

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
    final isDark = ref.watch(themeControllerProvider);
    
    return MaterialApp(
      title: 'CitySwim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      scrollBehavior: CustomScrollBehavior(),
      home: const RoleSelectionScreen(),
    );
  }
}
