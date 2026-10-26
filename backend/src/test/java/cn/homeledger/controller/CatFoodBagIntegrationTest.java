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
 * §4.3.2 猫粮袋的推导与 §4.3.4 的余量推算，对应验收用例 21 / 24 / 25。
 * <p>
 * 日期一律相对今天写：在用袋的结束日就是今天，写死日期会让这条测试在第二天就改变被测的那件事。
 * 克数与天数都取整数，每个期望值都能一口心算核对。
 */
class CatFoodBagIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("用例 21：已完成袋算得出使用天数与日均，当前袋算不出、余量卡按历史日均推")
	void case21_closedBagUsageAndCurrentEstimation() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long first = create(owner, bag("皇家", 2000, TODAY.minusDays(50), "换粮过渡期"));
		long second = create(owner, bag("渴望", 2000, TODAY.minusDays(10), null));

		List<JsonNode> bags = list(owner);
		assertThat(bags.stream().map(node -> node.path("id").asLong()).toList()).containsExactly(first, second);
		JsonNode closed = bags.get(0);
		assertThat(closed.path("usageDays").asLong()).as("今天−50 到 今天−10，不含结束日").isEqualTo(40);
		assertThat(closed.path("dailyAverage").asInt()).as("2000 ÷ 40").isEqualTo(50);
		assertThat(closed.path("current").asBoolean()).isFalse();
		assertThat(closed.path("remark").asText()).as("落库的备注要回带出来").isEqualTo("换粮过渡期");
		JsonNode current = bags.get(1);
		assertThat(current.path("current").asBoolean()).isTrue();
		assertThat(current.path("usageDays").isNull()).as("一袋还没吃完，它自己的使用天数不是事实").isTrue();
		assertThat(current.path("dailyAverage").isNull()).isTrue();

		JsonNode card = current(owner);
		assertThat(card.path("bag").path("id").asLong()).isEqualTo(second);
		assertThat(card.path("estimate").path("usedDays").asLong()).as("今天−10 到今天，含头含尾").isEqualTo(11);
		assertThat(card.path("estimate").path("dailyAverage").asInt()).isEqualTo(50);
		assertThat(card.path("estimate").path("consumedGrams").asInt()).as("11 × 50").isEqualTo(550);
		assertThat(card.path("estimate").path("remainingGrams").asInt()).isEqualTo(1450);
		assertThat(card.path("estimate").path("remainingPercent").asInt()).as("72.5% 向下取整").isEqualTo(72);
		assertThat(card.path("estimate").path("daysLeft").asInt()).as("1450 ÷ 50").isEqualTo(29);
		assertThat(card.path("estimate").path("depletionDate").asText())
			.as("今天 + 29 天，界面上那句「约可用至」的日期").isEqualTo(TODAY.plusDays(29).toString());
		assertThat(card.path("estimate").path("fromHistory").asBoolean()).isTrue();
		assertThat(card.path("estimate").path("overEstimate").asBoolean()).isFalse();
	}

	@Test
	@DisplayName("用例 24：只改后一袋的开始日，前一袋的使用天数与日均跟着重算，被清空的备注真写成 NULL")
	void case24_editingStartedDateRecomputesThePreviousBag() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long first = create(owner, bag("皇家", 2000, TODAY.minusDays(50), "换粮过渡期"));
		long second = create(owner, bag("渴望", 2000, TODAY.minusDays(10), "旧备注"));

		// 只给第二袋发一次 PATCH，且这份表单里 remark 是空的
		assertThat(patchJson(CAT_FOOD_BAGS + "/" + second, bag("渴望", 2000, TODAY.minusDays(20), null),
				owner.accessToken()).code()).isEqualTo("OK");

		List<JsonNode> bags = list(owner);
		assertThat(bags.get(0).path("usageDays").asLong())
			.as("A 的结束日就是 B 的新开始日，全程没对 A 发过请求")
			.isEqualTo(30);
		assertThat(bags.get(0).path("dailyAverage").asInt()).as("2000 ÷ 30 = 66.67，四舍五入到 67").isEqualTo(67);
		assertThat(bags.get(1).path("remark").isNull()).as("整份表单覆盖要把清空的备注真写成 NULL").isTrue();
		assertThat(current(owner).path("estimate").path("usedDays").asLong()).isEqualTo(21);
		assertThat(bags.get(0).path("id").asLong()).isEqualTo(first);
	}

	@Test
	@DisplayName("用例 25：同一天开第二袋被拒，且响应给的就是那句人话")
	void case25_duplicateStartedDateIsRejectedWithAClearMessage() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		create(owner, bag("皇家", 2000, TODAY.minusDays(5), null));

		Call call = postJson(CAT_FOOD_BAGS, bag("渴望", 2000, TODAY.minusDays(5), null), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.message()).as("应用层查重的全部职责就是这句人话，只断 400 等于没测").isEqualTo("该日期已有另一袋猫粮，一个家庭同一天只能开一袋");
		assertThat(list(owner)).as("被拒的那一袋没落库").hasSize(1);
	}

	@Test
	@DisplayName("用例 25：删掉中间那袋，前后两袋自动重新闭合")
	void case25_deletingTheMiddleBagReclosesTheTimeline() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		create(owner, bag("皇家", 2000, TODAY.minusDays(50), null));
		long middle = create(owner, bag("渴望", 1500, TODAY.minusDays(30), null));
		create(owner, bag("网易严选", 2000, TODAY.minusDays(10), null));

		assertThat(deleteNoBody(CAT_FOOD_BAGS + "/" + middle, owner.accessToken()).code()).isEqualTo("OK");

		List<JsonNode> bags = list(owner);
		assertThat(bags).hasSize(2);
		assertThat(bags.get(0).path("usageDays").asLong()).as("50 → 10，中间那袋一删就接上了").isEqualTo(40);
		assertThat(bags.get(0).path("dailyAverage").asInt()).isEqualTo(50);
		assertThat(bags.get(1).path("current").asBoolean()).isTrue();
	}

	@Test
	@DisplayName("用例 25：删掉的那袋用同一个开始日重录要能成，软删行不占这个日期")
	void case25_reinsertingADeletedStartDateSucceeds() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		create(owner, bag("皇家", 2000, TODAY.minusDays(50), null));
		long middle = create(owner, bag("渴望", 1500, TODAY.minusDays(30), null));

		deleteNoBody(CAT_FOOD_BAGS + "/" + middle, owner.accessToken());
		Map<String, Object> reinserted = bag("渴望", 1500, TODAY.minusDays(30), "补录");
		assertThat(postJson(CAT_FOOD_BAGS, reinserted, owner.accessToken()).code())
			.as("应用层查重与库上的唯一索引都不许把补录的路堵死").isEqualTo("OK");

		List<JsonNode> bags = list(owner);
		assertThat(bags).as("删掉的那袋不会跟着回来，列表仍是两袋").hasSize(2);
		assertThat(bags.get(1).path("id").asLong()).as("重录的是新行，不是把软删的那行翻回来").isNotEqualTo(middle);
		assertThat(bags.get(1).path("remark").asText()).isEqualTo("补录");
	}

	@Test
	@DisplayName("别家的袋子按 id 修改一律 404，本家的时间线不动")
	void bagFromAnotherFamilyIsNotFound() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long id = create(owner, bag("皇家", 2000, TODAY.minusDays(50), null));

		Call call = patchJson(CAT_FOOD_BAGS + "/" + id, bag("被篡改", 3000, TODAY.minusDays(50), null),
				outsider.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(call.code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(deleteNoBody(CAT_FOOD_BAGS + "/" + id, outsider.accessToken()).code()).isEqualTo("RESOURCE_NOT_FOUND");

		JsonNode untouched = list(owner).get(0);
		assertThat(untouched.path("brand").asText()).isEqualTo("皇家");
		assertThat(untouched.path("packGrams").asInt()).isEqualTo(2000);
		assertThat(list(outsider)).isEmpty();
	}

	@Test
	@DisplayName("无家庭的账号碰猫粮袋端点返回 NO_FAMILY")
	void foodBagsRequireAFamily() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call listed = getJson(CAT_FOOD_BAGS, lonely.accessToken());
		assertThat(listed.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(listed.code()).isEqualTo("NO_FAMILY");
		assertThat(getJson(CAT_FOOD_BAG_CURRENT, lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
		assertThat(postJson(CAT_FOOD_BAGS, bag("皇家", 2000, TODAY.minusDays(1), null), lonely.accessToken()).code())
			.isEqualTo("NO_FAMILY");
	}

	@Test
	@DisplayName("包装规格越界是 400 的校验失败，不是带着 0 克或超大值走进推算后炸成 500")
	void packGramsAboveTheBoundIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		Call tooBig = postJson(CAT_FOOD_BAGS, bag("皇家", 100001, TODAY.minusDays(3), null), owner.accessToken());
		assertThat(tooBig.status()).as("100001 克这一挡是余量推算不溢出的前提").isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(tooBig.code()).isEqualTo("VALIDATION_FAILED");
		assertThat(postJson(CAT_FOOD_BAGS, bag("皇家", 0, TODAY.minusDays(3), null), owner.accessToken()).code())
			.isEqualTo("VALIDATION_FAILED");
		assertThat(list(owner)).isEmpty();
	}

	@Test
	@DisplayName("开始喂养日期晚于今天被拒：可回溯填过去，但不能预支未来的一袋")
	void futureStartedDateIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		Call call = postJson(CAT_FOOD_BAGS, bag("皇家", 2000, TODAY.plusDays(1), null), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.message()).contains("不能晚于今天");
		assertThat(list(owner)).isEmpty();
	}

	// ---- 辅助 ----

	private List<JsonNode> list(Account account) throws Exception {
		Call call = getJson(CAT_FOOD_BAGS, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		List<JsonNode> nodes = new ArrayList<>();
		call.data().forEach(nodes::add);
		return nodes;
	}

	private JsonNode current(Account account) throws Exception {
		Call call = getJson(CAT_FOOD_BAG_CURRENT, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private long create(Account account, Map<String, Object> payload) throws Exception {
		Call call = postJson(CAT_FOOD_BAGS, payload, account.accessToken());
		assertThat(call.code()).as("开一袋猫粮 %s", payload.get("brand")).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private static Map<String, Object> bag(String brand, int packGrams, LocalDate startedDate, String remark) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("brand", brand);
		body.put("packGrams", packGrams);
		body.put("startedDate", startedDate.toString());
		body.put("remark", remark);
		return body;
	}

}
