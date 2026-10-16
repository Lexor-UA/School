import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Інформація про стан прив'язки Google Authenticator (TOTP) для співробітника.
class StaffTotpStatus {
  final String userId;
  final String loginId;
  final String displayName;
  final String role;
  final bool totpEnabled;
  final String secret;
  final String otpAuthUri;

  const StaffTotpStatus({
    required this.userId,
    required this.loginId,
    required this.displayName,
    required this.role,
    required this.totpEnabled,
    required this.secret,
    required this.otpAuthUri,
  });
}

/// Допоміжний сервіс для роботи з одноразовими кодами Google Authenticator
/// за стандартами RFC 4226 (HOTP) та RFC 6238 (TOTP, HMAC-SHA1, 6 цифр, 30 секунд).
class TotpSecurityHelper {
  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const int defaultPeriodSeconds = 30;
  static const int defaultDigits = 6;

  /// Генерує криптографічно стійкий Base32-секрет (за замовчуванням 32 символи = 160 біт).
  static String generateBase32Secret({int length = 32}) {
    Random random;
    try {
      random = Random.secure();
    } catch (_) {
      random = Random();
    }
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_base32Alphabet[random.nextInt(_base32Alphabet.length)]);
    }
    return buffer.toString();
  }

  /// Генерує детермінований резервний секрет для офлайн-режиму на основі ідентифікатора.
  static String deterministicFallbackSecret(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    final digest = sha1.convert('cityswim_totp_seed_2026:$normalized'.codeUnits).bytes;
    return base32Encode(Uint8List.fromList(digest));
  }

  /// Форматує секретний ключ групами по 4 символи для зручного читання та ручного введення.
  static String formatSecretForDisplay(String secret) {
    final clean = secret.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  /// Формує стандартний URI `otpauth://totp/...` для сканування у Google Authenticator.
  static String buildOtpAuthUri({
    required String accountName,
    required String secret,
    String issuer = 'CitySwim',
    int digits = defaultDigits,
    int period = defaultPeriodSeconds,
  }) {
    final cleanSecret = secret.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final cleanIssuer = issuer.trim();
    final cleanAccount = accountName.trim();
    final label = '${Uri.encodeComponent(cleanIssuer)}:${Uri.encodeComponent(cleanAccount)}';
    final queryParams = <String, String>{
      'secret': cleanSecret,
      'issuer': cleanIssuer,
      'algorithm': 'SHA1',
      'digits': '$digits',
      'period': '$period',
    };
    final query = queryParams.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return 'otpauth://totp/$label?$query';
  }

  /// Генерує 6-значний TOTP-код для заданого Base32-секрету та часу [time].
  static String generateCode(
    String base32Secret, {
    DateTime? time,
    int periodSeconds = defaultPeriodSeconds,
    int digits = defaultDigits,
  }) {
    final targetTime = (time ?? DateTime.now()).toUtc();
    final counter = targetTime.millisecondsSinceEpoch ~/ 1000 ~/ periodSeconds;
    return generateHotpCode(base32Secret, counter, digits: digits);
  }

  /// Генерує HOTP-код (RFC 4226) для лічильника [counter].
  static String generateHotpCode(
    String base32Secret,
    int counter, {
    int digits = defaultDigits,
  }) {
    final keyBytes = base32Decode(base32Secret);
    final counterBytes = Uint8List(8);
    int temp = counter;
    for (int i = 7; i >= 0; i--) {
      counterBytes[i] = temp & 0xff;
      temp >>= 8;
    }

    final hmac = Hmac(sha1, keyBytes);
    final hash = hmac.convert(counterBytes).bytes;

    final offset = hash[hash.length - 1] & 0x0f;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    int mod = 1;
    for (int i = 0; i < digits; i++) {
      mod *= 10;
    }
    final otp = binary % mod;
    return otp.toString().padLeft(digits, '0');
  }

  /// Перевіряє введений користувачем 6-значний код із допуском [window] інтервалів (±30 сек).
  static bool verifyCode(
    String inputCode,
    String base32Secret, {
    DateTime? time,
    int window = 1,
    int periodSeconds = defaultPeriodSeconds,
    int digits = defaultDigits,
  }) {
    final cleanCode = inputCode.replaceAll(RegExp(r'\D'), '');
    if (cleanCode.length != digits) {
      return false;
    }
    final cleanSecret = base32Secret.replaceAll(RegExp(r'[^A-Za-z2-7]'), '').toUpperCase();
    if (cleanSecret.isEmpty) {
      return false;
    }

    final targetTime = (time ?? DateTime.now()).toUtc();
    final currentCounter = targetTime.millisecondsSinceEpoch ~/ 1000 ~/ periodSeconds;

    for (int offset = -window; offset <= window; offset++) {
      final candidate = generateHotpCode(
        cleanSecret,
        currentCounter + offset,
        digits: digits,
      );
      if (_constantTimeEquals(cleanCode, candidate)) {
        return true;
      }
    }
    return false;
  }

  /// Повертає кількість секунд, що залишилися до оновлення поточного 30-секундного TOTP-коду.
  static int remainingSeconds({DateTime? time, int periodSeconds = defaultPeriodSeconds}) {
    final nowSec = ((time ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000);
    return periodSeconds - (nowSec % periodSeconds);
  }

  /// Кодує байти у Base32 (RFC 4648 без паддінгу `=`).
  static String base32Encode(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    final output = StringBuffer();
    int buffer = bytes[0];
    int next = 1;
    int bitsLeft = 8;

    while (bitsLeft > 0 || next < bytes.length) {
      if (bitsLeft < 5) {
        if (next < bytes.length) {
          buffer <<= 8;
          buffer |= (bytes[next++] & 0xff);
          bitsLeft += 8;
        } else {
          final pad = 5 - bitsLeft;
          buffer <<= pad;
          bitsLeft += pad;
        }
      }
      final index = 0x1f & (buffer >> (bitsLeft - 5));
      bitsLeft -= 5;
      output.write(_base32Alphabet[index]);
    }
    return output.toString();
  }

  /// Декодує рядок Base32 (RFC 4648) у масив байтів [Uint8List].
  static Uint8List base32Decode(String input) {
    final clean = input
        .toUpperCase()
        .replaceAll('=', '')
        .replaceAll(RegExp(r'[^A-Z2-7]'), '');
    if (clean.isEmpty) return Uint8List(0);

    final out = <int>[];
    int buffer = 0;
    int bitsLeft = 0;

    for (int i = 0; i < clean.length; i++) {
      final val = _base32Alphabet.indexOf(clean[i]);
      if (val < 0) continue;
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        out.add((buffer >> bitsLeft) & 0xff);
      }
    }
    return Uint8List.fromList(out);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
