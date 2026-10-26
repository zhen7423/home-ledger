package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 编辑猫咪档案（§4.3.1）。与 {@link CatCreateRequest} 同形同校验：PATCH 是整份表单覆盖，
 * 所以可空栏位「从有到无」会真的写成 NULL，见 {@code CatMapper#overwrite}。
 */
public record CatUpdateRequest(
		@NotBlank(message = "请填写猫咪昵称") @Size(max = 12, message = "猫咪昵称最多 12 个字符") String name,
		@NotBlank(message = "请选择性别")
		@Pattern(regexp = "MALE|FEMALE|UNKNOWN", message = "性别只能是公、母或未知") String gender,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate birthday, boolean birthdayEstimated,
		@Size(max = 20, message = "品种最多 20 个字符") String breed,
		@DecimalMin(value = "0.01", message = "体重要大于 0") @DecimalMax(value = "999.99",
				message = "体重最大 999.99 kg") BigDecimal weightKg,
		@NotBlank(message = "请选择绝育状态")
		@Pattern(regexp = "YES|NO|UNKNOWN", message = "绝育状态只能是已绝育、未绝育或未知") String neutered,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
