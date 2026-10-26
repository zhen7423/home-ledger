import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/token_response.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/token_storage.dart';

/// §4.1 账号：注册、登录、登出、改密码。
///
/// 令牌落盘归这里管，ViewModel 不碰 flutter_secure_storage。
class AuthRepository {
  AuthRepository({required this._api, required this._storage});

  final ApiClient _api;
  final TokenStorage _storage;

  /// 本地是否有令牌。只判断存不存在，不校验有效性——真失效由服务端回 401，
  /// ApiClient 会清令牌并通过 sessionLost 通知守卫，启动时不必为此多发一次请求。
  Future<bool> hasStoredSession() async =>
      (await _storage.readTokens()) != null;

  Future<String?> readLastPhone() => _storage.readLastPhone();

  Future<void> signIn({required String phone, required String password}) async {
    final data = await _api.post(
      '/auth/login',
      body: {'phone': phone, 'password': password},
    );
    await _saveSession(requireData(data), phone);
  }

  /// §4.1.1 注册即登录：接口直接回令牌对，省掉让用户再填一次同样手机号和密码的步骤。
  Future<void> signUp({
    required String phone,
    required String password,
    required String nickname,
  }) async {
    final data = await _api.post(
      '/auth/register',
      body: {'phone': phone, 'password': password, 'nickname': nickname},
    );
    await _saveSession(requireData(data), phone);
  }

  /// §4.1.2 改密码会递增令牌版本号，本人已签发的令牌随之作废，所以必须换上响应里的新令牌，
  /// 否则改个密码就把自己弹回登录页。
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final data = await _api.patch(
      '/auth/password',
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    await _storage.writeTokens(TokenResponse.fromJson(requireData(data)));
  }

  Future<void> signOut() async {
    final tokens = await _storage.readTokens();
    if (tokens != null) {
      try {
        await _api.post(
          '/auth/logout',
          body: {'refreshToken': tokens.refreshToken},
        );
      } on ApiException {
        // 登出要幂等成功：服务端那头令牌本就已失效的话，目的已经达成，本地清干净就够了
      }
    }
    await _storage.clearTokens();
  }

  Future<void> _saveSession(Map<String, dynamic> data, String phone) async {
    await _storage.writeTokens(TokenResponse.fromJson(data));
    await _storage.writeLastPhone(phone);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    api: ref.watch(apiClientProvider),
    storage: ref.watch(tokenStorageProvider),
  ),
);
