package cn.homeledger.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * §4.2.7 导出上限与分批大小。5 万行是按 100 家庭 × 10 年的容量设计（§5.1）估出来的单次导出天花板，
 * 超出就该让用户缩小时间区间，而不是让容器堆替用户扛。
 */
@ConfigurationProperties(prefix = "homeledger.export")
public record ExportProperties(int maxRows, int batchSize) {

}
