package cn.homeledger.service.impl;

import java.time.LocalDate;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import cn.homeledger.common.AuthContext;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.entity.RecurringRule;
import cn.homeledger.mapper.RecurringRuleMapper;
import cn.homeledger.service.RecurringGenerationService;
import cn.homeledger.service.RecurringRuleExecutor;

/**
 * §4.2.3 定时任务的入口：把「今天」摊给每一条启用规则。
 * <p>
 * 本类<b>不能</b>标 {@code @Transactional}。它跨家庭、跨规则，包成一个大事务等于把
 * 「一条规则失败不影响其他」这条设计直接废掉，而且整个扫描期间会一直占着一条数据库连接。
 */
@Service
public class RecurringGenerationServiceImpl implements RecurringGenerationService {

	private static final Logger log = LoggerFactory.getLogger(RecurringGenerationServiceImpl.class);

	private final RecurringRuleMapper ruleMapper;

	private final RecurringRuleExecutor executor;

	public RecurringGenerationServiceImpl(RecurringRuleMapper ruleMapper, RecurringRuleExecutor executor) {
		this.ruleMapper = ruleMapper;
		this.executor = executor;
	}

	@Override
	public int runFor(LocalDate today) {
		List<RecurringRule> rules = this.ruleMapper.selectAllEnabledRules(today);
		int generated = 0;
		Long currentFamilyId = null;
		AuthContext previous = AuthContextHolder.get();
		try {
			for (RecurringRule rule : rules) {
				// 扫描结果按 family_id 有序，所以每个家庭只切一次上下文而不是每条规则一次
				if (!rule.getFamilyId().equals(currentFamilyId)) {
					currentFamilyId = rule.getFamilyId();
					AuthContextHolder.set(memberContext(rule, currentFamilyId));
				}
				try {
					generated += this.executor.execute(rule, today);
				}
				catch (Exception e) {
					// 一条规则失败只丢它自己那份（execute 上有独立事务，已经回滚），其余照常。
					// 这里不重抛：定时任务没有人看着，重抛只会让当天剩下的规则全部不执行
					log.error("周期记账规则执行失败 ruleId={} familyId={} bizDate={}", rule.getId(), rule.getFamilyId(),
							today, e);
				}
			}
		}
		finally {
			restore(previous);
		}
		return generated;
	}

	@Override
	public int runForRule(RecurringRule rule, LocalDate today) {
		AuthContext previous = AuthContextHolder.get();
		AuthContextHolder.set(memberContext(rule, rule.getFamilyId()));
		try {
			return this.executor.execute(rule, today);
		}
		finally {
			restore(previous);
		}
	}

	/**
	 * 以「建这条规则的人」的身份进这个家庭。
	 * <p>
	 * role 给 MEMBER 是取最小值：这个字段只在 {@code UserServiceImpl#me} 的出参里被读，引擎这一路的权限判定
	 * 全靠 familyId 过租户拦截器，不需要也不该带着 OWNER 在后台线程里走。
	 */
	private static AuthContext memberContext(RecurringRule rule, Long familyId) {
		return new AuthContext(rule.getCreatedBy(), familyId, AuthContext.ROLE_MEMBER);
	}

	private static void restore(AuthContext previous) {
		// 定时任务的线程是复用的，漏了恢复会让下一个任务带着上一个家庭的身份跑
		if (previous == null) {
			AuthContextHolder.clear();
		}
		else {
			AuthContextHolder.set(previous);
		}
	}

}
