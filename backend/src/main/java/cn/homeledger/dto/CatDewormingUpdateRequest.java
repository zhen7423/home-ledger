package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 修改一条驱虫记录（§4.3.3）。与 {@link CatDewormingCreateRequest} 同形同校验：PATCH 是整份表单覆盖，
 * 所以「把规格/剂量清空」会真的写成 NULL，见 {@code CatDewormingMapper#overwrite}。
 * <p>
 * nextDate 的可空含义与新建时一致——传空就是「这次帮我按周期算」，不是「保持原值不变」。
 */
public record CatDewormingUpdateRequest(@NotNull(message = "请选择猫咪") Long catId,
		@NotBlank(message = "请选择驱虫类型") @Pattern(regexp = "INTERNAL|EXTERNAL", message = "驱虫类型只能是内驱或外驱") String type,
		@JsonFormat(shape = JsonFormat.Shape.STRING) @NotNull(message = "请选择驱虫日期") LocalDate doneDate,
		@NotBlank(message = "请填写药品名称") @Size(max = 30, message = "药品名称最多 30 个字符") String medicine,
		@Size(max = 50, message = "规格/剂量最多 50 个字符") String dosage,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate nextDate,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
