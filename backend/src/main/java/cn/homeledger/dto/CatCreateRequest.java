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
 * 新建猫咪档案（§4.3.1）。生日可以只给年月：{@code birthdayEstimated = true} 时前端把日期选择器
 * 换成「年 + 月」两个控件，落到 {@code birthday} 的是<b>该月 1 日</b>，日没有含义但 {@code estimated}
 * 那一列有——不这么折一次的话，「生日」这一列要么允许 NULL（于是年龄展示处处判空），
 * 要么允许未来的日（没有意义）。
 */
public record CatCreateRequest(
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
