package cn.homeledger.dto;

import java.time.LocalDate;

import cn.homeledger.common.StatisticsCache;

/**
 * 猫粮消耗的筛选条件（§4.3.5）。只有起止两项——区间之外的条件在猫粮这一侧没有对象：
 * 没有金额、没有类别、没有成员，猫也不参与（消耗是家庭整体口径，§4.3.4）。
 * 因此不复用 {@link TransactionQueryRequest}：借一个十条筛选的 DTO 过来，等于在 OpenAPI 上挂出
 * 八个传了没用的参数。
 */
public record CatFoodStatisticsRequest(LocalDate startDate, LocalDate endDate) {

	/**
	 * 缓存键的条件部分（§5.1、第 23 轮 (3)：规范化由条件的主人负责）。
	 * 驱虫那条端点<b>没有</b>这个方法，它的规范化条件就是空串。
	 */
	public String canonicalConditions() {
		return StatisticsCache.joinConditions(text(startDate), text(endDate));
	}

	private static String text(Object value) {
		return value == null ? null : value.toString();
	}

}
