package cn.homeledger.common;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * 日历月龄（§4.4.1）——全项目<b>只此一处</b>实现月龄与应种日期的加法。
 * <p>
 * 生长标准查表、应种清单推算、档案页的年龄文案三处都从这里取值。分叉成三份的后果是曲线上的点和
 * 清单上的日期各按各的算法走，而编译器查不出来（§6.4.1）。
 * <p>
 * 口径是「生日当天即满一个月」：1 月 31 日出生则 2 月 28 日算满一个月。这是孕周/儿保口径的常用算法，
 * 与 {@code ChronoUnit.MONTHS} 差一格——后者给出 0。两个方法共用这一套，互为逆。
 * <p>
 * 不进 Spring 容器：无状态、无依赖，测试直接调静态方法。
 */
public final class BabyAge {

	private static final int MONTHS_PER_YEAR = 12;

	/** 分界线：24 个月起改用「X 岁 Y 个月」（§4.4.1） */
	private static final int YEAR_BRANCH_FROM_MONTHS = 24;

	private BabyAge() {
	}

	/**
	 * 到 {@code onDate} 为止的完整月龄，早于出生日一律 0（不给负数）。
	 * <p>
	 * 两个 while 各最多进一次：{@code ChronoUnit.MONTHS} 与日历月最多差 1，差的正是
	 * 「生日当天即满月」那一格。留着它们，这条口径才有唯一的落地点。
	 */
	public static int monthsBetween(LocalDate birthDate, LocalDate onDate) {
		int months = (int) ChronoUnit.MONTHS.between(birthDate, onDate);
		if (months < 0) {
			return 0;
		}
		while (birthDate.plusMonths(months + 1).compareTo(onDate) <= 0) {
			months++;
		}
		while (months > 0 && birthDate.plusMonths(months).compareTo(onDate) > 0) {
			months--;
		}
		return months;
	}

	/**
	 * 出生日期 + n 个日历月 = 应种日期。目标月没有该日时落在月末（3 月 31 日 + 1 个月 = 4 月 30 日），
	 * 由 {@link LocalDate#plusMonths} 的月末夹取负责，与 {@link #monthsBetween} 是同一套日历月。
	 */
	public static LocalDate plusMonths(LocalDate birthDate, int months) {
		return birthDate.plusMonths(months);
	}

	/** ≤ 24 个月「X 个月 Y 天」，24 个月起「X 岁 Y 个月」；Y 是该月内的天数差。 */
	public static String ageText(LocalDate birthDate, LocalDate onDate) {
		int months = monthsBetween(birthDate, onDate);
		if (months < YEAR_BRANCH_FROM_MONTHS) {
			long days = Math.max(ChronoUnit.DAYS.between(plusMonths(birthDate, months), onDate), 0L);
			return months + " 个月 " + days + " 天";
		}
		return months / MONTHS_PER_YEAR + " 岁 " + months % MONTHS_PER_YEAR + " 个月";
	}

}
