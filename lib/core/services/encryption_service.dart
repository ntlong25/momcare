import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../utils/app_logger.dart';

/// Service to manage encryption keys for Hive databases
/// Uses flutter_secure_storage to securely store the encryption key
class EncryptionService {
  static const String _encryptionKeyName = 'hive_encryption_key';
  static const AndroidOptions _androidOptions = AndroidOptions(
    // Never wipe the stored key on a read error: that would make existing
    // encrypted health data permanently unreadable.
    resetOnError: false,
    migrateOnAlgorithmChange: true,
    migrateWithBackup: false,
    storageNamespace: 'momcare_hive_encryption',
  );
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );
  static final _secureStorage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
  static final _logger = AppLogger.instance;

  /// True when the last [getEncryptionCipher] call could not use secure
  /// storage and Hive boxes were opened without encryption.
  static bool isFallbackActive = false;

  static Future<String?> _readKeyWithRetry() async {
    try {
      return await _secureStorage.read(
        key: _encryptionKeyName,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      // Keystore may be briefly unavailable right after boot/unlock.
      _logger.warning('Reading encryption key failed, retrying once', error: e);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _secureStorage.read(
        key: _encryptionKeyName,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    }
  }

  /// Initialize and get encryption cipher for Hive
  /// Generates a new key if one doesn't exist
  ///
  /// Returns null (unencrypted fallback) only when secure storage is not
  /// usable. The fallback is logged as a warning and exposed through
  /// [isFallbackActive]; callers must not open previously encrypted boxes
  /// without a cipher (see `DatabaseService.init`).
  static Future<HiveAesCipher?> getEncryptionCipher() async {
    isFallbackActive = false;
    try {
      // Try to get existing key
      String? encryptionKey = await _readKeyWithRetry();

      if (encryptionKey == null) {
        // Generate new key
        _logger.info('Generating new encryption key for Hive');
        final key = Hive.generateSecureKey();
        encryptionKey = base64Url.encode(key);
        await _secureStorage.write(
          key: _encryptionKeyName,
          value: encryptionKey,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
        _logger.info('Encryption key generated and stored securely');
      }

      // Decode key and create cipher
      final key = base64Url.decode(encryptionKey);
      return HiveAesCipher(key);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get encryption cipher',
        error: e,
        stackTrace: stackTrace,
      );
      _logger.warning(
        'SECURITY: secure storage unavailable - Hive data will NOT be encrypted',
      );
      isFallbackActive = true;
      return null;
    }
  }

  /// Delete the encryption key (use with caution - will make existing data unreadable)
  static Future<void> deleteEncryptionKey() async {
    try {
      await _secureStorage.delete(
        key: _encryptionKeyName,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      _logger.warning(
        'Encryption key deleted - existing encrypted data will be unreadable',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to delete encryption key',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if encryption key exists
  static Future<bool> hasEncryptionKey() async {
    try {
      final key = await _secureStorage.read(
        key: _encryptionKeyName,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      return key != null;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to check encryption key',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

/// Thrown when data was previously stored encrypted but the key cannot be
/// read now. Opening the boxes without a cipher could corrupt that data.
class EncryptionUnavailableException implements Exception {
  final String message;

  const EncryptionUnavailableException(this.message);

  @override
  String toString() => 'EncryptionUnavailableException: $message';
}
