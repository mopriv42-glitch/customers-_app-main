import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod provider for [StorageService]
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(
    const FlutterSecureStorage(),
    SharedPreferences.getInstance(),
  );
});

/// Handles all local persistence. Sensitive data → secure storage, non-sensitive → shared prefs.
class StorageService {
  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> _prefs;
  static const _authTokenKey = 'auth_token';

  StorageService(this._secureStorage, this._prefs);

  /* ---------------- Secure storage helpers ---------------- */
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _authTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: _authTokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _authTokenKey);
  }

  /* ---------------- Shared-prefs helpers ---------------- */
  Future<void> setOnboardingComplete() async {
    final prefs = await _prefs;
    await prefs.setBool('onboarding_complete', true);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
