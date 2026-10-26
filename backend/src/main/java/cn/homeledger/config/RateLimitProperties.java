package cn.homeledger.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * §5.2 限流与 §4.1.2 登录锁定阈值。默认值即需求文档口径：邀请码校验 10 次/分钟（§4.1.4）、
 * 密码连续错误 5 次锁 15 分钟（§4.1.2）。其余 IP 维度阈值文档未给具体数字，取保守默认值并集中在此便于调整。
 */
@ConfigurationProperties(prefix = "homeledger.rate-limit")
public record RateLimitProperties(int loginPerIpPerMinute, int registerPerIpPerMinute, int joinFamilyPerIpPerMinute,
		int changePasswordPerIpPerMinute, int passwordFailLimit, Duration passwordLockWindow) {

}
