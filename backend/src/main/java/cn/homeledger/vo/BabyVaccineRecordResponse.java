package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条接种记录（§4.4.4）。
 * <p>
 * {@code planId} 为空是正常状态：自费疫苗的首次录入、名称写法不同的补种本来就没有对应行可回写。
 * {@code nextDate} 为空同样是正常状态——该疫苗在本宝宝清单里没有未完成剂次（§1.4 第 11 条）。
 */
public record BabyVaccineRecordResponse(Long id, Long babyId, Long planId, String vaccineName, String doseNo,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate givenDate, String clinic, String batchNo,
		String reaction, @JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate nextDate, String remark) {

}
