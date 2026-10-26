package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
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
 * §4.5.3 奶粉开罐的推导与余量推算（第 32 轮），与猫粮袋同一份 ConsumptionEstimate。
 * <p>
 * 日期一律相对今天写：在用罐的结束日就是今天，写死日期会让这条测试在第二天就改变被测的那件事。
 * 克数与天数都取整数，每个期望值都能一口心算核对。
 */
class BabyFormulaBagIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("已完成罐算得出使用天数与日均，当前罐算不出、余量卡按历史日均推；没历史时用手填的预估")
	void closedBagUsageAndCurrentEstimation() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long first = create(owner, bag("皇家一段", 800, TODAY.minusDays(20), null, "宝宝口粮"));
		long second = create(owner, bag("合生元", 800, TODAY.minusDays(5), null, null));

		List<JsonNode> bags = list(owner);
		assertThat(bags.stream().map(node -> node.path("id").asLong()).toList()).containsExactly(first, second);
		JsonNode closed = bags.get(0);
		assertThat(closed.path("usageDays").asLong()).as("今天−20 到 今天−5，不含结束日").isEqualTo(15);
		assertThat(closed.path("dailyAverage").asInt()).as("800 ÷ 15 = 53.33，四舍五入到 53").isEqualTo(53);
		assertThat(closed.path("current").asBoolean()).isFalse();
		assertThat(closed.path("remark").asText()).isEqualTo("宝宝口粮");
		JsonNode current = bags.get(1);
		assertThat(current.path("current").asBoolean()).isTrue();
		assertThat(current.path("usageDays").isNull()).as("一罐还没喝完，它自己的使用天数不是事实").isTrue();
		assertThat(current.path("dailyAverage").isNull()).isTrue();

		JsonNode card = current(owner);
		assertThat(card.path("bag").path("id").asLong()).isEqualTo(second);
		assertThat(card.path("estimate").path("usedDays").asLong()).as("今天−5 到今天，含头含尾").isEqualTo(6);
		assertThat(card.path("estimate").path("dailyAverage").asInt()).isEqualTo(53);
		assertThat(card.path("estimate").path("consumedGrams").asInt()).as("6 × 53").isEqualTo(318);
		assertThat(card.path("estimate").path("remainingGrams").asInt()).isEqualTo(482);
		assertThat(card.path("estimate").path("daysLeft").asInt()).as("482 ÷ 53 = 9.09").isEqualTo(9);
		assertThat(card.path("estimate").path("depletionDate").asText()).isEqualTo(TODAY.plusDays(9).toString());
		assertThat(card.path("estimate").path("fromHistory").asBoolean()).isTrue();
		assertThat(card.path("estimate").path("overEstimate").asBoolean()).isFalse();

		// 只有一罐且填了预估日均：没有历史可折算，退到用户手填的预估
		Account fresh = registerWithFamily("13800000009", "李四");
		create(fresh, bag("合生元", 800, TODAY.minusDays(2), 100, null));
		JsonNode freshCard = current(fresh);
		assertThat(freshCard.path("estimate").path("dailyAverage").asInt()).as("没有历史罐，用开罐时填的预估").isEqualTo(100);
		assertThat(freshCard.path("estimate").path("fromHistory").asBoolean()).isFalse();
	}

	@Test
	@DisplayName("只改后一罐的开罐日，前一罐的使用天数与日均跟着重算，清空的预估与备注真写成 NULL")
	void editingStartedDateRecomputesThePreviousBag() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long first = create(owner, bag("皇家一段", 800, TODAY.minusDays(20), 80, "旧备注"));
		long second = create(owner, bag("合生元", 800, TODAY.minusDays(5), 100, "旧备注"));

		// 只给第二罐发一次 PATCH，且这份表单里预估日均与备注都是空的
		assertThat(patchJson(BABY_FORMULA_BAGS + "/" + second, bag("合生元", 800, TODAY.minusDays(10), null, null),
				owner.accessToken()).code()).isEqualTo("OK");

		List<JsonNode> bags = list(owner);
		assertThat(bags.get(0).path("usageDays").asLong())
			.as("A 的结束日就是 B 的新开罐日，全程没对 A 发过请求").isEqualTo(10);
		assertThat(bags.get(0).path("dailyAverage").asInt()).as("800 ÷ 10").isEqualTo(80);
		assertThat(bags.get(1).path("estimatedDailyGrams").isNull())
			.as("整份表单覆盖要把清空的预估日均真写成 NULL").isTrue();
		assertThat(bags.get(1).path("remark").isNull()).isTrue();
		assertThat(current(owner).path("estimate").path("usedDays").asLong()).isEqualTo(11);
		assertThat(bags.get(0).path("id").asLong()).isEqualTo(first);
	}

	@Test
	@DisplayName("同一天开第二罐被拒，且响应给的就是那句人话")
	void duplicateStartedDateIsRejectedWithAClearMessage() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		create(owner, bag("皇家一段", 800, TODAY.minusDays(5), null, null));

		Call call = postJson(BABY_FORMULA_BAGS, bag("合生元", 800, TODAY.minusDays(5), null, null), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.message()).isEqualTo("该日期已有一罐奶粉，一个家庭同一天只能开一罐");
		assertThat(list(owner)).hasSize(1);
	}

	@Test
	@DisplayName("删掉中间那罐，前后两罐自动重新闭合；软删后同一天重录要能成")
	void deletingAndReinsertingReclosesTheTimeline() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		create(owner, bag("皇家一段", 800, TODAY.minusDays(30), null, null));
		long middle = create(owner, bag("合生元", 800, TODAY.minusDays(20), null, null));
		create(owner, bag("美素佳儿", 800, TODAY.minusDays(5), null, null));

		assertThat(deleteNoBody(BABY_FORMULA_BAGS + "/" + middle, owner.accessToken()).code()).isEqualTo("OK");

		List<JsonNode> bags = list(owner);
		assertThat(bags).hasSize(2);
		assertThat(bags.get(0).path("usageDays").asLong()).as("30 → 5，中间那罐一删就接上了").isEqualTo(25);
		assertThat(bags.get(0).path("dailyAverage").asInt()).as("800 ÷ 25").isEqualTo(32);
		assertThat(bags.get(1).path("current").asBoolean()).isTrue();

		Map<String, Object> reinserted = bag("合生元", 800, TODAY.minusDays(20), null, "补录");
		assertThat(postJson(BABY_FORMULA_BAGS, reinserted, owner.accessToken()).code())
			.as("应用层查重与库上的唯一索引都不许把补录的路堵死").isEqualTo("OK");
		// 删掉的那罐不会跟着回来：重录是新行
		assertThat(list(owner).stream().map(node -> node.path("id").asLong()).toList())
			.doesNotContain(middle);
	}

	@Test
	@DisplayName("别家的罐按 id 修改 404；无家庭的账号全部端点 NO_FAMILY")
	void isolationAndFamilyRequirement() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long id = create(owner, bag("皇家一段", 800, TODAY.minusDays(10), null, null));

		Call call = patchJson(BABY_FORMULA_BAGS + "/" + id, bag("被篡改", 800, TODAY.minusDays(10), null, null),
				outsider.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(deleteNoBody(BABY_FORMULA_BAGS + "/" + id, outsider.accessToken()).code())
			.isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(list(owner).get(0).path("brand").asText()).isEqualTo("皇家一段");

		Account lonely = register(PHONE_ALONE, "赵六");
		assertThat(getJson(BABY_FORMULA_BAGS, lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
		assertThat(getJson(BABY_FORMULA_BAG_CURRENT, lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
		assertThat(getJson(BABY_FORMULA_STATISTICS, lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
		assertThat(postJson(BABY_FORMULA_BAGS, bag("皇家一段", 800, TODAY.minusDays(1), null, null),
				lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
	}

	@Test
	@DisplayName("包装规格越界是校验失败、开罐日不能是未来；奶粉见底提醒由默认开关直接进 pending")
	void validationAndLowReminder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		assertThat(postJson(BABY_FORMULA_BAGS, bag("皇家一段", 100001, TODAY.minusDays(3), null, null),
				owner.accessToken()).code()).isEqualTo("VALIDATION_FAILED");
		assertThat(postJson(BABY_FORMULA_BAGS, bag("皇家一段", 800, TODAY.plusDays(1), null, null),
				owner.accessToken()).message()).contains("不能晚于今天");
		assertThat(list(owner)).isEmpty();

		// 一罐开在今天、按历史日均推：首家没历史靠手填预估 200 g/日 → 800 克 4 天见底，剩余 0 天不改发
		create(owner, bag("皇家一段", 800, TODAY.minusDays(4), 300, null));
		JsonNode card = current(owner);
		assertThat(card.path("estimate").path("daysLeft").asInt()).isZero();
		assertThat(card.path("estimate").path("overEstimate").asBoolean()).as("4 × 300 = 1200 > 800，超期未换罐")
			.isTrue();

		List<JsonNode> pending = pendingList(owner);
		assertThat(pending.stream().map(node -> node.path("type").asText()).toList())
			.as("奶粉见底默认开（§4.5.3），触底即进待办").contains("BABY_FORMULA_LOW");
		JsonNode row = pending.stream().filter(node -> node.path("type").asText().equals("BABY_FORMULA_LOW"))
			.findFirst().orElseThrow();
		assertThat(row.path("body").asText()).isEqualTo("已超出预计用量，请确认是否已开新罐");
		assertThat(row.path("route").asText()).isEqualTo("/baby/formulas");
	}

	@Test
	@DisplayName("统计：累计克数与日均按区间口径算，逐月柱形求和恒等于整段（telescoping）")
	void statisticsAreConsistentWithTheTimeline() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		// 30 天前开第一罐（用了 20 天吃完 800 g）；10 天前开第二罐（在用，按历史日均分摊到本次查询日）
		create(owner, bag("皇家一段", 800, TODAY.minusDays(30), null, null));
		create(owner, bag("合生元", 800, TODAY.minusDays(10), null, null));

		JsonNode stats = getJson(BABY_FORMULA_STATISTICS, owner.accessToken()).data();
		// 与猫粮同一分摊数学：已完成罐按实际使用天数分摊整罐，在用罐按已用天数分摊整罐
		// （consumedThrough 封顶在 usageDays，对在用罐即「今天为止」）——这里只断确定值，
		// 不断具体月份的克数：它依赖「今天」落在哪个月的哪一天，写死会在月初/月末变红
		assertThat(stats.path("totalGrams").asInt()).isEqualTo(1600);
		assertThat(stats.path("totalDays").asLong()).as("从第一罐开罐日到今天，含头含尾").isEqualTo(31);
		assertThat(stats.path("dailyAverage").asInt()).as("1600 ÷ 31 = 51.6 → 52").isEqualTo(52);

		// telescoping：6 根柱子的总和恒等于整段消耗，不会出现「逐月相加比概览卡多几克」的毛刺
		int monthSum = 0;
		List<JsonNode> trend = new ArrayList<>();
		stats.path("monthlyTrend").forEach(trend::add);
		assertThat(trend).hasSize(6);
		for (JsonNode month : trend) {
			monthSum += month.path("grams").asInt();
		}
		assertThat(monthSum).isEqualTo(1600);
	}

	// ---- 辅助 ----

	private List<JsonNode> pendingList(Account account) throws Exception {
		Call call = getJson(REMINDER_PENDING, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		List<JsonNode> nodes = new ArrayList<>();
		call.data().forEach(nodes::add);
		return nodes;
	}

	private List<JsonNode> list(Account account) throws Exception {
		Call call = getJson(BABY_FORMULA_BAGS, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		List<JsonNode> nodes = new ArrayList<>();
		call.data().forEach(nodes::add);
		return nodes;
	}

	private JsonNode current(Account account) throws Exception {
		Call call = getJson(BABY_FORMULA_BAG_CURRENT, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private long create(Account account, Map<String, Object> payload) throws Exception {
		Call call = postJson(BABY_FORMULA_BAGS, payload, account.accessToken());
		assertThat(call.code()).as("开一罐奶粉 %s", payload.get("brand")).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private static Map<String, Object> bag(String brand, int packGrams, LocalDate startedDate, Integer dailyGrams,
			String remark) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("brand", brand);
		body.put("packGrams", packGrams);
		body.put("startedDate", startedDate.toString());
		body.put("estimatedDailyGrams", dailyGrams);
		body.put("remark", remark);
		return body;
	}

}