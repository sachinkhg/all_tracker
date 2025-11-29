/*
 * File: password_encryption_service.dart
 *
 * Purpose:
 *   Provides encryption and decryption services for passwords and secret question answers.
 *   Uses AES-256 encryption with a key stored securely in flutter_secure_storage.
 *   The encryption key is device-specific and derived from secure storage.
 *
 * Security considerations:
 *   - Encryption key is stored in platform secure storage (Keychain on iOS, Keystore on Android)
 *   - Uses AES-256-GCM for authenticated encryption
 *   - Each encrypted value is base64 encoded for storage
 */

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for encrypting and decrypting sensitive data.
///
/// This service uses AES-256-GCM encryption with a key stored in secure storage.
/// The encryption key is device-specific and automatically generated on first use.
class PasswordEncryptionService {
  static const String _keyStorageKey = 'password_encryption_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final AesGcm _cipher = AesGcm.with256bits();

  /// Gets or creates the encryption key from secure storage.
  ///
  /// If no key exists, a new one is generated and stored securely.
  Future<SecretKey> _getOrCreateKey() async {
    final existingKeyData = await _secureStorage.read(key: _keyStorageKey);
    
    if (existingKeyData != null) {
      // Key exists, decode it
      final keyBytes = base64Decode(existingKeyData);
      return SecretKey(keyBytes);
    } else {
      // Generate new key
      final newKey = await _cipher.newSecretKey();
      final keyBytes = await newKey.extractBytes();
      final keyBase64 = base64Encode(keyBytes);
      
      // Store in secure storage
      await _secureStorage.write(key: _keyStorageKey, value: keyBase64);
      return newKey;
    }
  }

  /// Encrypts a plaintext string.
  ///
  /// Returns a base64-encoded string containing the encrypted data and nonce.
  /// The format is: base64(nonce + encrypted_data + mac)
  Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) {
      return '';
    }

    try {
      final key = await _getOrCreateKey();
      final plaintextBytes = utf8.encode(plaintext);
      
      // Encrypt with a random nonce
      final secretBox = await _cipher.encrypt(
        plaintextBytes,
        secretKey: key,
      );

      // Combine nonce, ciphertext, and mac for storage
      final nonceLength = secretBox.nonce.length;
      final ciphertextLength = secretBox.cipherText.length;
      final macLength = secretBox.mac.bytes.length;
      
      final combined = Uint8List(nonceLength + ciphertextLength + macLength);
      combined.setRange(0, nonceLength, secretBox.nonce);
      combined.setRange(nonceLength, nonceLength + ciphertextLength, secretBox.cipherText);
      combined.setRange(nonceLength + ciphertextLength, combined.length, secretBox.mac.bytes);

      // Return base64 encoded
      return base64Encode(combined);
    } catch (e) {
      // If encryption fails, throw exception
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts a base64-encoded encrypted string.
  ///
  /// Expects the format: base64(nonce + encrypted_data + mac)
  /// Returns the decrypted plaintext string.
  Future<String> decrypt(String ciphertext) async {
    if (ciphertext.isEmpty) {
      return '';
    }

    try {
      final key = await _getOrCreateKey();
      final combined = base64Decode(ciphertext);
      
      // Extract nonce (first 12 bytes for GCM), ciphertext, and mac
      final nonceLength = 12;
      final macLength = 16; // GCM MAC is 16 bytes
      final ciphertextLength = combined.length - nonceLength - macLength;
      
      final nonce = combined.sublist(0, nonceLength);
      final encryptedData = combined.sublist(nonceLength, nonceLength + ciphertextLength);
      final macBytes = combined.sublist(nonceLength + ciphertextLength);

      // Create secret box from stored data
      final secretBox = SecretBox(
        encryptedData,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      // Decrypt
      final decryptedBytes = await _cipher.decrypt(
        secretBox,
        secretKey: key,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      // If decryption fails, throw exception
      throw Exception('Decryption failed: $e');
    }
  }
}

