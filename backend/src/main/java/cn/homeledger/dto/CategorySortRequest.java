package cn.homeledger.dto;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

/**
 * 拖拽排序（§4.2.2）。orderedIds 是同一个父级、同一收支类型下的同级兄弟按新顺序排开的 id 列表，
 * 服务端据此把 sort_no 重写为 1…n。
 */
public record CategorySortRequest(
		@NotBlank(message = "请选择收支类型") @Pattern(regexp = "EXPENSE|INCOME", message = "收支类型只能是 EXPENSE 或 INCOME") String type,
		Long parentId, @NotNull @NotEmpty(message = "排序列表不能为空") List<Long> orderedIds) {

}
