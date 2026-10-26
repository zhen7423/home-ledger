package cn.homeledger.common;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;

/**
 * 包装消耗余量推算（§4.3.4 的猫粮、§4.5.3 的奶粉共用）——实现日均消耗与余量/耗尽日的唯一落点。
 * <p>
 * 猫粮的三个调用方（在用袋查询、猫咪统计、{@code CAT_FOOD_LOW} 的 pending 判定）与奶粉的三个调用方
 * （在用罐查询、奶粉统计、{@code BABY_FORMULA_LOW} 的 pending 判定）都从这里取值。分叉成六份的后果是
 * 同一屏上出现六个互不相同的「日均」，而编译器查不出来（§6.4.1）。
 * <p>
 * 本类的 dailyAverage 是「当前袋推算的输入」那个口径，与各统计响应的 {@code dailyAverage}
 * （区间消耗 ÷ 区间天数）<b>不是同一个数</b>，两者可以差很远，所以界面上一个写「日均 50 g」、
 * 一个写「区间日均 30 g」。
 * <p>
 * 全程不用 double：要四舍五入的地方用 BigDecimal，要向下取整的地方用整数除法。
 */
public final class ConsumptionEstimate {

	/** 一袋已完成包装的推算输入：规格克数与它实际吃掉的天数（由下一袋的开始日推导）。 */
	public record ClosedBag(int packGrams, long usageDays) {
	}

	/**
	 * @param dailyAverage 日均消耗克数（历史折算或用户预估）
	 * @param consumedGrams 当前袋已消耗估算，<b>封顶在本袋规格</b>，超出部分由 overEstimate 表达
	 * @param remainingGrams 剩余克数，下限 0
	 * @param remainingPercent 剩余百分比，向下取整到整数
	 * @param daysLeft 预计可食天数，向下取整；已超时为 0
	 * @param depletionDate 预计耗尽日期 = today + daysLeft
	 * @param fromHistory true 表示日均来自已完成袋，false 表示用的是用户手填的预估——设置页据此把预估那一栏
	 *            置灰并标注「已由历史数据接管」
	 * @param overEstimate 已消耗估算超过包装规格（超期未换袋），界面提示「已超出预计用量，请确认是否已开新袋/新罐」
	 */
	public record Result(int dailyAverage, int consumedGrams, int remainingGrams, int remainingPercent, int daysLeft,
			LocalDate depletionDate, boolean fromHistory, boolean overEstimate) {
	}

	private ConsumptionEstimate() {
	}

	/**
	 * @param usedDays 当前袋已用天数，<b>含头含尾</b>（今天 − 开始日 + 1）
	 * @param today 由调用方从 Clock 取，本类不调 {@code LocalDate.now()}：pending 判定要在测试里造日期
	 * @return 推不出来时返回 {@code null}——既没有可用的已完成袋也没有有效的预估。调用方据此出 null 数据与
	 *         提示语，<b>不许</b>换成一个全零的 Result：零会被当成「还剩 0 克」读。
	 */
	public static Result of(int packGrams, long usedDays, Integer estimatedDailyGrams, List<ClosedBag> closedBags,
			LocalDate today) {
		Integer daily = dailyAverage(closedBags, estimatedDailyGrams);
		if (daily == null) {
			return null;
		}
		boolean fromHistory = closedBags.stream().anyMatch(bag -> bag.usageDays() > 0);
		long projected = (long) daily * Math.max(usedDays, 0L);
		boolean over = projected > packGrams;
		// 已消耗封顶在本袋规格：剩余与百分比因此恒在 int 范围内，而「超了」这件事由 overEstimate 单独说话
		int consumed = (int) Math.min(projected, packGrams);
		int remaining = packGrams - consumed;
		int percent = (int) ((long) remaining * 100L / packGrams);
		int daysLeft = over ? 0 : remaining / daily;
		return new Result(daily, consumed, remaining, percent, daysLeft, today.plusDays(daysLeft), fromHistory, over);
	}

	/**
	 * 有真实历史就用历史，否则退到用户预估。
	 * <p>
	 * 历史侧是 Σ规格 ÷ Σ天数而不是「各袋日均的算术平均」：后者会让一袋吃了 40 天的大袋和一袋吃 3 天的小袋
	 * 权重相同，而消耗口径要的是这段时间整体的消耗率。四舍五入到整数克用 {@code HALF_UP}——克数在这一层是
	 * 展示与推算的中间量，不是钱，不保留两位小数。
	 * <p>
	 * 折算出 0 g/日时按「推不出来」处理返回 null：除以 0 会炸，而一个 0 消耗率的估算本身也没有可展示的意义。
	 */
	private static Integer dailyAverage(List<ClosedBag> closedBags, Integer estimatedDailyGrams) {
		long grams = 0L;
		long days = 0L;
		for (ClosedBag bag : closedBags) {
			if (bag.usageDays() > 0) {
				grams += bag.packGrams();
				days += bag.usageDays();
			}
		}
		if (days > 0L) {
			int daily = BigDecimal.valueOf(grams)
				.divide(BigDecimal.valueOf(days), 0, RoundingMode.HALF_UP)
				.intValue();
			return daily == 0 ? null : daily;
		}
		if (estimatedDailyGrams == null || estimatedDailyGrams <= 0) {
			return null;
		}
		return estimatedDailyGrams;
	}

}