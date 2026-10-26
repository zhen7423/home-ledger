package cn.homeledger.dto;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 保存提醒开关（§4.5.1）。前端把设置页整份提交，未列出的类型保持原值不动——所以这里没有「删除」语义，
 * null 也不是「清空全部」，而是缺参数，直接被 @NotNull 挡成 400。
 */
public record ReminderSettingSaveRequest(@NotNull(message = "请提交要设置的提醒项") @Valid List<Item> items) {

	/**
	 * type 是 ReminderType 的枚举名。不校验取值范围是因为服务端要在错误信息里说清是哪一个不认识，
	 * 交给 Bean Validation 只能得到一句「格式不对」。
	 */
	public record Item(@NotBlank(message = "提醒类型不能为空") String type, boolean enabled) {

	}

}
