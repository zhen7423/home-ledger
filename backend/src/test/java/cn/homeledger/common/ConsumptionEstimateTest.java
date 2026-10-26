package cn.homeledger.common;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * §4.3.4 的余量推算。数值本身对不对在这里钉，接口测试只验端点把这套数原样吐出来。
 * <p>
 * 每条断言都能一口心算核对，所以入参全用整数克与整天数。
 */
class ConsumptionEstimateTest {

	private static final LocalDate TODAY = LocalDate.of(2026, 9, 15);

	@Test
	@DisplayName("有已完成袋时日均按历史折算，当前袋的已消耗、剩余、可食天数都跟着它")
	void closedBagHistoryDrivesTheCurrentBag() {
		ConsumptionEstimate.Result result = ConsumptionEstimate.of(2000, 11, null, List.of(bag(2000, 40)), TODAY);

		assertThat(result).isNotNull();
		assertThat(result.dailyAverage()).isEqualTo(50);
		assertThat(result.consumedGrams()).isEqualTo(550);
		assertThat(result.remainingGrams()).isEqualTo(1450);
		assertThat(result.remainingPercent()).isEqualTo(72);
		assertThat(result.daysLeft()).isEqualTo(29);
		assertThat(result.depletionDate()).isEqualTo(LocalDate.of(2026, 10, 14));
		assertThat(result.fromHistory()).isTrue();
		assertThat(result.overEstimate()).isFalse();
	}

	@Test
	@DisplayName("多袋折算是 Σ规格 ÷ Σ天数，不是各袋日均的算术平均")
	void historyAveragesOverTheWholePeriodNotPerBag() {
		ConsumptionEstimate.Result even = ConsumptionEstimate.of(2000, 1, null, List.of(bag(2000, 40), bag(1500, 30)), TODAY);
		assertThat(even).isNotNull();
		assertThat(even.dailyAverage()).isEqualTo(50);

		// 第二袋故意做成 1500g/25 天：两组都摊成 50 的话，两种平均分不出胜负，这条就退化成只测「不崩」
		ConsumptionEstimate.Result skewed = ConsumptionEstimate.of(2000, 1, null, List.of(bag(2000, 40), bag(1500, 25)),
				TODAY);
		assertThat(skewed).isNotNull();
		assertThat(skewed.dailyAverage()).as("合计折算 3500 ÷ 65 = 53.85，四舍五入到 54").isEqualTo(54);
		assertThat(skewed.dailyAverage()).as("55 才是逐袋平均 (50 + 60) ÷ 2").isNotEqualTo(55);
	}

	@Test
	@DisplayName("0 天的袋不进分母：补录同一天留下的异常袋不该稀释日均")
	void zeroLengthBagsAreSkipped() {
		ConsumptionEstimate.Result result = ConsumptionEstimate.of(2000, 5, null, List.of(bag(2000, 40), bag(2000, 0)), TODAY);

		assertThat(result).isNotNull();
		assertThat(result.dailyAverage()).isEqualTo(50);
		assertThat(result.fromHistory()).isTrue();
	}

	@Test
	@DisplayName("没有任何历史时退到用户预估")
	void fallsBackToTheUserEstimate() {
		ConsumptionEstimate.Result result = ConsumptionEstimate.of(2000, 10, 60, List.of(), TODAY);

		assertThat(result).isNotNull();
		assertThat(result.dailyAverage()).isEqualTo(60);
		assertThat(result.remainingGrams()).isEqualTo(1400);
		assertThat(result.daysLeft()).isEqualTo(23);
		assertThat(result.fromHistory()).isFalse();
	}

	@Test
	@DisplayName("既没有历史也没有预估时返回 null；预估填 0 与没填同义")
	void underivableReturnsNull() {
		assertThat(ConsumptionEstimate.of(2000, 10, null, List.of(), TODAY)).isNull();
		assertThat(ConsumptionEstimate.of(2000, 10, 0, List.of(), TODAY)).isNull();
	}

	@Test
	@DisplayName("一旦有可用历史，手填的预估即刻失效")
	void historyBeatsTheEstimate() {
		ConsumptionEstimate.Result result = ConsumptionEstimate.of(2000, 1, 999, List.of(bag(2000, 40)), TODAY);

		assertThat(result).isNotNull();
		assertThat(result.dailyAverage()).isEqualTo(50);
		assertThat(result.fromHistory()).isTrue();
	}

	@Test
	@DisplayName("超期未换袋：已消耗封顶在规格，超出这件事由 overEstimate 单独说")
	void overEstimateClampsToThePackSize() {
		ConsumptionEstimate.Result result = ConsumptionEstimate.of(2000, 60, null, List.of(bag(2000, 40)), TODAY);

		assertThat(result).isNotNull();
		assertThat(result.overEstimate()).isTrue();
		assertThat(result.consumedGrams()).isEqualTo(2000);
		assertThat(result.remainingGrams()).isZero();
		assertThat(result.remainingPercent()).isZero();
		assertThat(result.daysLeft()).isZero();
		assertThat(result.depletionDate()).isEqualTo(TODAY);
	}

	@Test
	@DisplayName("剩余百分比向下取整：72.5% 报 72 而不是 73")
	void percentFloorsInsteadOfRounding() {
		ConsumptionEstimate.Result result = ConsumptionEstimate.of(2000, 11, null, List.of(bag(2000, 40)), TODAY);

		assertThat(result).isNotNull();
		assertThat(result.remainingPercent()).isEqualTo(72);
	}

	@Test
	@DisplayName("折算出 0 g/日时按推不出来处理，不留一个除以 0 的现场")
	void zeroDailyIsNotAnEstimate() {
		assertThat(ConsumptionEstimate.of(2000, 3, null, List.of(bag(1, 400)), TODAY)).isNull();
	}

	private static ConsumptionEstimate.ClosedBag bag(int packGrams, long usageDays) {
		return new ConsumptionEstimate.ClosedBag(packGrams, usageDays);
	}

}