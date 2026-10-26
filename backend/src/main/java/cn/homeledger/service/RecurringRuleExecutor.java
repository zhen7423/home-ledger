package cn.homeledger.service;

import java.time.LocalDate;

import cn.homeledger.entity.RecurringRule;

/**
 * 一条规则在一个补记窗口内的全部生成，整体一个事务。
 * <p>
 * 单独成一个 bean 只为了 Spring 的事务代理：{@code @Transactional} 靠动态代理生效，同一个类里
 * {@code this.execute(rule, today)} 自调用不走代理，注解会静默失效。真把循环和单条执行写在一起，
 * 代价是「一条规则炸了会把当天已生成的全部流水一起回滚」，而单元测试里没有真实事务，测不出来，
 * 只有集成测试会以「其他规则的流水也消失了」的形式暴露。
 */
public interface RecurringRuleExecutor {

	/** 生成这一条规则在 {@code today} 这个窗口里的流水，返回新生成的笔数。 */
	int execute(RecurringRule rule, LocalDate today);

}
