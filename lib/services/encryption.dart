import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Encryption {
  static final _secureStorage = FlutterSecureStorage();

  // Generate a random 32-byte encryption key
  static String generateEncryptionKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(keyBytes);
  }

  // Generate a random 16-byte IV
  static String generateIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64UrlEncode(ivBytes);
  }

  // Store encryption key and IV securely
  static Future<void> storeEncryptionKeys(String key, String iv) async {
    await _secureStorage.write(key: 'encryption_key', value: key);
    await _secureStorage.write(key: 'encryption_iv', value: iv);
  }

  // Retrieve encryption key and IV securely
  static Future<Map<String, String?>> getEncryptionKeys() async {
    final key = await _secureStorage.read(key: 'encryption_key');
    final iv = await _secureStorage.read(key: 'encryption_iv');
    return {'key': key, 'iv': iv};
  }

  // Encrypt data using AES-256
  static String encryptAES(String plainText, String key, String iv) {
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromBase64(key)));
    final encrypted = encrypter.encrypt(plainText, iv: encrypt.IV.fromBase64(iv));
    return encrypted.base64;
  }

  // Decrypt data using AES-256
  static String decryptAES(String encryptedText, String key, String iv) {
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromBase64(key)));
    final decrypted = encrypter.decrypt64(encryptedText, iv: encrypt.IV.fromBase64(iv));
    return decrypted;
  }
}