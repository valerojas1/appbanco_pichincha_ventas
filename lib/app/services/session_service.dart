import '../core/auth_constants.dart';
import 'secure_storage_service.dart';

class SessionService {
  final SecureStorageService _secure = SecureStorageService();

  Future<int> getFailedAttempts() async {
    final raw = await _secure.read(SecureStorageService.keyLoginFailedAttempts);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> recordFailedAttempt() async {
    final attempts = await getFailedAttempts() + 1;
    await _secure.write(
      SecureStorageService.keyLoginFailedAttempts,
      attempts.toString(),
    );
    if (attempts >= AuthConstants.maxLoginAttempts) {
      final lockedUntil = DateTime.now().add(AuthConstants.lockoutDuration);
      await _secure.write(
        SecureStorageService.keyLoginLockedUntil,
        lockedUntil.toIso8601String(),
      );
    }
  }

  Future<void> clearFailedAttempts() async {
    await _secure.delete(SecureStorageService.keyLoginFailedAttempts);
    await _secure.delete(SecureStorageService.keyLoginLockedUntil);
  }

  Future<DateTime?> getLockedUntil() async {
    final raw = await _secure.read(SecureStorageService.keyLoginLockedUntil);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> isLockedOut() async {
    final lockedUntil = await getLockedUntil();
    if (lockedUntil == null) return false;
    if (DateTime.now().isBefore(lockedUntil)) return true;
    await clearFailedAttempts();
    return false;
  }

  Future<Duration?> remainingLockout() async {
    final lockedUntil = await getLockedUntil();
    if (lockedUntil == null) return null;
    final diff = lockedUntil.difference(DateTime.now());
    if (diff.isNegative) return null;
    return diff;
  }

  Future<void> touchActivity() async {
    await _secure.write(
      SecureStorageService.keyLastActivity,
      DateTime.now().toIso8601String(),
    );
  }

  Future<bool> isSessionExpiredByInactivity() async {
    final raw = await _secure.read(SecureStorageService.keyLastActivity);
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last) > AuthConstants.sessionInactivityLimit;
  }

  Future<void> saveProfileJson(String json) async {
    await _secure.write(SecureStorageService.keySessionProfile, json);
    await touchActivity();
  }

  Future<String?> readProfileJson() async {
    return _secure.read(SecureStorageService.keySessionProfile);
  }

  Future<void> clearSession() async {
    await _secure.clearSession();
  }
}
