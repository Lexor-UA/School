import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/parent/presentation/parent_main.dart';
import '../../features/coach/presentation/coach_main.dart';
import '../../features/admin/presentation/admin_main.dart';
import '../../features/owner/presentation/owner_main.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerMain(),
      ),
    ],
  );
});
