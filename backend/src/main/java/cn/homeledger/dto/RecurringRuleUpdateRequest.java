package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 编辑周期记账规则（§4.2.3），整体覆盖语义：所有字段都按 {@link RecurringRuleCreateRequest} 的约束重校一遍，
 * null 就是空，不做「null 表示不改」。
 * <p>
 * 与 Create 字段完全相同却另写一个 record：复用会把「创建」与「更新」的约束绑死，将来任一侧要加字段
 * 就得动另一侧。两个 record 各十行，重复的成本低于耦合的成本。周期参数直接复用 Create 里那个嵌套 record，
 * 它是纯数据结构、没有校验注解，再抄一份只是噪音。
 */
public record RecurringRuleUpdateRequest(
		@NotBlank(message = "请填写规则名称") @Size(max = 20, message = "规则名称最多 20 个字符") String name,
		@NotNull(message = "金额不能为空") @DecimalMin(value = "0.01", message = "金额必须大于 0") @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount,
		@NotNull(message = "请选择收支类别") Long categoryId, Long subCategoryId,
		@NotNull(message = "请选择支付方式") Long accountId,
		@NotBlank(message = "请选择周期类型") String periodType,
		@NotNull(message = "请填写周期参数") @Valid RecurringRuleCreateRequest.PeriodValue periodValue,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate startDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate endDate) {

}
