package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 新建一条身高体重记录（§4.4.2）。三个量都选填，但身高与体重不能同时为空——那条跨字段规则
 * Bean Validation 表达不了，由服务层判。头围可以单独存在（有时只量头围）。
 */
public record BabyGrowthCreateRequest(@NotNull(message = "请选择宝宝") Long babyId,
		@NotNull(message = "请选择测量日期")
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate measureDate,
		@DecimalMin(value = "20.0", message = "身高应在 20–200 cm 之间")
		@DecimalMax(value = "200.0", message = "身高应在 20–200 cm 之间") BigDecimal heightCm,
		@DecimalMin(value = "1.00", message = "体重应在 1–100 kg 之间")
		@DecimalMax(value = "100.00", message = "体重应在 1–100 kg 之间") BigDecimal weightKg,
		@DecimalMin(value = "30.0", message = "头围应在 30–60 cm 之间")
		@DecimalMax(value = "60.0", message = "头围应在 30–60 cm 之间") BigDecimal headCm,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
