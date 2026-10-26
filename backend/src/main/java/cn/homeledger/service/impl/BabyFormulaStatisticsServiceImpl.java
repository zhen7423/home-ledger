package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.service.BabyFormulaBagService;
import cn.homeledger.service.BabyFormulaBagService.TimelineEntry;
import cn.homeledger.service.BabyFormulaStatisticsService;
import cn.homeledger.vo.BabyFormulaStatisticsResponse;
import cn.homeledger.vo.BabyFormulaStatisticsResponse.BabyFormulaMonthGrams;

/**
 * §4.5.3 奶粉消耗统计。
 * <p>
 * 月趋势与「区间日均」的分摊口径与 {@code CatStatisticsServiceImpl#foodConsumption} 同源
 * （telescoping：逐月相加恒等于整段相加，不会出现 12 根柱子的总和比概览卡多几克）——
 * 那是被验收测试钉过的数学，改动须两处同步（§4.5.3）。
 * <p>
 * 走 {@link StatisticsCache} 的 {@code MODULE_BABY} 段：奶粉开罐/改罐/删罐由
 * {@code BabyFormulaBagServiceImpl} 失效该段，与宝宝统计共用版本号（模块内粗粒度，§5.1）。
 */
@Service
public class BabyFormulaStatisticsServiceImpl implements BabyFormulaStatisticsService {

	/** 月趋势的窗口：近 6 个自然月，够看食量随月龄的走势，不必照搬猫咪的 12 根柱子。 */
	private static final int WINDOW_MONTHS = 6;

	private static final String ENDPOINT_FORMULA = "baby-formula";

	private static final String NO_CONDITIONS = "";

	private static final DateTimeFormatter MONTH_KEY = DateTimeFormatter.ofPattern("yyyy-MM");

	private final BabyFormulaBagService babyFormulaBagService;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public BabyFormulaStatisticsServiceImpl(BabyFormulaBagService babyFormulaBagService,
			StatisticsCache statisticsCache, Clock clock) {
		this.babyFormulaBagService = babyFormulaBagService;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public BabyFormulaStatisticsResponse formula() {
		Long familyId = AuthContextHolder.require().familyId();
		BabyFormulaStatisticsResponse cached = this.statisticsCache.read(StatisticsCache.MODULE_BABY,
				ENDPOINT_FORMULA, familyId, NO_CONDITIONS, BabyFormulaStatisticsResponse.class);
		if (cached != null) {
			return cached;
		}
		BabyFormulaStatisticsResponse response = buildFormula();
		this.statisticsCache.write(StatisticsCache.MODULE_BABY, ENDPOINT_FORMULA, familyId, NO_CONDITIONS, response);
		return response;
	}

	private BabyFormulaStatisticsResponse buildFormula() {
		List<TimelineEntry> entries = this.babyFormulaBagService.timeline();
		LocalDate today = LocalDate.now(this.clock);
		// 累计口径：从第一罐开罐日起（一罐都还没有时是今天），到今天的区间
		LocalDate start = entries.isEmpty() ? today : entries.get(0).startedDate();
		long days = Math.max(0, ChronoUnit.DAYS.between(start, today) + 1L);
		int totalGrams = start.isAfter(today) ? 0 : gramsBetween(entries, start, today);
		int dailyAverage = days == 0 ? 0 : round(totalGrams, days);
		return new BabyFormulaStatisticsResponse(totalGrams, days, dailyAverage, monthlyTrend(entries, today));
	}

	private List<BabyFormulaMonthGrams> monthlyTrend(List<TimelineEntry> entries, LocalDate today) {
		LocalDate from = today.withDayOfMonth(1).minusMonths(WINDOW_MONTHS - 1L);
		List<BabyFormulaMonthGrams> trend = new ArrayList<>(WINDOW_MONTHS);
		for (int i = 0; i < WINDOW_MONTHS; i++) {
			LocalDate monthStart = from.plusMonths(i);
			LocalDate monthEnd = monthStart.plusMonths(1).minusDays(1);
			trend.add(new BabyFormulaMonthGrams(monthStart.format(MONTH_KEY),
					gramsBetween(entries, monthStart, monthEnd)));
		}
		return trend;
	}

	/** 到 {@code through} 那天为止这一罐累计喝掉了多少克（均匀分摊，telescoping 口径见类注释）。 */
	private static int gramsBetween(List<TimelineEntry> entries, LocalDate from, LocalDate to) {
		int grams = 0;
		for (TimelineEntry entry : entries) {
			grams += consumedThrough(entry, to) - consumedThrough(entry, from.minusDays(1));
		}
		return grams;
	}

	private static int consumedThrough(TimelineEntry entry, LocalDate through) {
		if (entry.usageDays() <= 0L) {
			return 0;
		}
		long days = ChronoUnit.DAYS.between(entry.startedDate(), through) + 1L;
		long clamped = Math.min(Math.max(days, 0L), entry.usageDays());
		return (int) (entry.packGrams() * clamped / entry.usageDays());
	}

	private static int round(long grams, long days) {
		return BigDecimal.valueOf(grams).divide(BigDecimal.valueOf(days), 0, RoundingMode.HALF_UP).intValue();
	}

}