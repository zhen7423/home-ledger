package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 手动新增一条应种项（§4.4.4 的自费项入口）。
 * <p>
 * 只有「疫苗名称 + 剂次 + 应种日期」三项：手动行不参与改生日重算，它的应种日期由用户定，
 * 跟着出生日期平移等于把用户填的那个日期悄悄改掉。落库时 {@code manual = 1}，只有它能被删除。
 * <p>
 * 撞上同宝宝同 (疫苗名称, 剂次) 的既有行即拒绝——匹配键必须唯一，否则接种记录回写时
 * 「回写到哪一行」没有定义（§1.4 第 13 条）。
 */
public record BabyVaccinePlanCreateRequest(@NotNull(message = "请选择宝宝") Long babyId,
		@NotBlank(message = "请填写疫苗名称") @Size(max = 30, message = "疫苗名称最多 30 个字符") String vaccineName,
		@NotBlank(message = "请填写剂次") @Size(max = 8, message = "剂次最多 8 个字符") String doseNo,
		@NotNull(message = "请选择应种日期")
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate dueDate) {

}
