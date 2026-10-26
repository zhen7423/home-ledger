package cn.homeledger.vo;

import java.util.List;

/**
 * 奶粉消耗统计（§4.5.3 的 GET /statistics/baby/formula）。
 * <p>
 * 「区间日均」与 {@link BabyFormulaEstimateResponse#dailyAverage}（当前罐推算的输入）是两个数，
 * 与猫粮的同一句说明一致（§4.3.4 与 §4.3.5 各说一件事）。月趋势按自然月分摊每罐的克数，
 * 口径与猫咪统计的 {@code CatFoodConsumptionResponse#monthlyTrend} 同源（§4.5.3）。
 */
public record BabyFormulaStatisticsResponse(int totalGrams, long totalDays, int dailyAverage,
		List<BabyFormulaMonthGrams> monthlyTrend) {

	/** 一个自然月的奶粉消耗克数。month 是 {@code yyyy-MM}。 */
	public record BabyFormulaMonthGrams(String month, int grams) {
	}

}