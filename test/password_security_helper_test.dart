import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/shared/utils/password_security_helper.dart';

void main() {
  group('PasswordSecurityHelper Tests', () {
    test('Hashes password deterministically', () {
      final hash1 = PasswordSecurityHelper.hashPassword('admin123');
      final hash2 = PasswordSecurityHelper.hashPassword('admin123');
      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64));
      expect(PasswordSecurityHelper.isHashed(hash1), isTrue);
    });

    test('Verifies plain text password for legacy accounts (e.g. 1)', () {
      expect(PasswordSecurityHelper.verifyPassword('1', '1'), isTrue);
      expect(PasswordSecurityHelper.verifyPassword('wrong', '1'), isFalse);
    });

    test('Verifies hashed password correctly', () {
      final hash = PasswordSecurityHelper.hashPassword('SecretPass2026');
      expect(PasswordSecurityHelper.verifyPassword('SecretPass2026', hash), isTrue);
      expect(PasswordSecurityHelper.verifyPassword('WrongPass', hash), isFalse);
    });

    test('Detects hashed strings correctly', () {
      expect(PasswordSecurityHelper.isHashed('1'), isFalse);
      expect(PasswordSecurityHelper.isHashed('simple_password'), isFalse);
      expect(
        PasswordSecurityHelper.isHashed('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
        isTrue,
      );
    });
  });
}
