package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 编辑一条就诊记录（§4.4.5）。整份表单覆盖，除就诊日期外每一列不传即清空。
 * <p>
 * 没有 {@code babyId}：与里程碑同理，归属靠建时定，多传的键被 Jackson 忽略。
 */
public record BabyMedicalUpdateRequest(
		@NotNull(message = "请选择就诊日期")
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate visitDate,
		@Size(max = 50, message = "医院最多 50 个字符") String hospital,
		@Size(max = 30, message = "科室最多 30 个字符") String department,
		@Size(max = 200, message = "诊断最多 200 个字符") String diagnosis,
		@Size(max = 200, message = "用药最多 200 个字符") String medicine,
		@DecimalMin(value = "0", message = "费用不能为负数")
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal costAmount,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
