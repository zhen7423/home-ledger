package cn.homeledger.common;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import cn.homeledger.config.StatisticsProperties;
import tools.jackson.databind.ObjectMapper;

/**
 * §5.1 的统计缓存。缓存的是 VO 的 JSON，所以命中与未命中必须返回逐字段相同的数据，
 * `StatisticsIntegrationTest` 用「同一条件连查两次、两次逐字段一致」钉住这一点。
 */
@Component
public class StatisticsCache {

	private static final Logger log = LoggerFactory.getLogger(StatisticsCache.class);

	private static final String KEY_PREFIX = "stats:";

	/** 每家庭每个模块一个版本号。写操作 INCR 自己那一版，键里的版本号段随之对不上，旧条目自然读不到。 */
	private static final String VERSION_PREFIX = "stats:ver:";

	/** 从没写过流水的家庭没有版本号键，取 "0" 而不是现建一个：INCR 会把不存在的键当 0 起算，两边口径要一致。 */
	private static final String VERSION_ABSENT = "0";

	private static final int FINGERPRINT_LENGTH = 16;

	/** 缓存键与版本号键里的模块段。各模块的统计互不相干，各自的数据各自失效自己的那一版（§5.1）。 */
	public static final String MODULE_FINANCE = "fin";

	public static final String MODULE_CAT = "cat";

	public static final String MODULE_BABY = "baby";

	private final StringRedisTemplate redis;

	private final ObjectMapper objectMapper;

	private final StatisticsProperties properties;

	public StatisticsCache(StringRedisTemplate redis, ObjectMapper objectMapper, StatisticsProperties properties) {
		this.redis = redis;
		this.objectMapper = objectMapper;
		this.properties = properties;
	}

	/**
	 * 未命中、Redis 不可用、JSON 坏掉，一律返回 null 走重算。缓存不许变成故障源：
	 * 统计读不到旧值的代价是多跑一次聚合，读不到任何值的代价是页面白屏。
	 * <p>
	 * conditions 是<b>调用方规范化过</b>的条件串——哪些字段参与指纹、按什么顺序，只有条件本身知道；
	 * 让缓存类去反射一个它不该认识的 DTO，等于每加一个模块都要回来改一次这里（§5.1、第 23 轮 (3)）。
	 */
	public <T> T read(String module, String endpoint, Long familyId, String conditions, Class<T> type) {
		try {
			String json = this.redis.opsForValue().get(key(module, endpoint, familyId, conditions));
			return json == null ? null : this.objectMapper.readValue(json, type);
		}
		catch (RuntimeException e) {
			// Jackson 3 的 JacksonException 是 RuntimeException 的子类，反序列化失败也落在这里
			log.warn("统计缓存读取失败，按未命中处理: {}", e.toString());
			return null;
		}
	}

	public void write(String module, String endpoint, Long familyId, String conditions, Object value) {
		try {
			this.redis.opsForValue()
				.set(key(module, endpoint, familyId, conditions), this.objectMapper.writeValueAsString(value),
						this.properties.cacheTtl());
		}
		catch (RuntimeException e) {
			log.warn("统计缓存写入失败，本次结果不落缓存: {}", e.toString());
		}
	}

	/**
	 * 让本家庭的该模块统计缓存立刻读不到。只 INCR 一个键，不枚举、不删除。
	 * <p>
	 * 粒度到模块为止是刻意的粗：猫咪侧三类端点共用 {@link #MODULE_CAT}，要逐图判断「改一袋猫粮会影响哪几张图」
	 * 就得复制一份口径推断逻辑，而那份逻辑错一次的代价是统计长期悄悄偏差。
	 * <p>
	 * 失败只记 error 不往外抛：调用它的四处都在 {@code @Transactional} 里，为一个缓存版本号回滚一次
	 * 已经写成功的记账是拿 correctness 换 correctness，方向反了。后果是本家庭最长 cache-ttl 内
	 * 可能读到旧统计，这个窗口 §4.2.6 已经为字典改名接受过一次。
	 */
	public void invalidate(String module, Long familyId) {
		try {
			this.redis.opsForValue().increment(versionKey(module, familyId));
		}
		catch (RuntimeException e) {
			log.error("统计缓存版本号递增失败，本家庭最长 {} 内可能读到旧统计: {}", this.properties.cacheTtl(),
					e.toString());
		}
	}

	private String key(String module, String endpoint, Long familyId, String conditions) {
		return KEY_PREFIX + module + ':' + endpoint + ':' + familyId + ':' + version(module, familyId) + ':'
				+ fingerprint(conditions);
	}

	private String version(String module, Long familyId) {
		String value = this.redis.opsForValue().get(versionKey(module, familyId));
		return value == null ? VERSION_ABSENT : value;
	}

	private static String versionKey(String module, Long familyId) {
		return VERSION_PREFIX + module + ':' + familyId;
	}

	/** 条件串的指纹。规范化已由调用方做完，这里只剩「同一串必须永远同一值」这一件事。 */
	public static String fingerprint(String canonicalConditions) {
		return sha256Hex(canonicalConditions).substring(0, FINGERPRINT_LENGTH);
	}

	/**
	 * 拼规范化条件串用的分隔与空值口径，供各模块的 canonicalConditions() 复用。
	 * <p>
	 * 「不传这个条件」与「传了个空串」必须是同一个键，否则同一份查询会存出两份永不互认的缓存；
	 * 这条规则若由各调用方各写一遍，迟早有人漏掉 null。除此之外（哪些字段进、按什么顺序）仍归调用方。
	 */
	public static String joinConditions(String... parts) {
		return String.join("|", Arrays.stream(parts).map(part -> part == null ? "" : part).toList());
	}

	private static String sha256Hex(String value) {
		try {
			return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
		}
		catch (NoSuchAlgorithmException e) {
			// JDK 强制要求实现 SHA-256，走到这里说明运行时不是标准 JDK
			throw new IllegalStateException("SHA-256 不可用", e);
		}
	}

}
