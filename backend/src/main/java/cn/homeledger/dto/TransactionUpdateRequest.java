package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 编辑一笔流水。与新建同形，整份表单覆盖式提交。
 * <p>
 * 刻意不做「null 表示不改」的局部更新：小类与备注本来就可以留空，若 null 意味着保持原值，
 * 用户想把小类从「打车」改回「未细分」就再也发不出去，只能给它编一个表示清空的魔数。
 * 类别是否变化由服务端与原行比对，据此决定要不要刷新名称快照（§5.5）。
 */
public record TransactionUpdateRequest(
		@NotNull(message = "金额不能为空") @DecimalMin(value = "0.01", message = "金额必须大于 0") @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount,
		@NotNull(message = "请选择收支类别") Long categoryId, Long subCategoryId,
		@NotNull(message = "请选择支付方式") Long accountId,
		@NotNull(message = "请选择记账日期") @JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate bizDate,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
