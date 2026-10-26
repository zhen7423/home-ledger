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

import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.2.3 周期记账规则的增删改查与校验。
 * <p>
 * 引擎本身的行为（月末钳制、幂等、窗口、跨家庭）在 RecurringGenerationIntegrationTest 里测，
 * 那一组是直接把日期喂给引擎的；这一组走接口，所以只留一条 A4 当场补跑的断言，别把同一件事测两遍。
 */
class RecurringRuleIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	@Test
	@DisplayName("收支类型由大类决定：客户端另塞一个 type 也不会改变结果")
	void typeIsDerivedFromTopCategory() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Map<String, Object> payload = new LinkedHashMap<>(rule("房租", "1500.00", topCategoryId(owner, "餐饮"),
				paymentAccountId(owner, "现金"), "MONTHLY", Map.of("daysOfMonth", List.of(5))));
		// 契约里没有 type 字段，多出来的那个应当被忽略，而不是让 EXPENSE 的类别配出一条 INCOME 规则
		payload.put("type", "INCOME");

		Call call = postJson(RECURRING_RULES, payload, owner.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("type").asText()).isEqualTo("EXPENSE");
		assertThat(call.data().path("categoryName").asText()).isEqualTo("餐饮");
		assertThat(call.data().path("accountName").asText()).isEqualTo("现金");
	}

	@Test
	@DisplayName("周期参数按 periodType 分别校验：形状不对与数值越界是两个错误码")
	void periodValueIsValidatedPerPeriodType() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");

		assertThat(createRule(owner, rule("房租", "100.00", dining, cash, "MONTHLY", Map.of("weekdays", List.of(1))))
			.code()).as("MONTHLY 只认 daysOfMonth，给了 weekdays 就是缺字段").isEqualTo("PERIOD_VALUE_INVALID");
		assertThat(createRule(owner, rule("房租", "100.00", dining, cash, "MONTHLY",
				Map.of("daysOfMonth", List.of(31), "intervalDays", 2))).code())
			.as("多给了不属于该类型的字段同样拒，放过去等于客户端自己串了配置").isEqualTo("PERIOD_VALUE_INVALID");
		assertThat(createRule(owner, rule("房租", "100.00", dining, cash, "MONTHLY", Map.of("daysOfMonth", List.of(32))))
			.code()).as("形状对但 32 号不存在，是用户填错").isEqualTo("PERIOD_RANGE_INVALID");
		assertThat(createRule(owner, rule("房租", "100.00", dining, cash, "MONTHLY", Map.of("daysOfMonth", List.of())))
			.code()).isEqualTo("PERIOD_VALUE_INVALID");
		assertThat(createRule(owner, rule("房租", "100.00", dining, cash, "YEARLY",
				Map.of("month", 13, "daysOfMonth", List.of(1)))).code()).isEqualTo("PERIOD_RANGE_INVALID");
		assertThat(createRule(owner, rule("房租", "100.00", dining, cash, "EVERY_OTHER_DAY",
				Map.of("intervalDays", 2))).code()).as("不认识的周期类型").isEqualTo("PERIOD_VALUE_INVALID");
	}

	@Test
	@DisplayName("起止日期：endDate 早于 startDate 拒，endDate 为空是长期有效")
	void endDateMustNotBeBeforeStartDate() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Map<String, Object> bad = rule("房租", "100.00", topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"),
				"MONTHLY", Map.of("daysOfMonth", List.of(5)));
		bad.put("startDate", "2026-09-10");
		bad.put("endDate", "2026-09-01");
		assertThat(createRule(owner, bad).code()).isEqualTo("PERIOD_RANGE_INVALID");

		Map<String, Object> openEnded = new LinkedHashMap<>(bad);
		openEnded.put("endDate", null);
		assertThat(createRule(owner, openEnded).data().path("endDate").isNull()).as("清空截止日期要真存成 NULL")
			.isTrue();
	}

	@Test
	@DisplayName("名称与金额的约束与记一笔同一套")
	void nameAndAmountConstraints() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");

		assertThat(createRule(owner, rule("名".repeat(20), "1.00", dining, cash, "MONTHLY",
				Map.of("daysOfMonth", List.of(5)))).code()).as("正好 20 字放行").isEqualTo("OK");
		assertThat(createRule(owner, rule("名".repeat(21), "1.00", dining, cash, "MONTHLY",
				Map.of("daysOfMonth", List.of(5)))).code()).as("超长由 Bean Validation 拦").isEqualTo("VALIDATION_FAILED");
		assertThat(createRule(owner, rule("房租", "1.005", dining, cash, "MONTHLY", Map.of("daysOfMonth", List.of(5))))
			.code()).as("三位小数不四舍五入，直接拒").isEqualTo("AMOUNT_SCALE_INVALID");
	}

	@Test
	@DisplayName("字典项校验：已停用的类别与支付方式都不许建规则，小类不能当大类用")
	void rulesMustPointAtUsableDictionaryItems() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		long disabledTop = createTopLevel(owner, "养车");
		long sub = createSub(owner, dining, "夜宵");

		toggleCategory(owner, disabledTop);
		assertThat(createRule(owner, rule("房租", "100.00", disabledTop, cash, "MONTHLY",
				Map.of("daysOfMonth", List.of(5)))).code())
			.as("建一条从诞生起就在生成看不懂的流水的规则没有意义").isEqualTo("CATEGORY_DISABLED");
		assertThat(createRule(owner, rule("房租", "100.00", sub, cash, "MONTHLY", Map.of("daysOfMonth", List.of(5))))
			.code()).as("categoryId 恒记大类").isEqualTo("BAD_REQUEST");
		assertThat(createRule(owner, rule("房租", "100.00", dining, disabledPaymentAccount(owner), "MONTHLY",
				Map.of("daysOfMonth", List.of(5)))).code()).isEqualTo("BAD_REQUEST");

		Map<String, Object> withSub = new LinkedHashMap<>(
				rule("房租", "100.00", dining, cash, "MONTHLY", Map.of("daysOfMonth", List.of(5))));
		withSub.put("subCategoryId", sub);
		Call call = createRule(owner, withSub);
		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("subCategoryName").asText()).isEqualTo("夜宵");
	}

	@Test
	@DisplayName("列表按 type 过滤，名称实时解析：大类改名后规则跟着显示新名")
	void listFiltersByTypeAndResolvesNamesLive() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		long salary = topCategoryIdOf(owner, "INCOME", "工资");
		long ruleOfDining = createRule(owner,
				rule("话费", "100.00", dining, cash, "MONTHLY", Map.of("daysOfMonth", List.of(5)))).data().path("id")
			.asLong();
		createRule(owner, incomeRule("年终奖", "5000.00", salary, cash));

		assertThat(names(list(owner, null))).containsExactly("年终奖", "话费");
		assertThat(names(list(owner, "EXPENSE"))).containsExactly("话费");
		assertThat(names(list(owner, "INCOME"))).containsExactly("年终奖");

		patchJson(CATEGORIES + "/" + dining, Map.of("name", "外食"), owner.accessToken());
		JsonNode afterRename = getJson(RECURRING_RULES + "/" + ruleOfDining, owner.accessToken()).data();
		assertThat(afterRename.path("categoryName").asText()).as("规则是配置，改名后该显示新名，与流水的快照口径相反")
			.isEqualTo("外食");
	}

	@Test
	@DisplayName("编辑是整份覆盖：把 endDate 传 null 就改回长期有效，改名称金额不动游标")
	void updateOverwritesTheWholeRecord() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		Map<String, Object> created = rule("房租", "1500.00", dining, cash, "MONTHLY",
				Map.of("daysOfMonth", List.of(5)));
		created.put("endDate", "2026-12-31");
		long id = createRule(owner, created).data().path("id").asLong();

		Map<String, Object> edited = rule("房租", "1600.00", dining, cash, "MONTHLY",
				Map.of("daysOfMonth", List.of(5)));
		edited.put("endDate", null);
		Call call = putJson(RECURRING_RULES + "/" + id, edited, owner.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("amount").asText()).isEqualTo("1600.00");
		assertThat(call.data().path("endDate").isNull()).isTrue();

		assertThat(putJson(RECURRING_RULES + "/" + id, rule("房租", "1.00", dining, cash, "MONTHLY",
				Map.of("weekdays", List.of(1))), owner.accessToken()).code())
			.as("编辑走的是同一套周期校验").isEqualTo("PERIOD_VALUE_INVALID");
	}

	@Test
	@DisplayName("启停只翻 enabled：已生成的流水不因暂停而消失")
	void toggleOnlyFlipsTheSwitch() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Map<String, Object> payload = rule("房租", "100.00", topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"),
				"DAILY", Map.of("intervalDays", 1));
		long id = createRule(owner, payload).data().path("id").asLong();
		assertThat(transactionCountOf(owner, id)).as("起始日为今天的每日规则，当场就该有一笔").isEqualTo(1);

		assertThat(toggleRule(owner, id).data().path("enabled").asBoolean()).isFalse();
		assertThat(transactionCountOf(owner, id)).isEqualTo(1);
		assertThat(toggleRule(owner, id).data().path("enabled").asBoolean()).isTrue();
		// 暂停期不整段补出来是靠游标实现的，那件事在 RecurringGenerationIntegrationTest 里钉
	}

	@Test
	@DisplayName("A4 落地在接口上：建规则的当场就把该补的流水记出来，补的那几笔带标记")
	void createBackfillsTheCurrentWindowRightAway() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Map<String, Object> payload = rule("房租", "100.00", topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"),
				"DAILY", Map.of("intervalDays", 1));
		payload.put("startDate", LocalDate.now().minusDays(2).toString());

		long id = createRule(owner, payload).data().path("id").asLong();
		List<JsonNode> rows = transactionsOfRule(owner, id);
		assertThat(rows).as("起始日到今天共三天，当场一次全补出来").hasSize(3);
		assertThat(rows).allSatisfy(
				row -> assertThat(row.path("ruleId").isNull()).as("自动生成的流水要能被认出来").isFalse());
		// 列表按业务日期倒序，所以今天那笔在最前：它不是补的，备注为空
		assertThat(remarks(rows)).containsExactly(null, "（系统补记）", "（系统补记）");
	}

	@Test
	@DisplayName("执行记录只回日志：把生成的流水删掉，那条执行记录仍在")
	void executionsSurviveTransactionDeletion() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Map<String, Object> payload = rule("房租", "100.00", topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"),
				"DAILY", Map.of("intervalDays", 1));
		payload.put("startDate", LocalDate.now().minusDays(1).toString());
		long id = createRule(owner, payload).data().path("id").asLong();

		List<JsonNode> executions = nodesOf(
				getJson(RECURRING_RULES + "/" + id + "/executions", owner.accessToken()).data());
		assertThat(executions).as("起始日是昨天，昨天与今天各一条").hasSize(2);
		assertThat(executions.get(0).path("bizDate").asText()).isEqualTo(LocalDate.now().toString());
		assertThat(executions.get(0).path("backfilled").asBoolean()).as("当天生成的不算补记").isFalse();
		assertThat(executions.get(1).path("bizDate").asText()).isEqualTo(LocalDate.now().minusDays(1).toString());
		assertThat(executions.get(1).path("backfilled").asBoolean()).as("执行日晚于业务日才是补记").isTrue();

		long transactionId = transactionsOfRule(owner, id).get(0).path("id").asLong();
		assertThat(deleteNoBody(TRANSACTIONS + "/" + transactionId, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(getJson(RECURRING_RULES + "/" + id + "/executions", owner.accessToken()).data())
			.as("它是审计轨迹，不是流水的下钻入口，所以用户删了流水它也该在").hasSize(2);
	}

	@Test
	@DisplayName("跨家庭越权：拿别家规则的 id 去查、改、停、删，一律 404 且原数据不动")
	void ruleOfAnotherFamilyIsInvisible() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long id = createRule(owner, rule("房租", "100.00", topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"),
				"MONTHLY", Map.of("daysOfMonth", List.of(5)))).data().path("id").asLong();

		assertThat(getJson(RECURRING_RULES + "/" + id, outsider.accessToken()).status())
			.isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(putJson(RECURRING_RULES + "/" + id,
				rule("被篡改", "1.00", topCategoryId(outsider, "餐饮"), paymentAccountId(outsider, "现金"), "MONTHLY",
						Map.of("daysOfMonth", List.of(5))), outsider.accessToken()).code())
			.isEqualTo("RECURRING_RULE_NOT_FOUND");
		assertThat(toggleRule(outsider, id).code()).isEqualTo("RECURRING_RULE_NOT_FOUND");
		assertThat(deleteNoBody(RECURRING_RULES + "/" + id, outsider.accessToken()).code())
			.isEqualTo("RECURRING_RULE_NOT_FOUND");
		assertThat(getJson(RECURRING_RULES + "/" + id + "/executions", outsider.accessToken()).code())
			.isEqualTo("RECURRING_RULE_NOT_FOUND");

		JsonNode intact = getJson(RECURRING_RULES + "/" + id, owner.accessToken()).data();
		assertThat(intact.path("name").asText()).isEqualTo("房租");
		assertThat(intact.path("amount").asText()).isEqualTo("100.00");
	}

	@Test
	@DisplayName("接缝 2：被规则引用的类别与支付方式不许停用或删除，删掉规则后才放行")
	void dictionaryItemsInUseByRulesAreProtected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long cash = paymentAccountId(owner, "现金");
		long dining = topCategoryId(owner, "餐饮");
		long custom = createTopLevel(owner, "养车");
		long id = createRule(owner,
				dormant(rule("网费", "100.00", custom, cash, "MONTHLY", Map.of("daysOfMonth", List.of(5))))).data()
			.path("id")
			.asLong();

		Call blockedDelete = deleteNoBody(CATEGORIES + "/" + custom, owner.accessToken());
		assertThat(blockedDelete.status()).isEqualTo(HttpStatus.CONFLICT.value());
		assertThat(blockedDelete.code()).isEqualTo("CATEGORY_USED_BY_RECURRING_RULE");

		// 停用的是大类，规则挂在它的小类上也要拦住——两列一起匹配，与「停用大类其下小类同时消失」同口径
		long sub = createSub(owner, dining, "夜宵");
		Map<String, Object> subRule = dormant(
				rule("早餐钱", "20.00", dining, cash, "MONTHLY", Map.of("daysOfMonth", List.of(5))));
		subRule.put("subCategoryId", sub);
		long subRuleId = createRule(owner, subRule).data().path("id").asLong();
		assertThat(toggleCategory(owner, dining).code()).isEqualTo("CATEGORY_USED_BY_RECURRING_RULE");

		deleteRule(owner, subRuleId);
		assertThat(toggleCategory(owner, dining).code())
			.as("预置大类可以停用，只是不能删；把规则删掉之后停用它就应当放行").isNotEqualTo("CATEGORY_USED_BY_RECURRING_RULE");
		deleteRule(owner, id);
		assertThat(deleteNoBody(CATEGORIES + "/" + custom, owner.accessToken()).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("接缝 2（支付方式侧）：被规则引用时停用与删除都拦下来，默认项另有自己的规则")
	void paymentAccountInUseByRuleIsProtected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long custom = createPaymentAccount(owner, "亲情卡");
		long id = createRule(owner, dormant(
				rule("网费", "100.00", topCategoryId(owner, "餐饮"), custom, "MONTHLY", Map.of("daysOfMonth", List.of(5)))))
			.data()
			.path("id")
			.asLong();

		Call blockedToggle = togglePaymentAccount(owner, custom);
		assertThat(blockedToggle.status()).isEqualTo(HttpStatus.CONFLICT.value());
		assertThat(blockedToggle.code()).isEqualTo("PAYMENT_ACCOUNT_USED_BY_RECURRING_RULE");
		assertThat(deleteNoBody(PAYMENT_ACCOUNTS + "/" + custom, owner.accessToken()).code())
			.isEqualTo("PAYMENT_ACCOUNT_USED_BY_RECURRING_RULE");

		deleteRule(owner, id);
		assertThat(togglePaymentAccount(owner, custom).code()).isEqualTo("OK");
		assertThat(deleteNoBody(PAYMENT_ACCOUNTS + "/" + custom, owner.accessToken()).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("来源筛选把自动与手工分开，未知取值报 400 而不是静默当成没筛")
	void sourceFilterSplitsAutoFromManual() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		long id = createRule(owner, rule("房租", "100.00", dining, cash, "DAILY", Map.of("intervalDays", 1))).data()
			.path("id")
			.asLong();
		recordExpense(owner, dining, cash, "30.00");

		Call auto = getJson(TRANSACTIONS, Map.of("source", "AUTO"), owner.accessToken());
		assertThat(auto.code()).isEqualTo("OK");
		assertThat(auto.data().path("total").asLong()).isEqualTo(1);
		assertThat(nodesOf(auto.data().path("records"))).allSatisfy(row -> assertThat(row.path("ruleId").asLong())
			.as("来源不是一列，出参靠生它的那条规则说话").isEqualTo(id));
		assertThat(auto.data().path("monthSummaries").get(0).path("count").asLong())
			.as("小计与列表共用同一段筛选条件").isEqualTo(1);

		Call manual = getJson(TRANSACTIONS, Map.of("source", "MANUAL"), owner.accessToken());
		assertThat(manual.data().path("total").asLong()).isEqualTo(1);
		assertThat(nodesOf(manual.data().path("records")).get(0).path("ruleId").isNull()).isTrue();

		assertThat(getJson(TRANSACTIONS, Map.of(), owner.accessToken()).data().path("total").asLong())
			.as("不传 source 时两类一起给，与 S3 完全一致").isEqualTo(2);
		assertThat(getJson(TRANSACTIONS, Map.of("source", "XXX"), owner.accessToken()).code())
			.as("静默忽略未知筛选值会让前端以为筛选生效了").isEqualTo("BAD_REQUEST");
	}

	@Test
	@DisplayName("接缝 1：成员退出后他的规则被暂停而不是删除，他生成的流水仍能反查到规则")
	void leavingMemberHasHisRulesPausedNotDeleted() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		Account member = register(PHONE_B, "李四");
		assertThat(inviteAndJoin(owner, member).code()).isEqualTo("OK");

		Map<String, Object> payload = rule("网费", "100.00", topCategoryId(member, "餐饮"),
				paymentAccountId(member, "现金"), "DAILY", Map.of("intervalDays", 1));
		payload.put("startDate", LocalDate.now().minusDays(1).toString());
		long id = createRule(member, payload).data().path("id").asLong();
		assertThat(transactionsOfRule(owner, id)).as("退出前先确认流水确实是他那条规则生的").hasSize(2);

		assertThat(postJson(FAMILIES + "/current/leave", Map.of(), member.accessToken()).code()).isEqualTo("OK");

		JsonNode loaded = getJson(RECURRING_RULES + "/" + id, owner.accessToken()).data();
		assertThat(loaded.path("enabled").asBoolean()).as("规则代表仍然成立的意图，可能由别人接手，所以只暂停").isFalse();
		assertThat(jdbcTemplate.queryForObject("SELECT deleted FROM recurring_rule WHERE id = ?", Integer.class, id))
			.as("行必须还在：删了它，历史流水上的 rule_id 就成了悬空引用").isZero();
		assertThat(transactionsOfRule(owner, id)).as("他记下的两笔留在家庭账本里").hasSize(2);
	}

	// ---- 请求与取值辅助 ----

	private Call deleteRule(Account account, long id) throws Exception {
		return deleteNoBody(RECURRING_RULES + "/" + id, account.accessToken());
	}

	private Call createRule(Account account, Map<String, Object> payload) throws Exception {
		return postJson(RECURRING_RULES, payload, account.accessToken());
	}

	private static Map<String, Object> rule(String name, String amount, long categoryId, long accountId,
			String periodType, Map<String, Object> periodValue) {
		Map<String, Object> payload = new LinkedHashMap<>();
		payload.put("name", name);
		payload.put("amount", amount);
		payload.put("categoryId", categoryId);
		payload.put("accountId", accountId);
		payload.put("periodType", periodType);
		payload.put("periodValue", periodValue);
		return payload;
	}

	private static Map<String, Object> incomeRule(String name, String amount, long categoryId, long accountId) {
		return rule(name, amount, categoryId, accountId, "MONTHLY", Map.of("daysOfMonth", List.of(5)));
	}

	/**
	 * 把起始日推到一个月后，于是这条规则一笔流水都没生过。
	 * <p>
	 * 接缝用例要的是「规则在用这个字典项」这一个条件，不能被「字典项名下有流水」抢在前面报出来——
	 * 不推到将来的话，每月 5 号跑就会红。
	 */
	private static Map<String, Object> dormant(Map<String, Object> payload) {
		payload.put("startDate", LocalDate.now().plusMonths(1).toString());
		return payload;
	}

	private List<JsonNode> list(Account account, String type) throws Exception {
		String path = type == null ? RECURRING_RULES : RECURRING_RULES + "?type=" + type;
		Call call = getJson(path, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return nodesOf(call.data());
	}

	private static List<JsonNode> nodesOf(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

	private void recordExpense(Account account, long categoryId, long accountId, String amount) throws Exception {
		Map<String, Object> payload = new LinkedHashMap<>();
		payload.put("amount", amount);
		payload.put("categoryId", categoryId);
		payload.put("accountId", accountId);
		payload.put("bizDate", LocalDate.now().toString());
		assertThat(postJson(TRANSACTIONS, payload, account.accessToken()).code()).as("记一笔 %s", payload)
			.isEqualTo("OK");
	}

	private List<JsonNode> transactionsOfRule(Account account, long ruleId) throws Exception {
		Call call = getJson(TRANSACTIONS, Map.of("source", "AUTO"), account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		List<JsonNode> rows = new ArrayList<>();
		for (JsonNode row : call.data().path("records")) {
			if (row.path("ruleId").asLong() == ruleId) {
				rows.add(row);
			}
		}
		return rows;
	}

	private int transactionCountOf(Account account, long ruleId) throws Exception {
		return transactionsOfRule(account, ruleId).size();
	}

	private List<String> remarks(List<JsonNode> rows) {
		List<String> remarks = new ArrayList<>();
		for (JsonNode row : rows) {
			remarks.add(row.path("remark").isNull() ? null : row.path("remark").asText());
		}
		return remarks;
	}

	private List<String> names(List<JsonNode> rows) {
		return rows.stream().map(row -> row.path("name").asText()).toList();
	}

	private long topCategoryIdOf(Account account, String type, String name) throws Exception {
		Call call = getJson(CATEGORIES + "?type=" + type + "&enabledOnly=false", account.accessToken());
		for (JsonNode node : call.data()) {
			if (node.path("name").asText().equals(name)) {
				return node.path("id").asLong();
			}
		}
		throw new AssertionError("预置类别树里应有大类 " + name);
	}

	private long createTopLevel(Account account, String name) throws Exception {
		Call call = postJson(CATEGORIES, Map.of("type", "EXPENSE", "name", name), account.accessToken());
		assertThat(call.code()).as("新建大类 " + name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private long createSub(Account account, long parentId, String name) throws Exception {
		Call call = postJson(CATEGORIES,
				Map.of("type", "EXPENSE", "parentId", parentId, "name", name), account.accessToken());
		assertThat(call.code()).as("在 " + parentId + " 下新建小类 " + name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private Call toggleCategory(Account account, long id) throws Exception {
		return patchJson(CATEGORIES + "/" + id + "/toggle", Map.of(), account.accessToken());
	}

	private long createPaymentAccount(Account account, String name) throws Exception {
		Call call = postJson(PAYMENT_ACCOUNTS, Map.of("name", name), account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	/** 已停用的支付方式：不是默认项，所以停用能过。 */
	private long disabledPaymentAccount(Account account) throws Exception {
		long id = createPaymentAccount(account, "已停用的卡");
		assertThat(togglePaymentAccount(account, id).code()).isEqualTo("OK");
		return id;
	}

	private Call togglePaymentAccount(Account account, long id) throws Exception {
		return patchJson(PAYMENT_ACCOUNTS + "/" + id + "/toggle", Map.of(), account.accessToken());
	}

	private Call toggleRule(Account account, long id) throws Exception {
		return patchJson(RECURRING_RULES + "/" + id + "/toggle", Map.of(), account.accessToken());
	}

}
