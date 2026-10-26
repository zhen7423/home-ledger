package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 新开一袋猫粮（§4.3.2）。
 * <p>
 * packGrams 用 {@code Integer} 而不是 {@code int}：基本类型下「字段整个没传」会被 Jackson 落成 0，
 * 于是用户看到的报错是「包装规格至少 1 克」，而他明明什么都没填。上限 100000 这一条不是「够用就行」，
 * 它是 {@code ConsumptionEstimate} 里 {@code today.plusDays(daysLeft)} 不抛 {@code DateTimeException} 的前提。
 */
public record CatFoodBagCreateRequest(
		@NotBlank(message = "请填写猫粮品牌") @Size(max = 20, message = "猫粮品牌最多 20 个字符") String brand,
		@NotNull(message = "请填写包装规格") @Min(value = 1, message = "包装规格至少 1 克") @Max(value = 100000,
				message = "包装规格最大 100000 克") Integer packGrams,
		@JsonFormat(shape = JsonFormat.Shape.STRING) @NotNull(message = "请选择开始喂养日期") LocalDate startedDate,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
