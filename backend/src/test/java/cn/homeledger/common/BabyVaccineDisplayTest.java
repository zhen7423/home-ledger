package cn.homeledger.common;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * §4.4.4 的展示态判定。四态落库、五态展示，展示态全靠 due_date 与今天现场算，
 * 所以两条 14 天边界与「已标记优先于逾期」要单独钉住。
 */
class BabyVaccineDisplayTest {

	private static final LocalDate TODAY = LocalDate.of(2026, 9, 16);

	@Test
	@DisplayName("已接种：status 为 DONE")
	void doneShowsVaccinated() {
		assertThat(display(BabyVaccineStatus.DONE, TODAY.minusDays(3), false)).isEqualTo(BabyVaccineDisplay.VACCINATED);
	}

	@Test
	@DisplayName("已接种：status 还是 PENDING 但已回写 record_id，重绑过的记录靠它兜住")
	void boundRecordShowsVaccinated() {
		assertThat(display(BabyVaccineStatus.PENDING, TODAY.minusDays(3), true)).isEqualTo(BabyVaccineDisplay.VACCINATED);
	}

	@Test
	@DisplayName("已跳过与不适用都显示为已标记")
	void skippedAndNaShowMarked() {
		assertThat(display(BabyVaccineStatus.SKIPPED, TODAY.plusDays(30), false)).isEqualTo(BabyVaccineDisplay.MARKED);
		assertThat(display(BabyVaccineStatus.NA, TODAY.plusDays(30), false)).isEqualTo(BabyVaccineDisplay.MARKED);
	}

	@Test
	@DisplayName("已标记优先于逾期：标记过的行不该再显示成红色逾期")
	void markedBeatsOverdue() {
		assertThat(display(BabyVaccineStatus.SKIPPED, TODAY.minusDays(30), false)).isEqualTo(BabyVaccineDisplay.MARKED);
		assertThat(display(BabyVaccineStatus.NA, TODAY.minusDays(30), false)).isEqualTo(BabyVaccineDisplay.MARKED);
	}

	@Test
	@DisplayName("逾期：应种日期早于今天")
	void pastDueDateIsOverdue() {
		assertThat(display(BabyVaccineStatus.PENDING, TODAY.minusDays(1), false)).isEqualTo(BabyVaccineDisplay.OVERDUE);
	}

	@Test
	@DisplayName("应种日期就是今天算即将接种，不是逾期")
	void todayIsDueSoonNotOverdue() {
		assertThat(display(BabyVaccineStatus.PENDING, TODAY, false)).isEqualTo(BabyVaccineDisplay.DUE_SOON);
	}

	@Test
	@DisplayName("14 天窗口的两端：今天 + 14 是即将接种，+ 15 是待接种")
	void theSoonWindowIsInclusiveOnBothEnds() {
		assertThat(display(BabyVaccineStatus.PENDING, TODAY.plusDays(BabyVaccineDisplay.SOON_WINDOW_DAYS), false))
			.isEqualTo(BabyVaccineDisplay.DUE_SOON);
		assertThat(display(BabyVaccineStatus.PENDING, TODAY.plusDays(BabyVaccineDisplay.SOON_WINDOW_DAYS + 1), false))
			.isEqualTo(BabyVaccineDisplay.UPCOMING);
	}

	@Test
	@DisplayName("远离窗口的未完成项是待接种")
	void farFutureIsUpcoming() {
		assertThat(display(BabyVaccineStatus.PENDING, TODAY.plusDays(200), false)).isEqualTo(BabyVaccineDisplay.UPCOMING);
	}

	@Test
	@DisplayName("status 解析只认识四个落库值，其余抛业务异常；marked 只认 SKIPPED 与 NA")
	void statusParsingAndMarked() {
		assertThat(BabyVaccineStatus.of("PENDING")).isEqualTo(BabyVaccineStatus.PENDING);
		assertThat(BabyVaccineStatus.of("NA")).isEqualTo(BabyVaccineStatus.NA);
		assertThatThrownBy(() -> BabyVaccineStatus.of("DUE_SOON")).isInstanceOf(BizException.class)
			.hasFieldOrPropertyWithValue("errorCode", ErrorCode.BAD_REQUEST);

		assertThat(BabyVaccineStatus.PENDING.marked()).isFalse();
		assertThat(BabyVaccineStatus.DONE.marked()).isFalse();
		assertThat(BabyVaccineStatus.SKIPPED.marked()).isTrue();
		assertThat(BabyVaccineStatus.NA.marked()).isTrue();
	}

	private static BabyVaccineDisplay display(BabyVaccineStatus status, LocalDate dueDate, boolean hasRecord) {
		return BabyVaccineDisplay.of(status, dueDate, TODAY, hasRecord);
	}

}
