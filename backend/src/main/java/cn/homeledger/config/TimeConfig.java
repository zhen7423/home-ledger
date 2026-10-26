package cn.homeledger.config;

import java.time.Clock;
import java.time.ZoneId;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * §7.2：时区固定 Asia/Shanghai，业务日期计算不受部署机时区影响。
 * 统一注入 Clock 而不是在业务代码里写 LocalDateTime.now()，部署机时区一旦配错也不会污染业务时间。
 */
@Configuration
public class TimeConfig {

	public static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");

	@Bean
	public Clock clock() {
		return Clock.system(ZONE);
	}

}
