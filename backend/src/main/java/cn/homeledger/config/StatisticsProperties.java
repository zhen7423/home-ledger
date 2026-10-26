package cn.homeledger.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * §5.1 统计缓存。TTL 是配置项而不是常量，压测时要在不动代码的前提下试出合适的值。
 */
@ConfigurationProperties(prefix = "homeledger.statistics")
public record StatisticsProperties(Duration cacheTtl) {

}
