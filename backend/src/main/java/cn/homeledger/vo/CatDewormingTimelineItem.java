package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 驱虫时间轴上的一个节点（§4.3.5 第六块），近 12 个月内一条记录一个节点，含已归档的猫。
 * <p>
 * 带 {@code medicine} 是那一节明写的（「含药品名」）；{@code dosage} 不带——时间轴上两行字已经满了。
 */
public record CatDewormingTimelineItem(Long catId, String catName, String type,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate doneDate, String medicine) {

}
