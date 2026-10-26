package cn.homeledger.job;

import java.time.Clock;
import java.time.LocalDateTime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import cn.homeledger.service.FamilyPurgeService;

/**
 * 解散家庭 30 天保留期到期的每日清理触发器（§4.1.6 / §12 S10）。
 * <p>
 * 本类只做「报时间、数结果」两件事，扫描、删除、文件清理都在 service 里——job 包与
 * controller 包共用那道判据（§6.4.1）：类里有没有决定业务走向的 if，没有就属于这里。
 */
@Component
@ConditionalOnProperty(name = "homeledger.purge.enabled", havingValue = "true", matchIfMissing = true)
public class FamilyPurgeJob {

	private static final Logger log = LoggerFactory.getLogger(FamilyPurgeJob.class);

	private final FamilyPurgeService purgeService;

	private final Clock clock;

	public FamilyPurgeJob(FamilyPurgeService purgeService, Clock clock) {
		this.purgeService = purgeService;
		this.clock = clock;
	}

	/**
	 * 每天 01:30 跑一次。选凌晨 1 点不止为了避开用户使用时段，还为了避开周期记账的 00:10
	 * （§4.2.3）——两件事都会全表扫，错开高峰比抢同一段窗口便宜。
	 * zone 显式写 Asia/Shanghai：容器默认时区通常是 UTC，不写的话「每天 01:30」会跑到北京时间的
	 * 09:30，而那时家人可能正在用，删除动作刚开头就被用户查到了中间态。
	 */
	@Scheduled(cron = "0 30 1 * * *", zone = "Asia/Shanghai")
	public void purgeDaily() {
		int purged = this.purgeService.purgeExpiredFamilies(LocalDateTime.now(this.clock));
		log.info("解散家庭物理清除任务结束 purged={}", purged);
	}

}