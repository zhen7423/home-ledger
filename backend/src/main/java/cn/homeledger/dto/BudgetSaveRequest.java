package cn.homeledger.dto;

import java.math.BigDecimal;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 三维度预算的整体替换（§4.2.4）。
 * <p>
 * 这里没有任何 id：保存不是「改哪一行」，而是「这个月这家人的预算就是这几条」。所以每次保存之后所有行的
 * id 都会变，前端不能拿它做任何键（改预算是整份重提，不存在按 id PATCH 的接口）。
 */
public record BudgetSaveRequest(@Valid List<Item> items) {

	/**
	 * 一个维度一行。items 为 null 表示清空这个家庭的全部预算，空列表同样清空——那是「我们决定这个月不设预算」
	 * 的正常表达，不是错误。
	 * <p>
	 * bucketKey 不在这里：它由后端从 scope + categoryId + memberUserId 派生。收客户端传的唯一性键，等于把
	 * 防重的责任交给调用方，而它一旦传错就能绕开 uk_budget_bucket 塞进两行同维度的预算。
	 */
	public record Item(@NotBlank(message = "请选择预算维度") String scope, Long categoryId, Long memberUserId,
			@NotNull(message = "预算金额不能为空") @DecimalMin(value = "0.01", message = "预算金额必须大于 0") BigDecimal amount) {

	}

}
