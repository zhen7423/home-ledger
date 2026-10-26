package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.config.TimeConfig;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.5.1 的第七类提醒（{@code GROWTH_RECORD_DUE}）进 {@code GET /reminders/pending}。
 * <p>
 * 这一类的形状与另外六类都不同：它没有清单页、不发系统通知（{@code pushed = false}），
 * 所以「每月 ≤ 2 次」那个上限只能落在「它进不进这份列表」上——落到第 30 天与第 45 天各一次，
 * 其余日子不进。这份测试逐条钉的就是那三个数字（30 / 15 / 36 月龄）。
 * <p>
 * 日期一律相对今天：判的是「距上次记录多少天」，写死日期明天就测不到那几条边界了。
 */
class GrowthReminderIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final String GROWTH_RECORD_DUE = "GROWTH_RECORD_DUE";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("出生满 30 天还没量过就提一次：正文说清楚是谁、多久没记了")
	void newbornWithoutAnyRecordIsRemindedOnDayThirty() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusDays(30).toString());

		JsonNode item = onlyOf(pending(owner), GROWTH_RECORD_DUE);

		assertThat(item.path("body").asText()).as("没有记录时从出生日期起算，否则新家庭永远等不到这一条")
			.isEqualTo("小满已经 30 天没有记录身高体重了");
		assertThat(item.path("title").asText()).isEqualTo("宝宝成长记录待补");
		assertThat(item.path("key").asText()).isEqualTo(GROWTH_RECORD_DUE + ":BABY:" + babyId);
		assertThat(item.path("route").asText()).as("身高体重列表就是「去补一条」的地方").isEqualTo("/baby/growths");
		assertThat(item.path("fireAt").isNull()).as("这类提醒不发通知，没有任何「该做某事的时刻」").isTrue();
		assertThat(item.path("fireDate").isNull()).isTrue();
	}

	@Test
	@DisplayName("差一天不提前：第 29 天不进列表")
	void dayTwentyNineIsNotYetDue() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusDays(29).toString());

		assertThat(typesOf(pending(owner))).doesNotContain(GROWTH_RECORD_DUE);
	}

	@Test
	@DisplayName("补录一条就把表拨回去：30 天前量过才提，29 天前量过不提")
	void aMeasurementResetsTheClock() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long stale = createBaby(token, "小满", "MALE", TODAY.minusDays(200).toString());
		long fresh = createBaby(token, "小满弟", "MALE", TODAY.minusDays(200).toString());
		createGrowth(token, stale, TODAY.minusDays(30).toString(), "70.0", "8.00");
		createGrowth(token, fresh, TODAY.minusDays(29).toString(), "70.0", "8.00");

		assertThat(keysOf(pending(owner), GROWTH_RECORD_DUE))
			.as("数的是「距上次记录」，不是「距出生」；两个宝宝只差一条 29 天前的记录")
			.containsExactly(GROWTH_RECORD_DUE + ":BABY:" + stale);
	}

	@Test
	@DisplayName("第 30 天起每 15 天一次：第 40 天与第 46 天都不在节奏上，第 45 天在")
	void repeatsEveryFifteenDays() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		createBaby(token, "小满", "MALE", TODAY.minusDays(40).toString());
		long on = createBaby(token, "小满弟", "MALE", TODAY.minusDays(45).toString());
		createBaby(token, "小满妹", "FEMALE", TODAY.minusDays(46).toString());

		assertThat(keysOf(pending(owner), GROWTH_RECORD_DUE))
			.as("三个宝宝里只有落在 30 + 15n 那一天的那个该出现")
			.containsExactly(GROWTH_RECORD_DUE + ":BABY:" + on);
	}

	@Test
	@DisplayName("满 3 周岁就不再催：这一条只对 0–3 岁的宝宝启用")
	void stopsAtThreeYearsOld() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long preschooler = createBaby(token, "小满", "MALE", TODAY.minusMonths(48).toString());
		createGrowth(token, preschooler, TODAY.minusDays(30).toString(), "100.0", "16.00");

		assertThat(typesOf(pending(owner)))
			.as("上一次记录正好是 30 天前，卡住它的只能是月龄那一道").doesNotContain(GROWTH_RECORD_DUE);
	}

	@Test
	@DisplayName("归档的宝宝不再被催：归档的语义就是不再参与新记录")
	void archivedBabyIsNotReminded() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusDays(200).toString());
		createGrowth(token, babyId, TODAY.minusDays(30).toString(), "70.0", "8.00");
		assertThat(typesOf(pending(owner))).contains(GROWTH_RECORD_DUE);

		assertThat(patchJson(BABIES + "/" + babyId + "/archive", null, token).code()).isEqualTo("OK");

		assertThat(typesOf(pending(owner))).doesNotContain(GROWTH_RECORD_DUE);
	}

	@Test
	@DisplayName("开关关掉就不产出这一条：其余六类照旧")
	void switchOffSuppressesGrowthReminder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusDays(30).toString());
		assertThat(typesOf(pending(owner))).contains(GROWTH_RECORD_DUE);

		assertThat(putJson(REMINDER_SETTINGS, Map.of("items", List.of(Map.of("type", GROWTH_RECORD_DUE, "enabled", false))),
				owner.accessToken()).code()).isEqualTo("OK");

		assertThat(typesOf(pending(owner))).doesNotContain(GROWTH_RECORD_DUE);
	}

	@Test
	@DisplayName("A 家的成长记录提醒不会出现在 B 家的待提醒里")
	void growthRemindersAreFamilyScoped() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusDays(30).toString());

		assertThat(keysOf(pending(owner), GROWTH_RECORD_DUE)).hasSize(1);
		assertThat(typesOf(pending(outsider))).as("B 家没有宝宝，开关开着也没有产出").isEmpty();
	}

	@Test
	@DisplayName("同一个事实两次查询得到同一个 key：前端拿它记「今天已经提醒过」")
	void reminderKeyStableAcrossCalls() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusDays(30).toString());

		assertThat(keysOf(pending(owner), GROWTH_RECORD_DUE)).containsExactly(GROWTH_RECORD_DUE + ":BABY:" + babyId);
		assertThat(keysOf(pending(owner), GROWTH_RECORD_DUE)).containsExactly(GROWTH_RECORD_DUE + ":BABY:" + babyId);
	}

	@Test
	@DisplayName("无家庭的账号：pending 是 200 加空列表，不是 403")
	void noFamilyReturnsEmpty() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call call = getJson(REMINDER_PENDING, lonely.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.OK.value());
		assertThat(toList(call.data())).isEmpty();
	}

	// ---- 辅助 ----

	private List<JsonNode> pending(Account account) throws Exception {
		Call call = getJson(REMINDER_PENDING, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return toList(call.data());
	}

	private List<String> typesOf(List<JsonNode> items) {
		return items.stream().map(item -> item.path("type").asText()).toList();
	}

	private List<String> keysOf(List<JsonNode> items, String type) {
		return items.stream()
			.filter(item -> item.path("type").asText().equals(type))
			.map(item -> item.path("key").asText())
			.toList();
	}

	private JsonNode onlyOf(List<JsonNode> items, String type) {
		List<JsonNode> hits = items.stream().filter(item -> item.path("type").asText().equals(type)).toList();
		assertThat(hits).as("提醒类型 " + type + " 应当恰好一条").hasSize(1);
		return hits.get(0);
	}

	private List<JsonNode> toList(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

}
