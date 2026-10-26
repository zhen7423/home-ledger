package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonInclude;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 新建周期记账规则（§4.2.3）。
 * <p>
 * 不含 type 字段：收支类型由服务端从所选大类读出，理由与 {@link TransactionCreateRequest} 同——
 * 让客户端另传一个 type，会造出「EXPENSE 的类别配一条 INCOME 规则」这种两头进不去统计的脏数据。
 * name 只用于列表展示，不进流水，所以没有名称快照；类别与支付方式存 id，改名后规则显示新名。
 */
public record RecurringRuleCreateRequest(
		@NotBlank(message = "请填写规则名称") @Size(max = 20, message = "规则名称最多 20 个字符") String name,
		@NotNull(message = "金额不能为空") @DecimalMin(value = "0.01", message = "金额必须大于 0") @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount,
		@NotNull(message = "请选择收支类别") Long categoryId, Long subCategoryId,
		@NotNull(message = "请选择支付方式") Long accountId,
		@NotBlank(message = "请选择周期类型") String periodType,
		@NotNull(message = "请填写周期参数") @Valid PeriodValue periodValue,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate startDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate endDate) {

	/**
	 * 四种 periodType 各用其中一部分字段，用扁平 record 而非四个子类：OpenAPI 里能一眼看全所有可能字段，
	 * 跨字段校验也只需一个 switch。这里只挂结构约束，取值范围由 service 按 periodType 判——
	 * Bean Validation 拿不到 periodType，写不出「WEEKLY 才允许 weekdays」这种规则。
	 * <p>
	 * 不加 @JsonInclude 的话，一条 MONTHLY 规则会把三个用不上的 null 一起存进 period_value，
	 * 加上整月的 31 天就贴着 VARCHAR(200) 的列宽了。
	 */
	@JsonInclude(JsonInclude.Include.NON_NULL)
	public record PeriodValue(Integer intervalDays, List<Integer> weekdays, List<Integer> daysOfMonth, Integer month) {

	}

}
