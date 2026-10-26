package cn.homeledger.security;

import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.UUID;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.stereotype.Service;

import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.JwtParser;
import io.jsonwebtoken.Jwts;

/**
 * §4.1.2 令牌签发与校验。
 * <p>
 * 载荷刻意只放 userId / 令牌版本号 / 类型：familyId 与 role 每请求实时查库（见 {@link cn.homeledger.common.AuthContext}），
 * 因此「退出家庭后旧令牌仍带着原 familyId」这一越权窗口从设计上不存在。
 */
@Service
public class JwtService {

	public static final String CLAIM_TOKEN_VERSION = "tv";

	public static final String CLAIM_TYPE = "typ";

	public static final String TYPE_ACCESS = "access";

	public static final String TYPE_REFRESH = "refresh";

	private static final String HMAC_ALGORITHM = "HmacSHA256";

	private static final int MIN_SECRET_BYTES = 32;

	/** 客户端与服务端时钟允许的最大偏差，避免整点前后几分钟内出现无谓的过期判定。 */
	private static final long CLOCK_SKEW_SECONDS = 60;

	private final JwtProperties properties;

	private final SecretKey key;

	private final JwtParser parser;

	public JwtService(JwtProperties properties) {
		this.properties = properties;
		this.key = buildKey(properties.secret());
		this.parser = Jwts.parser().verifyWith(this.key).clockSkewSeconds(CLOCK_SKEW_SECONDS).build();
	}

	/** 用 SecretKeySpec 而非 Keys.hmacShaKeyFor：后者按密钥长度推断算法，长密钥会得到 HmacSHA512，与显式声明的 HS256 冲突。 */
	private static SecretKey buildKey(String base64Secret) {
		if (base64Secret == null || base64Secret.isBlank()) {
			throw new IllegalStateException(
					"homeledger.jwt.secret 未配置。§5.2 要求签名密钥从环境变量注入，不得写入代码库。");
		}
		byte[] raw;
		try {
			raw = Base64.getDecoder().decode(base64Secret.trim());
		}
		catch (IllegalArgumentException ex) {
			throw new IllegalStateException("homeledger.jwt.secret 不是合法的 Base64 字符串。", ex);
		}
		if (raw.length < MIN_SECRET_BYTES) {
			throw new IllegalStateException("homeledger.jwt.secret 解码后为 " + raw.length + " 字节，HS256 要求至少 "
					+ MIN_SECRET_BYTES + " 字节（256 位）。");
		}
		return new SecretKeySpec(raw, HMAC_ALGORITHM);
	}

	public String issueAccessToken(Long userId, long tokenVersion) {
		return build(userId, tokenVersion, TYPE_ACCESS, this.properties.accessTtl());
	}

	public IssuedRefreshToken issueRefreshToken(Long userId, long tokenVersion) {
		String jti = UUID.randomUUID().toString();
		Instant now = Instant.now();
		String token = build(userId, tokenVersion, TYPE_REFRESH, this.properties.refreshTtl(), jti, now);
		return new IssuedRefreshToken(token, jti);
	}

	private String build(Long userId, long tokenVersion, String type, Duration ttl) {
		return build(userId, tokenVersion, type, ttl, UUID.randomUUID().toString(), Instant.now());
	}

	private String build(Long userId, long tokenVersion, String type, Duration ttl, String jti, Instant issuedAt) {
		return Jwts.builder()
			.issuer(this.properties.issuer())
			.subject(Long.toString(userId))
			.id(jti)
			.issuedAt(Date.from(issuedAt))
			.expiration(Date.from(issuedAt.plus(ttl)))
			.claim(CLAIM_TYPE, type)
			.claim(CLAIM_TOKEN_VERSION, tokenVersion)
			.signWith(this.key, Jwts.SIG.HS256)
			.compact();
	}

	public ParsedToken parseAccessToken(String token) {
		return parse(token, TYPE_ACCESS, ErrorCode.TOKEN_EXPIRED, ErrorCode.UNAUTHORIZED);
	}

	public ParsedToken parseRefreshToken(String token) {
		return parse(token, TYPE_REFRESH, ErrorCode.REFRESH_TOKEN_INVALID, ErrorCode.REFRESH_TOKEN_INVALID);
	}

	private ParsedToken parse(String token, String expectedType, ErrorCode onExpired, ErrorCode onInvalid) {
		if (token == null || token.isBlank()) {
			throw new BizException(onInvalid);
		}
		Claims claims;
		try {
			claims = this.parser.parseSignedClaims(token).getPayload();
		}
		catch (ExpiredJwtException ex) {
			throw new BizException(onExpired);
		}
		catch (JwtException | IllegalArgumentException ex) {
			throw new BizException(onInvalid);
		}
		if (!expectedType.equals(claims.get(CLAIM_TYPE, String.class))) {
			throw new BizException(onInvalid);
		}
		Number tokenVersion = claims.get(CLAIM_TOKEN_VERSION, Number.class);
		if (tokenVersion == null) {
			throw new BizException(onInvalid);
		}
		return new ParsedToken(Long.valueOf(claims.getSubject()), tokenVersion.longValue(), claims.getId());
	}

	public Duration accessTtl() {
		return this.properties.accessTtl();
	}

	public Duration refreshTtl() {
		return this.properties.refreshTtl();
	}

	/** Refresh Token 的 jti 单独返回，供 Redis 吊销表落键。 */
	public record IssuedRefreshToken(String token, String jti) {

	}

	public record ParsedToken(Long userId, long tokenVersion, String jti) {

	}

}
