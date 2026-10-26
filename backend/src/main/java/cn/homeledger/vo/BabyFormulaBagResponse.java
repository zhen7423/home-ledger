package cn.homeledger.vo;

import java.time.LocalDate;
import java.time.LocalTime;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 奶粉开罐列表的一行（§4.5.3：每行除落库字段外必带 usageDays / dailyAverage / current 三个派生字段）。
 * <p>
 * 当前罐的 usageDays 与 dailyAverage 都是 null，与猫粮袋同一句原话：一罐还没用完，它自己的
 * 「折算日均」就不是一个事实。「今天 − 开始日 + 1」那个已用天数在
 * {@link BabyFormulaEstimateResponse#usedDays} 上，它属于推算卡而不是列表行。
 * 客户端对两格 null 显示「—」而不是 0——显示 0 会被读成「这罐一天就喝完了」。
 * <p>
 * startedTime 选填（V20261026130000）：开罐具体时刻，纯展示；null 时客户端只显示日期。
 */
public record BabyFormulaBagResponse(Long id, String brand, int packGrams,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate startedDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalTime startedTime, Integer estimatedDailyGrams,
		Long usageDays, Integer dailyAverage, boolean current, String remark) {

}