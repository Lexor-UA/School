import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_prefs_provider.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/parent/presentation/parent_main.dart';
import '../../features/coach/presentation/coach_main.dart';
import '../../features/admin/presentation/admin_main.dart';
import '../../features/owner/presentation/owner_main.dart';
import '../../features/owner/presentation/owner_reports_screen.dart';
import '../../features/owner/presentation/owner_staff_screen.dart';
import '../../features/owner/presentation/owner_payouts_screen.dart';

import '../../features/admin/presentation/admin_chat_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  final savedRole = prefs.getString('userRole');
  
  String initialLocation = '/';
  if (savedRole == 'parent') initialLocation = '/parent';
  else if (savedRole == 'coach') initialLocation = '/coach';
  else if (savedRole == 'admin') initialLocation = '/admin';
  else if (savedRole == 'owner') initialLocation = '/owner';

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleSelectionScreen(),
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
              return AdminChatScreen(clientName: clientName);
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
