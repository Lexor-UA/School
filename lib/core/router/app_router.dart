import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/password_recovery_screen.dart';
import '../../features/parent/presentation/parent_main.dart';
import '../../features/coach/presentation/coach_main.dart';
import '../../features/admin/presentation/admin_main.dart';
import '../../features/owner/presentation/owner_main.dart';
import '../../features/owner/presentation/owner_reports_screen.dart';
import '../../features/owner/presentation/owner_staff_screen.dart';
import '../../features/owner/presentation/owner_payouts_screen.dart';

import '../../features/admin/presentation/admin_chat_screen.dart';

class KeyboardDismissNavigatorObserver extends NavigatorObserver {
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismissKeyboard();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  // We no longer set initialLocation based on prefs here.
  // We always start at '/' so the user sees the Splash Screen animation.
  // The RoleSelectionScreen will handle auto-login if prefs are set.
  
  return GoRouter(
    initialLocation: '/',
    observers: [KeyboardDismissNavigatorObserver()],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final skipSplash = state.uri.queryParameters['skipSplash'] == 'true';
          return RoleSelectionScreen(skipSplash: skipSplash);
        },
      ),
      GoRoute(
        path: '/password-recovery',
        builder: (context, state) {
          final initialLogin = state.uri.queryParameters['initialLogin'] ?? '';
          return PasswordRecoveryScreen(initialLogin: initialLogin);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentMain(),
      ),
      GoRoute(
        path: '/coach',
        builder: (context, state) => const CoachMain(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminMain(),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final clientName = state.uri.queryParameters['clientName'] ?? 'Клієнт';
              final clientId = state.uri.queryParameters['clientId'] ?? '';
              final dialogId = state.uri.queryParameters['dialogId'];
              final coachId = state.uri.queryParameters['coachId'];
              final coachName = state.uri.queryParameters['coachName'];
              final childName = state.uri.queryParameters['childName'];
              final isMonitoring = state.uri.queryParameters['isMonitoring'] == 'true';
              return AdminChatScreen(
                clientName: clientName,
                clientId: clientId,
                dialogId: dialogId,
                coachId: coachId,
                coachName: coachName,
                childName: childName,
                isMonitoring: isMonitoring,
              );
            },
          ),
        ]
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerMain(),
        routes: [
          GoRoute(
            path: 'reports',
            builder: (context, state) => const OwnerReportsScreen(),
          ),
          GoRoute(
            path: 'staff',
            builder: (context, state) => const OwnerStaffScreen(),
          ),
          GoRoute(
            path: 'payouts',
            builder: (context, state) => const OwnerPayoutsScreen(),
          ),
        ]
      ),
    ],
  );
});
