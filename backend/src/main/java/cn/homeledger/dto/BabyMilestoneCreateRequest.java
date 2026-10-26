package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 新增一条里程碑（§4.4.5）。
 * <p>
 * {@code title} 不加字典校验：内置常用项是前端一份常量清单，用户点它和自由输入落的是同一列，
 * 服务端不必知道「哪些算内置」。
 */
public record BabyMilestoneCreateRequest(@NotNull(message = "请选择宝宝") Long babyId,
		@NotNull(message = "请选择发生日期")
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate occurDate,
		@NotBlank(message = "请填写标题") @Size(max = 30, message = "标题最多 30 个字符") String title,
		@Size(max = 200, message = "描述最多 200 个字符") String description) {

}
