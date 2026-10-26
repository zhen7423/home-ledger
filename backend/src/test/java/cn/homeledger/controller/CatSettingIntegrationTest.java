package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.config.TimeConfig;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.3.3 猫咪设置。这张表的两个读法对「有没有那一行」的态度是相反的：GET 回默认值且不建行，PUT 才建。
 */
class CatSettingIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_ALONE = "13800000004";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("新家庭的 GET 回默认值，并且一行都不写")
	void getReturnsDefaultsWithoutWritingARow() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		JsonNode data = get(owner);
		assertThat(data.path("internalMonths").asInt()).isEqualTo(3);
		assertThat(data.path("externalMonths").asInt()).isEqualTo(1);
		assertThat(data.path("estimatedDailyGrams").isNull()).as("没填就是没填，不能翻成 0").isTrue();
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM cat_setting", Integer.class))
			.as("打开一次设置页不是写入事件：落了库就把「用户没填」与「从没打开过」搅成一锅").isZero();
	}

	@Test
	@DisplayName("PUT 之后再 GET，三栏原样回，接管标注还没有")
	void putThenGetReturnsTheStoredValues() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		assertThat(save(owner, 2, 6, 80).code()).isEqualTo("OK");
		JsonNode data = get(owner);
		assertThat(data.path("internalMonths").asInt()).isEqualTo(2);
		assertThat(data.path("externalMonths").asInt()).isEqualTo(6);
		assertThat(data.path("estimatedDailyGrams").asInt()).isEqualTo(80);
		assertThat(data.path("estimateTakenOverByHistory").asBoolean()).as("一袋都没开过时谈不上接管").isFalse();
	}

	@Test
	@DisplayName("第二个成员保存是覆盖同一行，并把 created_by 换成他")
	void secondPutOverwritesAndRecordsTheNewOperator() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		save(owner, 2, 6, 80);

		assertThat(save(member, 4, 8, null).code()).isEqualTo("OK");

		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM cat_setting", Integer.class))
			.as("每家庭至多一行，覆盖不是追加").isEqualTo(1);
		assertThat(jdbcTemplate.queryForObject("SELECT created_by FROM cat_setting WHERE family_id = ?", Long.class,
				family.id())).as("这一列记的是最后一次 PUT 的操作者").isEqualTo(member.userId());
		JsonNode data = get(member);
		assertThat(data.path("internalMonths").asInt()).isEqualTo(4);
		assertThat(data.path("estimatedDailyGrams").isNull()).isTrue();
	}

	@Test
	@DisplayName("周期越界被拒，报的是注解里那句人话，库里不留半套值")
	void outOfRangeMonthsAreRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		for (int months : new int[] { 0, 13 }) {
			Call call = save(owner, months, 1, null);
			assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
			assertThat(call.message()).contains(months == 0 ? "至少 1 个月" : "最多 12 个月");
		}
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM cat_setting", Integer.class))
			.as("被拒的保存不该顺手建行").isZero();
		assertThat(get(owner).path("internalMonths").asInt()).as("被拒之后仍是默认值").isEqualTo(3);
	}

	@Test
	@DisplayName("预估日均留空是合法值，且覆盖时能把已存的那个数真的清空")
	void blankEstimateIsValidAndMeansNoFallback() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		save(owner, 3, 1, 80);

		assertThat(save(owner, 3, 1, null).code()).isEqualTo("OK");
		assertThat(get(owner).path("estimatedDailyGrams").isNull())
			.as("「我没有预估，等第一袋吃完再算」是一个有含义的选择，不是漏填").isTrue();
	}

	@Test
	@DisplayName("用例 23：一旦出现可用的已完成袋，预估那一栏就被标注为已由历史接管")
	void case23_theEstimateFieldIsMarkedTakenOverOnceHistoryExists() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		save(owner, 3, 1, 80);
		openTwoBags(owner);

		JsonNode data = get(owner);
		assertThat(data.path("estimateTakenOverByHistory").asBoolean())
			.as("判据是「有没有可用历史袋」，不是当前那一袋推不推得出").isTrue();
	}

	@Test
	@DisplayName("无家庭的账号碰设置端点返回 NO_FAMILY")
	void settingsRequireAFamily() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call call = getJson(CAT_SETTINGS, lonely.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(call.code()).isEqualTo("NO_FAMILY");
		assertThat(putJson(CAT_SETTINGS, payload(3, 1, null), lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
	}

	// ---- 辅助 ----

	private JsonNode get(Account account) throws Exception {
		Call call = getJson(CAT_SETTINGS, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private Call save(Account account, int internalMonths, int externalMonths, Integer estimatedDailyGrams)
			throws Exception {
		return putJson(CAT_SETTINGS, payload(internalMonths, externalMonths, estimatedDailyGrams),
				account.accessToken());
	}

	private static Map<String, Object> payload(int internalMonths, int externalMonths, Integer estimatedDailyGrams) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("internalMonths", internalMonths);
		body.put("externalMonths", externalMonths);
		body.put("estimatedDailyGrams", estimatedDailyGrams);
		return body;
	}

	/** 两袋：前一袋已经吃完（有可用的使用天数与日均），后一袋在用。可用的已完成袋只需要这一对。 */
	private void openTwoBags(Account account) throws Exception {
		bag(account, "皇家", 2000, TODAY.minusDays(50));
		bag(account, "渴望", 2000, TODAY.minusDays(10));
	}

	private void bag(Account account, String brand, int packGrams, LocalDate startedDate) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("brand", brand);
		body.put("packGrams", packGrams);
		body.put("startedDate", startedDate.toString());
		body.put("remark", null);
		assertThat(postJson(CAT_FOOD_BAGS, body, account.accessToken()).code()).isEqualTo("OK");
	}

}
