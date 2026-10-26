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
 * §4.3.3 驱虫记录，对应验收用例 18 与 19。
 * <p>
 * 下次驱虫日期的三个分支是这一类的主体：按周期算（基准必须是驱虫日期）、手动覆盖（照抄不回算）、
 * 改周期（只影响之后新建的记录）。日期一律相对今天写，只有驱虫日期本身是往前减出来的固定日子，
 * 因为那条规则的要害正是「不许拿今天当基准」。
 */
class CatDewormingIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("用例 18：下次日期由驱虫日期按周期推算，不是从今天往后算")
	void case18_nextDateDefaultsToOneMonthAfterTheRecord() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		LocalDate doneDate = TODAY.minusMonths(2);

		JsonNode row = create(owner, form(catId, "EXTERNAL", doneDate, null));

		assertThat(row.path("nextDate").asText()).as("外驱默认 1 个月，加在这条记录的驱虫日期上")
			.isEqualTo(doneDate.plusMonths(1).toString());
		assertThat(row.path("nextDate").asText()).as("误用 today.plusMonths(1) 会落到这里").isNotEqualTo(TODAY.plusMonths(1).toString());
		assertThat(row.path("doneDate").asText()).isEqualTo(doneDate.toString());
		assertThat(row.path("catName").asText()).as("猫名是反查出来的，不是让前端自己按 catId 找").isEqualTo("奶糖");
		assertThat(row.path("medicine").asText()).isEqualTo("拜宠清");
	}

	@Test
	@DisplayName("用例 18：手动给的下次日期照抄不回算；整份覆盖也能把规格/剂量与备注真清空")
	void case18_manualOverrideSurvives() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		LocalDate doneDate = TODAY.minusMonths(2);

		JsonNode created = create(owner, form(catId, "INTERNAL", doneDate, doneDate.plusDays(20)));

		assertThat(created.path("nextDate").asText()).as("给了就照抄，不回算成内驱默认的 +3 个月")
			.isEqualTo(doneDate.plusDays(20).toString());

		Map<String, Object> edited = form(catId, "INTERNAL", doneDate, doneDate.plusDays(45));
		edited.put("dosage", null);
		edited.put("remark", null);
		Call call = patchJson(CAT_DEWORMINGS + "/" + created.path("id").asLong(), edited, owner.accessToken());

		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("nextDate").asText()).as("PATCH 里手动给的那天才作数，不用周期重算")
			.isEqualTo(doneDate.plusDays(45).toString());
		assertThat(call.data().path("dosage").isNull()).as("不传即清空：updateById 会静默留着旧值").isTrue();
		assertThat(call.data().path("remark").isNull()).isTrue();
	}

	@Test
	@DisplayName("用例 19：外驱周期从 1 个月改成 2 个月，已有记录一字不变，只有之后新建的按新周期")
	void case19_changingTheCycleLeavesExistingRecordsAlone() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		LocalDate doneDate = TODAY.minusMonths(3);
		JsonNode old = create(owner, form(catId, "EXTERNAL", doneDate, null));
		assertThat(old.path("nextDate").asText()).as("没有设置行时按默认 1 个月").isEqualTo(doneDate.plusMonths(1).toString());

		saveSettings(owner, 3, 2);

		assertThat(findById(list(owner, null), old.path("id").asLong()).path("nextDate").asText())
			.as("已有记录不被顺手重算").isEqualTo(doneDate.plusMonths(1).toString());
		assertThat(create(owner, form(catId, "EXTERNAL", doneDate, null)).path("nextDate").asText())
			.as("同一天再记一条才吃新周期").isEqualTo(doneDate.plusMonths(2).toString());
	}

	@Test
	@DisplayName("内驱读内驱那一列月数、外驱读外驱那一列：两条同名类型的记录各按各的周期")
	void internalUsesTheOtherColumn() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		saveSettings(owner, 6, 2);
		LocalDate doneDate = TODAY.minusDays(40);

		assertThat(create(owner, form(catId, "INTERNAL", doneDate, null)).path("nextDate").asText())
			.isEqualTo(doneDate.plusMonths(6).toString());
		assertThat(create(owner, form(catId, "EXTERNAL", doneDate, null)).path("nextDate").asText())
			.as("把两列月数读反时这两条断言会同时红").isEqualTo(doneDate.plusMonths(2).toString());
	}

	@Test
	@DisplayName("下次驱虫日期必须晚于本次：早于和同一天都被拒，一条也不落库")
	void nextDateNotAfterDoneDateIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		LocalDate doneDate = TODAY.minusDays(10);

		Call earlier = postJson(CAT_DEWORMINGS, form(catId, "EXTERNAL", doneDate, doneDate.minusDays(1)),
				owner.accessToken());
		assertThat(earlier.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(earlier.message()).contains("晚于本次驱虫日期");
		assertThat(postJson(CAT_DEWORMINGS, form(catId, "EXTERNAL", doneDate, doneDate), owner.accessToken()).code())
			.as("同一天等于「今天驱完明天又该驱」，同样是手滑").isEqualTo("BAD_REQUEST");
		assertThat(list(owner, null)).isEmpty();
	}

	@Test
	@DisplayName("驱虫日期可以回溯填过去，但不能晚于今天")
	void futureDoneDateIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");

		Call call = postJson(CAT_DEWORMINGS, form(catId, "EXTERNAL", TODAY.plusDays(1), null), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.message()).contains("不能晚于今天");
		assertThat(list(owner, null)).isEmpty();
	}

	@Test
	@DisplayName("已归档的猫不接受新记录：要先恢复在册")
	void archivedCatRefusesANewRecord() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		patchJson(CATS + "/" + catId + "/archive", Map.of(), owner.accessToken());

		Call call = postJson(CAT_DEWORMINGS, form(catId, "EXTERNAL", TODAY.minusDays(3), null), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.message()).as("文案要指出恢复在册这条路").contains("归档");
		assertThat(list(owner, null)).isEmpty();
	}

	@Test
	@DisplayName("归档之后记录照旧出现在列表里，猫名也照旧给得出：归档不等于删除")
	void listShowsRecordsOfAnArchivedCat() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		JsonNode row = create(owner, form(catId, "EXTERNAL", TODAY.minusDays(3), null));

		patchJson(CATS + "/" + catId + "/archive", Map.of(), owner.accessToken());

		List<JsonNode> rows = list(owner, null);
		assertThat(rows).as("列表不带 enabled 条件").hasSize(1);
		assertThat(rows.get(0).path("id").asLong()).isEqualTo(row.path("id").asLong());
		assertThat(rows.get(0).path("catName").asText()).as("归档猫的名字反查还要走得通").isEqualTo("奶糖");
	}

	@Test
	@DisplayName("倒计时与逾期天数互斥，且「今天该驱」算倒计时而不是逾期")
	void daysToDueAndOverdueDaysAreMutuallyExclusive() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");

		JsonNode upcoming = create(owner, form(catId, "EXTERNAL", TODAY.minusDays(5), TODAY.plusDays(10)));
		assertThat(upcoming.path("daysToDue").asLong()).isEqualTo(10);
		assertThat(upcoming.path("overdueDays").isNull()).isTrue();

		JsonNode dueToday = create(owner, form(catId, "EXTERNAL", TODAY.minusDays(5), TODAY));
		assertThat(dueToday.path("daysToDue").asLong()).as("§4.3.3 的逾期判定不含等于").isZero();
		assertThat(dueToday.path("overdueDays").isNull()).isTrue();

		JsonNode late = create(owner, form(catId, "EXTERNAL", TODAY.minusDays(30), TODAY.minusDays(4)));
		assertThat(late.path("daysToDue").isNull()).isTrue();
		assertThat(late.path("overdueDays").asLong()).as("逾期值就是今天减下次日期").isEqualTo(4);
	}

	@Test
	@DisplayName("别家的猫按 id 记驱虫查不到，别家的记录改不了也删不掉")
	void catFromAnotherFamilyIsNotFound() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long catId = createCat(owner, "奶糖");

		Call foreign = postJson(CAT_DEWORMINGS, form(catId, "EXTERNAL", TODAY.minusDays(5), null),
				outsider.accessToken());
		assertThat(foreign.status()).isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(foreign.code()).isEqualTo("RESOURCE_NOT_FOUND");

		long id = create(owner, form(catId, "EXTERNAL", TODAY.minusDays(5), null)).path("id").asLong();
		assertThat(patchJson(CAT_DEWORMINGS + "/" + id, form(catId, "INTERNAL", TODAY.minusDays(5), null),
				outsider.accessToken()).code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(deleteNoBody(CAT_DEWORMINGS + "/" + id, outsider.accessToken()).code())
			.isEqualTo("RESOURCE_NOT_FOUND");

		assertThat(list(owner, null)).as("本家那条一个字段都没动").hasSize(1);
		assertThat(list(outsider, null)).as("外人自己家里一条也没有").isEmpty();
	}

	@Test
	@DisplayName("无家庭的账号碰驱虫端点返回 NO_FAMILY")
	void dewormingsRequireAFamily() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call listed = getJson(CAT_DEWORMINGS, lonely.accessToken());
		assertThat(listed.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(listed.code()).isEqualTo("NO_FAMILY");
		assertThat(postJson(CAT_DEWORMINGS, form(1L, "EXTERNAL", TODAY.minusDays(5), null), lonely.accessToken()).code())
			.isEqualTo("NO_FAMILY");
	}

	@Test
	@DisplayName("按别人家的 catId 过滤是 200 加空清单，不是 404：查询条件与注入的 family_id 求交自然为空")
	void filteringByAnotherFamilyCatReturnsEmpty() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long catId = createCat(owner, "奶糖");
		create(owner, form(catId, "EXTERNAL", TODAY.minusDays(5), null));

		Call call = getJson(CAT_DEWORMINGS + "?catId=" + catId, outsider.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.OK.value());
		assertThat(call.code()).isEqualTo("OK");
		assertThat(list(outsider, catId)).as("拿到的永远是空，这里没有任何信息可泄露").isEmpty();
	}

	// ---- 辅助 ----

	private List<JsonNode> list(Account account, Long catId) throws Exception {
		Call call = getJson(catId == null ? CAT_DEWORMINGS : CAT_DEWORMINGS + "?catId=" + catId,
				account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		List<JsonNode> nodes = new ArrayList<>();
		call.data().forEach(nodes::add);
		return nodes;
	}

	private JsonNode create(Account account, Map<String, Object> payload) throws Exception {
		Call call = postJson(CAT_DEWORMINGS, payload, account.accessToken());
		assertThat(call.code()).as("新增驱虫记录 %s", payload.get("type")).isEqualTo("OK");
		return call.data();
	}

	private long createCat(Account account, String name) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("name", name);
		body.put("gender", "FEMALE");
		body.put("birthdayEstimated", false);
		body.put("neutered", "YES");
		Call call = postJson(CATS, body, account.accessToken());
		assertThat(call.code()).as("建档 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private void saveSettings(Account account, int internalMonths, int externalMonths) throws Exception {
		Call call = putJson(CAT_SETTINGS, Map.of("internalMonths", internalMonths, "externalMonths", externalMonths),
				account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
	}

	private JsonNode findById(List<JsonNode> rows, long id) {
		return rows.stream().filter(node -> node.path("id").asLong() == id).findFirst().orElse(null);
	}

	private static Map<String, Object> form(long catId, String type, LocalDate doneDate, LocalDate nextDate) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("catId", catId);
		body.put("type", type);
		body.put("doneDate", doneDate.toString());
		body.put("medicine", "拜宠清");
		body.put("dosage", "按体重 4kg 用 1 支");
		body.put("nextDate", nextDate == null ? null : nextDate.toString());
		body.put("remark", "饭后喂");
		return body;
	}

}
