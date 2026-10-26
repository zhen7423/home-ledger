package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 猫粮袋列表的一行（§8：每行除落库字段外必带 usageDays / dailyAverage / current 三个派生字段）。
 * <p>
 * 当前袋的 usageDays 与 dailyAverage 都是 null，这是 §8 的原话而不是省事：一袋还没吃完，
 * 它自己的「折算日均」就不是一个事实。「今天 − 开始日 + 1」那个已用天数在
 * {@link CatFoodEstimateResponse#usedDays} 上，它属于推算卡而不是列表行。
 * 客户端对两格 null 显示「—」而不是 0——显示 0 会被读成「这袋一天就吃完了」。
 * <p>
 * 这里没有 endDate 一列：界面上「这一袋什么时候结束」的答案就是下一行的开始日期，
 * 而当前袋的那一列只能显示今天，用户会读成「今天必须开新袋」。
 */
public record CatFoodBagResponse(Long id, String brand, int packGrams,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate startedDate, Long usageDays, Integer dailyAverage,
		boolean current, String remark) {

}
