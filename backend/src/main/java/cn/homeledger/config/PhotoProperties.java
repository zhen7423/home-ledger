package cn.homeledger.config;

import java.nio.file.Path;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * §4.3.1 档案照片的存储配置（{@code homeledger.upload.*}）。
 *
 * @param dir 磁盘目录。compose 全量 profile 下 app 与 nginx 共享这一卷；本地直跑用可写目录
 * @param maxBytes 单张上限，需求写死 5 MB
 * @param useNginxAccel 直读模式：true 时 GET 照片回 {@code X-Accel-Redirect} 由 Nginx internal 直出
 *        （生产、compose full），false 时后端自己流式返回（本地没有 Nginx，图片也要能看）
 */
@ConfigurationProperties(prefix = "homeledger.upload")
public record PhotoProperties(Path dir, long maxBytes, boolean useNginxAccel) {

}