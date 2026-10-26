package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 应种清单的一行（§4.4.4）。
 * <p>
 * {@code status} 是落库四态，{@code displayStatus} 是「待接种 / 即将接种 / 逾期」那一层的展示态。
 * 两个都给：界面按 {@code displayStatus} 上色，但「标记跳过 / 撤销」这些动作要判的是落库态，
 * 让前端从展示态反推落库态会在 <em>即将接种</em> 与 <em>逾期</em> 之间出错。
 * <p>
 * {@code manual} 决定这一行能不能删（§4.4.4）。{@code recordId} 非空时界面据它去接种记录里
 * 取回该行的实际接种日期。
 * <p>
 * {@code dueDate} 是程序表推导的原定应种日；{@code plannedDate} 是用户设定的计划接种日期
 * （可空，2026-10-26 需求②）；{@code effectiveDate} = plannedDate ?? dueDate，服务端算好，
 * 界面的日期展示 / 排序一律取它，不要在客户端再写一遍 COALESCE。
 */
public record BabyVaccinePlanResponse(Long id, Long babyId, String vaccineName, String doseNo,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate dueDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate plannedDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate effectiveDate, String status, String skipReason,
		Long recordId, boolean manual, String displayStatus) {

}
