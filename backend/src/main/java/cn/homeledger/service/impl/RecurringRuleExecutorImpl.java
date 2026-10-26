package cn.homeledger.service.impl;

import java.time.LocalDate;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.FinanceDictionaryResolver;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.RecurringRuleCreateRequest;
import cn.homeledger.entity.RecurringExecutionLog;
import cn.homeledger.entity.RecurringRule;
import cn.homeledger.entity.Transaction;
import cn.homeledger.mapper.RecurringExecutionLogMapper;
import cn.homeledger.mapper.RecurringRuleMapper;
import cn.homeledger.mapper.TransactionMapper;
import cn.homeledger.service.RecurringRuleExecutor;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

/**
 * §4.2.3 周期记账的生成引擎，一次只管一条规则。
 */
@Service
public class RecurringRuleExecutorImpl implements RecurringRuleExecutor {

	/** 补记窗口的天数上限。7 天是产品口径而不是技术限制：它就是「服务停了一周以上，重启后只补最近一周」那句对用户说的话。 */
	private static final int BACKFILL_DAYS = 7;

	/** 与 {@code RecurringRuleServiceImpl#assertPeriod} 分派的是同一组值；库里出现第五种值说明数据被绕过接口改过。 */
	private static final String PERIOD_DAILY = "DAILY";

	private static final String PERIOD_WEEKLY = "WEEKLY";

	private static final String PERIOD_MONTHLY = "MONTHLY";

	private static final String PERIOD_YEARLY = "YEARLY";

	/** 补记出来的流水要标出自己是补的，否则用户翻到上个月会以为是自己哪天手记的。 */
	private static final String BACKFILL_REMARK = "（系统补记）";

	private final RecurringRuleMapper ruleMapper;

	private final RecurringExecutionLogMapper executionLogMapper;

	private final TransactionMapper transactionMapper;

	private final FinanceDictionaryResolver dictionaryResolver;

	private final ObjectMapper objectMapper;

	private final StatisticsCache statisticsCache;

	public RecurringRuleExecutorImpl(RecurringRuleMapper ruleMapper, RecurringExecutionLogMapper executionLogMapper,
			TransactionMapper transactionMapper, FinanceDictionaryResolver dictionaryResolver,
			ObjectMapper objectMapper, StatisticsCache statisticsCache) {
		this.ruleMapper = ruleMapper;
		this.executionLogMapper = executionLogMapper;
		this.transactionMapper = transactionMapper;
		this.dictionaryResolver = dictionaryResolver;
		this.objectMapper = objectMapper;
		this.statisticsCache = statisticsCache;
	}

	@Override
	@Transactional
	public int execute(RecurringRule rule, LocalDate today) {
		if (rule.getEndDate() != null && today.isAfter(rule.getEndDate())) {
			return 0;
		}
		LocalDate windowStart = windowStart(rule, today);
		if (windowStart.isAfter(today)) {
			return 0;
		}
		Schedule schedule = parse(rule);
		int generated = 0;
		LocalDate lastProcessed = windowStart.minusDays(1);
		for (LocalDate date = windowStart; !date.isAfter(today); date = date.plusDays(1)) {
			if (schedule.matches(date) && this.executionLogMapper.countByRuleAndDate(rule.getId(), date) == 0) {
				Transaction transaction = buildTransaction(rule, date, today);
				this.transactionMapper.insert(transaction);
				RecurringExecutionLog entry = new RecurringExecutionLog();
				entry.setFamilyId(rule.getFamilyId());
				entry.setRuleId(rule.getId());
				entry.setBizDate(date);
				entry.setTransactionId(transaction.getId());
				// 撞 uk_exec_rule_date 不在这里 catch。唯一索引是最后一道防线而不是常规控制流，
				// 撞上说明上面那句幂等判定本身出了 bug，让它冒到 runFor 的 per-rule catch 里去回滚并记 error，
				// 比静默跳过更早暴露问题
				this.executionLogMapper.insert(entry);
				generated++;
			}
			lastProcessed = date;
		}
		// 一次 execute 只 INCR 一次：停机一周后补记会一次生成 7 笔，7 次与 1 次效果相同
		if (generated > 0) {
			this.statisticsCache.invalidate(StatisticsCache.MODULE_FINANCE, rule.getFamilyId());
		}
		// 游标推到窗口末尾而不是 today：窗口末尾可能早于 today（end_date 已过），推过头会让规则永久跳过中间的日子
		this.ruleMapper.advanceProcessedDate(rule.getId(), lastProcessed);
		return generated;
	}

	/**
	 * 补记窗口的起点，三个下界取最大。
	 * <p>
	 * start_date 之前的日子不能补；today - 6 是那次「停机一个月后重启，一次性灌进一个月的流水」事故的上限；
	 * last_processed_date + 1 让暂停期间跨过的执行日不再补回来——这是 A4「当月立即生效」与「暂停一个月不要
	 * 一次性补出来」两条要求能同时成立的唯一办法。
	 */
	private LocalDate windowStart(RecurringRule rule, LocalDate today) {
		LocalDate floor = today.minusDays(BACKFILL_DAYS - 1);
		LocalDate start = rule.getStartDate();
		if (rule.getLastProcessedDate() != null) {
			LocalDate next = rule.getLastProcessedDate().plusDays(1);
			if (next.isAfter(start)) {
				start = next;
			}
		}
		return start.isAfter(floor) ? start : floor;
	}

	/**
	 * 周期参数每次 execute 解析一遍，不缓存。一次 JSON 反序列化的开销与它后面那几十次写入相比可以忽略，
	 * 而缓存会引出「规则改了但缓存没失效」这一整类问题。
	 */
	private Schedule parse(RecurringRule rule) {
		RecurringRuleCreateRequest.PeriodValue value;
		try {
			value = this.objectMapper.readValue(rule.getPeriodValue(), RecurringRuleCreateRequest.PeriodValue.class);
		}
		catch (JacksonException e) {
			throw new BizException(ErrorCode.PERIOD_VALUE_INVALID, "这条规则的周期参数在库里已经坏了，请删掉重建");
		}
		return new Schedule(rule.getPeriodType(), value.intervalDays(), value.weekdays(), value.daysOfMonth(),
				value.month(), rule.getStartDate());
	}

	/**
	 * 一笔自动生成的流水。名称快照取的是<b>生成这一刻</b>字典里的名字——流水记的是「它被记下来时那一项叫什么」，
	 * 这与手记一笔没有区别，所以规则上只存 id。
	 */
	private Transaction buildTransaction(RecurringRule rule, LocalDate bizDate, LocalDate today) {
		// 三个 mustBeUsable 全传 false：字典项在规则建成时已经验过可用，之后被停用只可能发生在规则也停用之后
		// （B8 拦住了「还有规则在用的字典项被停用」）。这里若要求可用，用户看到的会是
		// 「规则明明开着却每天不出流水，也没有任何提示」，那比记一笔已停用的类别更难查
		FinanceDictionaryResolver.Dictionary dict = this.dictionaryResolver.resolve(rule.getFamilyId(),
				rule.getCategoryId(), rule.getSubCategoryId(), rule.getAccountId(), false, false, false);
		Transaction transaction = new Transaction();
		transaction.setFamilyId(rule.getFamilyId());
		transaction.setType(rule.getType());
		transaction.setAmount(rule.getAmount());
		transaction.setCategoryId(rule.getCategoryId());
		transaction.setCategoryNameSnapshot(dict.category().getName());
		transaction.setSubCategoryId(rule.getSubCategoryId());
		transaction.setSubCategoryNameSnapshot(dict.subCategory() == null ? null : dict.subCategory().getName());
		transaction.setAccountId(rule.getAccountId());
		transaction.setAccountNameSnapshot(dict.account().getName());
		transaction.setBizDate(bizDate);
		transaction.setRemark(bizDate.isBefore(today) ? BACKFILL_REMARK : null);
		// A5：记录人是建规则的人，不是当天有没有人活着看到这条流水
		transaction.setCreatedBy(rule.getCreatedBy());
		transaction.setRecorderNameSnapshot(this.dictionaryResolver.nicknameOf(rule.getCreatedBy()));
		transaction.setRuleId(rule.getId());
		return transaction;
	}

	/**
	 * 一条规则的周期判据。四个字段里只有 periodType 点名的那几个有用，写入侧 {@code assertPeriod} 已经把过多余字段
	 * 拒掉了，所以这里直接取。
	 *
	 * @param anchor DAILY 的起算日，取规则的 start_date
	 */
	private record Schedule(String periodType, Integer intervalDays, List<Integer> weekdays,
			List<Integer> daysOfMonth, Integer month, LocalDate anchor) {

		boolean matches(LocalDate date) {
			return switch (this.periodType) {
			// 锚点必须是 start_date：用 toEpochDay() 直接取余等于以 1970-01-01 起算，
			// 用户设「每 3 天」时命中的日子跟他哪天建的规则无关，看着像随机
			case PERIOD_DAILY -> Math.floorMod(date.toEpochDay() - this.anchor.toEpochDay(),
					require(this.intervalDays, "intervalDays")) == 0;
			case PERIOD_WEEKLY -> require(this.weekdays, "weekdays").contains(date.getDayOfWeek().getValue());
			case PERIOD_MONTHLY -> hitsDayOfMonth(date, require(this.daysOfMonth, "daysOfMonth"));
			case PERIOD_YEARLY -> require(this.month, "month") == date.getMonthValue()
					&& hitsDayOfMonth(date, require(this.daysOfMonth, "daysOfMonth"));
			default -> throw new BizException(ErrorCode.PERIOD_VALUE_INVALID, "不支持的周期类型 " + this.periodType);
			};
		}

		/**
		 * 短月钳制：把规则里的每个「几号」按当月天数截断，截断后等于当天日期就算命中。
		 * <p>
		 * 明确不用另一种常见写法「规则日 &gt;= 当月天数且今天是最后一天则命中」：它在 {@code [28, 31]} + 平年 2 月
		 * 会生成两笔，因为 28 既按字面命中、又作为当月最后一天再命中一次。钳制把两个值映射到同一天，天然只有一笔。
		 * 这个差别只在 2 月暴露，而 2 月一年一次，写错了要等一年才发现。
		 */
		private static boolean hitsDayOfMonth(LocalDate date, List<Integer> daysOfMonth) {
			int lengthOfMonth = date.lengthOfMonth();
			return daysOfMonth.stream()
				.map(day -> Math.min(day, lengthOfMonth))
				.anyMatch(day -> day == date.getDayOfMonth());
		}

		private static <T> T require(T value, String field) {
			if (value == null) {
				throw new BizException(ErrorCode.PERIOD_VALUE_INVALID, "这条规则的周期参数缺了 " + field + "，请删掉重建");
			}
			return value;
		}

	}

}
