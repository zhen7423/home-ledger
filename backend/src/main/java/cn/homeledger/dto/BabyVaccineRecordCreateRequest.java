package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 新建一条接种记录（§4.4.4）。
 * <p>
 * {@code planId} 是补种、异地接种、名称写法不一致时的落点：给了就以它为准，不按名称自动匹配。
 * 不给则拿「疫苗名称 + 剂次」去该宝宝的应种清单里找，匹配不到也不报错——自费疫苗的首次录入
 * 本来就没有对应行可回写。
 * <p>
 * {@code nextDate} 留空时由服务端按该疫苗下一个 {@code PENDING} 剂次的应种日期推算（§1.4 第 11 条）；
 * 给了就照抄。两种情形在 JSON 上都表现为「没给」，所以前端没有「清空下一针日期」这个操作。
 */
public record BabyVaccineRecordCreateRequest(@NotNull(message = "请选择宝宝") Long babyId,
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
