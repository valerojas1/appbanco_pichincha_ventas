import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const String keySessionProfile = 'session_profile_json';
  static const String keyLastActivity = 'last_activity_iso';
  static const String keyLoginFailedAttempts = 'login_failed_attempts';
  static const String keyLoginLockedUntil = 'login_locked_until_iso';

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearSession() async {
    await Future.wait([
      delete(keySessionProfile),
      delete(keyLastActivity),
    ]);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
