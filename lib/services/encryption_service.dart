import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  // Replace with your actual keys from Android strings.xml
  static const String _secretKey = 'YOUR_SECRET_KEY_HERE';
  static const String _salt = 'YOUR_SALT_HERE';

  late final enc.Key _key;
  late final enc.IV _iv;
  late final enc.Encrypter _encrypter;

  EncryptionService() {
    _initializeEncryption();
  }

  void _initializeEncryption() {
    // Generate key from secret key and salt
    final keyBytes = _deriveKey(_secretKey, _salt);
    _key = enc.Key(keyBytes);

    // Initialize IV with zeros (16 bytes) - same as Android
    _iv = enc.IV(Uint8List(16));

    // Create encrypter with AES algorithm
    _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
  }

  /// Derive key using PBKDF2-like approach (matches Android implementation)
  Uint8List _deriveKey(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    // Simple key derivation (for production, use proper PBKDF2)
    var key = [...passwordBytes, ...saltBytes];

    // Hash 1000 times for key strengthening
    for (int i = 0; i < 1000; i++) {
      key = sha256.convert(key).bytes;
    }

    // Take first 32 bytes for AES-256
    return Uint8List.fromList(key.take(32).toList());
  }

  /// Encrypt string and return base64 encoded result
  String encrypt(String plainText) {
    try {
      if (plainText.isEmpty) return '';

      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('❌ Encryption error: $e');
      return '';
    }
  }

  /// Decrypt base64 encoded string
  String decrypt(String encryptedText) {
    try {
      if (encryptedText.isEmpty) return '';

      final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      print('❌ Decryption error: $e');
      return '';
    }
  }

  /// Encrypt with null safety - returns null if input is null/empty
  String? encryptOrNull(String? plainText) {
    if (plainText == null || plainText.isEmpty) return null;

    try {
      return encrypt(plainText);
    } catch (e) {
      print('❌ Encryption error: $e');
      return null;
    }
  }

  /// Decrypt with null safety - returns null if input is null/empty
  String? decryptOrNull(String? encryptedText) {
    if (encryptedText == null || encryptedText.isEmpty) return null;

    try {
      return decrypt(encryptedText);
    } catch (e) {
      print('❌ Decryption error: $e');
      return null;
    }
  }

  /// Verify if encryption is working correctly
  bool testEncryption() {
    try {
      const testString = 'test_encryption_123';
      final encrypted = encrypt(testString);
      final decrypted = decrypt(encrypted);
      return decrypted == testString;
    } catch (e) {
      print('❌ Encryption test failed: $e');
      return false;
    }
  }
}
