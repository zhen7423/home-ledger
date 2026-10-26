package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.common.PresetFinanceDict;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.2.2 两级收支类别字典。
 * <p>
 * 「类别下已有流水就不能删」那几条要有流水才能测，放在 TransactionFlowIntegrationTest 里钉。
 */
class CategoryFlowIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	@Test
	@DisplayName("创建家庭即装入预置类别：支出 11/58、收入 6/20，大类带图标配色而小类不带")
	void presetsAreInstalledWhenFamilyIsCreated() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		JsonNode expense = tree(owner, "EXPENSE", false);
		JsonNode income = tree(owner, "INCOME", false);
		assertThat(expense).as("支出大类 11 个").hasSize(11);
		assertThat(children(expense)).as("支出小类 58 个").hasSize(58);
		assertThat(income).as("收入大类 6 个").hasSize(6);
		assertThat(children(income)).as("收入小类 20 个").hasSize(20);

		Set<Integer> indexes = new HashSet<>();
		for (JsonNode top : iterable(expense)) {
			assertThat(top.path("preset").asBoolean()).as("预置大类 preset=true").isTrue();
			assertThat(top.path("iconKey").asText()).isNotBlank();
			assertThat(top.path("colorIndex").isNumber()).as("大类必须有配色索引").isTrue();
			assertThat(indexes.add(top.path("colorIndex").asInt())).as("配色索引不得重复").isTrue();
		}
		for (JsonNode top : iterable(income)) {
			assertThat(indexes.add(top.path("colorIndex").asInt()))
				.as("配色占用按整个家庭算，收入侧不能跟支出侧重号（§4.2.2 第 15 轮）").isTrue();
		}
		assertThat(indexes).as("11 + 6 个大类各占一个").hasSize(17);

		for (JsonNode sub : children(expense)) {
			assertThat(sub.path("iconKey").isNull()).as("小类不着色也不带图标").isTrue();
			assertThat(sub.path("colorIndex").isNull()).isTrue();
			assertThat(sub.path("preset").asBoolean()).isTrue();
		}
	}

	@Test
	@DisplayName("验收用例 7：A 新建「养车」及其小类，B 登录后看到的是同一套")
	void newCategoryIsVisibleToEveryMember() throws Exception {
		Account a = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(a, "张家");
		Account b = register(PHONE_B, "李四");
		assertThat(inviteAndJoin(a, b).code()).isEqualTo("OK");

		long topId = createTopLevel(a, "EXPENSE", "养车");
		assertThat(topId).isPositive();
		createSub(a, topId, "洗车费");
		assertThat(createJson(a, Map.of("type", "EXPENSE", "parentId", topId, "name", "加油")).code())
			.as("查重只在同一父级内生效，预置「交通 / 加油」挡不住「养车 / 加油」").isEqualTo("OK");

		JsonNode seenByB = tree(b, "EXPENSE", false);
		JsonNode car = findTop(seenByB, "养车");
		assertThat(car).as("B 必须看到 A 新建的大类（§4.1.5 数据全共享）").isNotNull();
		assertThat(names(childNodes(car))).containsExactly("洗车费", "加油");
		assertThat(names(childNodes(findTop(seenByB, "交通")))).contains("加油");
	}

	@Test
	@DisplayName("同级查重：重名、带尾随空格的重名、仅大小写不同的重名一律拒")
	void duplicateSiblingNamesAreRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long topId = createTopLevel(owner, "EXPENSE", "养车");
		createSub(owner, topId, "洗车费");

		assertThat(createSubExpectingFailure(owner, topId, "洗车费")).isEqualTo("CATEGORY_NAME_DUPLICATED");
		assertThat(createSubExpectingFailure(owner, topId, "洗车费 "))
			.as("utf8mb4_0900_ai_ci 是 NO PAD，尾随空格是显著字符，不 trim 就漏判").isEqualTo("CATEGORY_NAME_DUPLICATED");
		assertThat(createTopLevelExpectingFailure(owner, "EXPENSE", "其他 ")).as("预置里已有「其他」")
			.isEqualTo("CATEGORY_NAME_DUPLICATED");

		createTopLevel(owner, "INCOME", "ETC");
		assertThat(createTopLevelExpectingFailure(owner, "INCOME", "etc"))
			.as("大小写不敏感交给排序规则，不在 Java 里再转一次小写").isEqualTo("CATEGORY_NAME_DUPLICATED");

		assertThat(createJson(owner, Map.of("type", "EXPENSE", "name", "洗车费")).code())
			.as("换个层级就不算重名").isEqualTo("OK");
	}

	@Test
	@DisplayName("层级与挂接规则：小类下不能再建小类、不能跨收支类型、停用的大类下面不给建")
	void structuralRulesOfTheTwoLevelTree() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long topId = createTopLevel(owner, "EXPENSE", "养车");
		long subId = createSub(owner, topId, "洗车费");

		assertThat(createSubExpectingFailure(owner, subId, "打蜡")).as("只允许两级").isEqualTo("CATEGORY_DEPTH_EXCEEDED");
		assertThat(createJson(owner, Map.of("type", "INCOME", "parentId", topId, "name", "过路费")).code())
			.isEqualTo("CATEGORY_PARENT_MISMATCH");

		toggle(owner, topId);
		assertThat(createSubExpectingFailure(owner, topId, "打蜡"))
			.as("大类停用期间往里加小类，等于造出一批选不到的行").isEqualTo("CATEGORY_PARENT_DISABLED");
	}

	@Test
	@DisplayName("名称长度：大类超 6 字走业务码，小类 8 字放行、9 字被注解挡下")
	void nameLengthLimitsPerLevel() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		createTopLevel(owner, "EXPENSE", "六个字的名称");
		assertThat(createTopLevelExpectingFailure(owner, "EXPENSE", "七个字的名称啊")).isEqualTo("CATEGORY_NAME_TOO_LONG");

		long topId = createTopLevel(owner, "EXPENSE", "养车");
		createSub(owner, topId, "八个字的小类名称");
		assertThat(createJson(owner, Map.of("type", "EXPENSE", "parentId", topId, "name", "九个字的小类名称啊")).code())
			.as("超过 8 字在 DTO 层就该拦下，不必进业务码").isEqualTo("VALIDATION_FAILED");
	}

	@Test
	@DisplayName("预置类别可以改名、可以停用，但不能物理删除")
	void presetCategoryCanBeRenamedButNotDeleted() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catering = findTop(tree(owner, "EXPENSE", false), "餐饮").path("id").asLong();

		Call renamed = patchJson(CATEGORIES + "/" + catering, Map.of("name", "吃喝"), owner.accessToken());
		assertThat(renamed.code()).isEqualTo("OK");
		assertThat(renamed.data().path("name").asText()).isEqualTo("吃喝");

		JsonNode afterRename = findTop(tree(owner, "EXPENSE", false), "吃喝");
		assertThat(afterRename).isNotNull();
		assertThat(childNodes(afterRename)).as("改名不动层级，6 个小类还挂在它下面").hasSize(6);

		Call deleted = deleteNoBody(CATEGORIES + "/" + catering, owner.accessToken());
		assertThat(deleted.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(deleted.code()).isEqualTo("CATEGORY_PRESET_UNDELETABLE");
	}

	@Test
	@DisplayName("停用大类级联停用小类，重新启用大类不自动把小类带回来")
	void disablingTopLevelCascadesWhileEnablingDoesNot() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long transport = findTop(tree(owner, "EXPENSE", false), "交通").path("id").asLong();

		toggle(owner, transport);
		JsonNode usable = tree(owner, "EXPENSE", true);
		assertThat(findTop(usable, "交通")).as("停用后大类本身从可用树里消失").isNull();
		assertThat(names(children(usable))).as("它下面 6 个小类一并消失").doesNotContain("打车", "公共交通");
		assertThat(children(usable)).hasSize(52);

		toggle(owner, transport);
		JsonNode afterEnable = tree(owner, "EXPENSE", true);
		assertThat(findTop(afterEnable, "交通")).as("大类本身回来了").isNotNull();
		assertThat(names(children(afterEnable))).as("小类保持用户当初关掉的状态，不被顺手点亮").doesNotContain("打车");
	}

	@Test
	@DisplayName("新建大类领走空闲配色，图标与配色共用同一个下标")
	void customTopLevelCategoryTakesAFreeColorIndex() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		JsonNode first = createJson(owner, Map.of("type", "EXPENSE", "name", "养车")).data();
		JsonNode second = createJson(owner, Map.of("type", "INCOME", "name", "意外所得")).data();
		int firstIndex = first.path("colorIndex").asInt();
		int secondIndex = second.path("colorIndex").asInt();

		assertThat(firstIndex).as("预置占满 0–16，自定义大类从 17 起").isEqualTo(17);
		assertThat(secondIndex).isNotEqualTo(firstIndex);
		assertThat(first.path("iconKey").asText()).isEqualTo(PresetFinanceDict.ICON_POOL.get(firstIndex));
		assertThat(second.path("iconKey").asText()).isEqualTo(PresetFinanceDict.ICON_POOL.get(secondIndex));
	}

	@Test
	@DisplayName("拖拽排序把同级 sort_no 重写为 1…n，少给或错层则整批拒绝")
	void sortRewritesSortNoInSubmittedOrder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		List<JsonNode> original = iterable(tree(owner, "EXPENSE", false));
		List<Long> reversed = new ArrayList<>(ids(original));
		Collections.reverse(reversed);

		assertThat(putJson(CATEGORIES + "/sort", Map.of("type", "EXPENSE", "orderedIds", reversed), owner.accessToken())
			.code()).isEqualTo("OK");

		List<JsonNode> topNow = iterable(tree(owner, "EXPENSE", false));
		assertThat(ids(topNow)).isEqualTo(reversed);
		for (int i = 0; i < topNow.size(); i++) {
			assertThat(topNow.get(i).path("sortNo").asInt()).as("第 %d 个节点的 sort_no", i + 1).isEqualTo(i + 1);
		}

		assertThat(putJson(CATEGORIES + "/sort", Map.of("type", "EXPENSE", "orderedIds", reversed.subList(0, 3)),
				owner.accessToken()).code()).as("只给一部分必然与未提及的行撞号").isEqualTo("SORT_IDS_MISMATCH");
		assertThat(putJson(CATEGORIES + "/sort", Map.of("type", "INCOME", "orderedIds", reversed), owner.accessToken())
			.code()).as("拿支出层的 id 去排收入层，整批拒绝").isEqualTo("SORT_IDS_MISMATCH");
		assertThat(ids(iterable(tree(owner, "EXPENSE", false)))).as("被拒的那两次没改动任何顺序").isEqualTo(reversed);
	}

	@Test
	@DisplayName("跨家庭越权：别家按 id 改名或删除自己的类别，一律 404 且原数据不动")
	void categoryOfAnotherFamilyIsInvisible() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long topId = createTopLevel(owner, "EXPENSE", "养车");

		Call renamed = patchJson(CATEGORIES + "/" + topId, Map.of("name", "被篡改"), outsider.accessToken());
		assertThat(renamed.status()).isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(renamed.code()).isEqualTo("CATEGORY_NOT_FOUND");
		Call deleted = deleteNoBody(CATEGORIES + "/" + topId, outsider.accessToken());
		assertThat(deleted.code()).isEqualTo("CATEGORY_NOT_FOUND");

		assertThat(findTop(tree(owner, "EXPENSE", false), "养车")).as("名称未被改动、行也还在").isNotNull();
		assertThat(findTop(tree(outsider, "EXPENSE", false), "养车")).as("外人自己的树里也不该出现").isNull();
	}

	// ---- 辅助 ----

	private JsonNode tree(Account account, String type, boolean enabledOnly) throws Exception {
		Call call = getJson(CATEGORIES + "?type=" + type + "&enabledOnly=" + enabledOnly, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private Call createJson(Account account, Map<String, Object> payload) throws Exception {
		return postJson(CATEGORIES, payload, account.accessToken());
	}

	private long createTopLevel(Account account, String type, String name) throws Exception {
		Call call = createJson(account, Map.of("type", type, "name", name));
		assertThat(call.code()).as("新建大类 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private long createSub(Account account, long parentId, String name) throws Exception {
		Call call = createJson(account, Map.of("type", "EXPENSE", "parentId", parentId, "name", name));
		assertThat(call.code()).as("新建小类 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private String createTopLevelExpectingFailure(Account account, String type, String name) throws Exception {
		return createJson(account, Map.of("type", type, "name", name)).code();
	}

	private String createSubExpectingFailure(Account account, long parentId, String name) throws Exception {
		return createJson(account, Map.of("type", "EXPENSE", "parentId", parentId, "name", name)).code();
	}

	private Call toggle(Account account, long id) throws Exception {
		return patchJson(CATEGORIES + "/" + id + "/toggle", Map.of(), account.accessToken());
	}

	private JsonNode findTop(JsonNode tree, String name) {
		for (JsonNode node : iterable(tree)) {
			if (node.path("name").asText().equals(name)) {
				return node;
			}
		}
		return null;
	}

	/** 整棵树拍平成「全部小类」一个列表，用于断言级联停用后小类也跟着消失。 */
	private List<JsonNode> children(JsonNode tree) {
		List<JsonNode> children = new ArrayList<>();
		for (JsonNode top : iterable(tree)) {
			children.addAll(iterable(top.path("children")));
		}
		return children;
	}

	private List<JsonNode> childNodes(JsonNode top) {
		return iterable(top.path("children"));
	}

	private List<JsonNode> iterable(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

	private List<String> names(List<JsonNode> nodes) {
		return nodes.stream().map(node -> node.path("name").asText()).toList();
	}

	private List<Long> ids(List<JsonNode> nodes) {
		return nodes.stream().map(node -> node.path("id").asLong()).toList();
	}

}
