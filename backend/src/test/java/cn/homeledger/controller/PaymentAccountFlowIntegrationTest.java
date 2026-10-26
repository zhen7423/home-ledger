package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.common.PresetFinanceDict;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.2.1 支付方式字典。
 * <p>
 * 「名下有流水只能停用不能删除」这条要有流水才能测，放在 TransactionFlowIntegrationTest 里钉。
 */
class PaymentAccountFlowIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	@Test
	@DisplayName("创建家庭即装入 8 个预置支付方式，现金是默认项")
	void presetsAreInstalledAndCashIsDefault() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		List<JsonNode> accounts = list(owner, false);
		assertThat(names(accounts)).as("顺序即 sort_no，与 §4.2.1 的清单一致")
			.containsExactlyElementsOf(PresetFinanceDict.PAYMENT_ACCOUNTS);
		assertThat(accounts).allSatisfy(account -> assertThat(account.path("enabled").asBoolean()).isTrue());
		assertThat(defaultNames(accounts)).containsExactly("现金");
		for (int i = 0; i < accounts.size(); i++) {
			assertThat(accounts.get(i).path("sortNo").asInt()).isEqualTo(i + 1);
		}
	}

	@Test
	@DisplayName("设新默认时旧默认的标记在同一次请求里被清掉，家庭里恒有一行默认")
	void settingNewDefaultClearsTheOldOne() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long wechat = idOf(list(owner, false), "微信");

		Call call = patchJson(PAYMENT_ACCOUNTS + "/" + wechat, Map.of("isDefault", true), owner.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("isDefault").asBoolean()).isTrue();

		List<JsonNode> after = list(owner, false);
		assertThat(defaultNames(after)).as("默认项换人而不是两人并列").containsExactly("微信");
		assertThat(findByName(after, "现金").path("isDefault").asBoolean()).as("旧默认只是失去标记，行还在").isFalse();
	}

	@Test
	@DisplayName("当前默认项既不能停用也不能删除，要先让它把默认交出去")
	void defaultAccountCanBeNeitherDisabledNorDeleted() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long cash = idOf(list(owner, false), "现金");

		Call disabled = patchJson(PAYMENT_ACCOUNTS + "/" + cash + "/toggle", Map.of(), owner.accessToken());
		assertThat(disabled.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(disabled.code()).isEqualTo("PAYMENT_ACCOUNT_IS_DEFAULT");
		assertThat(deleteNoBody(PAYMENT_ACCOUNTS + "/" + cash, owner.accessToken()).code())
			.isEqualTo("PAYMENT_ACCOUNT_IS_DEFAULT");

		assertThat(findByName(list(owner, false), "现金").path("enabled").asBoolean()).as("被拒的两次都没改动数据")
			.isTrue();
	}

	@Test
	@DisplayName("已停用的支付方式不能被设为默认，否则它一当上默认就再也启用不了")
	void disabledAccountCannotBecomeDefault() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long credit = idOf(list(owner, false), "信用卡");
		patchJson(PAYMENT_ACCOUNTS + "/" + credit + "/toggle", Map.of(), owner.accessToken());

		Call call = patchJson(PAYMENT_ACCOUNTS + "/" + credit, Map.of("isDefault", true), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.message()).as("文案要指出先启用").contains("启用");
		assertThat(defaultNames(list(owner, false))).as("默认项没有被动到").containsExactly("现金");
	}

	@Test
	@DisplayName("isDefault=false 落在非默认项上是空操作，落在默认项上才拒")
	void unsettingDefaultIsOnlyRejectedOnTheCurrentDefault() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long alipay = idOf(list(owner, false), "支付宝");

		assertThat(patchJson(PAYMENT_ACCOUNTS + "/" + alipay, Map.of("isDefault", false), owner.accessToken()).code())
			.as("整份表单回传时带上 isDefault=false 是常见写法，不该因此报错").isEqualTo("OK");
		assertThat(defaultNames(list(owner, false))).containsExactly("现金");

		long cash = idOf(list(owner, false), "现金");
		assertThat(patchJson(PAYMENT_ACCOUNTS + "/" + cash, Map.of("isDefault", false), owner.accessToken()).code())
			.as("取消唯一的默认会让家庭没有默认项").isEqualTo("BAD_REQUEST");
	}

	@Test
	@DisplayName("名称查重：重名、带尾随空格、仅大小写不同都拒；改名时不算跟自己重名")
	void namesAreTrimmedAndDeduplicated() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		assertThat(createExpectingFailure(owner, "微信 ")).as("NO PAD 排序规则下尾随空格是显著字符，须先 trim")
			.isEqualTo("PAYMENT_ACCOUNT_NAME_DUPLICATED");
		assertThat(createExpectingFailure(owner, "现金")).isEqualTo("PAYMENT_ACCOUNT_NAME_DUPLICATED");

		long id = create(owner, "ETC卡");
		assertThat(findById(list(owner, false), id).path("name").asText()).isEqualTo("ETC卡");
		assertThat(createExpectingFailure(owner, "etc卡")).as("大小写不敏感由排序规则给出")
			.isEqualTo("PAYMENT_ACCOUNT_NAME_DUPLICATED");

		assertThat(patchJson(PAYMENT_ACCOUNTS + "/" + id, Map.of("name", "ETC卡 "), owner.accessToken()).code())
			.as("改名成自己原本的名字不算重名").isEqualTo("OK");
		assertThat(findById(list(owner, false), id).path("name").asText()).isEqualTo("ETC卡");
	}

	@Test
	@DisplayName("改名成空白被拒，名称不会被写成空串")
	void renamingToBlankIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long id = create(owner, "ETC卡");

		// name 可空表示「不改」，故 DTO 上没有 @NotBlank；一串空格 trim 后为空，必须在服务层拦下，
		// 否则会落一个空名称，与类别改名的 @NotBlank 口径不一致。
		Call call = patchJson(PAYMENT_ACCOUNTS + "/" + id, Map.of("name", "   "), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.code()).isEqualTo("VALIDATION_FAILED");
		assertThat(findById(list(owner, false), id).path("name").asText()).as("被拒后原名不动").isEqualTo("ETC卡");
	}

	@Test
	@DisplayName("拖拽排序按提交顺序重写 sort_no，清单不完整则整批拒绝")
	void sortRewritesSortNoInSubmittedOrder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		List<Long> ids = new ArrayList<>(
				list(owner, false).stream().map(node -> node.path("id").asLong()).toList());
		Collections.reverse(ids);

		assertThat(putJson(PAYMENT_ACCOUNTS + "/sort", Map.of("orderedIds", ids), owner.accessToken()).code())
			.isEqualTo("OK");
		assertThat(list(owner, false).stream().map(node -> node.path("id").asLong()).toList()).isEqualTo(ids);

		assertThat(putJson(PAYMENT_ACCOUNTS + "/sort", Map.of("orderedIds", ids.subList(0, 5)), owner.accessToken())
			.code()).isEqualTo("SORT_IDS_MISMATCH");
		assertThat(list(owner, false).stream().map(node -> node.path("id").asLong()).toList()).as("被拒的排序不落库")
			.isEqualTo(ids);
	}

	@Test
	@DisplayName("停用的支付方式只从可用清单里消失，管理清单仍能看到它")
	void disabledAccountDisappearsOnlyFromTheUsableList() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long huabei = idOf(list(owner, false), "花呗白条");

		patchJson(PAYMENT_ACCOUNTS + "/" + huabei + "/toggle", Map.of(), owner.accessToken());
		assertThat(names(list(owner, true))).doesNotContain("花呗白条");
		assertThat(names(list(owner, false))).contains("花呗白条");

		patchJson(PAYMENT_ACCOUNTS + "/" + huabei + "/toggle", Map.of(), owner.accessToken());
		assertThat(names(list(owner, true))).as("重新启用回来了").contains("花呗白条");
	}

	@Test
	@DisplayName("无流水的支付方式可以物理删除，预置的那 8 个也一样能删")
	void accountWithoutTransactionsIsDeletedPhysically() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long id = create(owner, "数字人民币");

		assertThat(deleteNoBody(PAYMENT_ACCOUNTS + "/" + id, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(findById(list(owner, false), id)).isNull();
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM payment_account WHERE id = ?", Integer.class, id))
			.as("是真删掉而不是打上删除标记").isEqualTo(0);
	}

	@Test
	@DisplayName("跨家庭越权：别家按 id 改名或停用本家的支付方式，一律 404 且数据不动")
	void accountOfAnotherFamilyIsInvisible() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long wechat = idOf(list(owner, false), "微信");

		Call renamed = patchJson(PAYMENT_ACCOUNTS + "/" + wechat, Map.of("name", "被篡改"), outsider.accessToken());
		assertThat(renamed.status()).isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(renamed.code()).isEqualTo("PAYMENT_ACCOUNT_NOT_FOUND");
		assertThat(patchJson(PAYMENT_ACCOUNTS + "/" + wechat + "/toggle", Map.of(), outsider.accessToken()).code())
			.isEqualTo("PAYMENT_ACCOUNT_NOT_FOUND");
		assertThat(deleteNoBody(PAYMENT_ACCOUNTS + "/" + wechat, outsider.accessToken()).code())
			.isEqualTo("PAYMENT_ACCOUNT_NOT_FOUND");

		assertThat(names(list(owner, false))).as("本家的 8 行都还在原位").contains("微信");
		assertThat(names(list(outsider, false))).as("外人自己的清单里也没有").doesNotContain("被篡改");
	}

	// ---- 辅助 ----

	private List<JsonNode> list(Account account, boolean enabledOnly) throws Exception {
		Call call = getJson(PAYMENT_ACCOUNTS + "?enabledOnly=" + enabledOnly, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		List<JsonNode> nodes = new ArrayList<>();
		call.data().forEach(nodes::add);
		return nodes;
	}

	private long create(Account account, String name) throws Exception {
		Call call = postJson(PAYMENT_ACCOUNTS, Map.of("name", name), account.accessToken());
		assertThat(call.code()).as("新建支付方式 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private String createExpectingFailure(Account account, String name) throws Exception {
		return postJson(PAYMENT_ACCOUNTS, Map.of("name", name), account.accessToken()).code();
	}

	private JsonNode findByName(List<JsonNode> accounts, String name) {
		return accounts.stream().filter(node -> node.path("name").asText().equals(name)).findFirst().orElse(null);
	}

	private JsonNode findById(List<JsonNode> accounts, long id) {
		return accounts.stream().filter(node -> node.path("id").asLong() == id).findFirst().orElse(null);
	}

	private long idOf(List<JsonNode> accounts, String name) {
		JsonNode node = findByName(accounts, name);
		assertThat(node).as("预置清单里应有 %s", name).isNotNull();
		return node.path("id").asLong();
	}

	private List<String> names(List<JsonNode> accounts) {
		return accounts.stream().map(node -> node.path("name").asText()).toList();
	}

	private List<String> defaultNames(List<JsonNode> accounts) {
		return accounts.stream()
			.filter(node -> node.path("isDefault").asBoolean())
			.map(node -> node.path("name").asText())
			.toList();
	}

}
