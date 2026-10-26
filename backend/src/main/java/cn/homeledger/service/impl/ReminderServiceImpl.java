package cn.homeledger.service.impl;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BabyAge;
import cn.homeledger.common.BizException;
import cn.homeledger.common.DewormingType;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.ReminderType;
import cn.homeledger.dto.ReminderSettingSaveRequest;
import cn.homeledger.entity.ReminderSetting;
import cn.homeledger.mapper.ReminderSettingMapper;
import cn.homeledger.service.BabyService;
import cn.homeledger.service.BabyStatisticsService;
import cn.homeledger.service.BabyFormulaBagService;
import cn.homeledger.service.BudgetService;
import cn.homeledger.service.CatFoodBagService;
import cn.homeledger.service.CatStatisticsService;
import cn.homeledger.service.ReminderService;
import cn.homeledger.vo.BabyFormulaEstimateResponse;
import cn.homeledger.vo.BabyGrowthStatisticsResponse.BabyGrowthItem;
import cn.homeledger.vo.BabyResponse;
import cn.homeledger.vo.BabyVaccineStatisticsResponse.BabyVaccineItem;
import cn.homeledger.vo.BabyVaccineStatisticsResponse.BabyVaccinePlanItem;
import cn.homeledger.vo.BudgetProgressResponse;
import cn.homeledger.vo.CatDueCountdownItem;
import cn.homeledger.vo.CatFoodEstimateResponse;
import cn.homeledger.vo.PendingReminderResponse;
import cn.homeledger.vo.ReminderSettingResponse;

/**
 * §4.5.1 的八类提醒的产出：预算两类（S4）+ 猫咪三类（S6）+ 疫苗一类（S7）+ 成长记录待补（S8）+
 * 奶粉见底（第 32 轮）。
 * <p>
 * 本类不自己算预算进度，而是调 {@link BudgetService#progress}。这是刻意的依赖——一个家庭这个月花了多少、
 * 算不算超支，只能有一处定义；在这里重算一遍，将来预算口径一改就会变成「设置页说超支、首页红点说不超支」。
 * <p>
 * 猫粮余量与驱虫倒计时同理走 {@link CatStatisticsService} 与 {@link CatFoodBagService}，奶粉走
 * {@link BabyFormulaBagService}，疫苗与成长记录走 {@link BabyStatisticsService}，本类一律不重算：
 * 各侧调用方共用一个 {@code common/ConsumptionEstimate} 才让「总览页说还能吃 4 天、通知里说明天耗尽」不可能发生（§6.4.1）。
 * <p>
 * 有到期日的两类（驱虫、疫苗）还要回答「什么时候弹」：§4.5.1 的提前量是<b>触发日</b>（提前 N 天、当天、
 * 逾期后每 3 天），落在未来那一个上就写进 {@code fireAt}，由客户端定时。今天正好是触发日时给空值——
 * 那件事此刻已经成立，让客户端立即弹比让它排到十分钟后合理。
 */
@Service
public class ReminderServiceImpl implements ReminderService {

	/** 三类预算维度共用一个落点：S4 不做「跳到该类别的流水筛选」，那是 S5 的事。 */
	private static final String BUDGET_ROUTE = "/finance/budgets";

	/** 驱虫提醒的落点。猫咪列表与记录页共用这一条：待提醒要回答的是「去做驱虫」，不是「去看某只猫」。 */
	private static final String DEWORMING_ROUTE = "/cat/dewormings";

	private static final String FOOD_ROUTE = "/cat/food-bags";

	/** 奶粉见底的落点：奶粉罐列表页就是「去开新罐」的地方（§4.5.3）。 */
	private static final String FORMULA_ROUTE = "/baby/formulas";

	/** 疫苗接种提醒的落点。应种清单是「去做这一针」的唯一落点，疫苗统计页只回答「打了多少」。 */
	private static final String VACCINE_ROUTE = "/baby/vaccines";

	/** 成长记录待补的落点。身高体重列表页就是「去补一条」的地方，曲线页只回答「长得怎么样」。 */
	private static final String GROWTH_ROUTE = "/baby/growths";

	/** §4.5.1 写死的提前量。驱虫与猫粮共用这一个数字，两处语义无关但值相同，所以只有这一个常量。 */
	private static final int LEAD_DAYS = 3;

	/**
	 * 疫苗的提前量比猫多几天：接种有档期与请假成本，提前 3 天才说就来不及约了。
	 * 与 {@code upcoming} 端点的 14 天窗口也不是一回事——那是给人看的清单，这是红点。
	 */
	private static final int BABY_LEAD_DAYS = 7;

	/** 「逾期后每 3 天」的频次：驱虫与疫苗的上限表里是同一个数，只留一个常量。 */
	private static final int OVERDUE_REPEAT_DAYS = 3;

	/**
	 * 「三天内」紧急度桶的阈值（§4.6 第 4 条）。与 {@link #OVERDUE_REPEAT_DAYS} 只是恰好等值：
	 * 那是逾期后的重复频次，这是未到期项的分桶边界，两者各自演化，不能共用。
	 */
	private static final int URGENT_WITHIN_DAYS = 3;

	/**
	 * 定时提醒落在几点。这个钟点只用于<b>未来</b>那一天（{@code fireAt} 非空时）；今天就是触发日时给空值，
	 * 客户端立即弹。取上午而不是 0 点：半夜弹一条「该驱虫了」会把人吵醒，而 0 点也正是「今天」刚刚开始的那一刻，
	 * 用户前一天晚上看 App 时这条提醒还没出现。
	 */
	private static final int FIRE_HOUR = 9;

	/** 成长记录待补的提前量：距上次记录满 30 天才提（§4.5.1）。 */
	private static final int GROWTH_LEAD_DAYS = 30;

	/**
	 * 成长记录待补的复提节奏：第 30 天起每 15 天一次。
	 * 这就是 §4.5.1 那一列的「每月 ≤ 2 次」——一个 30 天的节奏里恰好落两次（第 30 天与第 45 天），
	 * 而这类提醒不发系统通知，除了进不进这份列表之外没有别的地方能承载这个上限。
	 */
	private static final int GROWTH_REPEAT_DAYS = 15;

	/** 成长记录待补只对 0–3 岁的宝宝启用（§4.5.1）：未满 3 周岁即月龄 &lt; 36，与头围表的止界同一个月龄口径。 */
	private static final int GROWTH_MAX_MONTHS = 36;

	private static final Logger log = LoggerFactory.getLogger(ReminderServiceImpl.class);

	private final ReminderSettingMapper reminderSettingMapper;

	private final BudgetService budgetService;

	private final CatStatisticsService catStatisticsService;

	private final CatFoodBagService catFoodBagService;

	private final BabyFormulaBagService babyFormulaBagService;

	private final BabyStatisticsService babyStatisticsService;

	private final BabyService babyService;

	private final Clock clock;

	public ReminderServiceImpl(ReminderSettingMapper reminderSettingMapper, BudgetService budgetService,
			CatStatisticsService catStatisticsService, CatFoodBagService catFoodBagService,
			BabyFormulaBagService babyFormulaBagService, BabyStatisticsService babyStatisticsService,
			BabyService babyService, Clock clock) {
		this.reminderSettingMapper = reminderSettingMapper;
		this.budgetService = budgetService;
		this.catStatisticsService = catStatisticsService;
		this.catFoodBagService = catFoodBagService;
		this.babyFormulaBagService = babyFormulaBagService;
		this.babyStatisticsService = babyStatisticsService;
		this.babyService = babyService;
		this.clock = clock;
	}

	@Override
	public List<ReminderSettingResponse> settings(Long userId) {
		Map<String, Boolean> stored = storedSwitches(userId);
		return Arrays.stream(ReminderType.values())
			.map(type -> new ReminderSettingResponse(type.name(), type.label(),
					stored.getOrDefault(type.name(), type.defaultEnabled()), type.pushed()))
			.toList();
	}

	@Override
	@Transactional
	public void saveSettings(Long userId, ReminderSettingSaveRequest request) {
		Map<String, ReminderSetting> rows = this.reminderSettingMapper.selectByUser(userId)
			.stream()
			.collect(Collectors.toMap(ReminderSetting::getType, row -> row));
		Set<String> seen = new HashSet<>();
		for (ReminderSettingSaveRequest.Item item : request.items()) {
			if (ReminderType.of(item.type()) == null) {
				throw new BizException(ErrorCode.BAD_REQUEST, "不认识的提醒类型：" + item.type());
			}
			// 请求内去重不能省：唯一索引挡不住同一事务里的两行，那时用户看到的是一条 500
			if (!seen.add(item.type())) {
				throw new BizException(ErrorCode.REMINDER_SETTING_DUPLICATED);
			}
			ReminderSetting row = rows.get(item.type());
			if (row == null) {
				ReminderSetting setting = new ReminderSetting();
				setting.setUserId(userId);
				setting.setType(item.type());
				setting.setEnabled(item.enabled() ? 1 : 0);
				this.reminderSettingMapper.insert(setting);
				continue;
			}
			// 只带 id 与 enabled 去更新，不复用查出来的那行：实体里的 created_at / updated_at 一旦非空，
			// updateById 会把旧值原样写回去，updated_at 的 ON UPDATE CURRENT_TIMESTAMP 也就不会触发了
			ReminderSetting patch = new ReminderSetting();
			patch.setId(row.getId());
			patch.setEnabled(item.enabled() ? 1 : 0);
			this.reminderSettingMapper.updateById(patch);
		}
		log.info("保存提醒开关 userId={} count={}", userId, request.items().size());
	}

	// 四段共用 enabled 一次查询的结果。留下这四个平铺的调用而不是抽 Producer 接口：四段各自的数据源与筛选
	// 都不一样，抽出来只是把四个 if 换成四个实现类，读的人还要跳一次文件。
	@Override
	public List<PendingReminderResponse> pending(Long userId) {
		if (!AuthContextHolder.require().hasFamily()) {
			return List.of();
		}
		Set<ReminderType> enabled = enabledTypes(userId);
		List<Ranked> reminders = new ArrayList<>(budgetReminders(enabled));
		reminders.addAll(catReminders(enabled));
		reminders.addAll(formulaReminders(enabled));
		reminders.addAll(babyReminders(enabled));
		reminders.addAll(growthReminders(enabled));
		// 返回顺序即紧急度顺序（§4.6 第 4 条）：首页的待办卡片区直接铺这一份，不必自己再排一次。
		// List.sort 是稳定排序，所以同桶同紧迫度之间保持上面那五段的先后（预算 → 猫 → 奶粉 → 疫苗 → 成长）
		reminders.sort(Comparator.comparingInt(Ranked::bucket).thenComparingLong(Ranked::urgency));
		return reminders.stream().map(Ranked::row).toList();
	}

	/**
	 * 一条待提醒在紧急度上的位置。
	 *
	 * @param bucket 0 已逾期或已成立、1 三天内、2 十四天内、3 其余状态类（§4.6 第 4 条那三档，外加兜底的一档）
	 * @param urgency 同桶内的次级键，越小越前：逾期类取负的逾期天数（欠得越久越靠前），临期类取剩余天数
	 */
	private record Ranked(int bucket, long urgency, PendingReminderResponse row) {

	}

	/** 逾期：桶 0，欠得越久越靠前。 */
	private static Ranked overdue(long days, PendingReminderResponse row) {
		return new Ranked(0, -days, row);
	}

	/** 已成立但没有「欠了几天」的事实（预算超支）。与逾期的同桶，排在它们之后。 */
	private static Ranked settled(PendingReminderResponse row) {
		return new Ranked(0, 0, row);
	}

	/** 有到期日的：3 天内进桶 1，更远的（只有疫苗能到 14 天）进桶 2。 */
	private static Ranked dueWithin(long days, PendingReminderResponse row) {
		return new Ranked(days <= URGENT_WITHIN_DAYS ? 1 : 2, days, row);
	}

	/** 状态类：预算预警、成长记录待补。它们不催人，压在最后。 */
	private static Ranked stateful(PendingReminderResponse row) {
		return new Ranked(3, 0, row);
	}

	private List<Ranked> budgetReminders(Set<ReminderType> enabled) {
		// 从 pending() 搬下来的预算专用短路：条件一字未改，搬走的理由是它只管预算这一段
		if (!enabled.contains(ReminderType.BUDGET_OVERRUN) && !enabled.contains(ReminderType.BUDGET_WARNING)) {
			return List.of();
		}
		List<Ranked> reminders = new ArrayList<>();
		for (BudgetProgressResponse budget : this.budgetService.progress(null)) {
			ReminderType type = switch (budget.level()) {
			// 两档互斥：同时产出会让用户为一个事实收到红点和通知各一份，而「已超支」显然比「即将超支」更该被看到
			case EXCEEDED -> ReminderType.BUDGET_OVERRUN;
			case WARNING -> ReminderType.BUDGET_WARNING;
			case NORMAL -> null;
			};
			if (type == null || !enabled.contains(type)) {
				continue;
			}
			PendingReminderResponse row = new PendingReminderResponse(type.name(), type.module().name(),
					keyOf(type, budget), "本月" + type.label(), bodyOf(type, budget), BUDGET_ROUTE, null, null);
			// 超支是已经成立的事实，进「逾期/已成立」那一桶；80% 预警还只是趋势，压在状态类里
			reminders.add(type == ReminderType.BUDGET_OVERRUN ? settled(row) : stateful(row));
		}
		return reminders;
	}

	/**
	 * 三类猫提醒。驱虫读 dueCountdown（全 App 倒计时唯一来源，第 23 轮 (c)）而不是读记录表：
	 * 一个「猫 × 类型」恰好一条，键因此天然唯一。按记录遍历会让一只拖了三次外驱的猫产出三条
	 * CAT_DEWORMING_EXTERNAL:CAT:1——同一天、同一句文案、同一个 key，前端按 key 去重后只剩一条，
	 * 而服务端白算三遍。
	 */
	private List<Ranked> catReminders(Set<ReminderType> enabled) {
		List<Ranked> reminders = new ArrayList<>();
		LocalDate today = LocalDate.now(this.clock);
		if (enabled.contains(ReminderType.CAT_DEWORMING_INTERNAL)
				|| enabled.contains(ReminderType.CAT_DEWORMING_EXTERNAL)) {
			for (CatDueCountdownItem item : this.catStatisticsService.deworming().dueCountdown()) {
				DewormingType type = DewormingType.of(item.type());
				if (type == null || !enabled.contains(type.reminderType())) {
					continue;
				}
				// 两列互斥（§4.3.3 的逾期判定）：不先判 null 就比大小会在逾期行上拆箱出 NPE
				boolean due = item.overdueDays() != null
						|| (item.daysToDue() != null && item.daysToDue() <= LEAD_DAYS);
				if (!due) {
					continue;
				}
				reminders.add(dewormingReminder(item, type, today));
			}
		}
		if (enabled.contains(ReminderType.CAT_FOOD_LOW)) {
			// estimate 为 null 有两种：一袋都没有、开了袋但推不出。两种都不发提醒——
			// 「还没开始喂猫粮」不是一件待处理的事，而「推不出」的那句提示属于总览页空态，不属于红点
			CatFoodEstimateResponse estimate = this.catFoodBagService.current().estimate();
			if (estimate != null && (estimate.remainingGrams() == 0 || estimate.daysLeft() <= LEAD_DAYS)) {
				PendingReminderResponse row = new PendingReminderResponse(ReminderType.CAT_FOOD_LOW.name(),
						ReminderType.CAT_FOOD_LOW.module().name(), ReminderType.CAT_FOOD_LOW.name() + ":FAMILY",
						ReminderType.CAT_FOOD_LOW.label(), foodLowBody(estimate), FOOD_ROUTE, null, null);
				// 触底是已经成立的事实，进「逾期/已成立」那一桶；还差几天才见底的按剩余天数排在三天内那一桶
				reminders.add(estimate.remainingGrams() == 0 ? settled(row) : dueWithin(estimate.daysLeft(), row));
			}
		}
		return reminders;
	}

	/**
	 * 驱虫那一条。定时信息由 {@code nextDate}（全 App 倒计时唯一来源）算出，不另取一个到期日：
	 * 倒计时列表说「还有 2 天」而通知排在后天，是没有第二处实现能造成的矛盾。
	 */
	private static Ranked dewormingReminder(CatDueCountdownItem item, DewormingType type, LocalDate today) {
		ReminderType reminder = type.reminderType();
		LocalDateTime fireAt = nextFireAt(item.nextDate(), LEAD_DAYS, today);
		PendingReminderResponse row = new PendingReminderResponse(reminder.name(), reminder.module().name(),
				reminder.name() + ":CAT:" + item.catId(), reminder.label(), dewormingBody(item, type),
				DEWORMING_ROUTE, fireAt, fireAt == null ? null : fireAt.toLocalDate());
		return item.overdueDays() != null ? overdue(item.overdueDays(), row) : dueWithin(item.daysToDue(), row);
	}

	/**
	 * 疫苗提醒。数据源是疫苗统计的 {@code upcoming} 与 {@code overdueList} 两张小列表，不另写查询：
	 * 「哪一针该提醒」只有一处实现，统计页说「逾期 2 针」而红点只出一条这种事就不可能发生。
	 * <p>
	 * 逐条产出而不是按宝宝聚合：三个宝宝各欠一针是三件事，聚成一条「有 3 针待接种」用户点进去还得自己找。
	 */
	private List<Ranked> babyReminders(Set<ReminderType> enabled) {
		if (!enabled.contains(ReminderType.VACCINE_UPCOMING)) {
			return List.of();
		}
		List<Ranked> reminders = new ArrayList<>();
		LocalDate today = LocalDate.now(this.clock);
		for (BabyVaccineItem baby : this.babyStatisticsService.vaccine(null).perBaby()) {
			for (BabyVaccinePlanItem plan : baby.upcoming()) {
				if (plan.daysToDue() == null || plan.daysToDue() > BABY_LEAD_DAYS) {
					continue;
				}
				reminders.add(vaccineReminder(baby, plan, today));
			}
			// 逾期全取，不再按天筛：已经欠下的账不该等到某个提前量才说
			for (BabyVaccinePlanItem plan : baby.overdueList()) {
				reminders.add(vaccineReminder(baby, plan, today));
			}
		}
		return reminders;
	}

	private static Ranked vaccineReminder(BabyVaccineItem baby, BabyVaccinePlanItem plan, LocalDate today) {
		LocalDateTime fireAt = nextFireAt(plan.dueDate(), BABY_LEAD_DAYS, today);
		PendingReminderResponse row = new PendingReminderResponse(ReminderType.VACCINE_UPCOMING.name(),
				ReminderType.VACCINE_UPCOMING.module().name(), vaccineKey(plan),
				ReminderType.VACCINE_UPCOMING.label(), vaccineBody(baby, plan), VACCINE_ROUTE, fireAt,
				fireAt == null ? null : fireAt.toLocalDate());
		return plan.overdueDays() != null ? overdue(plan.overdueDays(), row) : dueWithin(plan.daysToDue(), row);
	}

	/**
	 * 成长记录待补（§4.5.1 的第七类）。上次记录取身高体重列表里最新那一条，一次都没有时取出生日期——
	 * 不给出生的宝宝起算，这条提醒对新家庭永远不会出现，而「还没量过」正是最该被提一次的情形。
	 * <p>
	 * 数据源是两条既有查询的交叉：在册宝宝从 {@link BabyService#list}（归档的不催），最新测量日从
	 * {@link BabyStatisticsService#growth}（体格数据的唯一来源，本类不另写一条「最新一条是哪天」的 SQL）。
	 * 两次调用都是小结果集，且统计那条带缓存。
	 * <p>
	 * 只数在册宝宝还有一层含义：§4.4.1 的归档是「不再参与新记录」，催一个已经归档的宝宝补录身高体重
	 * 与那句语义相反。
	 */
	private List<Ranked> growthReminders(Set<ReminderType> enabled) {
		if (!enabled.contains(ReminderType.GROWTH_RECORD_DUE)) {
			return List.of();
		}
		LocalDate today = LocalDate.now(this.clock);
		Map<Long, LocalDate> latest = latestMeasureDates();
		List<Ranked> reminders = new ArrayList<>();
		for (BabyResponse baby : this.babyService.list(false)) {
			if (BabyAge.monthsBetween(baby.birthDate(), today) >= GROWTH_MAX_MONTHS) {
				continue;
			}
			LocalDate last = latest.getOrDefault(baby.id(), baby.birthDate());
			long days = ChronoUnit.DAYS.between(last, today);
			if (days < GROWTH_LEAD_DAYS || (days - GROWTH_LEAD_DAYS) % GROWTH_REPEAT_DAYS != 0) {
				continue;
			}
			reminders.add(stateful(new PendingReminderResponse(ReminderType.GROWTH_RECORD_DUE.name(),
					ReminderType.GROWTH_RECORD_DUE.module().name(),
					ReminderType.GROWTH_RECORD_DUE.name() + ":BABY:" + baby.id(),
					ReminderType.GROWTH_RECORD_DUE.label(), growthBody(baby.name(), days), GROWTH_ROUTE, null, null)));
		}
		return reminders;
	}

	/** 每个宝宝最新那一天的测量日期。一次都没有记录的宝宝不在表里，调用方回落到出生日期。 */
	private Map<Long, LocalDate> latestMeasureDates() {
		Map<Long, LocalDate> latest = new HashMap<>();
		for (BabyGrowthItem item : this.babyStatisticsService.growth(null).perBaby()) {
			if (item.latest() != null) {
				latest.put(item.babyId(), item.latest().measureDate());
			}
		}
		return latest;
	}

	/**
	 * 下一次该弹通知的时刻。
	 * <p>
	 * 触发日来自 §4.5.1 那一列「提前 N 天、当天、逾期后每 3 天」：到期日 D 的触发日是
	 * {@code D−N}、{@code D}、{@code D+3}、{@code D+6}……今天正好是其中一个时回 {@code null}
	 * （那件事此刻已经成立，交给客户端立即弹），否则回下一个触发日的 {@link #FIRE_HOUR} 点。
	 * <p>
	 * 这里刻意不回「最近一个已经过去的触发日 + 一天」那种近似值：定时通知排在过去会当场弹出，
	 * 而它要回答的是「从现在起还会不会有通知、什么时候有」。
	 */
	private static LocalDateTime nextFireAt(LocalDate dueDate, int leadDays, LocalDate today) {
		if (isTriggerDay(dueDate, leadDays, today)) {
			return null;
		}
		return nextTriggerDate(dueDate, today).atTime(FIRE_HOUR, 0);
	}

	private static boolean isTriggerDay(LocalDate dueDate, int leadDays, LocalDate today) {
		if (today.isBefore(dueDate)) {
			return today.equals(dueDate.minusDays(leadDays));
		}
		return ChronoUnit.DAYS.between(dueDate, today) % OVERDUE_REPEAT_DAYS == 0;
	}

	/**
	 * 今天之后的第一个触发日。未到期时是到期日当天（提前量那一个已经过去或还没到都不会走到这里：
	 * 没到的那些行根本不在 {@code pending} 里），已逾期时是「当前 3 天周期的下一个整点」。
	 * <p>
	 * 这里不需要 {@code leadDays}：提前量只在「今天是不是触发日」里起作用（{@link #isTriggerDay}），
	 * 未到期的下一次触发恒为到期日本身。签名刻意不与 {@code isTriggerDay} 对齐，免得读出「排程也受提前量影响」的误会。
	 */
	private static LocalDate nextTriggerDate(LocalDate dueDate, LocalDate today) {
		if (today.isBefore(dueDate)) {
			return dueDate;
		}
		long overdue = ChronoUnit.DAYS.between(dueDate, today);
		return dueDate.plusDays((overdue / OVERDUE_REPEAT_DAYS + 1) * OVERDUE_REPEAT_DAYS);
	}

	/** 键落在剂次上而不是宝宝上：宝宝身上同时欠两针时，前端按 key 去重不该把其中一条吞掉。 */
	private static String vaccineKey(BabyVaccinePlanItem plan) {
		return ReminderType.VACCINE_UPCOMING.name() + ":PLAN:" + plan.planId();
	}

	/** 「小满的麻腮风疫苗第 1 剂还有 5 天」。0 天单给一句，与 {@link #dewormingBody} 同一个理由。 */
	private static String vaccineBody(BabyVaccineItem baby, BabyVaccinePlanItem plan) {
		String subject = baby.name() + "的" + plan.vaccineName() + "第 " + plan.doseNo() + " 剂";
		if (plan.overdueDays() != null) {
			return subject + "已逾期 " + plan.overdueDays() + " 天";
		}
		return plan.daysToDue() == 0L ? subject + "今天应接种" : subject + "还有 " + plan.daysToDue() + " 天";
	}

	/** 「咪咪的外驱还有 3 天」。0 天单给一句：通知里写「还有 0 天」是要挨骂的。 */
	private static String dewormingBody(CatDueCountdownItem item, DewormingType type) {
		String subject = item.catName() + "的" + type.label();
		if (item.overdueDays() != null) {
			return subject + "已逾期 " + item.overdueDays() + " 天";
		}
		return item.daysToDue() == 0L ? subject + "今天到期" : subject + "还有 " + item.daysToDue() + " 天";
	}

	/** 触底那句是 §4.3.4 的逐字文案，改成「猫粮不多了」这类同义说法就算走偏。 */
	private static String foodLowBody(CatFoodEstimateResponse estimate) {
		if (estimate.remainingGrams() == 0) {
			return "已超出预计用量，请确认是否已开新袋";
		}
		return "剩余约 " + estimate.remainingGrams() + " g，"
				+ (estimate.daysLeft() == 0 ? "预计今天耗尽" : "预计还能吃 " + estimate.daysLeft() + " 天");
	}

	/**
	 * 奶粉见底，与 {@code CAT_FOOD_LOW} 同一类「此刻状态」提醒（§4.5.3）：estimate 为 null 有两种——
	 * 一罐都还没开、开了罐但推不出。两种都不发提醒——「还没开始喂奶粉」不是一件待处理的事，而
	 * 「推不出」的那句提示属于奶粉卡空态，不属于红点。
	 */
	private List<Ranked> formulaReminders(Set<ReminderType> enabled) {
		if (!enabled.contains(ReminderType.BABY_FORMULA_LOW)) {
			return List.of();
		}
		BabyFormulaEstimateResponse estimate = this.babyFormulaBagService.current().estimate();
		if (estimate == null || (estimate.remainingGrams() != 0 && estimate.daysLeft() > LEAD_DAYS)) {
			return List.of();
		}
		PendingReminderResponse row = new PendingReminderResponse(ReminderType.BABY_FORMULA_LOW.name(),
				ReminderType.BABY_FORMULA_LOW.module().name(), ReminderType.BABY_FORMULA_LOW.name() + ":FAMILY",
				ReminderType.BABY_FORMULA_LOW.label(), formulaLowBody(estimate), FORMULA_ROUTE, null, null);
		// 触底是已经成立的事实，进「逾期/已成立」那一桶；还差几天才见底的按剩余天数排在三天内那一桶
		return List.of(estimate.remainingGrams() == 0 ? settled(row) : dueWithin(estimate.daysLeft(), row));
	}

	/** 奶粉见底那句与猫粮同构逐字，只是单位与动作换成「罐」。 */
	private static String formulaLowBody(BabyFormulaEstimateResponse estimate) {
		if (estimate.remainingGrams() == 0) {
			return "已超出预计用量，请确认是否已开新罐";
		}
		return "剩余约 " + estimate.remainingGrams() + " g，"
				+ (estimate.daysLeft() == 0 ? "预计今天耗尽" : "预计还能喝 " + estimate.daysLeft() + " 天");
	}

	/**
	 * 「小满已经 34 天没有记录身高体重了」。写成陈述而不是命令句：这条提醒不发通知、只进 App 内的红点，
	 * 而它要回答的是「为什么又亮了」，不是「你现在必须去量一下」。
	 */
	private static String growthBody(String name, long days) {
		return name + "已经 " + days + " 天没有记录身高体重了";
	}

	/**
	 * 去重键里不带月份：跨月时昨天那条与今天这条会被当成两件事，前端的「今天已经提醒过」就失效了，
	 * 通知栏里会同时挂着 8 月和 9 月的超支提醒。
	 */
	private static String keyOf(ReminderType type, BudgetProgressResponse budget) {
		return switch (budget.scope()) {
		case "FAMILY" -> type.name() + ":FAMILY";
		case "CATEGORY" -> type.name() + ":C:" + budget.categoryId();
		case "MEMBER" -> type.name() + ":M:" + budget.memberUserId();
		default -> throw new BizException(ErrorCode.BAD_REQUEST, "预算行的维度不认识：" + budget.scope());
		};
	}

	private static String subjectOf(BudgetProgressResponse budget) {
		return switch (budget.scope()) {
		case "CATEGORY" -> budget.categoryName();
		case "MEMBER" -> budget.memberName();
		default -> "全家";
		};
	}

	/** 金额用 toPlainString 原样带上，不加千分位——那是显示层的事，这里加了前端就没法按自己的规则再格式化一遍。 */
	private static String bodyOf(ReminderType type, BudgetProgressResponse budget) {
		String subject = subjectOf(budget);
		String used = subject + "已用 " + budget.used().toPlainString() + " 元，";
		if (type == ReminderType.BUDGET_WARNING) {
			return used + "还剩 " + budget.remaining().toPlainString() + " 元";
		}
		// 恰好花完额度时 remaining 是 0，「超出预算 0.00 元」读起来像程序算错了
		return budget.remaining().signum() == 0 ? used + "本月预算已用完"
				: used + "超出预算 " + budget.remaining().negate().toPlainString() + " 元";
	}

	private Set<ReminderType> enabledTypes(Long userId) {
		Map<String, Boolean> stored = storedSwitches(userId);
		return Arrays.stream(ReminderType.values())
			.filter(type -> stored.getOrDefault(type.name(), type.defaultEnabled()))
			.collect(Collectors.toUnmodifiableSet());
	}

	private Map<String, Boolean> storedSwitches(Long userId) {
		return this.reminderSettingMapper.selectByUser(userId)
			.stream()
			.collect(Collectors.toMap(ReminderSetting::getType, row -> row.getEnabled() == 1));
	}

}
