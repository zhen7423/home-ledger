package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BabyAge;
import cn.homeledger.common.BabyDisclaimers;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.GrowthPercentile;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyGrowth;
import cn.homeledger.entity.GrowthStandardDict;
import cn.homeledger.mapper.BabyGrowthMapper;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.GrowthStandardDictMapper;
import cn.homeledger.service.BabyCurveService;
import cn.homeledger.vo.BabyCurvePoint;
import cn.homeledger.vo.BabyCurveResponse;
import cn.homeledger.vo.GrowthStandardRowResponse;

/**
 * §4.4.3 生长曲线。插值与档位判定都委托 {@link GrowthPercentile}，这里只做三件事：
 * 把用户选的指标翻成字典里的表名、把该宝宝的实测行整理成点、把标准表原样搬进响应。
 * <p>
 * 选表用的月龄是按<b>今天</b>算的，不是按测量日期（§4.4.3）：一个 25 个月的宝宝回头补录 20 个月时
 * 量身长的那条记录，读的仍是 2 岁以上的表。按测量日期逐点选表听着更贴，但那样同一张响应里会出现
 * 两张标准表——它们的横轴在 75–100 cm 之间重叠，画在一张图上就是两条互相矛盾的参考带。
 * <p>
 * 实测点每天只留 id 最大的那条，与「较上一次」同一条口径（§4.4.2）：列表页的代表行与曲线上的
 * 代表点必须是同一条记录，否则同一天补录第二条之后，两处会各显示一个值。
 */
@Service
public class BabyCurveServiceImpl implements BabyCurveService {

	private static final String DEFAULT_METRIC = "HEIGHT";

	private static final String METRIC_HEIGHT = "HEIGHT";

	private static final String METRIC_WEIGHT = "WEIGHT";

	private static final String METRIC_WEIGHT_HEIGHT = "WEIGHT_HEIGHT";

	private static final String METRIC_BMI = "BMI";

	private static final String METRIC_HEAD_CIRCUMFERENCE = "HEAD_CIRCUMFERENCE";

	private final BabyMapper babyMapper;

	private final BabyGrowthMapper babyGrowthMapper;

	private final GrowthStandardDictMapper growthStandardDictMapper;

	private final Clock clock;

	public BabyCurveServiceImpl(BabyMapper babyMapper, BabyGrowthMapper babyGrowthMapper,
			GrowthStandardDictMapper growthStandardDictMapper, Clock clock) {
		this.babyMapper = babyMapper;
		this.babyGrowthMapper = babyGrowthMapper;
		this.growthStandardDictMapper = growthStandardDictMapper;
		this.clock = clock;
	}

	@Override
	public BabyCurveResponse curve(Long babyId, String metric) {
		Long familyId = AuthContextHolder.require().familyId();
		Baby baby = requireBaby(familyId, babyId);
		String selected = metric == null ? DEFAULT_METRIC : metric;
		assertMetricSupported(selected);
		int ageMonths = BabyAge.monthsBetween(baby.getBirthDate(), LocalDate.now(this.clock));
		String standardMetric = GrowthPercentile.resolveMetric(selected, ageMonths);
		List<GrowthStandardDict> standard = this.growthStandardDictMapper.selectByGenderAndMetric(baby.getGender(),
				GrowthPercentile.dictMetric(standardMetric));
		List<BabyCurvePoint> points = pointsOf(familyId, baby, selected, standard);
		return new BabyCurveResponse(babyId, selected, standardMetric, points,
				standard.stream().map(BabyCurveServiceImpl::toRow).toList(), BabyDisclaimers.STANDARD);
	}

	/**
	 * 非法 metric 不能静默降级成空曲线：不拦的话 measuredOf 全部 miss、字典查到不存在的表，
	 * 最后给一个 200 + points:[] + standard:[]，前端把它渲染成「超出标准表覆盖范围」——
	 * 把契约错误伪装成业务空态，排障时既看不到 400 也看不到日志。宁可直接 400。
	 */
	private static void assertMetricSupported(String metric) {
		if (!METRIC_HEIGHT.equals(metric) && !METRIC_WEIGHT.equals(metric) && !METRIC_WEIGHT_HEIGHT.equals(metric)
				&& !METRIC_BMI.equals(metric) && !METRIC_HEAD_CIRCUMFERENCE.equals(metric)) {
			throw new BizException(ErrorCode.BAD_REQUEST, "不支持的生长指标：" + metric);
		}
	}

	private List<BabyCurvePoint> pointsOf(Long familyId, Baby baby, String metric, List<GrowthStandardDict> standard) {
		// 显式带 familyId：虽然 baby_growth 走 TenantLineInnerInterceptor 会自动改写、且 baby 已验过归属，
		// 但本模块其余查询都把手写 family_id 亮出来给读代码的人看（双重防线），这里不留特例。
		List<BabyGrowth> rows = this.babyGrowthMapper.selectList(
				new LambdaQueryWrapper<BabyGrowth>().eq(BabyGrowth::getFamilyId, familyId)
					.eq(BabyGrowth::getBabyId, baby.getId())
					.orderByAsc(BabyGrowth::getMeasureDate)
					.orderByAsc(BabyGrowth::getId));
		// 升序遍历，同一天里最后写进去的那条就是 id 最大的那条
		Map<LocalDate, BabyGrowth> representative = new LinkedHashMap<>();
		for (BabyGrowth row : rows) {
			representative.put(row.getMeasureDate(), row);
		}
		List<BabyCurvePoint> points = new ArrayList<>();
		for (BabyGrowth row : representative.values()) {
			int ageMonths = BabyAge.monthsBetween(baby.getBirthDate(), row.getMeasureDate());
			BigDecimal x = xOf(metric, row, ageMonths);
			BigDecimal measured = measuredOf(metric, row);
			// 整条跳过而不是留个空点：这不是「被省略的实测点」，而是这一指标在这一行没有值（§4.4.3）
			if (x == null || measured == null) {
				continue;
			}
			GrowthPercentile.Percentiles percentiles = GrowthPercentile.interpolate(standard, x);
			points.add(new BabyCurvePoint(row.getMeasureDate(), ageMonths, x, measured,
					percentiles == null ? null : GrowthPercentile.bandOf(percentiles, measured)));
		}
		return points;
	}

	/** 四个年龄别指标的横轴是月龄，体重别身高的横轴是身高 cm（§1.4 第 15 条）。 */
	private static BigDecimal xOf(String metric, BabyGrowth row, int ageMonths) {
		return METRIC_WEIGHT_HEIGHT.equals(metric) ? row.getHeightCm() : BigDecimal.valueOf(ageMonths);
	}

	private static BigDecimal measuredOf(String metric, BabyGrowth row) {
		return switch (metric) {
			case METRIC_HEIGHT -> row.getHeightCm();
			case METRIC_WEIGHT -> row.getWeightKg();
			case METRIC_BMI -> GrowthPercentile.bmi(row.getHeightCm(), row.getWeightKg());
			case METRIC_WEIGHT_HEIGHT -> row.getWeightKg();
			case METRIC_HEAD_CIRCUMFERENCE -> row.getHeadCm();
			default -> null;
		};
	}

	private static GrowthStandardRowResponse toRow(GrowthStandardDict row) {
		return new GrowthStandardRowResponse(row.getXValue(), row.getP3(), row.getP10(), row.getP25(), row.getP50(),
				row.getP75(), row.getP90(), row.getP97());
	}

	/** 不查 enabled：归档的宝宝照旧看得见他的曲线（§4.4.1 的归档 ≠ 删除），这里只拦跨家庭。 */
	private Baby requireBaby(Long familyId, Long babyId) {
		Baby baby = this.babyMapper
			.selectOne(new LambdaQueryWrapper<Baby>().eq(Baby::getId, babyId).eq(Baby::getFamilyId, familyId));
		if (baby == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return baby;
	}

}
