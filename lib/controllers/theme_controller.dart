import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true; // Default to Dark Mode
  }

  void toggleTheme() {
    state = !state;
  }
}

final themeControllerProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});
