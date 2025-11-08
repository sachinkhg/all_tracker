import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling encryption and decryption of backup data.
/// 
/// Supports two encryption modes:
/// 1. Device Key: Uses an AES-256 key stored securely on the device
/// 2. E2EE (End-to-End Encrypted): Uses a user-provided passphrase with PBKDF2 key derivation
class EncryptionService {
  static const String _deviceKeyStorageKey = 'backup_device_key';
  static const int _pbkdf2Iterations = 200000; // OWASP recommended minimum
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AesGcm cryptographyAlgorithm = AesGcm.with256bits();

  /// Generate and store a device-specific encryption key.
  /// 
  /// Returns the generated key. The key is stored securely using flutter_secure_storage.
  Future<Uint8List> generateDeviceKey() async {
    final existingKey = await _secureStorage.read(key: _deviceKeyStorageKey);
    if (existingKey != null) {
      return base64Decode(existingKey);
    }
    
    // Generate a new 256-bit (32-byte) key
    final secretKey = await cryptographyAlgorithm.newSecretKey();
    final keyBytes = Uint8List.fromList(await secretKey.extractBytes());
    await _secureStorage.write(
      key: _deviceKeyStorageKey,
      value: base64Encode(keyBytes),
    );
    return keyBytes;
  }

  /// Derive an encryption key from a user passphrase using PBKDF2.
  /// 
  /// [passphrase]: The user's passphrase
  /// [salt]: The salt to use for key derivation
  /// 
  /// Returns a 256-bit key derived using PBKDF2 with 200k iterations.
  Future<Uint8List> deriveKeyFromPassphrase(
    String passphrase,
    Uint8List salt,
  ) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKeyData(utf8.encode(passphrase)),
      nonce: salt,
    );

    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Encrypt data using AES-256-GCM.
  /// 
  /// [data]: The plaintext data to encrypt
  /// [key]: The encryption key (256-bit / 32 bytes)
  /// 
  /// Returns a Map containing:
  /// - 'iv': The initialization vector (base64 encoded)
  /// - 'ciphertext': The encrypted data (base64 encoded)
  Future<Map<String, String>> encryptData(
    Uint8List data,
    Uint8List key,
  ) async {
    // Generate a random nonce
    final nonce = cryptographyAlgorithm.newNonce();
    
    final secretBox = await cryptographyAlgorithm.encrypt(
      data,
      secretKey: SecretKey(key),
      nonce: nonce,
    );

    return {
      'iv': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  /// Decrypt data that was encrypted with AES-256-GCM.
  /// 
  /// [encryptedData]: Map containing 'iv' and 'ciphertext' (both base64 encoded)
  /// [key]: The decryption key (256-bit / 32 bytes)
  /// 
  /// Returns the decrypted plaintext data.
  /// 
  /// Throws [FormatException] if decryption fails (integrity check failed).
  Future<Uint8List> decryptData(
    Map<String, String> encryptedData,
    Uint8List key,
  ) async {
    final nonce = base64Decode(encryptedData['iv']!);
    final ciphertext = base64Decode(encryptedData['ciphertext']!);
    final mac = base64Decode(encryptedData['mac']!);
    
    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(mac),
    );

    try {
      final decrypted = await cryptographyAlgorithm.decrypt(
        secretBox,
        secretKey: SecretKey(key),
      );
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw FormatException('Decryption failed: Integrity check failed', e);
    }
  }

  /// Generate a random salt for key derivation.
  /// 
  /// Returns 32 random bytes.
  Future<Uint8List> generateSalt() async {
    final secretKey = await cryptographyAlgorithm.newSecretKey();
    return Uint8List.fromList(await secretKey.extractBytes());
  }
}

