package cn.homeledger.vo;

/**
 * §4.1.2 令牌对。有效期以秒回传，客户端据此判断何时静默续期，不必解析 JWT 载荷。
 * 客户端须把两个令牌都存进 flutter_secure_storage，不落 SharedPreferences 明文、不写日志（§4.1.2）。
 */
public record TokenResponse(String tokenType, String accessToken, long accessExpiresInSeconds, String refreshToken,
		long refreshExpiresInSeconds) {

	public static TokenResponse bearer(String accessToken, long accessExpiresInSeconds, String refreshToken,
			long refreshExpiresInSeconds) {
		return new TokenResponse("Bearer", accessToken, accessExpiresInSeconds, refreshToken, refreshExpiresInSeconds);
	}

}
