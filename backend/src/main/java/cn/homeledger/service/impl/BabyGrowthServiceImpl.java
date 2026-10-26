package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BabyAge;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.GrowthPercentile;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.BabyGrowthCreateRequest;
import cn.homeledger.dto.BabyGrowthUpdateRequest;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyGrowth;
import cn.homeledger.entity.GrowthStandardDict;
import cn.homeledger.mapper.BabyGrowthMapper;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.GrowthStandardDictMapper;
import cn.homeledger.service.BabyGrowthService;
import cn.homeledger.vo.BabyGrowthDelta;
import cn.homeledger.vo.BabyGrowthResponse;
import cn.homeledger.vo.BabyGrowthResponse.BabyPercentiles;

/**
 * §4.4.2 身高体重记录。
 * <p>
 * {@code deltaFromPrevious} 是这张表唯一有分量的规则，口径只有一句：<b>按自然日去重，
 * 每天的代表行是该日 id 最大的一条，一条记录的「上一次」= 前一个有记录的自然日的代表行</b>。
 * 于是同一天的多条记录共享同一个「上一次」（同日补录第二次通常是在更正上一次，
 * 拿同一天的前一条当基准会算出间隔 0 天、差值 0），而它读时派生、不落库——改测量日期或改数值
 * 都会自然反映在下一次读的结果里。
 * <p>
 * 派生放在 Java 的单趟遍历里而不是 SQL：窗口函数本项目一处都没有，引入它只为一列差值是新负担；
 * 每行一次子查询则是 N+1。一次 {@code selectList} 就够，而它的排序（日期降序、同日 id 降序）
 * 正是「同一天的第一条即代表行」这个前提。
 */
@Service
public class BabyGrowthServiceImpl implements BabyGrowthService {

	private static final Logger log = LoggerFactory.getLogger(BabyGrowthServiceImpl.class);

	private final BabyGrowthMapper babyGrowthMapper;

	private final BabyMapper babyMapper;

	private final GrowthStandardDictMapper growthStandardDictMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public BabyGrowthServiceImpl(BabyGrowthMapper babyGrowthMapper, BabyMapper babyMapper,
			GrowthStandardDictMapper growthStandardDictMapper, StatisticsCache statisticsCache, Clock clock) {
		this.babyGrowthMapper = babyGrowthMapper;
		this.babyMapper = babyMapper;
		this.growthStandardDictMapper = growthStandardDictMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public List<BabyGrowthResponse> list(Long babyId) {
		Long familyId = currentFamilyId();
		List<BabyGrowth> rows = this.babyGrowthMapper.selectList(listScope(familyId, babyId));
		Map<DayKey, BabyGrowth> previous = previousByDay(rows);
		Map<Long, Baby> babies = babiesById(familyId);
		StandardTables tables = new StandardTables(this.growthStandardDictMapper);
		return rows.stream()
			.map(row -> toResponse(row, previous.get(dayKey(row)), babies.get(row.getBabyId()), tables))
			.toList();
	}

	@Override
	@Transactional
	public BabyGrowthResponse create(Long userId, BabyGrowthCreateRequest request) {
		Long familyId = currentFamilyId();
		requireBaby(familyId, request.babyId());
		assertMeasureDateUsable(request.measureDate());
		assertHeightOrWeight(request.heightCm(), request.weightKg());

		BabyGrowth record = new BabyGrowth();
		record.setFamilyId(familyId);
		record.setBabyId(request.babyId());
		record.setMeasureDate(request.measureDate());
		record.setHeightCm(request.heightCm());
		record.setWeightKg(request.weightKg());
		record.setHeadCm(request.headCm());
		record.setRemark(request.remark());
		record.setCreatedBy(userId);
		this.babyGrowthMapper.insert(record);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("新增身高体重记录 familyId={} growthId={} babyId={} measureDate={} operatorUserId={}", familyId,
				record.getId(), request.babyId(), request.measureDate(), userId);
		return respond(familyId, record);
	}

	@Override
	@Transactional
	public BabyGrowthResponse update(Long userId, Long id, BabyGrowthUpdateRequest request) {
		Long familyId = currentFamilyId();
		BabyGrowth record = requireRecord(familyId, id);
		// 记录记到了另一个宝宝头上要能挪回去，所以改后的 babyId 也得在本家庭里
		requireBaby(familyId, request.babyId());
		assertMeasureDateUsable(request.measureDate());
		assertHeightOrWeight(request.heightCm(), request.weightKg());

		record.setBabyId(request.babyId());
		record.setMeasureDate(request.measureDate());
		record.setHeightCm(request.heightCm());
		record.setWeightKg(request.weightKg());
		record.setHeadCm(request.headCm());
		record.setRemark(request.remark());
		// 整份覆盖必须走 overwrite：updateById 会跳过 null，「这次只称了体重」把身高清空就静默失效
		this.babyGrowthMapper.overwrite(record);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("修改身高体重记录 familyId={} growthId={} babyId={} measureDate={} operatorUserId={}", familyId, id,
				request.babyId(), request.measureDate(), userId);
		return respond(familyId, record);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		BabyGrowth record = requireRecord(familyId, id);
		// 没有守卫：一条量错的记录随时可删。删掉会改这个宝宝后面的「上一次」与曲线，所以失效不能省
		this.babyGrowthMapper.deleteById(record.getId());
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("删除身高体重记录 familyId={} growthId={} babyId={} operatorUserId={}", familyId, id,
				record.getBabyId(), userId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	/**
	 * 不查 enabled：归档的宝宝照旧量得了身高体重，历史记录也照旧改得动（§4.4.1 的归档 ≠ 删除）。
	 * 这里只拦「这个 babyId 不是本家庭的」。
	 */
	private void requireBaby(Long familyId, Long babyId) {
		Baby baby = this.babyMapper
			.selectOne(new LambdaQueryWrapper<Baby>().eq(Baby::getId, babyId).eq(Baby::getFamilyId, familyId));
		if (baby == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
	}

	private BabyGrowth requireRecord(Long familyId, Long id) {
		BabyGrowth record = this.babyGrowthMapper.selectOne(
				new LambdaQueryWrapper<BabyGrowth>().eq(BabyGrowth::getId, id).eq(BabyGrowth::getFamilyId, familyId));
		if (record == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return record;
	}

	private static LambdaQueryWrapper<BabyGrowth> listScope(Long familyId, Long babyId) {
		return new LambdaQueryWrapper<BabyGrowth>().eq(BabyGrowth::getFamilyId, familyId)
			.eq(babyId != null, BabyGrowth::getBabyId, babyId)
			.orderByDesc(BabyGrowth::getMeasureDate)
			.orderByDesc(BabyGrowth::getId);
	}

	/** 单行的增量与档位也要给：录入页提交后要立刻显示「较上次 +0.4 cm」，而「上一次」按日期链才定得下来。 */
	private BabyGrowthResponse respond(Long familyId, BabyGrowth row) {
		Map<DayKey, BabyGrowth> previous = previousByDay(
				this.babyGrowthMapper.selectList(listScope(familyId, row.getBabyId())));
		Map<Long, Baby> babies = babiesById(familyId);
		StandardTables tables = new StandardTables(this.growthStandardDictMapper);
		return toResponse(row, previous.get(dayKey(row)), babies.get(row.getBabyId()), tables);
	}

	/**
	 * 每个宝宝各自的「上一次」。按宝宝分链而不是全表一条链：不传 babyId 时列表是全家庭的，
	 * 跨宝宝比差值没有意义。
	 */
	private static Map<DayKey, BabyGrowth> previousByDay(List<BabyGrowth> rows) {
		Map<Long, List<BabyGrowth>> byBaby = new LinkedHashMap<>();
		for (BabyGrowth row : rows) {
			byBaby.computeIfAbsent(row.getBabyId(), key -> new ArrayList<>()).add(row);
		}
		Map<DayKey, BabyGrowth> previous = new HashMap<>();
		for (List<BabyGrowth> babyRows : byBaby.values()) {
			// 行已按 measure_date DESC, id DESC 排好，同一天里第一条就是 id 最大的那条
			Map<LocalDate, BabyGrowth> representative = new LinkedHashMap<>();
			for (BabyGrowth row : babyRows) {
				representative.putIfAbsent(row.getMeasureDate(), row);
			}
			BabyGrowth pending = null;
			for (BabyGrowth rep : representative.values()) {
				if (pending != null) {
					previous.put(dayKey(pending), rep);
				}
				pending = rep;
			}
		}
		return previous;
	}

	private static DayKey dayKey(BabyGrowth row) {
		return new DayKey(row.getBabyId(), row.getMeasureDate());
	}

	private static BabyGrowthResponse toResponse(BabyGrowth row, BabyGrowth previous, Baby baby,
			StandardTables tables) {
		return new BabyGrowthResponse(row.getId(), row.getBabyId(), row.getMeasureDate(), row.getHeightCm(),
				row.getWeightKg(), row.getHeadCm(), row.getRemark(), delta(row, previous),
				percentilesOf(baby, row, tables));
	}

	/**
	 * 一条记录五个指标的「百分之多少」（问题单：列表直接写 25%，不要 P50–P75）。
	 * 与统计页的 {@code BabyStatisticsServiceImpl.latestOf} 同一处 {@code GrowthPercentile} 算档位，
	 * 只是这里取具体百分位文本——同一份实测在列表与「当前体格」上不能给两个答案。
	 */
	private static BabyPercentiles percentilesOf(Baby baby, BabyGrowth row, StandardTables tables) {
		if (baby == null) {
			// 理论不达：行都查出来了，档案却缺（归档不会被摘出列表）。防御性给全空，不让越权判定钻进来。
			return new BabyPercentiles(null, null, null, null, null);
		}
		int ageMonths = BabyAge.monthsBetween(baby.getBirthDate(), row.getMeasureDate());
		BigDecimal age = BigDecimal.valueOf(ageMonths);
		return new BabyPercentiles(
				percentile(tables, baby.getGender(), METRIC_HEIGHT, age, row.getHeightCm()),
				percentile(tables, baby.getGender(), METRIC_WEIGHT, age, row.getWeightKg()),
				// 体重别身高按这一行的月龄选表而不是按今天：一条 20 个月时补录的记录，该用的是
				// 当时那张身长表。曲线那条反过来按今天选表（§4.4.3）。
				percentile(tables, baby.getGender(),
						GrowthPercentile.resolveMetric(METRIC_WEIGHT_HEIGHT, ageMonths), row.getHeightCm(),
						row.getWeightKg()),
				percentile(tables, baby.getGender(), METRIC_BMI, age,
						GrowthPercentile.bmi(row.getHeightCm(), row.getWeightKg())),
				percentile(tables, baby.getGender(), METRIC_HEAD_CIRCUMFERENCE, age, row.getHeadCm()));
	}

	/** 值为空或超出标准表覆盖范围都回 null：界面都出「—」，而就近取端点值会给出一个与表无关的百分位（§4.4.3）。 */
	private static String percentile(StandardTables tables, String gender, String metric, BigDecimal x,
			BigDecimal measured) {
		if (x == null || measured == null) {
			return null;
		}
		GrowthPercentile.Percentiles percentiles = GrowthPercentile
			.interpolate(tables.of(gender, GrowthPercentile.dictMetric(metric)), x);
		return percentiles == null ? null : GrowthPercentile.percentileTextOf(percentiles, measured);
	}

	/** 本家庭所有宝宝，按 id 索引。每行的档位判定要用性别与出生日期。 */
	private Map<Long, Baby> babiesById(Long familyId) {
		Map<Long, Baby> byId = new HashMap<>();
		for (Baby baby : this.babyMapper.selectList(new LambdaQueryWrapper<Baby>().eq(Baby::getFamilyId, familyId))) {
			byId.put(baby.getId(), baby);
		}
		return byId;
	}

	private static BabyGrowthDelta delta(BabyGrowth row, BabyGrowth previous) {
		if (previous == null) {
			return null;
		}
		return new BabyGrowthDelta(ChronoUnit.DAYS.between(previous.getMeasureDate(), row.getMeasureDate()),
				diff(row.getHeightCm(), previous.getHeightCm()), diff(row.getWeightKg(), previous.getWeightKg()),
				diff(row.getHeadCm(), previous.getHeadCm()));
	}

	/** 两行都有这一列才算，缺一边给 null——「较上次没量身高」与「较上次身高没变」是两件事（§4.4.2）。 */
	private static BigDecimal diff(BigDecimal current, BigDecimal previous) {
		return current == null || previous == null ? null : current.subtract(previous);
	}

	private void assertMeasureDateUsable(LocalDate measureDate) {
		if (measureDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "测量日期不能晚于今天");
		}
	}

	/** 跨字段所以 Bean Validation 表达不了（§3.4）：只称体重是常事，两项全空那一行记录没有含义。 */
	private static void assertHeightOrWeight(BigDecimal heightCm, BigDecimal weightKg) {
		if (heightCm == null && weightKg == null) {
			throw new BizException(ErrorCode.BAD_REQUEST, "身高与体重至少填一项");
		}
	}

	/** 自然日的代表行按 (宝宝, 日期) 定位：同一个宝宝同一天可能有多条，它们共享同一个「上一次」。 */
	private record DayKey(Long babyId, LocalDate measureDate) {
	}

	private static final String METRIC_HEIGHT = "HEIGHT";

	private static final String METRIC_WEIGHT = "WEIGHT";

	private static final String METRIC_WEIGHT_HEIGHT = "WEIGHT_HEIGHT";

	private static final String METRIC_BMI = "BMI";

	private static final String METRIC_HEAD_CIRCUMFERENCE = "HEAD_CIRCUMFERENCE";

	/**
	 * 一次列表请求内同一张标准表只查一次（与统计页同一个做法）：对几十行逐行各查一张表就是几十次查询，
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
