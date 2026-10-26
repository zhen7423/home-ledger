package cn.homeledger.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * @param secret     Base64 编码的 HMAC 密钥，解码后须 ≥ 32 字节（HS256 最小长度）。§5.2：从环境变量注入，不入代码库。
 * @param issuer     JWT iss claim
 * @param accessTtl  §4.1.2：Access Token 2 小时
 * @param refreshTtl §4.1.2：Refresh Token 30 天
 */
@ConfigurationProperties(prefix = "homeledger.jwt")
public record JwtProperties(String secret, String issuer, Duration accessTtl, Duration refreshTtl) {

}
