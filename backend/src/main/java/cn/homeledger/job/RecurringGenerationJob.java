package cn.homeledger.job;

import java.time.Clock;
import java.time.LocalDate;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import cn.homeledger.service.RecurringGenerationService;

/**
 * 周期记账的每日触发器。
 * <p>
 * 本类只做一件事：把「今天」交给引擎。所有业务分支都在 service 里——这是 job 包与 controller 包共用的判据
 * （§6.4.1）：类里有没有决定业务走向的 if，没有就属于这里。
 */
@Component
@ConditionalOnProperty(name = "homeledger.recurring.enabled", havingValue = "true", matchIfMissing = true)
public class RecurringGenerationJob {

	private static final Logger log = LoggerFactory.getLogger(RecurringGenerationJob.class);

	private final RecurringGenerationService generationService;

	private final Clock clock;

	public RecurringGenerationJob(RecurringGenerationService generationService, Clock clock) {
		this.generationService = generationService;
		this.clock = clock;
	}

	/**
	 * cron 显式带 zone：容器默认时区通常是 UTC，不写 zone 的话「每天 00:10」会在北京时间 08:10 触发，
	 * 而那正是用户开始记账的时段，生成的流水会带着昨天的日期出现在今天的列表顶部。
	 * 选 00:10 而不是 00:00 是留出跨日余量：整点触发时数据库与应用可能还没完全跨过日期边界。
	 */
	@Scheduled(cron = "0 10 0 * * *", zone = "Asia/Shanghai")
	public void generateDaily() {
		LocalDate today = LocalDate.now(this.clock);
		log.info("周期记账任务开始 bizDate={}", today);
		int generated = this.generationService.runFor(today);
		log.info("周期记账任务结束 bizDate={} generated={}", today, generated);
	}

}
