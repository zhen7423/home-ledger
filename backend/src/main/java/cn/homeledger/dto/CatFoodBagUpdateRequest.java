package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 修改一袋猫粮（§4.3.2）。与 {@link CatFoodBagCreateRequest} 同形同校验：PATCH 是整份表单覆盖，
 * 所以「把备注清空」会真的写成 NULL，见 {@code CatFoodBagMapper#overwrite}。
 */
public record CatFoodBagUpdateRequest(
		@NotBlank(message = "请填写猫粮品牌") @Size(max = 20, message = "猫粮品牌最多 20 个字符") String brand,
		@NotNull(message = "请填写包装规格") @Min(value = 1, message = "包装规格至少 1 克") @Max(value = 100000,
				message = "包装规格最大 100000 克") Integer packGrams,
		@JsonFormat(shape = JsonFormat.Shape.STRING) @NotNull(message = "请选择开始喂养日期") LocalDate startedDate,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
