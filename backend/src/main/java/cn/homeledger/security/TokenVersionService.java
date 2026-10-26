package cn.homeledger.security;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

/**
 * §5.2 令牌即时吊销：Redis 维护每用户令牌版本号，签发时写入 JWT 的 tv claim，此后每次请求比对。
 * <p>
 * 键不设 TTL：版本号必须活得比 30 天的 Refresh Token 更久，否则键过期后 current() 归零，
 * 会让仍在使用中的令牌全部失配。Redis 整体丢数据的后果是全员重新登录——这是偏安全的失败方向（拒绝服务，
 * 而非放行越权），且 compose 已为 Redis 开启 appendonly。
 */
@Service
public class TokenVersionService {

	static final String KEY_PREFIX = "auth:token-ver:";

	private final StringRedisTemplate redis;

	public TokenVersionService(StringRedisTemplate redis) {
		this.redis = redis;
	}

	public long current(Long userId) {
		String value = this.redis.opsForValue().get(KEY_PREFIX + userId);
		return (value == null) ? 0L : Long.parseLong(value);
	}

	/** 递增后已签发的全部 Access / Refresh Token 立即失效。INCR 在键不存在时从 0 起算，与 current() 的缺省值一致。 */
	public long bump(Long userId) {
		Long next = this.redis.opsForValue().increment(KEY_PREFIX + userId);
		return (next == null) ? 0L : next;
	}

}
