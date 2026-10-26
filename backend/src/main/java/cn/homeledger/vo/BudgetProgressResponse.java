package cn.homeledger.vo;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonFormat;

import cn.homeledger.common.BudgetLevel;

/**
 * 一条预算在某个月份里的执行情况（§4.2.4）。
 * <p>
 * 不带 id：进度是按 (scope, categoryId, memberUserId) 现算的，而整体替换语义下 id 每次保存都变，
 * 把它交给前端只会诱导前端拿它做缓存键。
 *
 * @param used 该维度这个月已记的支出。只算支出：预算是「花钱的额度」，收入不抵进来
 * @param remaining 预算减已用，<b>可以是负数</b>。「还剩 -320 元」比「还剩 0 元」信息量大得多，
 *            怎么显示由 level 决定
 * @param usedPercent 向下取整到整数，所以 79.6% 显示成 79；档位判定用的是没取整的比值，两者分开算
 * @param remainingDays 该月还剩几天。只有查当前月时非零
 */
public record BudgetProgressResponse(String month, String scope, Long categoryId, String categoryName,
		Long memberUserId, String memberName,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal used,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal remaining, int usedPercent, BudgetLevel level,
		int remainingDays) {

}
