import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_response.freezed.dart';
part 'token_response.g.dart';

/// 登录、注册、续期、改密码四个接口的共同返回体。
/// 有效期以秒回传，据此判断何时静默续期，不必解析 JWT 载荷。
@freezed
abstract class TokenResponse with _$TokenResponse {
  const factory TokenResponse({
    required String tokenType,
    required String accessToken,
    required int accessExpiresInSeconds,
    required String refreshToken,
    required int refreshExpiresInSeconds,
  }) = _TokenResponse;

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);
}
