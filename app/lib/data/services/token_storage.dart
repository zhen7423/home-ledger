import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/token_response.dart';

/// 令牌持久化。抽成接口是为了让单元测试能替身掉——flutter_secure_storage 走平台通道，
/// 在 `flutter test` 里没有 Android/iOS 宿主，直接实例化会抛 MissingPluginException。
abstract interface class TokenStorage {
  Future<StoredTokens?> readTokens();

  Future<void> writeTokens(TokenResponse token);

  Future<void> clearTokens();

  Future<String?> readLastPhone();

  Future<void> writeLastPhone(String phone);
}

/// 从 secure storage 读出的令牌。accessExpiresAt 由写入时刻加上后端回传的有效期秒数得出，
/// 拦截器据此判断是否该提前续期，不必解析 JWT 载荷。
class StoredTokens {
  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;

  bool expiresWithin(Duration window) =>
      accessExpiresAt.isBefore(DateTime.now().add(window));
}

/// §4.1.2：Access / Refresh Token 都存 flutter_secure_storage（Android 走 Keystore +
/// EncryptedSharedPreferences），不落 SharedPreferences 明文、不写日志。
///
/// 退出登录清掉三个令牌键，只留登录名用于下次填充。
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessExpiresAtKey = 'access_expires_at';
  static const String _lastPhoneKey = 'last_phone';

  @override
  Future<StoredTokens?> readTokens() async {
    final access = await _storage.read(key: _accessTokenKey);
    final refresh = await _storage.read(key: _refreshTokenKey);
    final expiresAt = await _storage.read(key: _accessExpiresAtKey);
    if (access == null || refresh == null || expiresAt == null) {
      return null;
    }
    // expiresAt 半截写入/迁移残留时按「早已过期」处理：随后的续期要么换新令牌自愈，
    // 要么失败清会话送回登录页。绝不让一个 FormatException 在每个请求的拦截器里反复炸。
    final expiresAtMillis = int.tryParse(expiresAt) ?? 0;
    return StoredTokens(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMillis),
    );
  }

  @override
  Future<void> writeTokens(TokenResponse token) async {
    final expiresAt = DateTime.now().add(
      Duration(seconds: token.accessExpiresInSeconds),
    );
    await _storage.write(key: _accessTokenKey, value: token.accessToken);
    await _storage.write(key: _refreshTokenKey, value: token.refreshToken);
    await _storage.write(
      key: _accessExpiresAtKey,
      value: expiresAt.millisecondsSinceEpoch.toString(),
    );
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accessExpiresAtKey);
  }

  @override
  Future<String?> readLastPhone() => _storage.read(key: _lastPhoneKey);

  @override
  Future<void> writeLastPhone(String phone) =>
      _storage.write(key: _lastPhoneKey, value: phone);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(const FlutterSecureStorage()),
);
