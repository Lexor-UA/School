import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Helper for secure password hashing and verification.
///
/// Ensures full backward compatibility: allows existing accounts with legacy
/// plain-text passwords (e.g. '1') to authenticate seamlessly while supporting
/// secure salted SHA-256 hashing for new or updated credentials.
class PasswordSecurityHelper {
  static const String _salt = 'city_swim_salt_2026_x9';

  /// Generates a salted SHA-256 hash of the password.
  static String hashPassword(String password) {
    final clean = password.trim();
    final bytes = utf8.encode('$_salt:$clean');
    return sha256.convert(bytes).toString();
  }

  /// Verifies an entered password against a stored credential (plain-text or hash).
  static bool verifyPassword(String inputPassword, String storedCredential) {
    final cleanInput = inputPassword.trim();
    final cleanStored = storedCredential.trim();

    // 1. If stored credential is already a 64-char SHA-256 hex hash, verify strictly via hash comparison
    // to prevent Pass-the-Hash attacks where a raw hash is pasted as the password.
    if (isHashed(cleanStored)) {
      return hashPassword(cleanInput).toLowerCase() == cleanStored.toLowerCase();
    }

    // 2. Direct match for legacy plain-text credentials (e.g. '1', initial pins)
    if (cleanInput == cleanStored) {
      return true;
    }

    // 3. Fallback hash verification
    final computedHash = hashPassword(cleanInput);
    return computedHash == cleanStored;
  }

  /// Determines whether the stored value is already a SHA-256 hash (64 hex characters).
  static bool isHashed(String value) {
    final clean = value.trim();
    return clean.length == 64 && RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(clean);
  }
}
