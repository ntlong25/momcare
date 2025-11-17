import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../utils/app_logger.dart';

/// Service to manage encryption keys for Hive databases
/// Uses flutter_secure_storage to securely store the encryption key
class EncryptionService {
  static const String _encryptionKeyName = 'hive_encryption_key';
  static final _secureStorage = const FlutterSecureStorage();
  static final _logger = AppLogger.instance;

  /// Initialize and get encryption cipher for Hive
  /// Generates a new key if one doesn't exist
  static Future<HiveAesCipher?> getEncryptionCipher() async {
    try {
      // Try to get existing key
      String? encryptionKey = await _secureStorage.read(key: _encryptionKeyName);

      if (encryptionKey == null) {
        // Generate new key
        _logger.info('Generating new encryption key for Hive');
        final key = Hive.generateSecureKey();
        encryptionKey = base64Url.encode(key);
        await _secureStorage.write(key: _encryptionKeyName, value: encryptionKey);
        _logger.info('Encryption key generated and stored securely');
      }

      // Decode key and create cipher
      final key = base64Url.decode(encryptionKey);
      return HiveAesCipher(key);
    } catch (e, stackTrace) {
      _logger.error('Failed to get encryption cipher', error: e, stackTrace: stackTrace);
      // Return null - boxes will be opened without encryption as fallback
      // In production, you might want to handle this differently
      return null;
    }
  }

  /// Delete the encryption key (use with caution - will make existing data unreadable)
  static Future<void> deleteEncryptionKey() async {
    try {
      await _secureStorage.delete(key: _encryptionKeyName);
      _logger.warning('Encryption key deleted - existing encrypted data will be unreadable');
    } catch (e, stackTrace) {
      _logger.error('Failed to delete encryption key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if encryption key exists
  static Future<bool> hasEncryptionKey() async {
    try {
      final key = await _secureStorage.read(key: _encryptionKeyName);
      return key != null;
    } catch (e, stackTrace) {
      _logger.error('Failed to check encryption key', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
