package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 当前袋的余量推算（§4.3.4 卡片的那五行）。字段与 {@code ConsumptionEstimate.Result} 一一对应，
 * 只多一个 usedDays：Result 把 usedDays 当输入，而卡片要说「已用 11 天」，那句话得有出处。
 * <p>
 * 这里的 dailyAverage 是 §4.3.4 那个「当前袋推算的输入」，与统计概览卡的区间日均不是一个数——
 * 后者是 §4.3.5 那三项概览里的「日均克数」。
 */
public record CatFoodEstimateResponse(long usedDays, int dailyAverage, int consumedGrams, int remainingGrams,
		int remainingPercent, int daysLeft,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate depletionDate, boolean fromHistory,
		boolean overEstimate) {

}
