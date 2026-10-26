package cn.homeledger.security;

import java.time.Duration;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

/**
 * §4.1.2「Refresh Token 存 Redis，支持服务端主动吊销」。键为 refresh token 的 jti，值为其所属 userId；
 * 值与令牌 sub 不一致即视为无效，防止拿别人的 jti 换自己的令牌。
 * <p>
 * 刷新时轮换：旧 jti 立即删除、签发新的一对令牌。被窃取的旧 refresh token 因此在一次刷新后即作废。
 */
@Service
public class RefreshTokenStore {

	static final String KEY_PREFIX = "auth:refresh:";

	private final StringRedisTemplate redis;

	public RefreshTokenStore(StringRedisTemplate redis) {
		this.redis = redis;
	}

	public void save(String jti, Long userId, Duration ttl) {
		this.redis.opsForValue().set(KEY_PREFIX + jti, Long.toString(userId), ttl);
	}

	/** 返回该 jti 归属的 userId；不存在（已吊销、已轮换或已过期）时返回 null。 */
	public Long findUserId(String jti) {
		String value = this.redis.opsForValue().get(KEY_PREFIX + jti);
		return (value == null) ? null : Long.valueOf(value);
	}

	public void revoke(String jti) {
		this.redis.delete(KEY_PREFIX + jti);
	}

}
