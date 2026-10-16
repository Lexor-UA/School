import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/shared/utils/totp_security_helper.dart';

void main() {
  group('TotpSecurityHelper (RFC 6238 Google Authenticator)', () {
    test('Base32 encode and decode round-trip preserves bytes', () {
      final original = Uint8List.fromList([
        0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x21, 0xDE, 0xAD, 0xBE, 0xEF,
      ]);
      final encoded = TotpSecurityHelper.base32Encode(original);
      expect(encoded, equals('JBSWY3DPEHPK3PXP'));
      final decoded = TotpSecurityHelper.base32Decode(encoded);
      expect(decoded, equals(original));
    });

    test('generateBase32Secret produces valid 32-char Base32 key', () {
      final secret = TotpSecurityHelper.generateBase32Secret();
      expect(secret.length, equals(32));
      expect(RegExp(r'^[A-Z2-7]{32}$').hasMatch(secret), isTrue);
    });

    test('deterministicFallbackSecret returns stable 32-char Base32 key', () {
      final s1 = TotpSecurityHelper.deterministicFallbackSecret('owner');
      final s2 = TotpSecurityHelper.deterministicFallbackSecret('OWNER');
      final s3 = TotpSecurityHelper.deterministicFallbackSecret('admin');
      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
      expect(s1.length, equals(32));
    });

    test('formatSecretForDisplay groups Base32 characters by 4', () {
      const raw = 'JBSWY3DPEHPK3PXP';
      expect(
        TotpSecurityHelper.formatSecretForDisplay(raw),
        equals('JBSW Y3DP EHPK 3PXP'),
      );
    });

    test('buildOtpAuthUri generates standard Google Authenticator URI', () {
      final uri = TotpSecurityHelper.buildOtpAuthUri(
        accountName: 'owner',
        secret: 'JBSWY3DPEHPK3PXP',
        issuer: 'CitySwim',
      );
      expect(uri, startsWith('otpauth://totp/CitySwim:owner?'));
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
      expect(uri, contains('issuer=CitySwim'));
      expect(uri, contains('algorithm=SHA1'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('period=30'));
    });

    test('verifyCode accepts current step and +-1 adjacent 30s steps', () {
      const secret = 'JBSWY3DPEHPK3PXP';
      final fixedTime = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      final prevStepTime = fixedTime.subtract(const Duration(seconds: 30));
      final nextStepTime = fixedTime.add(const Duration(seconds: 30));
      final expiredTime = fixedTime.subtract(const Duration(seconds: 90));

      final currentCode = TotpSecurityHelper.generateCode(secret, time: fixedTime);
      final prevCode = TotpSecurityHelper.generateCode(secret, time: prevStepTime);
      final nextCode = TotpSecurityHelper.generateCode(secret, time: nextStepTime);
      final expiredCode = TotpSecurityHelper.generateCode(secret, time: expiredTime);

      expect(currentCode.length, equals(6));
      expect(TotpSecurityHelper.verifyCode(currentCode, secret, time: fixedTime), isTrue);
      expect(TotpSecurityHelper.verifyCode(prevCode, secret, time: fixedTime), isTrue);
      expect(TotpSecurityHelper.verifyCode(nextCode, secret, time: fixedTime), isTrue);
      expect(TotpSecurityHelper.verifyCode(expiredCode, secret, time: fixedTime), isFalse);
      expect(TotpSecurityHelper.verifyCode('000000', secret, time: fixedTime), isFalse);
      expect(TotpSecurityHelper.verifyCode('12345', secret, time: fixedTime), isFalse);
    });
  });
}
