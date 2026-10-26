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
 * §4.5.1 的三类猫提醒进 {@code GET /reminders/pending}（验收用例 20 的后半）。
 * <p>
 * 端点、条目那七个字段的形状、以及 {@code GET/PUT /reminders/settings} 的出参都不因这一步改变，
 * 所以这里的断言全部落在「哪几类该出现、正文是哪句话、去重键长什么样」上。
 * <p>
 * 日期一律相对今天：判的是「离今天还有几天」，写死日期明天就测不到那条边界了。
 */
class CatReminderIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final String DEWORMING_INTERNAL = "CAT_DEWORMING_INTERNAL";

	private static final String DEWORMING_EXTERNAL = "CAT_DEWORMING_EXTERNAL";

	private static final String FOOD_LOW = "CAT_FOOD_LOW";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("验收用例 20：提前 3 天是边界，还剩 4 天的那只猫不该出现在列表里")
	void case20_threeDaysAheadIsTheBoundary() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long due = cat(owner, "咪咪");
		dewormed(owner, due, "EXTERNAL", TODAY.minusDays(20), TODAY.plusDays(3));
		long stillFine = cat(owner, "花花");
		dewormed(owner, stillFine, "EXTERNAL", TODAY.minusDays(19), TODAY.plusDays(4));

		assertThat(keysOf(pending(owner), DEWORMING_EXTERNAL)).as("两侧都断：只断触发的一侧，提前量写成 30 这条也是绿的")
			.containsExactly(DEWORMING_EXTERNAL + ":CAT:" + due);
	}

	@Test
	@DisplayName("验收用例 20：逾期那条报的是逾期天数，key 与 route 两项形状照旧")
	void case20_overdueDewormingReportsTheOverdueDays() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = cat(owner, "咪咪");
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(32), TODAY.minusDays(2));

		JsonNode item = onlyOf(pending(owner), DEWORMING_EXTERNAL);
		assertThat(item.path("body").asText()).isEqualTo("咪咪的外驱已逾期 2 天");
		assertThat(item.path("title").asText()).as("标题说事由、正文说主体，与预算那两类同构").isEqualTo("猫咪体外驱虫到期");
		assertThat(item.path("key").asText()).isEqualTo(DEWORMING_EXTERNAL + ":CAT:" + catId);
		assertThat(item.path("route").asText()).isEqualTo("/cat/dewormings");
	}

	@Test
	@DisplayName("不在触发日上时给出下一个触发日的定时：逾期第 2 天排到第 3 天上午九点")
	void nonTriggerDaySchedulesTheNextThreeDayMark() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		dewormed(owner, cat(owner, "咪咪"), "EXTERNAL", TODAY.minusDays(32), TODAY.minusDays(2));

		JsonNode item = onlyOf(pending(owner), DEWORMING_EXTERNAL);

		assertThat(fireAtOf(item)).as("定时通知的意义就在这里：App 关着也能响").isEqualTo(TODAY.plusDays(1).atTime(9, 0));
		assertThat(item.path("fireDate").asText()).isEqualTo(TODAY.plusDays(1).toString());
	}

	@Test
	@DisplayName("提前 3 天与当天都是触发日：不给定时，那一刻已经成立")
	void triggerDaysAreImmediate() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		dewormed(owner, cat(owner, "三天后"), "EXTERNAL", TODAY.minusDays(20), TODAY.plusDays(3));
		dewormed(owner, cat(owner, "今天"), "EXTERNAL", TODAY.minusDays(30), TODAY);
		dewormed(owner, cat(owner, "逾期三天"), "EXTERNAL", TODAY.minusDays(33), TODAY.minusDays(3));

		List<JsonNode> items = pending(owner).stream()
			.filter(item -> item.path("type").asText().equals(DEWORMING_EXTERNAL))
			.toList();

		assertThat(items).as("三只猫各一条").hasSize(3);
		assertThat(items).as("三只猫各自都在自己的触发日上")
			.allSatisfy(item -> {
				assertThat(item.path("fireAt").isNull()).isTrue();
				assertThat(item.path("fireDate").isNull()).isTrue();
			});
	}

	@Test
	@DisplayName("提前量还没到的那只猫：定时也一并留给它到期那天，而不是今天")
	void beforeTheDueDateSchedulesTheDueDay() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		// 已逾期 1 天 → 下一个触发日是 2 天后（D+3），不是「明天」
		dewormed(owner, cat(owner, "咪咪"), "EXTERNAL", TODAY.minusDays(31), TODAY.minusDays(1));

		assertThat(fireAtOf(onlyOf(pending(owner), DEWORMING_EXTERNAL))).isEqualTo(TODAY.plusDays(2).atTime(9, 0));
	}

	@Test
	@DisplayName("验收用例 20：今天到期说「今天到期」，不说「还有 0 天」")
	void case20_todaysDewormingDoesNotSayZeroDays() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = cat(owner, "咪咪");
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(30), TODAY);

		assertThat(onlyOf(pending(owner), DEWORMING_EXTERNAL).path("body").asText()).contains("今天到期")
			.doesNotContain("0 天");
	}

	@Test
	@DisplayName("内驱与外驱是两个独立开关，一只猫的两格各算各的")
	void internalAndExternalAreSeparateSwitches() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = cat(owner, "咪咪");
		dewormed(owner, catId, "INTERNAL", TODAY.minusDays(95), TODAY.minusDays(1));
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(32), TODAY.minusDays(1));
		assertThat(typesOf(pending(owner))).containsExactlyInAnyOrder(DEWORMING_INTERNAL, DEWORMING_EXTERNAL);

		assertThat(saveSettings(owner, List.of(setting(DEWORMING_EXTERNAL, false))).code()).isEqualTo("OK");
		assertThat(typesOf(pending(owner))).as("这一条是内驱/外驱到提醒类型那张映射表的取证")
			.containsExactly(DEWORMING_INTERNAL);
	}

	@Test
	@DisplayName("一只猫拖了三次外驱也只产出一条：读倒计时而不是逐条读记录")
	void dewormingRemindersDoNotStackPerRecord() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = cat(owner, "咪咪");
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(60), TODAY.minusDays(20));
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(40), TODAY.minusDays(10));
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(20), TODAY.minusDays(1));

		assertThat(keysOf(pending(owner), DEWORMING_EXTERNAL)).as("三次逾期共用同一个去重键，前端按 key 也只剩一条")
			.hasSize(1);
		assertThat(onlyOf(pending(owner), DEWORMING_EXTERNAL).path("body").asText())
			.as("说的是最近那一次欠下的账").isEqualTo("咪咪的外驱已逾期 1 天");
	}

	@Test
	@DisplayName("验收用例 20：猫粮还剩 3 天口粮时出 CAT_FOOD_LOW，正文是克数加天数")
	void case20_foodLowReminderAtTheThreeDayBoundary() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		estimateDaily(owner, 200);
		openBag(owner, "测试牌", 1000, TODAY.minusDays(1));

		JsonNode item = onlyOf(pending(owner), FOOD_LOW);
		assertThat(item.path("body").asText()).as("已用 2 天 × 200g，剩 600g ÷ 200g").isEqualTo("剩余约 600 g，预计还能吃 3 天");
		assertThat(item.path("key").asText()).as("余量是家庭整体口径，键里不带猫").isEqualTo("CAT_FOOD_LOW:FAMILY");
		assertThat(item.path("route").asText()).isEqualTo("/cat/food-bags");
	}

	@Test
	@DisplayName("还能吃 5 天时不产猫粮提醒")
	void moreThanThreeDaysLeftProducesNoFoodReminder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		estimateDaily(owner, 200);
		openBag(owner, "测试牌", 1400, TODAY.minusDays(1));

		assertThat(typesOf(pending(owner))).as("理由与驱虫那条边界一样：只断触发的一侧挡不住提前量写大")
			.doesNotContain(FOOD_LOW);
	}

	@Test
	@DisplayName("剩余触底时用的是钉下来的那句原文")
	void foodBottomedOutUsesTheDocumentedCopy() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		estimateDaily(owner, 200);
		openBag(owner, "测试牌", 200, TODAY.minusDays(1));

		assertThat(onlyOf(pending(owner), FOOD_LOW).path("body").asText())
			.as("这句是 §4.3.4 定下的用户文案，写成 contains 就守不住它").isEqualTo("已超出预计用量，请确认是否已开新袋");
	}

	@Test
	@DisplayName("一袋都没开时推算整段为 null，猫粮那条既不产出也不抛")
	void noFoodBagProducesNoFoodLowReminder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		cat(owner, "咪咪");

		assertThat(getJson(REMINDER_PENDING, owner.accessToken()).status()).isEqualTo(HttpStatus.OK.value());
		assertThat(typesOf(pending(owner))).doesNotContain(FOOD_LOW);
	}

	@Test
	@DisplayName("预算两档全关的用户照样收得到猫提醒：预算那道短路只管预算这一段")
	void budgetSwitchesOffStillServeCatReminders() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = cat(owner, "咪咪");
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(32), TODAY.minusDays(2));
		assertThat(saveSettings(owner, List.of(setting("BUDGET_OVERRUN", false), setting("BUDGET_WARNING", false)))
			.code()).isEqualTo("OK");

		assertThat(typesOf(pending(owner))).as("短路还留在 pending() 里时这条红在 Expecting empty to not be empty")
			.containsExactly(DEWORMING_EXTERNAL);
	}

	@Test
	@DisplayName("反过来也一样：三个猫开关全关，超预算的产出不多也不少")
	void catSwitchesOffLeaveBudgetRemindersAlone() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = cat(owner, "咪咪");
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(32), TODAY.minusDays(2));
		assertThat(saveSettings(owner,
				List.of(setting(DEWORMING_INTERNAL, false), setting(DEWORMING_EXTERNAL, false), setting(FOOD_LOW, false)))
			.code()).isEqualTo("OK");
		assertThat(saveBudgets(owner, List.of(budgetItem("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		record(owner, topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"), "1200.00");

		assertThat(typesOf(pending(owner))).containsExactly("BUDGET_OVERRUN");
	}

	@Test
	@DisplayName("A 家的逾期猫与见底猫粮都不会出现在 B 家的待提醒里")
	void catRemindersAreFamilyScoped() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long catId = cat(owner, "咪咪");
		dewormed(owner, catId, "EXTERNAL", TODAY.minusDays(32), TODAY.minusDays(2));
		estimateDaily(owner, 200);
		openBag(owner, "测试牌", 200, TODAY.minusDays(1));

		assertThat(keysOf(pending(owner), DEWORMING_EXTERNAL)).containsExactly(DEWORMING_EXTERNAL + ":CAT:" + catId);
		assertThat(typesOf(pending(outsider))).as("B 家没有猫也没有袋子，两个开关开着也没有产出").isEmpty();
	}

	@Test
	@DisplayName("无家庭的账号：pending 是 200 加空列表，不是 403")
	void pendingWithoutAFamilyStaysEmpty() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call call = getJson(REMINDER_PENDING, lonely.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.OK.value());
		assertThat(toList(call.data())).isEmpty();
	}

	@Test
	@DisplayName("从没驱过虫的新猫不催：它压根不在倒计时里")
	void newCatWithNoDewormingRecordIsNotReminded() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		cat(owner, "刚领回来的猫");

		assertThat(pending(owner)).as("催这样一只猫该用「去记第一次驱虫」的引导文案，而不是一个没有日期的倒计时").isEmpty();
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

	/** 解成 {@code LocalDateTime} 再比：Jackson 在秒为 0 时会省掉那一段，比字符串是比写法而不是比时刻。 */
	private static LocalDateTime fireAtOf(JsonNode item) {
		assertThat(item.path("fireAt").isNull()).as("这一条本该有定时时刻").isFalse();
		return LocalDateTime.parse(item.path("fireAt").asText());
	}

	@Test
	@DisplayName("两条猫提醒都带自己的模块名：客户端按它把角标挂到猫咪 Tab 上（§4.5.2）")
	void remindersCarryTheirModule() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		dewormed(owner, cat(owner, "咪咪"), "EXTERNAL", TODAY.minusDays(32), TODAY.minusDays(2));
		estimateDaily(owner, 200);
		openBag(owner, "测试牌", 200, TODAY.minusDays(1));

		List<JsonNode> items = pending(owner);

		assertThat(itemOf(items, DEWORMING_EXTERNAL).path("module").asText()).isEqualTo("CAT");
		assertThat(itemOf(items, FOOD_LOW).path("module").asText()).isEqualTo("CAT");
	}

	@Test
	@DisplayName("返回顺序即紧急度顺序：逾期最久的在最前，其次三天内，最后是状态类（§4.6 第 4 条）")
	void pendingIsOrderedByUrgency() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		// 逾期 5 天的那只猫、以及恰好花完额度的家庭预算（已成立、但没有「欠了几天」）
		dewormed(owner, cat(owner, "逾期最久"), "EXTERNAL", TODAY.minusDays(35), TODAY.minusDays(5));
		dewormed(owner, cat(owner, "今天到期"), "INTERNAL", TODAY.minusDays(90), TODAY);
		dewormed(owner, cat(owner, "还有两天"), "EXTERNAL", TODAY.minusDays(28), TODAY.plusDays(2));
		record(owner, topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"), "1200.00");
		assertThat(saveBudgets(owner, List.of(budgetItem("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");

		assertThat(typesOf(pending(owner))).as("逾期 5 天 → 预算超支（已成立）→ 今天到期 → 还有两天")
			.containsExactly(DEWORMING_EXTERNAL, "BUDGET_OVERRUN", DEWORMING_INTERNAL, DEWORMING_EXTERNAL);
	}

	private JsonNode itemOf(List<JsonNode> items, String type) {
		return items.stream()
			.filter(item -> item.path("type").asText().equals(type))
			.findFirst()
			.orElseThrow(() -> new AssertionError("待提醒里应有类型 " + type));
	}

	private long cat(Account account, String name) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("name", name);
		body.put("gender", "UNKNOWN");
		body.put("birthday", null);
		body.put("birthdayEstimated", false);
		body.put("neutered", "UNKNOWN");
		Call call = postJson(CATS, body, account.accessToken());
		assertThat(call.code()).as("建档 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	/** 显式给 nextDate：走「用户覆盖照抄」那一支，测试因此不必先反推周期该算到哪一天。 */
	private void dewormed(Account account, long catId, String type, LocalDate doneDate, LocalDate nextDate)
			throws Exception {
		Call call = postJson(CAT_DEWORMINGS, Map.of("catId", catId, "type", type, "doneDate", doneDate.toString(),
				"medicine", "测试用药", "nextDate", nextDate.toString()), account.accessToken());
		assertThat(call.code()).as("驱虫记录建不出来，后面的断言都没有意义").isEqualTo("OK");
	}

	/** 预估日均住在 cat_setting 那一行而不是袋上（§4.3.2）：没设过它又没有已完成袋时，推算整段为 null。 */
	private void estimateDaily(Account account, int grams) throws Exception {
		Call call = putJson(CAT_SETTINGS,
				Map.of("internalMonths", 3, "externalMonths", 1, "estimatedDailyGrams", grams), account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
	}

	private void openBag(Account account, String brand, int packGrams, LocalDate startedDate) throws Exception {
		Call call = postJson(CAT_FOOD_BAGS,
				Map.of("brand", brand, "packGrams", packGrams, "startedDate", startedDate.toString()),
				account.accessToken());
		assertThat(call.code()).as("开一袋 %s", brand).isEqualTo("OK");
	}

	private Call saveSettings(Account account, List<Map<String, Object>> items) throws Exception {
		return putJson(REMINDER_SETTINGS, Map.of("items", items), account.accessToken());
	}

	private static Map<String, Object> setting(String type, boolean enabled) {
		return Map.of("type", type, "enabled", enabled);
	}

	private Call saveBudgets(Account account, List<Map<String, Object>> items) throws Exception {
		return putJson(BUDGETS, Map.of("items", items), account.accessToken());
	}

	private static Map<String, Object> budgetItem(String scope, Long categoryId, Long memberUserId, String amount) {
		Map<String, Object> item = new LinkedHashMap<>();
		item.put("scope", scope);
		item.put("categoryId", categoryId);
		item.put("memberUserId", memberUserId);
		item.put("amount", amount);
		return item;
	}

	private void record(Account account, long categoryId, long accountId, String amount) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("amount", amount);
		body.put("categoryId", categoryId);
		body.put("accountId", accountId);
		body.put("bizDate", TODAY.toString());
		assertThat(postJson(TRANSACTIONS, body, account.accessToken()).code()).isEqualTo("OK");
	}

	private List<JsonNode> toList(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

}
