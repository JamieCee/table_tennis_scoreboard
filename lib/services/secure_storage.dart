import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const tokenTypeKey = 'token_type';
  static const expiresAtKey = 'expires_at';
  static const isSubscribedKey = 'is_subscribed';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
    required int expiresIn,
    required bool isSubscribed,
  }) async {
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;

    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
    await _storage.write(key: tokenTypeKey, value: tokenType);
    await _storage.write(key: expiresAtKey, value: expiresAt.toString());
    await _storage.write(key: isSubscribedKey, value: isSubscribed.toString());
  }

  Future<String?> getAccessToken() => _storage.read(key: accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<bool> isSubscribed() async {
    final value = await _storage.read(key: isSubscribedKey);
    return value == 'true';
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
