package cn.homeledger.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * 打开 Spring 的定时任务调度（§4.2.3）。
 * <p>
 * 关掉它的开关在 {@code src/test/resources/application-local.yml}（集成测试）与本地自建的
 * {@code application-local.yml}（模板见 {@code application-local.yml.example}；main 侧那份
 * 因携带开发口令已移出版本库，S10 审查 M3），而不是各测试类上写 {@code @SpringBootTest(properties = …)}：
 * 本地与测试跑的都是 local profile，一处就能同时盖住 {@code ApiTestBase} 与 {@code HomeLedgerApplicationTests}。
 * 只配前者的话，后者里那个盯拦截器顺序的测试会在 00:10 附近真把任务跑起来——那个线程没有登录态，
 * 跨家庭扫描撞上 -1 哨兵，日志里冒一串 WARN，看着像测试坏了。
 */
@Configuration
@EnableScheduling
@ConditionalOnProperty(name = "homeledger.recurring.enabled", havingValue = "true", matchIfMissing = true)
public class SchedulingConfig {

}
