package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 编辑一条接种记录（§4.4.4）。整份表单覆盖，不传的栏位即清空。
 * <p>
 * 允许改疫苗名称与剂次（§1.4 第 20 条）：录错了名称是最常见的编辑，不允许的话用户只能删了重建，
 * 而删除会连带把应种项退回 {@code PENDING}。服务端在同一事务内先撤销旧绑定、再按新键重新匹配。
 * <p>
 * {@code planId} 与新建同义：给了以它为准，不给就按新键自动匹配。
 */
public record BabyVaccineRecordUpdateRequest(@NotNull(message = "请选择宝宝") Long babyId,
		@NotBlank(message = "请填写疫苗名称") @Size(max = 30, message = "疫苗名称最多 30 个字符") String vaccineName,
		@NotBlank(message = "请填写剂次") @Size(max = 8, message = "剂次最多 8 个字符") String doseNo,
		@NotNull(message = "请选择接种日期")
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate givenDate, Long planId,
		@Size(max = 50, message = "接种机构最多 50 个字符") String clinic,
		@Size(max = 50, message = "疫苗批号最多 50 个字符") String batchNo,
		@Size(max = 200, message = "不良反应最多 200 个字符") String reaction,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate nextDate,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
