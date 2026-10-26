package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 新建宝宝档案（§4.4.1）。出生身高体重选填——建档时手边未必有出生证明，
 * 它们只是生长曲线的第一组点，之后由身高体重记录接着写。
 */
public record BabyCreateRequest(
		@NotBlank(message = "请填写宝宝姓名") @Size(max = 12, message = "宝宝姓名最多 12 个字符") String name,
		@NotBlank(message = "请选择性别")
		@Pattern(regexp = "MALE|FEMALE", message = "性别只能是男或女") String gender,
		@NotNull(message = "请选择出生日期")
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate birthDate,
		@DecimalMin(value = "20.0", message = "出生身高应在 20–200 cm 之间")
		@DecimalMax(value = "200.0", message = "出生身高应在 20–200 cm 之间") BigDecimal birthHeight,
		@DecimalMin(value = "1.00", message = "出生体重应在 1–100 kg 之间")
		@DecimalMax(value = "100.00", message = "出生体重应在 1–100 kg 之间") BigDecimal birthWeight,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
