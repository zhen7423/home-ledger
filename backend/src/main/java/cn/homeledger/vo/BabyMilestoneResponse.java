package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条里程碑（§4.4.5）。带 {@code babyId}：列表端点 `babyId` 缺省时按顶层数组跨宝宝返回，
 * 界面得靠它标出这一条是谁的。
 */
public record BabyMilestoneResponse(Long id, Long babyId,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate occurDate, String title, String description) {

}
