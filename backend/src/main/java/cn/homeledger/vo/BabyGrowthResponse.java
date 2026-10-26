package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条身高体重记录（§4.4.2 列表的一行）。
 * <p>
 * {@code deltaFromPrevious} 与 {@code percentiles} 都读时派生、不落库：改测量日期或改数值都会自然
 * 反映在下一次读的结果里，不存在「改了日期忘了刷增量」这条路径（§8 身高体重那行）。首条记录
 * {@code deltaFromPrevious} 为 null。
 * <p>
 * {@code percentiles} 是五个指标的「百分之多少」（问题单：列表直接写 25%，不要 P50–P75），口径与
 * 统计页「当前体格」同一处 {@code GrowthPercentile} 算出来——列表上每行看一眼就知道正不正常。
 * <p>
 * 三个度量列都不带单位后缀的换算——列名已把单位写死（cm / kg），前端不做换算只做格式化。
 */
public record BabyGrowthResponse(Long id, Long babyId,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate measureDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal heightCm,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal weightKg,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal headCm, String remark,
		BabyGrowthDelta deltaFromPrevious, BabyPercentiles percentiles) {

	/**
	 * 五个指标各自的百分位（问题单：直接写「多少%」）。值为 {@code "25%"} / {@code "<3%"} /
	 * {@code ">97%"}；空有两种原因：这一条没量那个量、或超出标准表覆盖范围（§4.4.3）。
	 */
	public record BabyPercentiles(String height, String weight, String weightHeight, String bmi,
			String headCircumference) {

	}

}