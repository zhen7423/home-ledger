package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 到期倒计时的一个条目（§4.3.5 第七块），<b>全 App「距下次驱虫 N 天」的唯一来源</b>（第 23 轮 (c)）：
 * 猫咪总览页与统计页读的是它，待提醒事项算的也是它，三处同值由这一个响应保证。
 * <p>
 * 不走 {@code GET /reminders/pending}：那条按用户的提醒开关过滤，关掉外驱提醒就会让一个数字凭空消失，
 * 而倒计时是事实陈述、不是通知。
 * <p>
 * 一条记录都没有的猫×类型不在这里：它该出现在「该给它驱了」的引导位，而不是倒计时里一个空白格子。
 */
public record CatDueCountdownItem(Long catId, String catName, String type,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate nextDate, Long daysToDue, Long overdueDays) {

}
