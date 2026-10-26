package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 当前罐的余量推算（§4.5.3 卡片的那五行）。字段与 {@code ConsumptionEstimate.Result} 一一对应，
 * 服务端只做一次「Result → 出参」的投影，客户端不重算。
 */
public record BabyFormulaEstimateResponse(long usedDays, int dailyAverage, int consumedGrams, int remainingGrams,
		int remainingPercent, int daysLeft, @JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate depletionDate,
		boolean fromHistory, boolean overEstimate) {

}