package cn.homeledger.dto;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 保存模块开关与 Tab 顺序（§3.2）。
 * <p>
 * <b>数组顺序即展示顺序</b>，不收客户端传的 sort_no：让客户端报序号等于把「有没有重号、有没有漏号、
 * 空档要不要压缩」这三个问题交给它回答，而服务端本来就能从数组位置推出唯一一份答案。
 * <p>
 * 未列出的模块沿用已存的值（没存过就用默认值），所以这不是「未提交即关闭」——提交半份不会静默关掉
 * 另外两个模块，那是最容易在拖拽交互里踩到的一种数据丢失。
 */
public record ModulePreferenceSaveRequest(@NotNull(message = "请提交模块开关") @Valid List<Item> items) {

	/**
	 * moduleKey 是 ModuleKey 的枚举名。不校验取值范围是因为服务端要在错误信息里说清是哪一个不认识，
	 * 交给 Bean Validation 只能得到一句「格式不对」，与 ReminderSettingSaveRequest 同一取舍。
	 */
	public record Item(@NotBlank(message = "模块不能为空") String moduleKey, boolean enabled) {

	}

}
