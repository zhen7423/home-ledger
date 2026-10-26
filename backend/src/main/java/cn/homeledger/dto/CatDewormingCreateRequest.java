package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 新建一条驱虫记录（§4.3.3）。
 * <p>
 * nextDate 可空：<b>空表示「按周期帮我算」，非空表示「我就要这一天」</b>。服务端对非空值照抄不回算，
 * 这是 §4.3.3「用户可手动覆盖」与 §8 那行的原话。落成 DDL 的 NOT NULL 由服务层保证：要么用户给，要么算得出。
 */
public record CatDewormingCreateRequest(@NotNull(message = "请选择猫咪") Long catId,
		@NotBlank(message = "请选择驱虫类型") @Pattern(regexp = "INTERNAL|EXTERNAL", message = "驱虫类型只能是内驱或外驱") String type,
		@JsonFormat(shape = JsonFormat.Shape.STRING) @NotNull(message = "请选择驱虫日期") LocalDate doneDate,
		@NotBlank(message = "请填写药品名称") @Size(max = 30, message = "药品名称最多 30 个字符") String medicine,
		@Size(max = 50, message = "规格/剂量最多 50 个字符") String dosage,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate nextDate,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
