package cn.homeledger.vo;

import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * §4.3.5 后三块视图（驱虫完成度 + 驱虫时间轴 + 到期倒计时）一次返回。
 * <p>
 * 两个窗口边界是把「固定近 12 个自然月」到底是哪一天摊开给界面：那句小字说明直接读它，
 * 前端不必再算一次 {@code minusMonths(11)}，也不必与服务端各持一份窗口定义。
 */
public record CatDewormingStatisticsResponse(
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate windowStart,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate windowEnd, List<CatDewormingCompletion> completion,
		List<CatDewormingTimelineItem> timeline, List<CatDueCountdownItem> dueCountdown) {

}
