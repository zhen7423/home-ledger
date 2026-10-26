package cn.homeledger.security;

import java.time.Duration;
import java.util.List;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.data.redis.core.script.RedisScript;
import org.springframework.stereotype.Service;

import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.config.RateLimitProperties;

/**
 * §5.2 限流：Redis INCR + EXPIRE 手写固定窗口，不引入 Bucket4j / Resilience4j（单实例部署，只需「N 次 / M 分钟」）。
 * §4.1.2 登录失败计数与锁定同样落在这里，键靠 TTL 到期自动解锁，因此 user 表不需要 failed_attempts / locked_until 字段。
 */
@Service
public class RateLimitService {

	/**
	 * INCR 与 PEXPIRE 必须原子：分两条命令发送时，若进程在两者之间崩溃，计数键将永久没有 TTL，
	 * 该账号/IP 会被无限期锁死。Lua 脚本消除了这个失败模式。
	 */
	private static final RedisScript<Long> INCR_WITH_WINDOW = new DefaultRedisScript<>(
			"local c = redis.call('INCR', KEYS[1]) " + "if c == 1 then redis.call('PEXPIRE', KEYS[1], ARGV[1]) end "
					+ "return c",
			Long.class);

	private static final String RATE_LIMIT_PREFIX = "rl:";

	private static final String LOGIN_FAIL_PREFIX = "auth:fail:";

	private static final String LOGIN_LOCK_PREFIX = "auth:lock:";

	private final StringRedisTemplate redis;

	private final RateLimitProperties properties;

	public RateLimitService(StringRedisTemplate redis, RateLimitProperties properties) {
		this.redis = redis;
		this.properties = properties;
	}

	public void checkLogin(String ip) {
		rejectIfOver("login:" + ip, this.properties.loginPerIpPerMinute(), Duration.ofMinutes(1));
	}

	public void checkRegister(String ip) {
		rejectIfOver("register:" + ip, this.properties.registerPerIpPerMinute(), Duration.ofMinutes(1));
	}

	/** §4.1.4：邀请码校验同一 IP 每分钟最多 10 次，防遍历。 */
	public void checkJoinFamily(String ip) {
		rejectIfOver("join-family:" + ip, this.properties.joinFamilyPerIpPerMinute(), Duration.ofMinutes(1));
	}

	public void checkChangePassword(String ip) {
		rejectIfOver("change-password:" + ip, this.properties.changePasswordPerIpPerMinute(), Duration.ofMinutes(1));
	}

	/** §4.1.2 / 验收用例 5：锁定期内即使密码正确也拒绝。必须在校验密码之前调用。 */
	public void assertNotLocked(String phone) {
		String lockKey = LOGIN_LOCK_PREFIX + phone;
		if (!Boolean.TRUE.equals(this.redis.hasKey(lockKey))) {
			return;
		}
		Long seconds = this.redis.getExpire(lockKey);
		long minutes = (seconds == null || seconds <= 0) ? 1 : Math.max(1, (seconds + 59) / 60);
		throw new BizException(ErrorCode.ACCOUNT_LOCKED,
				"密码连续错误 " + this.properties.passwordFailLimit() + " 次，账号已锁定，请 " + minutes + " 分钟后再试");
	}

	public void recordLoginFailure(String phone) {
		long failures = increment(LOGIN_FAIL_PREFIX + phone, this.properties.passwordLockWindow());
		if (failures >= this.properties.passwordFailLimit()) {
			this.redis.opsForValue()
				.set(LOGIN_LOCK_PREFIX + phone, Long.toString(failures), this.properties.passwordLockWindow());
			this.redis.delete(LOGIN_FAIL_PREFIX + phone);
		}
	}

	public void clearLoginFailures(String phone) {
		this.redis.delete(LOGIN_FAIL_PREFIX + phone);
		this.redis.delete(LOGIN_LOCK_PREFIX + phone);
	}

	private void rejectIfOver(String scene, int limit, Duration window) {
		if (increment(RATE_LIMIT_PREFIX + scene, window) > limit) {
			throw new BizException(ErrorCode.RATE_LIMITED);
		}
	}

	private long increment(String key, Duration window) {
		Long count = this.redis.execute(INCR_WITH_WINDOW, List.of(key), Long.toString(window.toMillis()));
		return (count == null) ? 1L : count;
	}

}
