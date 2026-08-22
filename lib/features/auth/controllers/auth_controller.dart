import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/shared/repositories/mock_db.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
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

  void updateAvatar(Uint8List bytes) {
    if (state != null) {
      state = state!.copyWith(avatarBytes: bytes);
    }
  }
}
