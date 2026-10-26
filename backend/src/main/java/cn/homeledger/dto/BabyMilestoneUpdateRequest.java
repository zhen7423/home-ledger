package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 编辑一条里程碑（§4.4.5）。整份表单覆盖，不传的 {@code description} 即清空。
 * <p>
 * 没有 {@code babyId}：里程碑归属靠建时定，多传的键被 Jackson 忽略。允许改归属会让它从一只宝宝的成长轴
 * 悄悄跳到另一只的，而界面上没有任何地方提示这件事。
 */
public record BabyMilestoneUpdateRequest(
		@NotNull(message = "请选择发生日期")
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate occurDate,
		@NotBlank(message = "请填写标题") @Size(max = 30, message = "标题最多 30 个字符") String title,
		@Size(max = 200, message = "描述最多 200 个字符") String description) {

}
