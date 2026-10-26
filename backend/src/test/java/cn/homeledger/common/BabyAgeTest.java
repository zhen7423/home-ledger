package cn.homeledger.common;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * §4.4.1 的日历月龄。生长标准查表与应种清单推算共用这一套算法，所以除了单点，还钉住
 * plusMonths 与 monthsBetween 互为逆——两张表各算一套的症状要等宝宝满月那天才看得见。
 */
class BabyAgeTest {

	@Test
	@DisplayName("生日当天即满一个月：1 月 31 日出生，2 月 28 日算满一个月")
	void monthEndBirthIsOneMonthOnTheClampedDay() {
		assertThat(BabyAge.monthsBetween(LocalDate.of(2026, 1, 31), LocalDate.of(2026, 2, 28))).isEqualTo(1);
	}

	@Test
	@DisplayName("差一天不满一个月：2 月 27 日还是 0 个月")
	void oneDayShortIsStillZero() {
		assertThat(BabyAge.monthsBetween(LocalDate.of(2026, 1, 31), LocalDate.of(2026, 2, 27))).isZero();
	}

	@Test
	@DisplayName("同一套口径的另一半：1 月 31 日加 1 个日历月落在 2 月 28 日")
	void plusMonthsClampsToTheMonthEnd() {
		assertThat(BabyAge.plusMonths(LocalDate.of(2026, 1, 31), 1)).isEqualTo(LocalDate.of(2026, 2, 28));
	}

	@Test
	@DisplayName("闰日出生跨年：2024-02-29 加 12 个月是 2025-02-28")
	void leapDayCrossesTheYear() {
		assertThat(BabyAge.plusMonths(LocalDate.of(2024, 2, 29), 12)).isEqualTo(LocalDate.of(2025, 2, 28));
	}

	@Test
	@DisplayName("出生当天是 0 个月")
	void sameDayIsZero() {
		LocalDate birth = LocalDate.of(2025, 7, 4);
		assertThat(BabyAge.monthsBetween(birth, birth)).isZero();
	}

	@Test
	@DisplayName("早于出生日不给负数")
	void beforeBirthIsZeroNotNegative() {
		LocalDate birth = LocalDate.of(2025, 7, 4);
		assertThat(BabyAge.monthsBetween(birth, birth.minusDays(1))).isZero();
	}

	@Test
	@DisplayName("满 24 个月当天走「岁」那一支，余数进「个月」")
	void twentyFourMonthsTurnsIntoYears() {
		LocalDate birth = LocalDate.of(2024, 1, 15);
		assertThat(BabyAge.ageText(birth, LocalDate.of(2026, 1, 15))).as("24 个月换成岁就是 2 岁整").isEqualTo("2 岁 0 个月");
		assertThat(BabyAge.ageText(birth, LocalDate.of(2026, 2, 15))).as("25 个月带 1 个月的余数").isEqualTo("2 岁 1 个月");
	}

	@Test
	@DisplayName("24 个月以内是「X 个月 Y 天」，Y 取该月内的天数差")
	void underTwentyFourMonthsShowsMonthsAndDays() {
		LocalDate birth = LocalDate.of(2024, 1, 15);
		assertThat(BabyAge.ageText(birth, LocalDate.of(2025, 12, 15))).isEqualTo("23 个月 0 天");
		assertThat(BabyAge.ageText(birth, LocalDate.of(2026, 1, 13))).isEqualTo("23 个月 29 天");
	}

	@Test
	@DisplayName("两函数互为逆：0–162 每个应种月龄加回去都读得出原值")
	void plusMonthsAndMonthsBetweenAreInverses() {
		// 月末与闰日出生是这套口径最容易分叉的地方，四种都进
		List<LocalDate> births = List.of(LocalDate.of(2024, 1, 31), LocalDate.of(2024, 2, 29), LocalDate.of(2023, 3, 31),
				LocalDate.of(2025, 12, 31), LocalDate.of(2024, 1, 30));
		for (LocalDate birth : births) {
			for (int months = 0; months <= 162; months++) {
				assertThat(BabyAge.monthsBetween(birth, BabyAge.plusMonths(birth, months))).as("%s 加 %d 个月", birth, months)
					.isEqualTo(months);
			}
		}
	}

}
