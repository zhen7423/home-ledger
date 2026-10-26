package cn.homeledger.common;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import cn.homeledger.entity.GrowthStandardDict;

/**
 * §4.4.3 的百分位插值与区间判定。曲线图上的三层带子、数据点提示、统计页的分布，全都由这里定，
 * 所以两处边界（首末行、恰好等于某档）都要单独钉住。
 */
class GrowthPercentileTest {

	/** 两条相邻行，x 差 2，各档差 0.8/0.8/0.8/0.8/0.8/0.8：正中点因此都是好核对的 .X0 */
	private static final GrowthStandardDict LOWER = row("0.0", "2.80", "3.00", "3.20", "3.50", "3.70", "4.00", "4.20");

	private static final GrowthStandardDict UPPER = row("2.0", "3.60", "3.80", "4.00", "4.30", "4.50", "4.80", "5.00");

	private static final List<GrowthStandardDict> ROWS = List.of(LOWER, UPPER);

	@Test
	@DisplayName("x 命中某一行时七档就是那一行")
	void exactHitTakesThatRow() {
		GrowthPercentile.Percentiles hit = GrowthPercentile.interpolate(ROWS, new BigDecimal("0.0"));

		assertThat(hit).isNotNull();
		assertThat(hit.p3()).isEqualTo(new BigDecimal("2.80"));
		assertThat(hit.p50()).isEqualTo(new BigDecimal("3.50"));
		assertThat(hit.p97()).isEqualTo(new BigDecimal("4.20"));
	}

	@Test
	@DisplayName("x 落在两行正中时每档都是两行的算术平均")
	void midpointAveragesTheNeighbours() {
		GrowthPercentile.Percentiles mid = GrowthPercentile.interpolate(ROWS, new BigDecimal("1.0"));

		assertThat(mid).isNotNull();
		assertThat(mid.p3()).isEqualTo(new BigDecimal("3.20"));
		assertThat(mid.p10()).isEqualTo(new BigDecimal("3.40"));
		assertThat(mid.p25()).isEqualTo(new BigDecimal("3.60"));
		assertThat(mid.p50()).isEqualTo(new BigDecimal("3.90"));
		assertThat(mid.p75()).isEqualTo(new BigDecimal("4.10"));
		assertThat(mid.p90()).isEqualTo(new BigDecimal("4.40"));
		assertThat(mid.p97()).isEqualTo(new BigDecimal("4.60"));
	}

	@Test
	@DisplayName("x 小于首行返回 null，交给调用方说「已超出标准表覆盖范围」")
	void belowTheFirstRowIsNull() {
		assertThat(GrowthPercentile.interpolate(ROWS, new BigDecimal("-0.1"))).isNull();
	}

	@Test
	@DisplayName("x 大于末行返回 null")
	void aboveTheLastRowIsNull() {
		assertThat(GrowthPercentile.interpolate(ROWS, new BigDecimal("2.1"))).isNull();
	}

	@Test
	@DisplayName("恰好等于末行取末行，不是 null——末行本身在覆盖范围内")
	void exactLastRowIsInRange() {
		GrowthPercentile.Percentiles last = GrowthPercentile.interpolate(ROWS, new BigDecimal("2.0"));

		assertThat(last).isNotNull();
		assertThat(last.p3()).isEqualTo(new BigDecimal("3.60"));
		assertThat(last.p97()).isEqualTo(new BigDecimal("5.00"));
	}

	@Test
	@DisplayName("bandOf 的分支，等于某档时归入上一档的区间上界")
	void bandOfPicksTheUpperBandOnATie() {
		GrowthPercentile.Percentiles levels = new GrowthPercentile.Percentiles(new BigDecimal("3.00"),
				new BigDecimal("4.00"), new BigDecimal("5.00"), new BigDecimal("6.00"), new BigDecimal("7.00"),
				new BigDecimal("8.00"), new BigDecimal("9.00"));

		assertThat(GrowthPercentile.bandOf(levels, new BigDecimal("2.99"))).isEqualTo("<P3");
		assertThat(GrowthPercentile.bandOf(levels, new BigDecimal("3.00"))).isEqualTo("P3–P10");
		assertThat(GrowthPercentile.bandOf(levels, new BigDecimal("6.50"))).isEqualTo("P50–P75");
		assertThat(GrowthPercentile.bandOf(levels, new BigDecimal("6.00"))).as("等于 P50 归入 P50–P75").isEqualTo("P50–P75");
		assertThat(GrowthPercentile.bandOf(levels, new BigDecimal("8.50"))).isEqualTo("P90–P97");
		assertThat(GrowthPercentile.bandOf(levels, new BigDecimal("9.00"))).as("等于 P97 归入 >P97").isEqualTo(">P97");
	}

	@Test
	@DisplayName("体重别身高按 24 个月换表，其余指标原样返回")
	void resolveMetricSwitchesAtTwentyFourMonths() {
		assertThat(GrowthPercentile.resolveMetric("WEIGHT_HEIGHT", 23)).isEqualTo("WEIGHT_LENGTH");
		assertThat(GrowthPercentile.resolveMetric("WEIGHT_HEIGHT", 24)).isEqualTo("WEIGHT_HEIGHT");
		assertThat(GrowthPercentile.resolveMetric("HEIGHT_AGE", 30)).isEqualTo("HEIGHT_AGE");
	}

	@Test
	@DisplayName("对外指标名翻成字典里的 metric 值：只有三个年龄别指标带 _AGE 后缀")
	void dictMetricAddsTheAgeSuffix() {
		assertThat(GrowthPercentile.dictMetric("HEIGHT")).isEqualTo("HEIGHT_AGE");
		assertThat(GrowthPercentile.dictMetric("WEIGHT")).isEqualTo("WEIGHT_AGE");
		assertThat(GrowthPercentile.dictMetric("BMI")).isEqualTo("BMI_AGE");
		assertThat(GrowthPercentile.dictMetric("HEAD_CIRCUMFERENCE")).as("字典里就叫这个").isEqualTo("HEAD_CIRCUMFERENCE");
		assertThat(GrowthPercentile.dictMetric(GrowthPercentile.resolveMetric("WEIGHT_HEIGHT", 23)))
			.as("两种体重别身高的表名本来就是字典名，再叠一次后缀就查不到表了")
			.isEqualTo("WEIGHT_LENGTH");
		assertThat(GrowthPercentile.dictMetric(GrowthPercentile.resolveMetric("WEIGHT_HEIGHT", 24)))
			.isEqualTo("WEIGHT_HEIGHT");
	}

	@Test
	@DisplayName("插值结果保留两位小数：1.005 进到 1.01")
	void interpolationRoundsHalfUpToTwoDecimals() {
		List<GrowthStandardDict> tenths = List.of(row("0.0", "1.00", "2.00", "3.00", "4.00", "5.00", "6.00", "7.00"),
				row("2.0", "1.01", "2.00", "3.00", "4.00", "5.00", "6.00", "7.00"));

		GrowthPercentile.Percentiles result = GrowthPercentile.interpolate(tenths, new BigDecimal("1.0"));

		assertThat(result).isNotNull();
		assertThat(result.p3()).isEqualTo(new BigDecimal("1.01"));
	}

	@Test
	@DisplayName("只有一行的退化表给不出插值，返回 null 而不是越界")
	void singleRowTableIsNull() {
		assertThat(GrowthPercentile.interpolate(List.of(LOWER), new BigDecimal("0.0"))).isNull();
	}

	private static GrowthStandardDict row(String x, String p3, String p10, String p25, String p50, String p75, String p90,
			String p97) {
		GrowthStandardDict row = new GrowthStandardDict();
		row.setXValue(new BigDecimal(x));
		row.setP3(new BigDecimal(p3));
		row.setP10(new BigDecimal(p10));
		row.setP25(new BigDecimal(p25));
		row.setP50(new BigDecimal(p50));
		row.setP75(new BigDecimal(p75));
		row.setP90(new BigDecimal(p90));
		row.setP97(new BigDecimal(p97));
		return row;
	}

}
