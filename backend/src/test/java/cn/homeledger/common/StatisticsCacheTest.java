package cn.homeledger.common;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import cn.homeledger.dto.TransactionQueryRequest;

/**
 * §5.1 统计缓存的键。条件串的规范化归 DTO、指纹的形状归缓存类，这里两层各测一半。
 * <p>
 * 缓存与 Redis 的交互、以及「改财务数据不会打掉猫咪模块缓存」那条都需要真 Redis，落在集成测试里，不在这里。
 */
class StatisticsCacheTest {

	@Test
	@DisplayName("指纹是 16 位小写十六进制")
	void fingerprintIsSixteenHexChars() {
		String fingerprint = StatisticsCache.fingerprint(empty().canonicalConditions());
		assertThat(fingerprint).hasSize(16).matches("[0-9a-f]{16}");
	}

	@Test
	@DisplayName("page / size 不参与条件串：不分页的接口不该因为前端多传一个 page=1 就各存一份")
	void pageAndSizeDoNotEnterTheConditionString() {
		assertThat(new TransactionQueryRequest(null, null, null, null, null, null, null, null, null, null, 1, 30)
			.canonicalConditions()).isEqualTo(empty().canonicalConditions());
		assertThat(new TransactionQueryRequest(null, null, null, null, null, null, null, null, null, null, 7, 200)
			.canonicalConditions()).isEqualTo(empty().canonicalConditions());
	}

	@Test
	@DisplayName("十个筛选条件各改一个，条件串与指纹都要变")
	void anyConditionChangeChangesTheFingerprint() {
		String emptyConditions = empty().canonicalConditions();
		List<TransactionQueryRequest> eachConditionChanged = List.of(
				new TransactionQueryRequest(LocalDate.of(2026, 1, 1), null, null, null, null, null, null, null, null,
						null, null, null),
				new TransactionQueryRequest(null, LocalDate.of(2026, 1, 31), null, null, null, null, null, null, null,
						null, null, null),
				new TransactionQueryRequest(null, null, "EXPENSE", null, null, null, null, null, null, null, null, null),
				new TransactionQueryRequest(null, null, null, 11L, null, null, null, null, null, null, null, null),
				new TransactionQueryRequest(null, null, null, null, 12L, null, null, null, null, null, null, null),
				new TransactionQueryRequest(null, null, null, null, null, 13L, null, null, null, null, null, null),
				new TransactionQueryRequest(null, null, null, null, null, null, 14L, null, null, null, null, null),
				new TransactionQueryRequest(null, null, null, null, null, null, null, "午餐", null, null, null, null),
				new TransactionQueryRequest(null, null, null, null, null, null, null, null, new BigDecimal("38.50"),
						null, null, null),
				new TransactionQueryRequest(null, null, null, null, null, null, null, null, null, "AUTO", null, null));
		for (TransactionQueryRequest changed : eachConditionChanged) {
			assertThat(changed.canonicalConditions()).as("条件 %s 必须参与缓存键", changed).isNotEqualTo(emptyConditions);
			assertThat(StatisticsCache.fingerprint(changed.canonicalConditions()))
				.as("条件 %s 必须参与指纹", changed)
				.isNotEqualTo(StatisticsCache.fingerprint(emptyConditions));
		}
	}

	@Test
	@DisplayName("金额不做数值归一化：1.0 与 1.00 是两个键")
	void amountScaleIsNotNormalized() {
		// 这是实施前确认过的代价：归一化等于在缓存键这一层复刻一套 BigDecimal 比较语义。日后改回去时这条会红，那时连注释一起改
		String oneDecimal = StatisticsCache.fingerprint(new TransactionQueryRequest(null, null, null, null, null, null,
				null, null, new BigDecimal("1.0"), null, null, null).canonicalConditions());
		String twoDecimals = StatisticsCache.fingerprint(new TransactionQueryRequest(null, null, null, null, null, null,
				null, null, new BigDecimal("1.00"), null, null, null).canonicalConditions());
		assertThat(oneDecimal).isNotEqualTo(twoDecimals);
	}

	@Test
	@DisplayName("空串与不传是同一个条件：否则同一份查询会存出两份永不互认的缓存")
	void absentAndEmptyConditionCollapse() {
		assertThat(new TransactionQueryRequest(null, null, null, null, null, null, null, "", null, null, null, null)
			.canonicalConditions()).isEqualTo(empty().canonicalConditions());
	}

	private static TransactionQueryRequest empty() {
		return new TransactionQueryRequest(null, null, null, null, null, null, null, null, null, null, null, null);
	}

}
