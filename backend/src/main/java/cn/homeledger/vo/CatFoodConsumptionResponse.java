package cn.homeledger.vo;

import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * §4.3.5 前四块视图（消耗概览卡 + 品牌占比 + 逐月趋势 + 每袋用时）一次返回。
 * <p>
 * {@code startDate} / {@code endDate} 回显的是<b>补齐并截断之后</b>服务端真正用的区间（同
 * {@link TransactionSummaryResponse} 的口径），而不是客户端传什么回什么：区间天数与日均都以这两个值为分母，
 * 界面上「日均」与「总克数 ÷ 天数」必须能互相核对得上。
 * <p>
 * {@code dailyAverage} 是<b>区间日均</b>（总克数 ÷ 区间天数），与余量卡那个由已完成袋折算的
 * {@link CatFoodEstimateResponse#dailyAverage} 是两个数，同一份数据里可以差很远（§4.3.4 与 §4.3.5 各说一件事）。
 */
public record CatFoodConsumptionResponse(
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate startDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate endDate, int days, int totalGrams, int dailyAverage,
		int finishedBags, List<CatBrandSlice> brandBreakdown, List<CatMonthGrams> monthlyTrend,
		List<CatFoodBagResponse> bagUsages) {

}
