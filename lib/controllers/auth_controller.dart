import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/app_user.dart';
import '../repositories/mock_db.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  AppUser? build() {
    return null;
  }

  void loginAsParent() {
    state = MockDB.users.firstWhere((u) => u.role == UserRole.parent);
  }

  void loginAsCoach() {
    state = MockDB.users.firstWhere((u) => u.role == UserRole.coach);
  }

  void loginAsOwner() {
    state = MockDB.users.firstWhere((u) => u.role == UserRole.owner);
  }

  void loginAsAdmin() {
    state = MockDB.users.firstWhere((u) => u.role == UserRole.admin);
  }

  void logout() {
    state = null;
  }
}
