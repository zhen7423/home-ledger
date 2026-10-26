package cn.homeledger.common;

import java.time.LocalDate;

/**
 * 应种项的展示态（§4.4.4 的表）。三个「由 due_date 与今天现场算出」的态只在这里判定一次，
 * 清单页的配色、完成率、提醒三处都从这里取值。
 * <p>
 * 与落库的四态是两层：一个 {@code PENDING} 行今天是「即将接种」、明天可能变「逾期」，
 * 而库里那一格始终是 {@code PENDING}。
 */
public enum BabyVaccineDisplay {

	VACCINATED, MARKED, OVERDUE, DUE_SOON, UPCOMING;

	/**
	 * 「今天起 14 天内」的阈值（§4.4.4）。与疫苗提醒的 7 天提前量是两个数，不要合并成一个：
	 * 一个是清单上的配色分界，一个是通知该不该响。
	 */
	public static final int SOON_WINDOW_DAYS = 14;

	/**
	 * @param hasRecord {@code baby_vaccine_plan.record_id} 非空。它与 {@code status == DONE} 是两个来源，
	 *            只要有一个成立就是已接种（§1.4 第 12 条：重复录入会重绑 record_id）。
	 */
	public static BabyVaccineDisplay of(BabyVaccineStatus status, LocalDate dueDate, LocalDate today,
			boolean hasRecord) {
		if (status == BabyVaccineStatus.DONE || hasRecord) {
			return VACCINATED;
		}
		// 排在逾期前面：已标记的行不该再显示成红色逾期（§4.4.4）
		if (status.marked()) {
			return MARKED;
		}
		if (dueDate.isBefore(today)) {
			return OVERDUE;
		}
		return dueDate.isAfter(today.plusDays(SOON_WINDOW_DAYS)) ? UPCOMING : DUE_SOON;
	}

}
