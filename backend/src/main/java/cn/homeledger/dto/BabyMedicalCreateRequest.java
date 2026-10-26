package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 新增一条就诊记录（§4.4.5）。除宝宝与就诊日期外全是选填，带一次孩子看病未必记得住科室与批号。
 * <p>
 * {@code costAmount} 只是记录，不同步生成流水（§4.4.5）：种下同步会让删掉就诊记录时那条流水留在账上，
 * 或者反过来被删掉，两边都不该由另一边决定。
 */
public record BabyMedicalCreateRequest(@NotNull(message = "请选择宝宝") Long babyId,
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
