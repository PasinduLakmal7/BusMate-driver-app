import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the JWT both in-memory (fast, reliable within session)
/// and in secure storage (persists across restarts).
/// The in-memory cache avoids Android Keystore read failures on emulators.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'driver_jwt_token';

  // In-memory cache — always up-to-date within the current app session
  static String? _memCache;

  static Future<void> saveToken(String token) async {
    _memCache = token; // write to memory first — always works
    await _storage.write(key: _tokenKey, value: token); // persist to disk
  }

  static Future<String?> getToken() async {
    if (_memCache != null && _memCache!.isNotEmpty) return _memCache;
    // Fall back to disk read (across restarts)
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) _memCache = token;
    return _memCache;
  }

  static Future<void> deleteToken() async {
    _memCache = null;
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
