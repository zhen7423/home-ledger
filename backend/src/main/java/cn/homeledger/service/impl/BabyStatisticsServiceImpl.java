package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BabyAge;
import cn.homeledger.common.BabyVaccineDisplay;
import cn.homeledger.common.BabyVaccineStatus;
import cn.homeledger.common.GrowthPercentile;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyGrowth;
import cn.homeledger.entity.BabyMilestone;
import cn.homeledger.entity.BabyVaccinePlan;
import cn.homeledger.entity.BabyVaccineRecord;
import cn.homeledger.entity.GrowthStandardDict;
import cn.homeledger.mapper.BabyGrowthMapper;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.BabyMilestoneMapper;
import cn.homeledger.mapper.BabyVaccinePlanMapper;
import cn.homeledger.mapper.BabyVaccineRecordMapper;
import cn.homeledger.mapper.GrowthStandardDictMapper;
import cn.homeledger.service.BabyStatisticsService;
import cn.homeledger.vo.BabyGrowthStatisticsResponse;
import cn.homeledger.vo.BabyGrowthStatisticsResponse.BabyGrowthGain;
import cn.homeledger.vo.BabyGrowthStatisticsResponse.BabyGrowthItem;
import cn.homeledger.vo.BabyGrowthStatisticsResponse.BabyGrowthLatest;
import cn.homeledger.vo.BabyGrowthStatisticsResponse.BabyGrowthWindows;
import cn.homeledger.vo.BabyGrowthStatisticsResponse.BabyPercentileBands;
import cn.homeledger.vo.BabyVaccineStatisticsResponse;
import cn.homeledger.vo.BabyVaccineStatisticsResponse.BabyMilestoneItem;
import cn.homeledger.vo.BabyVaccineStatisticsResponse.BabyVaccineCounts;
import cn.homeledger.vo.BabyVaccineStatisticsResponse.BabyVaccineItem;
import cn.homeledger.vo.BabyVaccineStatisticsResponse.BabyVaccinePlanItem;
import cn.homeledger.vo.BabyVaccineStatisticsResponse.BabyVaccineRecordItem;

/**
 * §4.4.6 宝宝统计。
 * <p>
 * 与猫咪统计同构：一条聚合 SQL 都不写，也不挂 {@code @Transactional}。一个家庭最多 5 个宝宝、几百条身高体重、
 * 二十几行应种清单，全读进内存再分组比写三条聚合便宜不了多少，而 SQL 侧要重写一遍「每天留一条代表行」
 * 「按窗口取首末两条」的口径——那两份口径在 Java 里已经各有一份，第二份只会长出第二个答案。
 * <p>
 * 不挂事务的理由同 {@code CatStatisticsServiceImpl}：统计是某一时刻的近似，§5.1 已用缓存 TTL 承认了这一点；
 * 而 {@code vaccine} 这条会被待提醒项的判定调到，在那条路径上开事务会把一次提醒查询拖成长事务。
 */
@Service
public class BabyStatisticsServiceImpl implements BabyStatisticsService {

	private static final String ENDPOINT_GROWTH = "baby-growth";

	private static final String ENDPOINT_VACCINE = "baby-vaccine";

	/** 逐月窗口（§4.4.6 的「近 3 个月 / 近 12 个月」与接种时间轴的「近 12 个月」共用这一个）。 */
	private static final int WINDOW_MONTHS = 12;

	private static final String METRIC_HEIGHT = "HEIGHT";

	private static final String METRIC_WEIGHT = "WEIGHT";

	private static final String METRIC_WEIGHT_HEIGHT = "WEIGHT_HEIGHT";

	private static final String METRIC_BMI = "BMI";

	private static final String METRIC_HEAD_CIRCUMFERENCE = "HEAD_CIRCUMFERENCE";

	private final BabyMapper babyMapper;

	private final BabyGrowthMapper babyGrowthMapper;

	private final BabyVaccinePlanMapper babyVaccinePlanMapper;

	private final BabyVaccineRecordMapper babyVaccineRecordMapper;

	private final BabyMilestoneMapper babyMilestoneMapper;

	private final GrowthStandardDictMapper growthStandardDictMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public BabyStatisticsServiceImpl(BabyMapper babyMapper, BabyGrowthMapper babyGrowthMapper,
			BabyVaccinePlanMapper babyVaccinePlanMapper, BabyVaccineRecordMapper babyVaccineRecordMapper,
			BabyMilestoneMapper babyMilestoneMapper, GrowthStandardDictMapper growthStandardDictMapper,
			StatisticsCache statisticsCache, Clock clock) {
		this.babyMapper = babyMapper;
		this.babyGrowthMapper = babyGrowthMapper;
		this.babyVaccinePlanMapper = babyVaccinePlanMapper;
		this.babyVaccineRecordMapper = babyVaccineRecordMapper;
		this.babyMilestoneMapper = babyMilestoneMapper;
		this.growthStandardDictMapper = growthStandardDictMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public BabyGrowthStatisticsResponse growth(Long babyId) {
		Long familyId = currentFamilyId();
		String conditions = conditionsOf(babyId);
		BabyGrowthStatisticsResponse cached = this.statisticsCache.read(StatisticsCache.MODULE_BABY, ENDPOINT_GROWTH,
				familyId, conditions, BabyGrowthStatisticsResponse.class);
		if (cached != null) {
			return cached;
		}
		BabyGrowthStatisticsResponse response = buildGrowth(familyId, babyId);
		this.statisticsCache.write(StatisticsCache.MODULE_BABY, ENDPOINT_GROWTH, familyId, conditions, response);
		return response;
	}

	@Override
	public BabyVaccineStatisticsResponse vaccine(Long babyId) {
		Long familyId = currentFamilyId();
		String conditions = conditionsOf(babyId);
		BabyVaccineStatisticsResponse cached = this.statisticsCache.read(StatisticsCache.MODULE_BABY, ENDPOINT_VACCINE,
				familyId, conditions, BabyVaccineStatisticsResponse.class);
		if (cached != null) {
			return cached;
		}
		BabyVaccineStatisticsResponse response = buildVaccine(familyId, babyId);
		this.statisticsCache.write(StatisticsCache.MODULE_BABY, ENDPOINT_VACCINE, familyId, conditions, response);
		return response;
	}

	// ---- 当前体格与增长情况 ----

	private BabyGrowthStatisticsResponse buildGrowth(Long familyId, Long babyId) {
		LocalDate today = LocalDate.now(this.clock);
		List<Baby> babies = familyBabies(familyId, babyId);
		Map<Long, List<BabyGrowth>> byBaby = this.babyGrowthMapper.selectList(growthScope(familyId, babyId))
			.stream()
			.collect(Collectors.groupingBy(BabyGrowth::getBabyId));
		StandardTables tables = new StandardTables(this.growthStandardDictMapper);
		return new BabyGrowthStatisticsResponse(babies.stream()
			.map(baby -> growthItem(baby, byBaby.getOrDefault(baby.getId(), List.of()), today, tables))
			.toList());
	}

	private static BabyGrowthItem growthItem(Baby baby, List<BabyGrowth> rows, LocalDate today,
			StandardTables tables) {
		List<BabyGrowth> representatives = representativeRows(rows);
		BabyGrowthLatest latest = representatives.isEmpty() ? null
				: latestOf(baby, representatives.get(representatives.size() - 1), tables);
		return new BabyGrowthItem(baby.getId(), baby.getName(), BabyAge.ageText(baby.getBirthDate(), today), latest,
				new BabyGrowthWindows(sinceLast(representatives), windowGain(representatives, today.minusMonths(3)),
						windowGain(representatives, today.minusMonths(WINDOW_MONTHS))));
	}

	/**
	 * 每天只留一条代表行（该日 id 最大的那条），按日期升序。
	 * <p>
	 * 与 §4.4.2 的「上一次」同一条口径：列表页的增量、曲线上的点、这里的体格与三档增长必须是同一条记录，
	 * 否则同一天补录第二条之后，三处会各显示一个值。行已由 {@link #growthScope} 按
	 * {@code measure_date ASC, id ASC} 排好，所以同日里后写进去的那条就是代表行。
	 */
	private static List<BabyGrowth> representativeRows(List<BabyGrowth> rows) {
		Map<LocalDate, BabyGrowth> representative = new java.util.TreeMap<>();
		for (BabyGrowth row : rows) {
			representative.put(row.getMeasureDate(), row);
		}
		return List.copyOf(representative.values());
	}

	private static BabyGrowthLatest latestOf(Baby baby, BabyGrowth row, StandardTables tables) {
		int ageMonths = BabyAge.monthsBetween(baby.getBirthDate(), row.getMeasureDate());
		BigDecimal age = BigDecimal.valueOf(ageMonths);
		return new BabyGrowthLatest(row.getMeasureDate(), row.getHeightCm(), row.getWeightKg(), row.getHeadCm(),
				new BabyPercentileBands(
						band(tables, baby.getGender(), METRIC_HEIGHT, age, row.getHeightCm()),
						band(tables, baby.getGender(), METRIC_WEIGHT, age, row.getWeightKg()),
						// 体重别身高按这一行的月龄选表而不是按今天：一条 20 个月时补录的记录，该用的是
						// 当时那张身长表。曲线那条反过来按今天选表，因为一张响应只能带一张表，
						// 逐点选表会让同一条曲线上出现两张横轴重叠、互相矛盾的参考带（§4.4.3）。
						band(tables, baby.getGender(),
								GrowthPercentile.resolveMetric(METRIC_WEIGHT_HEIGHT, ageMonths), row.getHeightCm(),
								row.getWeightKg()),
						band(tables, baby.getGender(), METRIC_BMI, age,
								GrowthPercentile.bmi(row.getHeightCm(), row.getWeightKg())),
						band(tables, baby.getGender(), METRIC_HEAD_CIRCUMFERENCE, age, row.getHeadCm())));
	}

	/** 值为空或超出标准表覆盖范围都回 null：界面都出「—」，而就近取端点值会给出一个与表无关的档位（§4.4.3）。 */
	private static String band(StandardTables tables, String gender, String metric, BigDecimal x, BigDecimal measured) {
		if (x == null || measured == null) {
			return null;
		}
		GrowthPercentile.Percentiles percentiles = GrowthPercentile
			.interpolate(tables.of(gender, GrowthPercentile.dictMetric(metric)), x);
		return percentiles == null ? null : GrowthPercentile.bandOf(percentiles, measured);
	}

	/** 最近两日代表行之差。只有一条记录时为 null——「较上次」需要一个上次（§4.4.2）。 */
	private static BabyGrowthGain sinceLast(List<BabyGrowth> representatives) {
		return representatives.size() < 2 ? null : gainOf(representatives.get(representatives.size() - 2),
				representatives.get(representatives.size() - 1));
	}

	/**
	 * 窗口内最早与最新两条代表行之差。
	 * <p>
	 * 不足两条时整段为 null，<b>不许</b>拿区间外的记录顶上：那算出来的是一段跨出窗口的增长，而这张卡问的是
	 * 「近 3 个月长了多少」。上界不必判——测量日期晚于今天的记录建不出来（§4.4.2）。
	 */
	private static BabyGrowthGain windowGain(List<BabyGrowth> representatives, LocalDate from) {
		List<BabyGrowth> inWindow = representatives.stream()
			.filter(row -> !row.getMeasureDate().isBefore(from))
			.toList();
		return inWindow.size() < 2 ? null : gainOf(inWindow.get(0), inWindow.get(inWindow.size() - 1));
	}

	private static BabyGrowthGain gainOf(BabyGrowth earlier, BabyGrowth later) {
		return new BabyGrowthGain((int) ChronoUnit.DAYS.between(earlier.getMeasureDate(), later.getMeasureDate()),
				diff(later.getHeightCm(), earlier.getHeightCm()), diff(later.getWeightKg(), earlier.getWeightKg()),
				diff(later.getHeadCm(), earlier.getHeadCm()));
	}

	/** 两行都有这一列才算，缺一边给 null——「这一次没量身高」与「身高没变」是两件事（§4.4.2）。 */
	private static BigDecimal diff(BigDecimal later, BigDecimal earlier) {
		return later == null || earlier == null ? null : later.subtract(earlier);
	}

	// ---- 疫苗六项 + 里程碑时间轴 ----

	private BabyVaccineStatisticsResponse buildVaccine(Long familyId, Long babyId) {
		LocalDate today = LocalDate.now(this.clock);
		List<Baby> babies = familyBabies(familyId, babyId);
		Map<Long, String> names = babies.stream().collect(Collectors.toMap(Baby::getId, Baby::getName));
		Map<Long, List<BabyVaccinePlan>> plans = this.babyVaccinePlanMapper.selectList(planScope(familyId, babyId))
			.stream()
			.collect(Collectors.groupingBy(BabyVaccinePlan::getBabyId));
		Map<Long, List<BabyVaccineRecord>> records = this.babyVaccineRecordMapper
			.selectList(recordScope(familyId, babyId))
			.stream()
			.collect(Collectors.groupingBy(BabyVaccineRecord::getBabyId));
		List<BabyVaccineItem> perBaby = babies.stream()
			.filter(BabyStatisticsServiceImpl::isActive)
			.map(baby -> vaccineItem(baby, plans.getOrDefault(baby.getId(), List.of()),
					records.getOrDefault(baby.getId(), List.of()), today))
			.toList();
		return new BabyVaccineStatisticsResponse(perBaby, milestoneTimeline(familyId, babyId, names));
	}

	/**
	 * 一个宝宝的完成率、状态分布与三张列表。
	 * <p>
	 * 「已标记」的排除走<b>落库态</b>（{@link BabyVaccineStatus#marked()}）而不是展示态：§4.4.6 写的是
	 * 「{@code status} 不是 {@code SKIPPED} / {@code NA}」，而展示态里 {@code VACCINATED} 排在
	 * {@code MARKED} 前面——先打过针再把这行标成跳过时（{@code record_id} 还在），
	 * 按展示态排除会让它留在分子分母里，与那一句不符。
	 * <p>
	 * 剩下四态与两张待办列表则共用 {@link BabyVaccineDisplay} 这一个判定（§4.4.4 把它定成「清单页配色、
	 * 完成率、提醒三处唯一来源」）：两处口径只要有一处不同，就会出现「分段条说逾期 2 条、下面的清单只有 1 条」。
	 * <p>
	 * 完成率的分母另走落库态：§4.4.6 写死了「{@code due_date <= 今天} 且非 {@code SKIPPED} / {@code NA}」，
	 * 分子是其中 {@code DONE} 的。一个刚到出生日的宝宝，两针出生剂次还没录时是 0%，登完两针就是 100%——
	 * 二十几针远期剂次不进分母，否则出院那天就会被读成「进度落后」。
	 */
	private static BabyVaccineItem vaccineItem(Baby baby, List<BabyVaccinePlan> plans,
			List<BabyVaccineRecord> records, LocalDate today) {
		int vaccinated = 0;
		int upcoming = 0;
		int dueSoon = 0;
		int overdue = 0;
		int due = 0;
		int done = 0;
		List<BabyVaccinePlanItem> upcomingList = new ArrayList<>();
		List<BabyVaccinePlanItem> overdueList = new ArrayList<>();
		// 生效日期升序（用户改过计划日期的行排到它该在的位置）：SQL 侧表达不了 COALESCE，这里排。
		// 两个待办列表的「按日期升序、逾期最久的在最前」因此保持成立。
		List<BabyVaccinePlan> ordered = plans.stream()
			.sorted(Comparator.comparing(BabyVaccinePlan::effectiveDate).thenComparing(BabyVaccinePlan::getId))
			.toList();
		for (BabyVaccinePlan plan : ordered) {
			BabyVaccineStatus status = BabyVaccineStatus.of(plan.getStatus());
			if (status.marked()) {
				continue;
			}
			// 生效日期（用户改过计划日期取 plannedDate）贯穿完成率分母、展示态与倒计时三处，
			// 与清单页同一口径（effectiveDate 是唯一定义）
			if (!plan.effectiveDate().isAfter(today)) {
				due++;
				done += status == BabyVaccineStatus.DONE ? 1 : 0;
			}
			BabyVaccineDisplay display = BabyVaccineDisplay.of(status, plan.effectiveDate(), today,
					plan.getRecordId() != null);
			switch (display) {
				case VACCINATED -> vaccinated++;
				case DUE_SOON -> {
					dueSoon++;
					upcomingList.add(planItem(plan, today));
				}
				case UPCOMING -> upcoming++;
				case OVERDUE -> {
					overdue++;
					overdueList.add(planItem(plan, today));
				}
				// 上面的 marked() 已经跳过，这条分支只是枚举穷尽
				case MARKED -> { }
			}
		}
		return new BabyVaccineItem(baby.getId(), baby.getName(), rateOf(done, due),
				new BabyVaccineCounts(vaccinated, upcoming, dueSoon, overdue), upcomingList, overdueList,
				recordTimeline(records, today));
	}

	/**
	 * 两列互斥且总有一列为空，与 {@code CatDueCountdownItem} 同一形状（§4.3.5）：未到期的只有
	 * {@code daysToDue}（当天是 0），逾期的只有 {@code overdueDays}。当天归「未到期」那一支，
	 * 「今天应接种」与「已逾期 0 天」是两句话。
	 */
	private static BabyVaccinePlanItem planItem(BabyVaccinePlan plan, LocalDate today) {
		LocalDate effective = plan.effectiveDate();
		boolean overdue = effective.isBefore(today);
		return new BabyVaccinePlanItem(plan.getId(), plan.getVaccineName(), plan.getDoseNo(), effective,
				overdue ? null : ChronoUnit.DAYS.between(today, effective),
				overdue ? ChronoUnit.DAYS.between(effective, today) : null);
	}

	/** 近 12 个月的接种记录（§4.4.6）。行已按 {@code given_date DESC, id DESC} 排好，过滤不会打乱顺序。 */
	private static List<BabyVaccineRecordItem> recordTimeline(List<BabyVaccineRecord> records, LocalDate today) {
		LocalDate from = today.minusMonths(WINDOW_MONTHS);
		return records.stream()
			.filter(row -> !row.getGivenDate().isBefore(from))
			.map(row -> new BabyVaccineRecordItem(row.getVaccineName(), row.getGivenDate(), row.getClinic()))
			.toList();
	}

	private List<BabyMilestoneItem> milestoneTimeline(Long familyId, Long babyId, Map<Long, String> names) {
		return this.babyMilestoneMapper.selectList(milestoneScope(familyId, babyId))
			.stream()
			.map(row -> new BabyMilestoneItem(row.getBabyId(), names.get(row.getBabyId()), row.getOccurDate(),
					row.getTitle(), row.getDescription()))
			.toList();
	}

	// ---- 查询范围与公共件 ----

	/**
	 * 含归档：§4.4.1 要求归档的宝宝继续出现在历史统计里。排序与档案列表逐字相同（在册的在前、其后按建档先后），
	 * 两条统计的 {@code perBaby} 因此与宝宝选择器同序。{@code vaccine} 侧再滤一次在册的，用的是这份列表。
	 * <p>
	 * 不校验 {@code babyId} 是不是本家庭的：与 {@code GET /baby-growths?babyId=} 同一条口径——它是一个筛选条件，
	 * 命中不了就是空表，而跨家庭的 id 在租户注入下本来也命中不了。
	 */
	private List<Baby> familyBabies(Long familyId, Long babyId) {
		return this.babyMapper.selectList(new LambdaQueryWrapper<Baby>().eq(Baby::getFamilyId, familyId)
			.eq(babyId != null, Baby::getId, babyId)
			.orderByDesc(Baby::getEnabled)
			.orderByAsc(Baby::getCreatedAt)
			.orderByAsc(Baby::getId));
	}

	private static boolean isActive(Baby baby) {
		return baby.getEnabled() != 0;
	}

	private static LambdaQueryWrapper<BabyGrowth> growthScope(Long familyId, Long babyId) {
		return new LambdaQueryWrapper<BabyGrowth>().eq(BabyGrowth::getFamilyId, familyId)
			.eq(babyId != null, BabyGrowth::getBabyId, babyId)
			.orderByAsc(BabyGrowth::getMeasureDate)
			.orderByAsc(BabyGrowth::getId);
	}

	/**
	 * 圈范围不做排序（调用方见 {@code vaccineItem} 的分组消费）：生效日期是 COALESCE(planned_date,
	 * due_date)，LambdaQueryWrapper 表达不了；待办列表的「按日期升序」在 planItem 落完后由
	 * vaccineItem 的遍历顺序保证不了时再排——这里数据量（每宝宝 ≤ 程序表行数）撑得起内存排序。
	 */
	private static LambdaQueryWrapper<BabyVaccinePlan> planScope(Long familyId, Long babyId) {
		return new LambdaQueryWrapper<BabyVaccinePlan>().eq(BabyVaccinePlan::getFamilyId, familyId)
			.eq(babyId != null, BabyVaccinePlan::getBabyId, babyId);
	}

	private static LambdaQueryWrapper<BabyVaccineRecord> recordScope(Long familyId, Long babyId) {
		return new LambdaQueryWrapper<BabyVaccineRecord>().eq(BabyVaccineRecord::getFamilyId, familyId)
			.eq(babyId != null, BabyVaccineRecord::getBabyId, babyId)
			.orderByDesc(BabyVaccineRecord::getGivenDate)
			.orderByDesc(BabyVaccineRecord::getId);
	}

	private static LambdaQueryWrapper<BabyMilestone> milestoneScope(Long familyId, Long babyId) {
		return new LambdaQueryWrapper<BabyMilestone>().eq(BabyMilestone::getFamilyId, familyId)
			.eq(babyId != null, BabyMilestone::getBabyId, babyId)
			.orderByAsc(BabyMilestone::getOccurDate)
			.orderByAsc(BabyMilestone::getId);
	}

	/** 完成率，逐字沿用 {@code CatStatisticsServiceImpl.rateOf}（§4.4.6、用例 28）：一针都没到期时是满分。 */
	private static int rateOf(int done, int due) {
		return due == 0 ? 100 : Math.min(100, done * 100 / due);
	}

	/** 规范化的条件串：只有 babyId 一个条件，不传与传空串在这里合成同一个键（§5.1）。 */
	private static String conditionsOf(Long babyId) {
		return StatisticsCache.joinConditions(babyId == null ? null : babyId.toString());
	}

	private static Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	/**
	 * 一次统计内同一张标准表只查一次。五个指标逐个宝宝各查一遍能把最多十次查询翻成五十次，
	 * 而这张表是静态数据、一次请求内不可能变。
	 */
	private static final class StandardTables {

		private final GrowthStandardDictMapper mapper;

		private final Map<String, List<GrowthStandardDict>> loaded = new HashMap<>();

		StandardTables(GrowthStandardDictMapper mapper) {
			this.mapper = mapper;
		}

		List<GrowthStandardDict> of(String gender, String metric) {
			return this.loaded.computeIfAbsent(gender + '|' + metric,
					key -> this.mapper.selectByGenderAndMetric(gender, metric));
		}
	}

}
