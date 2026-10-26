package cn.homeledger.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 设置 / 清除计划接种日期（2026-10-26 需求②，V20261026140000）。
 * <p>
 * {@code plannedDate} 为 null 表示清除覆盖、回到程序表应种日期。已接种的行会被服务层拒绝。
 */
public record BabyVaccinePlanPlannedDateRequest(
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate plannedDate) {

}
