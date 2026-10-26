package cn.homeledger.service;

import java.time.LocalDate;

import cn.homeledger.entity.RecurringRule;

/**
 * §4.2.3 周期记账的生成引擎。
 * <p>
 * 引擎只认「业务日期」，不认时钟：取哪一天是调用方的事（定时任务取今天，集成测试任意喂一天）。
 * 这套逻辑因此能完全脱离调度单独验证。
 */
public interface RecurringGenerationService {

	/**
	 * 跑完 today 这一天、所有家庭、所有启用规则，返回新生成的流水笔数。
	 * <p>
	 * 单条规则失败只丢它自己那一份（事务在 {@link RecurringRuleExecutor} 上，已经回滚），记一条 error
	 * 后继续下一条：定时任务没有人看着，把异常抛出去只会让当天剩下的规则全部不执行。
	 */
	int runFor(LocalDate today);

	/**
	 * 只跑一条规则，供新建与恢复规则时在同一事务内同步补跑（A4「当月立即生效」）。
	 * <p>
	 * 与 {@link #runFor} 唯一的行为差别是不吞异常：它由用户在界面上的一次点击触发，失败必须让 TA 当场看到，
	 * 而不是回一个「0 笔」假装一切正常。
	 */
	int runForRule(RecurringRule rule, LocalDate today);

}
