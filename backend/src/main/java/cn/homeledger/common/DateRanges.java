package cn.homeledger.common;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * 统计与导出共用的区间口径（§4.2.6、§4.2.7）。
 * <p>
 * 三个入口（summary / overview / export）要问的是同一批问题：起始能不能晚于结束、跨度超没超 366 天、
 * 含首尾一共几天。写在各自的 Service 里迟早会长出三种略微不同的答案，而「概览卡片的天数」与
 * 「导出页预查的天数」不一致是用户一眼就能看出来的那种 bug。
 */
public final class DateRanges {

	/** §4.2.6 自定义区间的跨度上限。取 366 而不是 365 是为了让「整年 + 闰日」这种区间也能选。 */
	public static final int MAX_SPAN_DAYS = 366;

	/**
	 * 「用户单边给的起点」最多上溯的年数。App 端所有日期选择器的 firstDate 都是今天−5 年，
	 * 服务端取同一口径：界面上选不出的起点也不在这里展开计算——dailyTrend 按天逐日循环，
	 * 一个 1900 年的 startDate 会让单次请求循环四万多次，ISO 扩展年份直接 OOM
	 * （扫描报告 2026-10-26 P1-1）。§4.2.6 的「366 天上限只约束起止同时给出的请求」
	 * 仍然成立：地板只作用于「用户给的起点」，不改变区间跨度规则本身。
	 */
	public static final int MAX_LOOKUP_YEARS = 5;

	private DateRanges() {
	}

	/**
	 * 起止都给全了才校验（§4.2.6：「366 天上限不生效（上限只约束同时给出起止日期的请求）」）。
	 * 缺一边就直接放过，由调用方按各自的口径补齐。
	 */
	public static void assertRange(LocalDate start, LocalDate end) {
		if (start == null || end == null) {
			return;
		}
		if (start.isAfter(end)) {
			throw new BizException(ErrorCode.BAD_REQUEST, "起始日期不能晚于结束日期");
		}
		if (ChronoUnit.DAYS.between(start, end) + 1 > MAX_SPAN_DAYS) {
			throw new BizException(ErrorCode.BAD_REQUEST, "时间区间最长 366 天，请缩小范围后再试");
		}
	}

	/**
	 * 把<b>用户给的</b>起点收进「end − {@value #MAX_LOOKUP_YEARS} 年」的地板。
	 * 只该对用户输入调用：派生自数据真值的起点（MIN(biz_date)、首袋开袋日）不走这里——
	 * 家里真有六年数据时天数就是六年，静默砍掉会改统计数字。
	 */
	public static LocalDate floorUserStart(LocalDate userStart, LocalDate end) {
		LocalDate floor = end.minusYears(MAX_LOOKUP_YEARS);
		return userStart.isBefore(floor) ? floor : userStart;
	}

	/** 含首尾的自然日数（§4.2.6 概览卡片的「区间天数」）。 */
	public static int daysInclusive(LocalDate start, LocalDate end) {
		return (int) ChronoUnit.DAYS.between(start, end) + 1;
	}

}
