package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.DateRanges;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.entity.Category;
import cn.homeledger.entity.PaymentAccount;
import cn.homeledger.mapper.CategoryMapper;
import cn.homeledger.mapper.FamilyMemberMapper;
import cn.homeledger.mapper.PaymentAccountMapper;
import cn.homeledger.mapper.TransactionMapper;
import cn.homeledger.service.StatisticsService;
import cn.homeledger.vo.AccountSlice;
import cn.homeledger.vo.CategoryAmount;
import cn.homeledger.vo.CategorySlice;
import cn.homeledger.vo.DailyPoint;
import cn.homeledger.vo.FinanceStatisticsResponse;
import cn.homeledger.vo.MemberSlice;
import cn.homeledger.vo.MonthSummary;
import cn.homeledger.vo.TransactionSummaryResponse;

/**
 * §4.2.6 记账统计。五块数据在一次请求里算完：统计页一屏就要这五块，拆成五个端点等于让手机在弱网下
 * 串五次往返，而五块的筛选条件完全相同，服务端一次就能算完。
 * <p>
 * <b>不挂 {@code @Transactional(readOnly = true)}。</b> 这里要跑五条聚合，包成一个只读事务等于让一个
 * 连接被占住整段时间；而统计天生是「某一时刻的近似」，§5.1 已经用 60 秒缓存承认了这一点。
 */
@Service
public class StatisticsServiceImpl implements StatisticsService {

	/** §4.2.6：Top 8 之外合并为「其他」。 */
	private static final int TOP_CATEGORIES = 8;

	/** §4.2.6：月度收支趋势固定最近 12 个自然月，不随时间范围选择器变化。 */
	private static final int TREND_MONTHS = 12;

	private static final String TYPE_EXPENSE = "EXPENSE";

	private static final String OTHER_NAME = "其他";

	/** 该大类下没被细分的金额（§4.2.6）。 */
	private static final String UNSUBDIVIDED_NAME = "未细分";

	/** 补 0 用的零值。scale 要与 SUM(DECIMAL(12,2)) 的结果一致，否则同一份响应里会同时出现 "0" 与 "0.00"。 */
	private static final BigDecimal ZERO = BigDecimal.ZERO.setScale(2);

	private static final BigDecimal ONE_HUNDRED = BigDecimal.valueOf(100);

	private static final DateTimeFormatter MONTH_KEY = DateTimeFormatter.ofPattern("yyyy-MM");

	private static final String ENDPOINT_SUMMARY = "summary";

	private static final String ENDPOINT_OVERVIEW = "finance-overview";

	private final TransactionMapper transactionMapper;

	private final CategoryMapper categoryMapper;

	private final PaymentAccountMapper paymentAccountMapper;

	private final FamilyMemberMapper familyMemberMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public StatisticsServiceImpl(TransactionMapper transactionMapper, CategoryMapper categoryMapper,
			PaymentAccountMapper paymentAccountMapper, FamilyMemberMapper familyMemberMapper,
			StatisticsCache statisticsCache, Clock clock) {
		this.transactionMapper = transactionMapper;
		this.categoryMapper = categoryMapper;
		this.paymentAccountMapper = paymentAccountMapper;
		this.familyMemberMapper = familyMemberMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public TransactionSummaryResponse summary(TransactionQueryRequest query) {
		Long familyId = currentFamilyId();
		DateRanges.assertRange(query.startDate(), query.endDate());
		TransactionSummaryResponse cached = this.statisticsCache.read(StatisticsCache.MODULE_FINANCE, ENDPOINT_SUMMARY,
				familyId, query.canonicalConditions(), TransactionSummaryResponse.class);
		if (cached != null) {
			return cached;
		}
		Range range = resolve(query, familyId);
		TransactionMapper.Totals totals = range.totals();
		BigDecimal dailyAverage = range.days() == 0 ? ZERO
				: totals.expense().divide(BigDecimal.valueOf(range.days()), 2, RoundingMode.HALF_UP);
		TransactionSummaryResponse response = new TransactionSummaryResponse(range.start(), range.end(), range.days(),
				totals.income(), totals.expense(), totals.income().subtract(totals.expense()), dailyAverage,
				totals.count());
		this.statisticsCache.write(StatisticsCache.MODULE_FINANCE, ENDPOINT_SUMMARY, familyId,
				query.canonicalConditions(), response);
		return response;
	}

	@Override
	public FinanceStatisticsResponse financeOverview(TransactionQueryRequest query) {
		Long familyId = currentFamilyId();
		DateRanges.assertRange(query.startDate(), query.endDate());
		FinanceStatisticsResponse cached = this.statisticsCache.read(StatisticsCache.MODULE_FINANCE, ENDPOINT_OVERVIEW,
				familyId, query.canonicalConditions(), FinanceStatisticsResponse.class);
		if (cached != null) {
			return cached;
		}
		Range range = resolve(query, familyId);
		TransactionQueryRequest expenseQuery = expenseOnly(query);
		List<CategorySlice> categories = categoryBreakdown(expenseQuery, familyId);
		FinanceStatisticsResponse response = new FinanceStatisticsResponse(range.start(), range.end(), categories,
				monthlyTrend(query, familyId), dailyTrend(expenseQuery, familyId, range),
				accountBreakdown(expenseQuery, familyId), memberComparison(expenseQuery, familyId, categories));
		this.statisticsCache.write(StatisticsCache.MODULE_FINANCE, ENDPOINT_OVERVIEW, familyId,
				query.canonicalConditions(), response);
		return response;
	}

	/**
	 * 把「可能缺边的区间」解析成一个确定的区间（§4.2.6）。
	 * <p>
	 * 结束日缺省取今天（Clock，不是 LocalDate.now()——部署机时区配错时会差一天）；
	 * 起始日缺省取家里第一笔流水的日期，一笔都没有就退化成结束日，此时 days 为 0。
	 * <p>
	 * days 为 0 而不是 1：日均支出要除以它，一笔流水都没有的区间谈「日均」没有意义，
	 * 而除数为 0 会让 BigDecimal 抛 ArithmeticException。
	 */
	private Range resolve(TransactionQueryRequest query, Long familyId) {
		TransactionMapper.Totals totals = this.transactionMapper.sumFiltered(query, familyId);
		LocalDate today = LocalDate.now(this.clock);
		LocalDate end = query.endDate() != null ? query.endDate() : today;
		// 终点截到今天：未来几天不可能有流水，截断不改变任何合法结果；不截的话
		// endDate=9999-12-31 会让 dailyTrend 按天循环数百万次、巨型 JSON 再冲垮统计缓存
		// （用户单边给全日期不经过 assertRange 的跨度校验，复扫 2026-10-26 P1）。
		if (end.isAfter(today)) {
			end = today;
		}
		LocalDate start;
		if (query.startDate() != null) {
			// 用户单边给的起点收 5 年地板（与 App 选择器同一口径）：dailyTrend 按天展开循环，
			// 无界的起点会让单次请求循环数万次、极端 ISO 年份直接 OOM（扫描报告 P1-1）。
			// 两边都给时 assertRange 已把跨度压进 366 天，地板不会生效。
			start = DateRanges.floorUserStart(query.startDate(), end);
		}
		else {
			start = totals.minBizDate() != null ? totals.minBizDate() : end;
		}
		if (start.isAfter(end)) {
			// 只有「用户给的 startDate 晚于 end」能走到这里：两边都给时 assertRange 已经挡过，
			// startDate 缺省时它取自已被 endDate 过滤过的 MIN(biz_date)，不可能大于 end。
			// 起止都给在未来（如 2099-01-01~2099-06-01）经终点截断后也会落到这里，
			// 同按「起始晚于结束」拒绝——那个区间里本来就不可能有任何流水。
			throw new BizException(ErrorCode.BAD_REQUEST, "起始日期不能晚于结束日期");
		}
		int days = totals.count() == 0 ? 0 : DateRanges.daysInclusive(start, end);
		return new Range(start, end, days, totals);
	}

	private record Range(LocalDate start, LocalDate end, int days, TransactionMapper.Totals totals) {
	}

	/**
	 * 类别占比 / 每日支出 / 支付方式占比 / 成员对比这四张图只统计支出（§4.2.6）。
	 * 覆写 type 而不是在 SQL 里写死，是为了让 filters 里那条 {@code <if test="q.type">} 保持唯一的真值来源。
	 */
	private static TransactionQueryRequest expenseOnly(TransactionQueryRequest query) {
		return new TransactionQueryRequest(query.startDate(), query.endDate(), TYPE_EXPENSE, query.categoryId(),
				query.subCategoryId(), query.accountId(), query.createdBy(), query.keyword(), query.amount(),
				query.source(), query.page(), query.size());
	}

	/**
	 * 月度趋势的窗口：最近 12 个自然月，从 11 个月前的 1 号到当月最后一天。
	 * <p>
	 * <b>type 被清成 null</b>：这张图同时画收入柱与支出柱（{@code MonthSummary} 内部按 CASE 分流），
	 * 留着调用方的 type 会让其中一种恒为 0。其余筛选条件（尤其是记录人）照旧保留——
	 * §4.2.6 说的是「不随时间范围变化」，不是「不随记录人变化」。
	 */
	private static TransactionQueryRequest trendWindow(TransactionQueryRequest query, LocalDate from, LocalDate to) {
		return new TransactionQueryRequest(from, to, null, query.categoryId(), query.subCategoryId(),
				query.accountId(), query.createdBy(), query.keyword(), query.amount(), query.source(), query.page(),
				query.size());
	}

	private List<CategorySlice> categoryBreakdown(TransactionQueryRequest expenseQuery, Long familyId) {
		List<TransactionMapper.CategorySubSpend> rows = this.transactionMapper
			.sumExpenseByCategoryAndSubCategoryFiltered(expenseQuery, familyId);
		if (rows.isEmpty()) {
			return List.of();
		}
		Map<Long, List<TransactionMapper.CategorySubSpend>> grouped = new LinkedHashMap<>();
		for (TransactionMapper.CategorySubSpend row : rows) {
			grouped.computeIfAbsent(row.categoryId(), key -> new ArrayList<>()).add(row);
		}
		List<Rolled> rolled = new ArrayList<>(grouped.size());
		grouped.forEach((categoryId, items) -> rolled
			.add(new Rolled(categoryId, items.stream().map(TransactionMapper.CategorySubSpend::amount).reduce(ZERO,
					BigDecimal::add), items)));
		rolled.sort(Comparator.comparing(Rolled::total).reversed().thenComparing(Rolled::categoryId));

		BigDecimal expenseTotal = rolled.stream().map(Rolled::total).reduce(ZERO, BigDecimal::add);
		List<Rolled> top = rolled.size() > TOP_CATEGORIES ? rolled.subList(0, TOP_CATEGORIES) : rolled;
		Map<Long, String> names = categoryNames(familyId, collectIds(top, rows));

		List<CategorySlice> slices = new ArrayList<>(top.size() + 1);
		for (Rolled item : top) {
			slices.add(new CategorySlice(item.categoryId(), names.getOrDefault(item.categoryId(), OTHER_NAME),
					item.total(), percent(item.total(), expenseTotal), subSlices(item, names)));
		}
		if (rolled.size() > TOP_CATEGORIES) {
			BigDecimal otherTotal = rolled.subList(TOP_CATEGORIES, rolled.size())
				.stream()
				.map(Rolled::total)
				.reduce(ZERO, BigDecimal::add);
			// 「其他」不是一片真的类别，没有小类可下钻，前端据 subCategories 为空禁掉点击
			slices.add(new CategorySlice(null, OTHER_NAME, otherTotal, percent(otherTotal, expenseTotal), List.of()));
		}
		return List.copyOf(slices);
	}

	private record Rolled(Long categoryId, BigDecimal total, List<TransactionMapper.CategorySubSpend> items) {
	}

	/**
	 * 一个大类下面的小类占比。subCategoryId 为 null 的那一组渲染成「未细分」（§4.2.6），
	 * <b>不做 Top N 截断</b>。percent 的分母是<b>父大类的合计</b>而不是总支出：下钻看到的饼图应该加起来是 100%。
	 */
	private List<CategorySlice> subSlices(Rolled parent, Map<Long, String> names) {
		BigDecimal parentTotal = parent.total();
		List<CategorySlice> subs = new ArrayList<>(parent.items().size());
		for (TransactionMapper.CategorySubSpend item : parent.items()) {
			Long subCategoryId = item.subCategoryId();
			String name = subCategoryId == null ? UNSUBDIVIDED_NAME : names.getOrDefault(subCategoryId, OTHER_NAME);
			subs.add(new CategorySlice(subCategoryId, name, item.amount(), percent(item.amount(), parentTotal),
					List.of()));
		}
		return List.copyOf(subs);
	}

	/** 大类 id 与这些大类名下小类 id 一次收齐，一趟 selectList 拿回全部名字；漏掉小类 id 会让下钻的名字全是回落值。 */
	private static Set<Long> collectIds(List<Rolled> top, List<TransactionMapper.CategorySubSpend> rows) {
		Set<Long> topIds = top.stream().map(Rolled::categoryId).collect(Collectors.toSet());
		Set<Long> ids = new HashSet<>();
		for (TransactionMapper.CategorySubSpend row : rows) {
			if (!topIds.contains(row.categoryId())) {
				continue;
			}
			ids.add(row.categoryId());
			if (row.subCategoryId() != null) {
				ids.add(row.subCategoryId());
			}
		}
		return ids;
	}

	/**
	 * 百分比一律向下取整。四舍五入会让若干片的占比加起来超过 100%，而饼图上写着 101% 是用户会截图发过来的那种 bug；
	 * 向下取整最多加起来 99%，那是「有些零头没显示」，可以接受。
	 */
	private static int percent(BigDecimal amount, BigDecimal total) {
		if (total.signum() == 0) {
			return 0;
		}
		return amount.multiply(ONE_HUNDRED).divide(total, 0, RoundingMode.DOWN).intValue();
	}

	private List<MonthSummary> monthlyTrend(TransactionQueryRequest query, Long familyId) {
		LocalDate from = LocalDate.now(this.clock).withDayOfMonth(1).minusMonths(TREND_MONTHS - 1L);
		LocalDate to = from.plusMonths(TREND_MONTHS).minusDays(1);
		Map<String, MonthSummary> found = this.transactionMapper
			.selectMonthSummaries(trendWindow(query, from, to), familyId)
			.stream()
			.collect(Collectors.toMap(MonthSummary::month, summary -> summary));
		List<MonthSummary> trend = new ArrayList<>(TREND_MONTHS);
		for (int i = 0; i < TREND_MONTHS; i++) {
			String month = from.plusMonths(i).format(MONTH_KEY);
			MonthSummary hit = found.get(month);
			trend.add(hit != null ? hit : new MonthSummary(month, ZERO, ZERO, ZERO, 0L));
		}
		return List.copyOf(trend);
	}

	private List<DailyPoint> dailyTrend(TransactionQueryRequest expenseQuery, Long familyId, Range range) {
		Map<LocalDate, BigDecimal> found = this.transactionMapper.sumExpenseByDayFiltered(expenseQuery, familyId)
			.stream()
			.collect(Collectors.toMap(TransactionMapper.DailySpend::bizDate, TransactionMapper.DailySpend::amount));
		List<DailyPoint> points = new ArrayList<>();
		for (LocalDate date = range.start(); !date.isAfter(range.end()); date = date.plusDays(1)) {
			points.add(new DailyPoint(date, found.getOrDefault(date, ZERO)));
		}
		return List.copyOf(points);
	}

	private List<AccountSlice> accountBreakdown(TransactionQueryRequest expenseQuery, Long familyId) {
		List<TransactionMapper.AccountSpend> rows = this.transactionMapper.sumExpenseByAccountFiltered(expenseQuery,
				familyId);
		if (rows.isEmpty()) {
			return List.of();
		}
		BigDecimal total = rows.stream().map(TransactionMapper.AccountSpend::amount).reduce(ZERO, BigDecimal::add);
		Map<Long, String> names = accountNames(familyId,
				rows.stream().map(TransactionMapper.AccountSpend::accountId).collect(Collectors.toSet()));
		return List.copyOf(rows.stream()
			.map(row -> new AccountSlice(row.accountId(), names.getOrDefault(row.accountId(), OTHER_NAME), row.amount(),
					percent(row.amount(), total)))
			.toList());
	}

	private List<MemberSlice> memberComparison(TransactionQueryRequest expenseQuery, Long familyId,
			List<CategorySlice> categories) {
		List<TransactionMapper.MemberCategorySpend> rows = this.transactionMapper
			.sumExpenseByMemberCategoryFiltered(expenseQuery, familyId);
		if (rows.isEmpty()) {
			return List.of();
		}
		Map<Long, BigDecimal> totals = new HashMap<>();
		Map<Long, Map<Long, BigDecimal>> perMember = new HashMap<>();
		for (TransactionMapper.MemberCategorySpend row : rows) {
			totals.merge(row.createdBy(), row.amount(), BigDecimal::add);
			perMember.computeIfAbsent(row.createdBy(), key -> new HashMap<>())
				.merge(row.categoryId(), row.amount(), BigDecimal::add);
		}
		Map<Long, String> names = this.familyMemberMapper.selectAllNamesIncludingLeft(familyId)
			.stream()
			.collect(Collectors.toMap(FamilyMemberMapper.MemberName::userId, FamilyMemberMapper.MemberName::nickname));
		Set<Long> topIds = categories.stream()
			.map(CategorySlice::categoryId)
			.filter(Objects::nonNull)
			.collect(Collectors.toSet());
		boolean hasOther = categories.stream().anyMatch(slice -> slice.categoryId() == null);

		List<Long> ordered = totals.keySet()
			.stream()
			.sorted(Comparator.<Long, BigDecimal>comparing(totals::get).reversed().thenComparing(userId -> userId))
			.toList();
		List<MemberSlice> slices = new ArrayList<>(ordered.size());
		for (Long userId : ordered) {
			Map<Long, BigDecimal> own = perMember.get(userId);
			List<CategoryAmount> byCategory = new ArrayList<>(categories.size());
			BigDecimal other = ZERO;
			for (CategorySlice slice : categories) {
				if (slice.categoryId() == null) {
					continue;
				}
				byCategory.add(new CategoryAmount(slice.categoryId(), own.getOrDefault(slice.categoryId(), ZERO)));
			}
			for (Map.Entry<Long, BigDecimal> entry : own.entrySet()) {
				if (!topIds.contains(entry.getKey())) {
					other = other.add(entry.getValue());
				}
			}
			if (hasOther) {
				byCategory.add(new CategoryAmount(null, other));
			}
			slices.add(new MemberSlice(userId, names.getOrDefault(userId, OTHER_NAME), totals.get(userId),
					List.copyOf(byCategory)));
		}
		return List.copyOf(slices);
	}

	private Map<Long, String> categoryNames(Long familyId, Set<Long> ids) {
		if (ids.isEmpty()) {
			return Map.of();
		}
		return this.categoryMapper
			.selectList(new LambdaQueryWrapper<Category>().select(Category::getId, Category::getName)
				.eq(Category::getFamilyId, familyId)
				.in(Category::getId, ids))
			.stream()
			.collect(Collectors.toMap(Category::getId, Category::getName));
	}

	private Map<Long, String> accountNames(Long familyId, Set<Long> ids) {
		if (ids.isEmpty()) {
			return Map.of();
		}
		return this.paymentAccountMapper
			.selectList(new LambdaQueryWrapper<PaymentAccount>()
				.select(PaymentAccount::getId, PaymentAccount::getName)
				.eq(PaymentAccount::getFamilyId, familyId)
				.in(PaymentAccount::getId, ids))
			.stream()
			.collect(Collectors.toMap(PaymentAccount::getId, PaymentAccount::getName));
	}

	private static Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

}
