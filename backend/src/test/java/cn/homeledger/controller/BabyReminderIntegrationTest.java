package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.config.TimeConfig;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.5.1 的第七类提醒（{@code VACCINE_UPCOMING}）进 {@code GET /reminders/pending}。
 * <p>
 * 端点与条目的七个字段不因这一步改变，所以断言全部落在「哪几针该出现、正文是哪句话、去重键长什么样」上。
 * <p>
 * 提前量是 7 天而 {@code upcoming} 端点的窗口是 14 天，这两个数不是一回事：窗口是给人看的清单，
 * 提前量是红点该不该响。两者之间那条缝要有一条专门盯着。
 * <p>
 * 凡是断「恰好一条」的用例都先把出生那两针录掉再建手动项：不录的话那两针本身就是两条待提醒
 * （出生当天到期，0 天 ≤ 7 天），数出来的条数与被测的那一条无关。
 */
class BabyReminderIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final String VACCINE_UPCOMING = "VACCINE_UPCOMING";

	private static final String HEP_B = "乙肝疫苗";

	private static final String BCG = "卡介苗";

	private static final String FLU = "流感疫苗";

	private static final String CHICKENPOX = "水痘疫苗";

	private static final String PCV = "肺炎球菌疫苗";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("七天内该打的那一针进待提醒，正文是「还有 N 天」，落点是应种清单")
	void vaccineUpcomingAppearsInPending() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = newbornWithBirthDoses(token);
		long planId = manualPlan(token, babyId, FLU, "1", TODAY.plusDays(5));

		JsonNode item = onlyOf(pending(owner), VACCINE_UPCOMING);

		assertThat(item.path("key").asText()).isEqualTo(VACCINE_UPCOMING + ":PLAN:" + planId);
		assertThat(item.path("title").asText()).as("标题说事由、正文说主体，与预算那两类同构").isEqualTo("疫苗接种即将到期");
		assertThat(item.path("body").asText()).isEqualTo("小满的流感疫苗第 1 剂还有 5 天");
		assertThat(item.path("route").asText()).as("点进去落在应种清单，错不了").isEqualTo("/baby/vaccines");
	}

	@Test
	@DisplayName("今天应接种的那一针不说「还有 0 天」")
	void todaysDoseSaysTodayNotZeroDays() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = newbornWithBirthDoses(token);
		manualPlan(token, babyId, FLU, "1", TODAY);

		assertThat(onlyOf(pending(owner), VACCINE_UPCOMING).path("body").asText())
			.as("通知里写「还有 0 天」是要挨骂的，与驱虫那三类同一个做法").isEqualTo("小满的流感疫苗第 1 剂今天应接种");
	}

	@Test
	@DisplayName("逾期的每一针都单独出一条，正文报的是自己欠下的天数")
	void overdueAppearsEvenWhenDueDatePassed() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(6).toString());
		long planId = manualPlan(token, babyId, FLU, "1", TODAY.minusDays(2));

		List<JsonNode> items = pending(owner);

		assertThat(keysOf(items, VACCINE_UPCOMING)).as("半岁宝宝身上欠着出生以来那几针，它们也各算一条")
			.contains(VACCINE_UPCOMING + ":PLAN:" + planId);
		assertThat(itemWithKey(items, VACCINE_UPCOMING + ":PLAN:" + planId).path("body").asText())
			.as("逾期全取：已经欠下的账不该等到某个提前量才说").isEqualTo("小满的流感疫苗第 1 剂已逾期 2 天");
	}

	@Test
	@DisplayName("10 天后的那一针在清单里却不在红点里：两个窗口的差就是这个 7 天提前量的意义")
	void beyondSevenDaysIsNotReminded() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = newbornWithBirthDoses(token);
		long planId = manualPlan(token, babyId, PCV, "1", TODAY.plusDays(10));

		Call stats = getJson(BABY_STATS_VACCINE, Map.of("babyId", String.valueOf(babyId)), token);
		List<JsonNode> upcoming = toList(stats.data().path("perBaby").get(0).path("upcoming"));
		assertThat(upcoming.stream().map(row -> row.path("planId").asLong()).toList())
			.as("应种清单的窗口是 14 天，这一针在里面").contains(planId);
		assertThat(keysOf(pending(owner), VACCINE_UPCOMING))
			.as("红点的提前量是 7 天，这一针还不到该响的时候").doesNotContain(VACCINE_UPCOMING + ":PLAN:" + planId);
	}

	@Test
	@DisplayName("去重键落在剂次上：同一个宝宝欠两针就是两条，前端按 key 去重不会吞掉一条")
	void reminderKeyIsPerDoseNotPerBaby() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = newbornWithBirthDoses(token);
		long first = manualPlan(token, babyId, FLU, "1", TODAY.plusDays(3));
		long second = manualPlan(token, babyId, CHICKENPOX, "1", TODAY.plusDays(4));

		assertThat(keysOf(pending(owner), VACCINE_UPCOMING))
			.containsExactlyInAnyOrder(VACCINE_UPCOMING + ":PLAN:" + first, VACCINE_UPCOMING + ":PLAN:" + second);
	}

	@Test
	@DisplayName("同一个事实两次查询得到同一个 key：前端拿它记「今天已经提醒过」")
	void reminderKeyStableAcrossCalls() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = newbornWithBirthDoses(token);
		long planId = manualPlan(token, babyId, FLU, "1", TODAY.plusDays(2));

		assertThat(keysOf(pending(owner), VACCINE_UPCOMING)).containsExactly(VACCINE_UPCOMING + ":PLAN:" + planId);
		assertThat(keysOf(pending(owner), VACCINE_UPCOMING)).containsExactly(VACCINE_UPCOMING + ":PLAN:" + planId);
	}

	@Test
	@DisplayName("疫苗提醒带自己的模块名：客户端按它把角标挂到宝宝 Tab 上（§4.5.2）")
	void vaccineReminderCarriesItsModule() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		manualPlan(owner.accessToken(), newbornWithBirthDoses(owner.accessToken()), FLU, "1", TODAY.plusDays(3));

		assertThat(onlyOf(pending(owner), VACCINE_UPCOMING).path("module").asText()).isEqualTo("BABY");
	}

	@Test
	@DisplayName("提前 7 天与当天都是触发日：不给定时，那一刻已经成立")
	void triggerDaysAreImmediate() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = newbornWithBirthDoses(token);
		long today = manualPlan(token, babyId, FLU, "1", TODAY);
		long seventh = manualPlan(token, babyId, CHICKENPOX, "1", TODAY.plusDays(7));

		List<JsonNode> items = pending(owner);

		assertThat(fireAtIsAbsent(itemWithKey(items, VACCINE_UPCOMING + ":PLAN:" + today))).isTrue();
		assertThat(fireAtIsAbsent(itemWithKey(items, VACCINE_UPCOMING + ":PLAN:" + seventh))).isTrue();
	}

	@Test
	@DisplayName("不在触发日上时排到到期日当天上午九点：通知不需要用户打开 App 才到")
	void nonTriggerDaySchedulesTheDueDay() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long planId = manualPlan(token, newbornWithBirthDoses(token), FLU, "1", TODAY.plusDays(5));

		JsonNode item = itemWithKey(pending(owner), VACCINE_UPCOMING + ":PLAN:" + planId);

		assertThat(LocalDateTime.parse(item.path("fireAt").asText())).isEqualTo(TODAY.plusDays(5).atTime(9, 0));
		assertThat(item.path("fireDate").asText()).isEqualTo(TODAY.plusDays(5).toString());
	}

	@Test
	@DisplayName("逾期后每 3 天：逾期第 1 天排到第 3 天，逾期第 3 天本身就是触发日")
	void overdueFollowsTheThreeDayRhythm() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(6).toString());
		long oneDay = manualPlan(token, babyId, FLU, "1", TODAY.minusDays(1));
		long threeDays = manualPlan(token, babyId, CHICKENPOX, "1", TODAY.minusDays(3));

		List<JsonNode> items = pending(owner);

		assertThat(LocalDateTime.parse(itemWithKey(items, VACCINE_UPCOMING + ":PLAN:" + oneDay).path("fireAt").asText()))
			.as("逾期 1 天落在第 1 与第 3 天之间，下一次是第 3 天").isEqualTo(TODAY.plusDays(2).atTime(9, 0));
		assertThat(fireAtIsAbsent(itemWithKey(items, VACCINE_UPCOMING + ":PLAN:" + threeDays)))
			.as("逾期 3 天整正是触发日").isTrue();
	}

	@Test
	@DisplayName("开关关掉就不产出这一针：其余六类照旧")
	void switchOffSuppressesVaccineReminder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = newbornWithBirthDoses(owner.accessToken());
		manualPlan(owner.accessToken(), babyId, FLU, "1", TODAY);
		record(owner, topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"), "1200.00");
		assertThat(saveBudgets(owner, "1000.00").code()).isEqualTo("OK");
		assertThat(typesOf(pending(owner))).contains(VACCINE_UPCOMING, "BUDGET_OVERRUN");

		assertThat(saveSettings(owner, List.of(setting(VACCINE_UPCOMING, false))).code()).isEqualTo("OK");

		assertThat(typesOf(pending(owner))).as("关的是疫苗那一类，超预算那一条不该被连坐").containsExactly("BUDGET_OVERRUN");
	}

	@Test
	@DisplayName("A 家的疫苗提醒不会出现在 B 家的待提醒里")
	void vaccineRemindersAreFamilyScoped() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long babyId = newbornWithBirthDoses(owner.accessToken());
		manualPlan(owner.accessToken(), babyId, FLU, "1", TODAY.plusDays(1));

		assertThat(keysOf(pending(owner), VACCINE_UPCOMING)).hasSize(1);
		assertThat(typesOf(pending(outsider))).as("B 家没有宝宝，开关开着也没有产出").isEmpty();
	}

	@Test
	@DisplayName("归档的宝宝不再被催：待办类统计本来就不含它")
	void archivedBabyProducesNoVaccineReminder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = newbornWithBirthDoses(token);
		manualPlan(token, babyId, FLU, "1", TODAY);
		assertThat(typesOf(pending(owner))).contains(VACCINE_UPCOMING);

		assertThat(patchJson(BABIES + "/" + babyId + "/archive", null, token).code()).isEqualTo("OK");

		assertThat(typesOf(pending(owner))).as("归档是「不再参与新记录」，不是把历史抹掉").doesNotContain(VACCINE_UPCOMING);
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

	/** 出生当天那两针本身就是「0 天后应接种」，先录掉它们，被测的那一条才数得清。 */
	private long newbornWithBirthDoses(String token) throws Exception {
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		record(token, babyId, HEP_B, "1");
		record(token, babyId, BCG, "1");
		return babyId;
	}

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

	private JsonNode itemWithKey(List<JsonNode> items, String key) {
		return items.stream()
			.filter(item -> item.path("key").asText().equals(key))
			.findFirst()
			.orElseThrow(() -> new AssertionError("待提醒里应有 key = " + key + " 的那一条"));
	}

	/** 两列要么都有要么都没有（§4.5.2 的形状约定），所以判有无只看 fireAt 就够。 */
	private static boolean fireAtIsAbsent(JsonNode item) {
		return item.path("fireAt").isNull() && item.path("fireDate").isNull();
	}

	/** 自费疫苗的手动建项：既决定了应种日期，也决定了这一条提醒的去重键。 */
	private long manualPlan(String token, long babyId, String vaccineName, String doseNo, LocalDate dueDate)
			throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("vaccineName", vaccineName);
		body.put("doseNo", doseNo);
		body.put("dueDate", dueDate.toString());
		Call call = postJson(BABY_VACCINE_PLANS, body, token);
		assertThat(call.code()).as("手动应种项建不出来，后面的断言都没有意义").isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private void record(String token, long babyId, String vaccineName, String doseNo) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("vaccineName", vaccineName);
		body.put("doseNo", doseNo);
		body.put("givenDate", TODAY.toString());
		assertThat(postJson(BABY_VACCINE_RECORDS, body, token).code()).as("出生那两针录不进去，后面的断言都没有意义")
			.isEqualTo("OK");
	}

	private void record(Account account, long categoryId, long accountId, String amount) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("amount", amount);
		body.put("categoryId", categoryId);
		body.put("accountId", accountId);
		body.put("bizDate", TODAY.toString());
		assertThat(postJson(TRANSACTIONS, body, account.accessToken()).code()).isEqualTo("OK");
	}

	private Call saveBudgets(Account account, String amount) throws Exception {
		Map<String, Object> item = new LinkedHashMap<>();
		item.put("scope", "FAMILY");
		item.put("categoryId", null);
		item.put("memberUserId", null);
		item.put("amount", amount);
		return putJson(BUDGETS, Map.of("items", List.of(item)), account.accessToken());
	}

	private Call saveSettings(Account account, List<Map<String, Object>> items) throws Exception {
		return putJson(REMINDER_SETTINGS, Map.of("items", items), account.accessToken());
	}

	private static Map<String, Object> setting(String type, boolean enabled) {
		return Map.of("type", type, "enabled", enabled);
	}

	private List<JsonNode> toList(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

}
