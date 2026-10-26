package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §3.2 的模块开关与 Tab 顺序（{@code GET/PUT /preferences/modules}）。
 * <p>
 * 这一组端点的三条要点各有一份取证：<b>默认值</b>（三项全开、顺序记账→宝宝→猫咪——问题单 8
 * 把猫咪挪到宝宝后面）、<b>sortNo 由数组顺序派生</b>（客户端报不了号，也就报不出重号与空档）、
 * <b>按用户而非按家庭</b>（同一家庭里两个人各看各的 Tab，A1 定的就是这条）。
 */
class ModulePreferenceIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_ALONE = "13800000004";

	private static final String FINANCE = "FINANCE";

	private static final String CAT = "CAT";

	private static final String BABY = "BABY";

	@Test
	@DisplayName("一行都没有时按默认值补齐：三项全开、顺序记账→宝宝→猫咪、sortNo 从 0 起")
	void unsetPrefersDefaults() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		List<JsonNode> rows = modules(owner);

		assertThat(keysOf(rows)).containsExactly(FINANCE, BABY, CAT);
		assertThat(rows).allSatisfy(row -> assertThat(row.path("enabled").asBoolean()).isTrue());
		assertThat(rows.stream().map(row -> row.path("sortNo").asInt()).toList()).containsExactly(0, 1, 2);
		assertThat(rows.get(0).path("label").asText()).as("中文标签由服务端给，前端不硬编码三份").isEqualTo("记账");
	}

	@Test
	@DisplayName("数组顺序即展示顺序，sortNo 由它派生而不是客户端传")
	void saveFollowsArrayOrder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		assertThat(save(owner, item(BABY, true), item(FINANCE, true), item(CAT, false))).isEqualTo("OK");

		List<JsonNode> rows = modules(owner);
		assertThat(keysOf(rows)).as("提交顺序就是 Tab 顺序").containsExactly(BABY, FINANCE, CAT);
		assertThat(rows.stream().map(row -> row.path("sortNo").asInt()).toList()).containsExactly(0, 1, 2);
		assertThat(rows.get(2).path("enabled").asBoolean()).as("关掉的那一项也在响应里，只是 enabled 为 false").isFalse();
	}

	@Test
	@DisplayName("只提交一项不会静默关掉另外两项：未提交的沿用已存的值，接在后面")
	void partialSubmitKeepsTheOthers() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		assertThat(save(owner, item(CAT, false))).isEqualTo("OK");

		List<JsonNode> rows = modules(owner);
		assertThat(keysOf(rows)).containsExactly(CAT, FINANCE, BABY);
		assertThat(rowOf(rows, CAT).path("enabled").asBoolean()).isFalse();
		assertThat(rowOf(rows, FINANCE).path("enabled").asBoolean()).isTrue();
		assertThat(rowOf(rows, BABY).path("enabled").asBoolean()).isTrue();
	}

	@Test
	@DisplayName("开关是按用户存的：同一家庭里 A 关掉猫咪，B 仍是三项全开")
	void perUserNotPerFamily() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account member = register(PHONE_B, "李四");
		assertThat(inviteAndJoin(owner, member).code()).isEqualTo("OK");

		assertThat(save(owner, item(CAT, false))).isEqualTo("OK");

		assertThat(rowOf(modules(owner), CAT).path("enabled").asBoolean()).isFalse();
		assertThat(modules(member)).as("B 的 Tab 不该被 A 的选择改掉（A1）")
			.allSatisfy(row -> assertThat(row.path("enabled").asBoolean()).isTrue());
	}

	@Test
	@DisplayName("无家庭的账号：GET 回默认值、PUT 照常成功，不是 403")
	void worksWithoutFamily() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call get = getJson(PREFERENCE_MODULES, lonely.accessToken());
		assertThat(get.status()).isEqualTo(HttpStatus.OK.value());
		assertThat(keysOf(toList(get.data()))).containsExactly(FINANCE, BABY, CAT);

		assertThat(save(lonely, item(BABY, false))).isEqualTo("OK");
		assertThat(rowOf(modules(lonely), BABY).path("enabled").asBoolean()).isFalse();
	}

	@Test
	@DisplayName("不认识的模块与重复提交都报 BAD_REQUEST，并且各有一句能读的文案")
	void unknownOrDuplicatedModuleIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		Call unknown = putJson(PREFERENCE_MODULES, Map.of("items", List.of(item("STOCK", true))),
				owner.accessToken());
		assertThat(unknown.code()).as("认不出来要说是哪一个，不能只回一句「参数不合法」").isEqualTo("BAD_REQUEST");
		assertThat(unknown.message()).contains("STOCK");

		Call duplicated = putJson(PREFERENCE_MODULES,
				Map.of("items", List.of(item(CAT, true), item(CAT, false))), owner.accessToken());
		assertThat(duplicated.code()).isEqualTo("BAD_REQUEST");
		assertThat(duplicated.message()).contains(CAT);
	}

	@Test
	@DisplayName("两次查询给出同一个顺序：sortNo 相同也不靠运气")
	void orderIsStableAcrossCalls() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		assertThat(keysOf(modules(owner))).isEqualTo(keysOf(modules(owner)));
	}

	// ---- 辅助 ----

	private static Map<String, Object> item(String moduleKey, boolean enabled) {
		Map<String, Object> item = new LinkedHashMap<>();
		item.put("moduleKey", moduleKey);
		item.put("enabled", enabled);
		return item;
	}

	private String save(Account account, Map<String, Object>... items) throws Exception {
		return saveAll(account, List.of(items));
	}

	private String saveAll(Account account, List<Map<String, Object>> items) throws Exception {
		return putJson(PREFERENCE_MODULES, Map.of("items", items), account.accessToken()).code();
	}

	private List<JsonNode> modules(Account account) throws Exception {
		Call call = getJson(PREFERENCE_MODULES, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return toList(call.data());
	}

	private static List<String> keysOf(List<JsonNode> rows) {
		return rows.stream().map(row -> row.path("moduleKey").asText()).toList();
	}

	private static JsonNode rowOf(List<JsonNode> rows, String moduleKey) {
		return rows.stream()
			.filter(row -> row.path("moduleKey").asText().equals(moduleKey))
			.findFirst()
			.orElseThrow(() -> new AssertionError("模块列表里应有 " + moduleKey));
	}

	private static List<JsonNode> toList(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

}
