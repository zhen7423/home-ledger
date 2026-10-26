import 'package:homeledger/data/models/token_response.dart';
import 'package:homeledger/data/services/token_storage.dart';

/// flutter_secure_storage 走平台通道，`flutter test` 里没有宿主，用它替身。
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this._tokens, this._lastPhone});

  StoredTokens? _tokens;
  String? _lastPhone;

  final List<TokenResponse> writtenTokens = [];
  int clearCount = 0;

  @override
  Future<StoredTokens?> readTokens() async => _tokens;

  @override
  Future<void> writeTokens(TokenResponse token) async {
    writtenTokens.add(token);
    _tokens = StoredTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      accessExpiresAt: DateTime.now().add(
        Duration(seconds: token.accessExpiresInSeconds),
      ),
    );
  }

  @override
  Future<void> clearTokens() async {
    clearCount++;
    _tokens = null;
  }

  @override
  Future<String?> readLastPhone() async => _lastPhone;

  @override
  Future<void> writeLastPhone(String phone) async => _lastPhone = phone;
}
