package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 新建类别（§4.2.2）。parentId 为空即建大类，非空即在其下建小类。
 * <p>
 * 长度只约束到 8（小类上限）：大类 ≤ 6 是条件校验，Bean Validation 表达不了，由 CategoryService 按
 * parentId 是否为空分别判。
 */
public record CategoryCreateRequest(
		@NotBlank(message = "请选择收支类型") @Pattern(regexp = "EXPENSE|INCOME", message = "收支类型只能是 EXPENSE 或 INCOME") String type,
		Long parentId,
		@NotBlank(message = "类别名称不能为空") @Size(max = 8, message = "类别名称最多 8 个字符") String name) {

}
