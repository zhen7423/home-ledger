package cn.homeledger.dto;

import java.time.LocalDate;
import java.time.LocalTime;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 修改一罐奶粉（§4.5.3）。与新建同形，整份覆盖：预估日均、备注、开罐时间不传即清空。
 */
public record BabyFormulaBagUpdateRequest(
		@NotBlank(message = "请填写奶粉品牌") @Size(max = 20, message = "奶粉品牌最多 20 个字符") String brand,
		@NotNull(message = "请填写包装规格") @Min(value = 1, message = "包装规格至少 1 克") @Max(value = 100000,
				message = "包装规格最大 100000 克") Integer packGrams,
		@JsonFormat(shape = JsonFormat.Shape.STRING) @NotNull(message = "请选择开罐日期") LocalDate startedDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalTime startedTime,
		@Min(value = 1, message = "预计每天克数至少 1 克") @Max(value = 2000, message = "预计每天克数最大 2000 克") Integer estimatedDailyGrams,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}