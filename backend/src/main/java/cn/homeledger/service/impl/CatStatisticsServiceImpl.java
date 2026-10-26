package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.DateRanges;
import cn.homeledger.common.DewormingType;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.CatFoodStatisticsRequest;
import cn.homeledger.entity.Cat;
import cn.homeledger.entity.CatDeworming;
import cn.homeledger.mapper.CatDewormingMapper;
import cn.homeledger.mapper.CatMapper;
import cn.homeledger.service.CatFoodBagService;
import cn.homeledger.service.CatFoodBagService.TimelineEntry;
import cn.homeledger.service.CatSettingService;
import cn.homeledger.service.CatStatisticsService;
import cn.homeledger.vo.CatBrandSlice;
import cn.homeledger.vo.CatDueCountdownItem;
import cn.homeledger.vo.CatDewormingCompletion;
import cn.homeledger.vo.CatDewormingStatisticsResponse;
import cn.homeledger.vo.CatDewormingTimelineItem;
import cn.homeledger.vo.CatFoodBagResponse;
import cn.homeledger.vo.CatFoodConsumptionResponse;
import cn.homeledger.vo.CatMonthGrams;
import cn.homeledger.vo.CatSettingResponse;

/**
 * §4.3.5 猫咪统计。
 * <p>
 * <b>这里一条聚合 SQL 都不写</b>：一个家庭最多 10 只猫、几十袋、几十条驱虫记录，全读进内存再分组比写五条
 * 聚合便宜不了多少，而 SQL 侧要重写一遍「均匀分摊」与「按月步进」的口径——那两份口径在 Java 里已经各有一份了，
 * 第二份只会长出第二个答案。
 * <p>
 * <b>不挂 {@code @Transactional}</b>（连只读都不挂），理由同 {@code StatisticsServiceImpl}：统计是某一时刻的
 * 近似，§5.1 已经用缓存 TTL 承认了这一点。驱虫那条尤其不能挂——待提醒项的判定要调它，那条路径上的事务注解
 * 会把一次提醒查询拖成长事务。
 */
@Service
public class CatStatisticsServiceImpl implements CatStatisticsService {

	/** 逐月趋势与驱虫窗口共用的那个「12 个自然月」（§4.3.5）。 */
	private static final int WINDOW_MONTHS = 12;

	private static final String ENDPOINT_FOOD = "cat-food-consumption";

	private static final String ENDPOINT_DEWORMING = "cat-deworming";

	/** 驱虫那条端点无入参，它的规范化条件就是空串。 */
	private static final String NO_CONDITIONS = "";

	private static final DateTimeFormatter MONTH_KEY = DateTimeFormatter.ofPattern("yyyy-MM");

	private final CatFoodBagService catFoodBagService;

	private final CatMapper catMapper;

	private final CatDewormingMapper catDewormingMapper;

	private final CatSettingService catSettingService;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public CatStatisticsServiceImpl(CatFoodBagService catFoodBagService, CatMapper catMapper,
			CatDewormingMapper catDewormingMapper, CatSettingService catSettingService, StatisticsCache statisticsCache,
			Clock clock) {
		this.catFoodBagService = catFoodBagService;
		this.catMapper = catMapper;
		this.catDewormingMapper = catDewormingMapper;
		this.catSettingService = catSettingService;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public CatFoodConsumptionResponse foodConsumption(CatFoodStatisticsRequest query) {
		Long familyId = currentFamilyId();
		DateRanges.assertRange(query.startDate(), query.endDate());
		CatFoodConsumptionResponse cached = this.statisticsCache.read(StatisticsCache.MODULE_CAT, ENDPOINT_FOOD,
				familyId, query.canonicalConditions(), CatFoodConsumptionResponse.class);
		if (cached != null) {
			return cached;
		}
		CatFoodConsumptionResponse response = buildFoodConsumption(query);
		this.statisticsCache.write(StatisticsCache.MODULE_CAT, ENDPOINT_FOOD, familyId, query.canonicalConditions(),
				response);
		return response;
	}

	@Override
	public CatDewormingStatisticsResponse deworming() {
		Long familyId = currentFamilyId();
		CatDewormingStatisticsResponse cached = this.statisticsCache.read(StatisticsCache.MODULE_CAT,
				ENDPOINT_DEWORMING, familyId, NO_CONDITIONS, CatDewormingStatisticsResponse.class);
		if (cached != null) {
			return cached;
		}
		CatDewormingStatisticsResponse response = buildDeworming(familyId);
		this.statisticsCache.write(StatisticsCache.MODULE_CAT, ENDPOINT_DEWORMING, familyId, NO_CONDITIONS, response);
		return response;
	}

	// ---- 消耗四块 ----

	private CatFoodConsumptionResponse buildFoodConsumption(CatFoodStatisticsRequest query) {
		List<TimelineEntry> entries = this.catFoodBagService.timeline();
		LocalDate today = LocalDate.now(this.clock);
		// 只截断分母：endDate 晚于今天时那几天根本没有消耗。克数侧不用截，分摊函数本来就只到今天
		LocalDate end = query.endDate() == null ? today : min(query.endDate(), today);
		LocalDate start;
		if (query.startDate() != null) {
			// 用户单边给的起点收 5 年地板，与记账统计同一口径（DateRanges.MAX_LOOKUP_YEARS）：
			// 无界起点会让 daysInclusive 溢出出荒谬的日均（扫描报告 P1-1）
			start = DateRanges.floorUserStart(query.startDate(), end);
		}
		else {
			start = entries.isEmpty() ? end : entries.get(0).startedDate();
		}
		// 只传一个晚于今天的 startDate 会让区间在截断之后倒挂，那时天数与克数都该是 0 而不是负数
		int days = Math.max(0, DateRanges.daysInclusive(start, end));
		int totalGrams = start.isAfter(end) ? 0 : gramsBetween(entries, start, end);
		List<CatFoodBagResponse> usages = entries.stream().filter(entry -> overlaps(entry, start, end))
			.map(CatFoodBagServiceImpl::toResponse)
			.toList();
		// 用完袋数只数已闭合的袋，且结束日要落在区间内（§4.3.5：当前袋不算，否则「用完 N 袋」在谁眼里都虚一格）
		int finishedBags = (int) entries.stream()
			.filter(entry -> !entry.current() && !entry.endDate().isBefore(start) && !entry.endDate().isAfter(end))
			.count();
		return new CatFoodConsumptionResponse(start, end, days, totalGrams, days == 0 ? 0 : round(totalGrams, days),
				finishedBags, brandBreakdown(entries, start, end, totalGrams), monthlyTrend(entries, today), usages);
	}

	private static List<CatBrandSlice> brandBreakdown(List<TimelineEntry> entries, LocalDate start, LocalDate end,
			int totalGrams) {
		if (totalGrams == 0) {
			return List.of();
		}
		// 按首次出现的顺序聚合，再按克数降序：sort 是稳定的，所以同克数的品牌保持开袋先后
		Map<String, Integer> gramsByBrand = new LinkedHashMap<>();
		for (TimelineEntry entry : entries) {
			int grams = consumedThrough(entry, end) - consumedThrough(entry, start.minusDays(1));
			if (grams > 0) {
				gramsByBrand.merge(entry.brand(), grams, Integer::sum);
			}
		}
		return gramsByBrand.entrySet()
			.stream()
			.map(item -> new CatBrandSlice(item.getKey(), item.getValue(),
					round(item.getValue() * 100L, totalGrams)))
			.sorted(Comparator.comparingInt(CatBrandSlice::grams).reversed())
			.toList();
	}

	/**
	 * 12 根柱子是<b>截至本月的近 12 个自然月</b>，与请求区间无关，每根对整个自然月作差、<b>不与区间求交</b>
	 * （§4.3.5「逐月消耗趋势同样固定近 12 个自然月、不随区间变化」）。求交之后用户选「本月」就得到 11 根零柱
	 * 加一根有值的柱子，而这张图要回答的是「食量随月份怎么变」。封顶由 usageDays 自己完成，不必区间再挡一次。
	 */
	private List<CatMonthGrams> monthlyTrend(List<TimelineEntry> entries, LocalDate today) {
		LocalDate from = today.withDayOfMonth(1).minusMonths(WINDOW_MONTHS - 1L);
		List<CatMonthGrams> trend = new ArrayList<>(WINDOW_MONTHS);
		for (int i = 0; i < WINDOW_MONTHS; i++) {
			LocalDate monthStart = from.plusMonths(i);
			LocalDate monthEnd = monthStart.plusMonths(1).minusDays(1);
			trend.add(new CatMonthGrams(monthStart.format(MONTH_KEY), gramsBetween(entries, monthStart, monthEnd)));
		}
		return trend;
	}

	private static int gramsBetween(List<TimelineEntry> entries, LocalDate from, LocalDate to) {
		int grams = 0;
		for (TimelineEntry entry : entries) {
			grams += consumedThrough(entry, to) - consumedThrough(entry, from.minusDays(1));
		}
		return grams;
	}

	/**
	 * 到 {@code through} 那天为止这一袋累计吃掉了多少克（§4.3.5 的均匀分摊）。
	 * <p>
	 * 一段区间的消耗写成 consumedThrough(末) − consumedThrough(首的前一天)，而不是「规格 × 区间内天数 ÷ 使用天数」
	 * 各自 floor 一次：前者是 telescoping 的，<b>逐月相加恒等于整段相加</b>，不会出现「12 根柱子的总和比概览卡
	 * 多 3 克」——那正是各段自己取整一次必然留下的毛刺，而概览卡的克数是用户会拿计算器核对的那个（验收用例 17）。
	 * <p>
	 * 使用天数 ≤ 0 的异常袋回 0：它既不该贡献克数也不该贡献柱子（§4.3.4 同一句）。乘除全程 long——
	 * 规格那一侧有 100000 克的上界，天数那一侧没有。
	 */
	private static int consumedThrough(TimelineEntry entry, LocalDate through) {
		if (entry.usageDays() <= 0L) {
			return 0;
		}
		long days = ChronoUnit.DAYS.between(entry.startedDate(), through) + 1L;
		long clamped = Math.min(Math.max(days, 0L), entry.usageDays());
		return (int) (entry.packGrams() * clamped / entry.usageDays());
	}

	/** 这一袋被吃掉的那几天与区间有交集。用完袋的最后一天是下一袋开始的前一天，用开始日 + 使用天数 − 1 表达。 */
	private static boolean overlaps(TimelineEntry entry, LocalDate start, LocalDate end) {
		LocalDate lastEatenDay = entry.startedDate().plusDays(entry.usageDays() - 1);
		return !entry.startedDate().isAfter(end) && !lastEatenDay.isBefore(start);
	}

	// ---- 驱虫三块 ----

	private CatDewormingStatisticsResponse buildDeworming(Long familyId) {
		LocalDate today = LocalDate.now(this.clock);
		// minusMonths(11) 只回卷到 11 个月前的同一天，withDayOfMonth(1) 才是整月（§4.3.5「近 12 个自然月」）
		LocalDate windowStart = today.minusMonths(WINDOW_MONTHS - 1L).withDayOfMonth(1);
		// 含归档的猫：时间轴要它的历史，完成度与倒计时在自己的循环里筛在册的
		List<Cat> cats = this.catMapper.selectList(new LambdaQueryWrapper<Cat>().eq(Cat::getFamilyId, familyId));
		List<CatDeworming> rows = this.catDewormingMapper
			.selectList(new LambdaQueryWrapper<CatDeworming>().eq(CatDeworming::getFamilyId, familyId));
		Map<Long, String> names = cats.stream().collect(Collectors.toMap(Cat::getId, Cat::getName));
		Map<String, List<CatDeworming>> byCatAndType = rows.stream()
			.collect(Collectors.groupingBy(row -> key(row.getCatId(), row.getType())));
		CatSettingResponse setting = this.catSettingService.get();
		return new CatDewormingStatisticsResponse(windowStart, today,
				completion(cats, byCatAndType, setting, windowStart, today),
				timeline(rows, names, windowStart), countdown(cats, byCatAndType, today));
	}

	/**
	 * 一只猫两行（内驱 / 外驱各一行），且<b>只算在册的猫</b>：这一块的产出是「接下来该给谁驱」，
	 * 归档猫占一格就成了一个永远做不完的任务（§4.3.5）。
	 * <p>
	 * 一条记录都没有的猫也出这一格：{@code due > 0} / {@code done = 0} 正是完成度视图最该说话的那个 case。
	 */
	private static List<CatDewormingCompletion> completion(List<Cat> cats,
			Map<String, List<CatDeworming>> byCatAndType, CatSettingResponse setting, LocalDate windowStart,
			LocalDate today) {
		List<CatDewormingCompletion> rows = new ArrayList<>();
		for (Cat cat : cats) {
			if (!isActive(cat)) {
				continue;
			}
			for (DewormingType type : DewormingType.values()) {
				List<CatDeworming> history = byCatAndType.getOrDefault(key(cat.getId(), type.name()), List.of());
				int months = type.monthsOf(setting.internalMonths(), setting.externalMonths());
				int due = dueTimes(originOf(cat), months, windowStart, today);
				int done = (int) history.stream()
					.filter(row -> !row.getDoneDate().isBefore(windowStart))
					.count();
				LocalDate nextDate = latestNextDate(history);
				rows.add(new CatDewormingCompletion(cat.getId(), cat.getName(), type.name(), due, done,
						rateOf(done, due), overdueDays(nextDate, today)));
			}
		}
		return rows;
	}

	private static boolean isActive(Cat cat) {
		return cat.getEnabled() != 0;
	}

	private static List<CatDewormingTimelineItem> timeline(List<CatDeworming> rows, Map<Long, String> names,
			LocalDate windowStart) {
		return rows.stream()
			.filter(row -> !row.getDoneDate().isBefore(windowStart))
			.map(row -> new CatDewormingTimelineItem(row.getCatId(), names.get(row.getCatId()), row.getType(),
					row.getDoneDate(), row.getMedicine()))
			// 倒序让「最近一次是什么时候」在屏幕顶上；同一天再按猫与类型定序，否则不给 ORDER BY 的返回顺序
			// 是实现细节，时间轴每次刷新可能换序
			.sorted(Comparator.comparing(CatDewormingTimelineItem::doneDate)
				.reversed()
				.thenComparing(CatDewormingTimelineItem::catId)
				.thenComparing(CatDewormingTimelineItem::type))
			.toList();
	}

	private static List<CatDueCountdownItem> countdown(List<Cat> cats, Map<String, List<CatDeworming>> byCatAndType,
			LocalDate today) {
		List<CatDueCountdownItem> items = new ArrayList<>();
		for (Cat cat : cats) {
			if (!isActive(cat)) {
				continue;
			}
			for (DewormingType type : DewormingType.values()) {
				LocalDate nextDate = latestNextDate(byCatAndType.getOrDefault(key(cat.getId(), type.name()), List.of()));
				if (nextDate == null) {
					// 没有下次日期的猫×类型不出现：它该出现在「该给它驱了」的引导位，而不是倒计时里的空白格
					continue;
				}
				items.add(new CatDueCountdownItem(cat.getId(), cat.getName(), type.name(), nextDate,
						daysToDue(nextDate, today), overdueDays(nextDate, today)));
			}
		}
		// 单键按下次日期升序：逾期置顶与「按紧急程度排」是同一件事，两个键反而解释不清「逾期 1 天」与「还有 1 天」谁在前
		items.sort(Comparator.comparing(CatDueCountdownItem::nextDate));
		return items;
	}

	/**
	 * 从起点按周期步进，数出落在窗口里的理论次数（§4.3.5 倒数第二条）。
	 * <p>
	 * 起点先快进到窗口内再开始计数：一只 2019 年建档、外驱周期 1 个月的猫，若从起点逐月走到窗口
	 * 要空转八十多次，而循环次数本就不该随建档年限增长。
	 * <p>
	 * periodMonths ≥ 1 是这里唯一的终止条件，它由设置接口的 {@code @Max(12)} 与 DDL 的 NOT NULL DEFAULT 共同保证。
	 * 不在此加防御性 clamp：校验只在边界挡一次，在这里再挡一遍等于承认注解不可信。
	 */
	private static int dueTimes(LocalDate origin, int periodMonths, LocalDate windowStart, LocalDate windowEnd) {
		LocalDate date = origin;
		while (date.isBefore(windowStart)) {
			date = date.plusMonths(periodMonths);
		}
		int due = 0;
		while (!date.isAfter(windowEnd)) {
			due++;
			date = date.plusMonths(periodMonths);
		}
		return due;
	}

	/**
	 * 起算日取建档日与生日里较晚的那个（§4.3.5 倒数第二条）。生日早于建档日是补录旧猫的常态，
	 * 那时窗口内的应做次数从「这只猫开始被记」算起；生日可以没有，那条没标必填。
	 */
	private static LocalDate originOf(Cat cat) {
		LocalDate registered = cat.getCreatedAt().toLocalDate();
		return cat.getBirthday() == null || cat.getBirthday().isBefore(registered) ? registered : cat.getBirthday();
	}

	/** 「下次驱虫日期」取最近那一次驱虫记下的那个值，而不是历史里的最大值：补录一条更早的记录不该把倒计时往后推。 */
	private static LocalDate latestNextDate(List<CatDeworming> history) {
		return history.stream()
			.max(Comparator.comparing(CatDeworming::getDoneDate).thenComparing(CatDeworming::getId))
			.map(CatDeworming::getNextDate)
			.orElse(null);
	}

	private static int rateOf(int done, int due) {
		return due == 0 ? 100 : Math.min(100, done * 100 / due);
	}

	private static Long overdueDays(LocalDate nextDate, LocalDate today) {
		return nextDate == null || !today.isAfter(nextDate) ? null : ChronoUnit.DAYS.between(nextDate, today);
	}

	private static Long daysToDue(LocalDate nextDate, LocalDate today) {
		return nextDate == null || today.isAfter(nextDate) ? null : ChronoUnit.DAYS.between(today, nextDate);
	}

	private static String key(Long catId, String type) {
		return catId + "|" + type;
	}

	/** 日均克数与品牌占比共用的一个取整：相除后 {@code HALF_UP} 到整数，乘 100 由占比那一侧的调用方自己做。 */
	private static int round(long numerator, long denominator) {
		return BigDecimal.valueOf(numerator).divide(BigDecimal.valueOf(denominator), 0, RoundingMode.HALF_UP).intValue();
	}

	private static LocalDate min(LocalDate first, LocalDate second) {
		return first.isAfter(second) ? second : first;
	}

	private static Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

}
