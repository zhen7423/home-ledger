package cn.homeledger.common;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

import cn.homeledger.entity.GrowthStandardDict;

/**
 * 百分位插值与档位判定（§4.4.3）——全项目<b>只此一处</b>把一次实测变成标准表上的位置。
 * <p>
 * 曲线图的三层带子、数据点提示的「P50–P75」、统计页的档位分布都从这里取值。全程 BigDecimal：
 * 表里存的是 DECIMAL(4,1) 与 DECIMAL(6,2)，转 double 会让「等于 P50」这类边界判定随浮点误差漂移。
 * <p>
 * {@link #bmi} 也住在这里：它是「用户量到的数」变成「能拿去查表的数」的最后一步，而它的两个调用方
 * （曲线上的 BMI 点与统计页的 BMI 档位）要回答的是同一个问题。
 * <p>
 * 不进 Spring 容器：无状态、无依赖，测试直接构造行列表调静态方法。
 */
public final class GrowthPercentile {

	private static final String WEIGHT_HEIGHT = "WEIGHT_HEIGHT";

	/** BMI 的取整位数（§4.4.3）：与标准表里 BMI 那两列的小数位一致。 */
	private static final int BMI_SCALE = 2;

	private static final String WEIGHT_LENGTH = "WEIGHT_LENGTH";

	/** 体重别身高换表的月龄分界（§4.4.3）：小于它用 WEIGHT_LENGTH，否则用 WEIGHT_HEIGHT */
	private static final int WEIGHT_LENGTH_MAX_MONTHS = 24;

	private static final int SCALE = 2;

	private static final String[] LEVEL_NAMES = { "P3", "P10", "P25", "P50", "P75", "P90", "P97" };

	/** 连字符是全角上下文的 U+2013（与需求文档 §4.4.3 的「P50–P75」逐字一致），前端按同一串匹配。 */
	private static final String BAND_DASH = "–";

	/**
	 * @param p3 第 3 百分位
	 * @param p10 第 10 百分位
	 * @param p25 第 25 百分位
	 * @param p50 中位数
	 * @param p75 第 75 百分位
	 * @param p90 第 90 百分位
	 * @param p97 第 97 百分位
	 */
	public record Percentiles(BigDecimal p3, BigDecimal p10, BigDecimal p25, BigDecimal p50, BigDecimal p75,
			BigDecimal p90, BigDecimal p97) {
	}

	private GrowthPercentile() {
	}

	/**
	 * 相邻两行线性插值，七档各自独立算，输出保留两位 {@code HALF_UP}。
	 * <p>
	 * {@code rows} 必须按 xValue 升序（{@code GrowthStandardDictMapper.selectByGenderAndMetric} 已排序）：
	 * 夹住 x 的两行就是列表里相邻的两行。
	 *
	 * @return x 落在首末行之外时 {@code null}——宝宝超出标准表覆盖范围，调用方据此把百分位留空并提示
	 *         「已超出标准表覆盖范围」，<b>不许</b>就近取端点值：那会给出一个与表毫无关系的百分位（§4.4.3）。
	 */
	public static Percentiles interpolate(List<GrowthStandardDict> rows, BigDecimal x) {
		// 少于两行给不出「夹住 x 的相邻两行」：单行退化表既无法插值也无从判越界，
		// 与「超出覆盖范围」同口径返回 null，免得 segment = last - 1 算成 -1 触发下标越界。
		if (rows == null || rows.size() < 2) {
			return null;
		}
		int last = rows.size() - 1;
		if (x.compareTo(rows.get(0).getXValue()) < 0 || x.compareTo(rows.get(last).getXValue()) > 0) {
			return null;
		}
		// x 等于末行时没有「上界」，取最后一对：t = 1 自然就落在末行的值上
		int segment = last - 1;
		for (int i = 0; i < last; i++) {
			if (x.compareTo(rows.get(i + 1).getXValue()) <= 0) {
				segment = i;
				break;
			}
		}
		GrowthStandardDict lower = rows.get(segment);
		GrowthStandardDict upper = rows.get(segment + 1);
		return new Percentiles(lerp(lower.getP3(), upper.getP3(), lower, upper, x),
				lerp(lower.getP10(), upper.getP10(), lower, upper, x),
				lerp(lower.getP25(), upper.getP25(), lower, upper, x),
				lerp(lower.getP50(), upper.getP50(), lower, upper, x),
				lerp(lower.getP75(), upper.getP75(), lower, upper, x),
				lerp(lower.getP90(), upper.getP90(), lower, upper, x),
				lerp(lower.getP97(), upper.getP97(), lower, upper, x));
	}

	/**
	 * 实测值落在哪一档：{@code "<P3"}、{@code "P25–P75"} 这类、{@code ">P97"}（§1.4 第 9 条）。
	 * <p>
	 * 恰好等于某档时归入以它为<b>下界</b>的那一段：等于 P50 是「P50–P75」而不是「P25–P50」。
	 */
	public static String bandOf(Percentiles percentiles, BigDecimal value) {
		BigDecimal[] levels = { percentiles.p3(), percentiles.p10(), percentiles.p25(), percentiles.p50(),
				percentiles.p75(), percentiles.p90(), percentiles.p97() };
		if (value.compareTo(levels[0]) < 0) {
			return "<" + LEVEL_NAMES[0];
		}
		if (value.compareTo(levels[LEVEL_NAMES.length - 1]) >= 0) {
			return ">" + LEVEL_NAMES[LEVEL_NAMES.length - 1];
		}
		int lower = 0;
		for (int i = 0; i < LEVEL_NAMES.length - 1; i++) {
			if (value.compareTo(levels[i]) >= 0) {
				lower = i;
			}
		}
		return LEVEL_NAMES[lower] + BAND_DASH + LEVEL_NAMES[lower + 1];
	}

	/** 七个锚点的百分位序号，与 {@code bandOf} 的 LEVEL_NAMES 一一对应（3 / 10 / 25 / 50 / 75 / 90 / 97）。 */
	private static final int[] PERCENTILE_ANCHORS = { 3, 10, 25, 50, 75, 90, 97 };

	/** 具体百分位的小数位（参考图上是 40.5%）：取整会让相邻两次测量看着一模一样。 */
	private static final int PERCENTILE_SCALE = 1;

	/**
	 * 实测值的具体百分位（问题单：列表直接写「多少%」，不要 P50–P75 这种区间）。
	 * <p>
	 * 落在相邻两个锚点之间时按差值线性插值：比如 P25 是 62.0、P50 是 66.0、实测 65.2，
	 * 就是 25 + (65.2 − 62.0) / (66.0 − 62.0) × 25 ≈ 45.0%，<b>取一位小数</b>后回 {@code "45.0%"}
	 * （参考图上是 40.5% 这个精度：取整会让相邻两次测量看着一模一样）。
	 * 低于 P3 / 高于 P97 回 {@code "<3%"} / {@code ">97%"}（上下界外没有更细的锚点了）。
	 *
	 * @return 超出标准表覆盖范围（interpolate 已回 null 的那一支）时为 null，调用方据此写「超范围」
	 */
	public static String percentileTextOf(Percentiles percentiles, BigDecimal value) {
		BigDecimal[] levels = { percentiles.p3(), percentiles.p10(), percentiles.p25(), percentiles.p50(),
				percentiles.p75(), percentiles.p90(), percentiles.p97() };
		if (value.compareTo(levels[0]) < 0) {
			return "<" + PERCENTILE_ANCHORS[0] + "%";
		}
		if (value.compareTo(levels[PERCENTILE_ANCHORS.length - 1]) >= 0) {
			return ">" + PERCENTILE_ANCHORS[PERCENTILE_ANCHORS.length - 1] + "%";
		}
		for (int i = 0; i < PERCENTILE_ANCHORS.length - 1; i++) {
			if (value.compareTo(levels[i + 1]) >= 0) {
				continue;
			}
			BigDecimal span = levels[i + 1].subtract(levels[i]);
			BigDecimal percent = BigDecimal.valueOf(PERCENTILE_ANCHORS[i]);
			if (span.signum() > 0) {
				BigDecimal ratio = value.subtract(levels[i]).divide(span, 4, RoundingMode.HALF_UP);
				percent = percent.add(ratio.multiply(
						BigDecimal.valueOf(PERCENTILE_ANCHORS[i + 1] - PERCENTILE_ANCHORS[i])));
			}
			return percent.setScale(PERCENTILE_SCALE, RoundingMode.HALF_UP).toPlainString() + "%";
		}
		return ">" + PERCENTILE_ANCHORS[PERCENTILE_ANCHORS.length - 1] + "%";
	}

	/** 体重别身高按年龄选表（§4.4.3）：小于 24 个月取 WEIGHT_LENGTH，否则 WEIGHT_HEIGHT；其余指标原样返回。 */
	public static String resolveMetric(String metric, int ageMonths) {
		if (!WEIGHT_HEIGHT.equals(metric)) {
			return metric;
		}
		return ageMonths < WEIGHT_LENGTH_MAX_MONTHS ? WEIGHT_LENGTH : WEIGHT_HEIGHT;
	}

	/**
	 * BMI = 体重 kg ÷ 身高 m²（§4.4.3）。曲线上的 BMI 点与统计页的 BMI 档位都调它：两处各写一遍
	 * 「先移位再相乘再除」迟早会分叉成一粗一细，而它们要回答的是同一个问题——这个宝宝胖瘦落在哪一档。
	 * <p>
	 * {@code movePointLeft(2)} 是精确移位，比除以 100 少一个舍入点。全程只在这一步除一次。
	 *
	 * @return 身高e或体重缺一边时为 {@code null}——缺一边就算不出来，那个点整条跳过（§4.4.3）
	 */
	public static BigDecimal bmi(BigDecimal heightCm, BigDecimal weightKg) {
		if (heightCm == null || weightKg == null) {
			return null;
		}
		BigDecimal heightM = heightCm.movePointLeft(2);
		return weightKg.divide(heightM.multiply(heightM), BMI_SCALE, RoundingMode.HALF_UP);
	}

	/**
	 * 对外指标名 → 字典里的 {@code metric} 值：三个年龄别指标在字典里带 {@code _AGE} 后缀（§7.2）。
	 * <p>
	 * 对外名与字典名不是一回事，这一步挪不掉：界面上的五个指标是 {@code HEIGHT} / {@code WEIGHT} /
	 * {@code BMI} / {@code WEIGHT_HEIGHT} / {@code HEAD_CIRCUMFERENCE}，而字典里躺着的是
	 * {@code HEIGHT_AGE} / {@code WEIGHT_AGE} / {@code BMI_AGE} / {@code WEIGHT_LENGTH} /
	 * {@code WEIGHT_HEIGHT} / {@code HEAD_CIRCUMFERENCE}。拿对外名直接查表会一行不中，
	 * 表现是整条曲线的百分位静默为空。
	 * <p>
	 * 它与 {@link #resolveMetric} 同住在这里，是因为两者都是「用户说的名字 ↔ 表的名字」的翻译，
	 * 分开住会让 {@code _AGE} 这个后缀的规则离 {@code WEIGHT_HEIGHT} 为什么没有后缀的规则太远。
	 */
	public static String dictMetric(String metric) {
		return switch (metric) {
			case "HEIGHT", "WEIGHT", "BMI" -> metric + "_AGE";
			default -> metric;
		};
	}

	/** 一次除到底：先通分再除，只在最后一步 scale 2 取整，中间不引入第二个舍入点。 */
	private static BigDecimal lerp(BigDecimal lowValue, BigDecimal highValue, GrowthStandardDict lower,
			GrowthStandardDict upper, BigDecimal x) {
		BigDecimal span = upper.getXValue().subtract(lower.getXValue());
		BigDecimal weighted = lowValue.multiply(span)
			.add(x.subtract(lower.getXValue()).multiply(highValue.subtract(lowValue)));
		return weighted.divide(span, SCALE, RoundingMode.HALF_UP);
	}

}
