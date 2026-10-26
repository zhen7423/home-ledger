package cn.homeledger.vo;

import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * §4.4.6 宝宝统计的第二条：疫苗六项 + 里程碑时间轴。
 * <p>
 * 里程碑挂在 vaccine 这条而不是 growth 那条：它与疫苗无关，但 growth 那条已经被体格与增长占满，
 * 而前端把两条端点各渲染成一张卡，把一段与体格毫无关系的列表挂在那边会让人以为里程碑是从
 * {@code baby_growth} 里算出来的（§4.4.6）。
 * <p>
 * {@code perBaby} <b>只含在册的宝宝</b>，与猫咪统计的完成度/倒计时同一条口径（§4.3.5）：待办类统计不该
 * 给一个已归档的宝宝留着永远做不完的逾期格，疫苗提醒也因此天然不会催一个归档的宝宝。里程碑时间轴相反，
 * 它是历史，归档宝宝的里程碑照旧在。
 * <p>
 * 不含生长曲线，理由见 {@link BabyGrowthStatisticsResponse}。
 */
public record BabyVaccineStatisticsResponse(List<BabyVaccineItem> perBaby, List<BabyMilestoneItem> milestoneTimeline) {

	public record BabyVaccineItem(Long babyId, String name, int completionRate, BabyVaccineCounts statusCounts,
			List<BabyVaccinePlanItem> upcoming, List<BabyVaccinePlanItem> overdueList,
			List<BabyVaccineRecordItem> recordTimeline) {

	}

	/**
	 * 四分段的四个数。已标记（{@code SKIPPED} / {@code NA}）的行<b>不进这四个</b>：它们是「本来就不该做」的，
	 * 混进任一段都会让那一段的含义变味，所以四个数之和可以小于应种总数（§4.4.6）。
	 */
	public record BabyVaccineCounts(int vaccinated, int upcoming, int dueSoon, int overdue) {

	}

	/**
	 * 待办清单里的一行。两列互斥且各有一列为空，与 {@code CatDueCountdownItem} 同一形状：未到期的只有
	 * {@code daysToDue}（当天是 0），逾期的只有 {@code overdueDays}。两列都空的行不会出现在这两个列表里。
	 */
	public record BabyVaccinePlanItem(Long planId, String vaccineName, String doseNo,
			@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate dueDate, Long daysToDue, Long overdueDays) {

	}

	/** 时间轴上一条接种记录（§4.4.6）：疫苗名 + 机构，不给批号与不良反应——那是接种记录页的事。 */
	public record BabyVaccineRecordItem(String vaccineName,
			@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate givenDate, String clinic) {

	}

	/**
	 * 时间轴上一条里程碑。带宝宝名是因为这一份是<b>顶层、跨宝宝</b>的：不写出这一条是谁的，
	 * 两个宝宝的里程碑混在一起就只能靠猜（§4.4.6）。不给 id：时间轴只读，没有任何操作要指向某一行。
	 */
	public record BabyMilestoneItem(Long babyId, String babyName,
			@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate occurDate, String title, String description) {

	}

}
