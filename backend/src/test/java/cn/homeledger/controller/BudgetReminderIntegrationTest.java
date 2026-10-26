package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
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
 * §4.2.4 三维度预算与 §4.5.1 的预算提醒。
 * <p>
 * 提醒那几条只断言「该出哪一档、出几条」，通知怎么排期、今天是否已经提醒过是客户端的 ReminderStateStore
 * 负责的事（F4），服务端没有那份状态可测。
 */
class BudgetReminderIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final String BUDGET_WARNING = "BUDGET_WARNING";

	private static final String BUDGET_OVERRUN = "BUDGET_OVERRUN";

	// ---- 预算：整体替换的语义 ----

	@Test
	@DisplayName("三个维度各存一条：列表按提交顺序回，名称实时解析，且不带 bucketKey")
	void threeScopesSaveAndList() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		long dining = topCategoryId(owner, "餐饮");

		Call saved = saveBudgets(owner, List.of(item("FAMILY", null, null, "5000.00"),
				item("CATEGORY", dining, null, "2000.00"), item("MEMBER", null, member.userId(), "1500.00")));
		assertThat(saved.code()).isEqualTo("OK");

		List<JsonNode> rows = toList(getJson(BUDGETS, owner.accessToken()).data());
		assertThat(rows).as("没设过的维度不会自己冒出来").hasSize(3);
		assertThat(rows).noneMatch(row -> row.has("bucketKey"));
		assertThat(rows.get(0).path("scope").asText()).as("按提交顺序回，雪花 id 单调递增").isEqualTo("FAMILY");
		assertThat(rows.get(0).path("amount").asText()).isEqualTo("5000.00");
		assertThat(rows.get(1).path("categoryName").asText()).isEqualTo("餐饮");
		assertThat(rows.get(2).path("memberName").asText()).as("成员预算显示的是他在家里的名字").isEqualTo("李四");
	}

	@Test
	@DisplayName("同一份请求里两个家庭维度：409，且先前存好的预算一行都没被冲掉")
	void duplicatedScopeRollsBackTheWholeRequest() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "3000.00"))).code()).isEqualTo("OK");
		List<Long> before = budgetIds(owner);

		Call call = saveBudgets(owner, List.of(item("FAMILY", null, null, "3000.00"), item("FAMILY", null, null,
				"4000.00")));
		assertThat(call.status()).isEqualTo(HttpStatus.CONFLICT.value());
		assertThat(call.code()).isEqualTo("BUDGET_DUPLICATED");
		assertThat(budgetIds(owner)).as("保存是先物理删再重插，回滚要是没盖住那句删除，界面上预算就全空了").isEqualTo(before);
	}

	@Test
	@DisplayName("整体替换后所有行的 id 都变了：前端不能持有 id 做任何事")
	void idsChangeOnEverySave() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "3000.00"))).code()).isEqualTo("OK");
		List<Long> first = budgetIds(owner);

		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "3000.00"))).code()).isEqualTo("OK");
		assertThat(budgetIds(owner)).as("同一维度、同一金额重存一次，id 仍然是新的").isNotEqualTo(first);
	}

	@Test
	@DisplayName("items 传 null 或空数组都是清空，两个接口仍返回 200 与空数组")
	void emptyItemsClearsEverything() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "3000.00"))).code()).isEqualTo("OK");

		Map<String, Object> nullPayload = new LinkedHashMap<>();
		nullPayload.put("items", null);
		assertThat(putJson(BUDGETS, nullPayload, owner.accessToken()).status()).isEqualTo(HttpStatus.OK.value());
		assertThat(getJson(BUDGETS, owner.accessToken()).data()).isEmpty();
		assertThat(getJson(BUDGET_PROGRESS, owner.accessToken()).data()).as("没预算就没有进度可算，但不该报 500")
			.isEmpty();

		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		assertThat(saveBudgets(owner, List.of()).code()).as("空数组是「这个月不设预算」的正常表达，不是缺参数").isEqualTo("OK");
		assertThat(getJson(BUDGETS, owner.accessToken()).data()).isEmpty();
	}

	// ---- 预算：维度与字段的形状 ----

	@Test
	@DisplayName("类别预算只能设在大类上")
	void categoryBudgetMustTargetMajorCategory() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long sub = subCategoryId(owner, "餐饮", "午餐");

		Call call = saveBudgets(owner, List.of(item("CATEGORY", sub, null, "500.00")));
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.code()).isEqualTo("BUDGET_CATEGORY_NOT_MAJOR");
	}

	@Test
	@DisplayName("成员预算只能给本家庭的人：给一个外人 403")
	void memberBudgetMustBelongToTheFamily() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account stranger = register(PHONE_OTHER, "赵六");

		Call call = saveBudgets(owner, List.of(item("MEMBER", null, stranger.userId(), "500.00")));
		assertThat(call.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(call.code()).isEqualTo("BUDGET_MEMBER_NOT_IN_FAMILY");
	}

	@Test
	@DisplayName("维度与字段必须严格对齐：多带一个 id 也报 BUDGET_SCOPE_INVALID，不静默丢掉")
	void scopeAndFieldsMustMatchExactly() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");

		assertThat(saveBudgets(owner, List.of(item("FAMILY", dining, null, "500.00"))).code())
			.as("FAMILY 带了 categoryId：客户端把两张表单串成了一份，静默丢掉那个 id 会让用户以为类别预算设好了")
				.isEqualTo("BUDGET_SCOPE_INVALID");
		assertThat(saveBudgets(owner, List.of(item("CATEGORY", null, null, "500.00"))).code())
			.isEqualTo("BUDGET_SCOPE_INVALID");
		assertThat(saveBudgets(owner, List.of(item("MEMBER", dining, owner.userId(), "500.00"))).code())
			.as("MEMBER 两个 id 都带了").isEqualTo("BUDGET_SCOPE_INVALID");
		assertThat(saveBudgets(owner, List.of(item("TOTAL", null, null, "500.00"))).code())
			.as("不认识的维度").isEqualTo("BUDGET_SCOPE_INVALID");
	}

	@Test
	@DisplayName("已停用的大类允许设预算：历史流水还在往里记")
	void disabledTopCategoryStillAcceptsABudget() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long carCare = postJson(CATEGORIES, Map.of("type", "EXPENSE", "name", "养车"), owner.accessToken()).data()
			.path("id").asLong();
		assertThat(patchJson(CATEGORIES + "/" + carCare + "/toggle", Map.of(), owner.accessToken()).code())
			.isEqualTo("OK");

		assertThat(saveBudgets(owner, List.of(item("CATEGORY", carCare, null, "500.00"))).code()).isEqualTo("OK");
	}

	// ---- 预算：进度口径 ----

	@Test
	@DisplayName("百分比向下取整：79.6% 显示 79% 且档位仍是 NORMAL，800 才进预警")
	void percentIsRoundedDownWhileTheBandUsesTheRawRatio() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");

		record(owner, dining, cash, "796.00");
		JsonNode justBelow = progressOf(owner, "FAMILY");
		assertThat(justBelow.path("usedPercent").asInt()).as("四舍五入会得到 80，界面上就是「写着 80%、颜色却没变」").isEqualTo(79);
		assertThat(justBelow.path("level").asText()).isEqualTo("NORMAL");

		record(owner, dining, cash, "4.00");
		JsonNode atEighty = progressOf(owner, "FAMILY");
		assertThat(atEighty.path("usedPercent").asInt()).isEqualTo(80);
		assertThat(atEighty.path("level").asText()).isEqualTo("WARNING");
	}

	@Test
	@DisplayName("恰好花完额度算超支而不是预警，剩余为 0")
	void exactlyTheBudgetIsExceeded() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		record(owner, dining, cash, "1000.00");

		JsonNode row = progressOf(owner, "FAMILY");
		assertThat(row.path("level").asText()).as("§4.2.4 的阈值表把 ≥100% 划在超支这一档").isEqualTo("EXCEEDED");
		assertThat(row.path("usedPercent").asInt()).isEqualTo(100);
		assertThat(money(row.path("remaining"))).isEqualByComparingTo("0.00");
	}

	@Test
	@DisplayName("超支时剩余是负数，服务端不替前端把它抹成 0")
	void overBudgetKeepsANegativeRemaining() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		record(owner, dining, cash, "1000.01");

		JsonNode row = progressOf(owner, "FAMILY");
		assertThat(row.path("level").asText()).isEqualTo("EXCEEDED");
		assertThat(money(row.path("remaining"))).isEqualByComparingTo("-0.01");
		assertThat(row.path("usedPercent").asInt()).as("100.001% 向下取整成 100，不是 101").isEqualTo(100);
	}

	@Test
	@DisplayName("本月一笔没花：0%、NORMAL、剩余等于额度")
	void noSpendAtAll() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");

		JsonNode row = progressOf(owner, "FAMILY");
		assertThat(money(row.path("used"))).isEqualByComparingTo("0.00");
		assertThat(row.path("usedPercent").asInt()).isZero();
		assertThat(row.path("level").asText()).isEqualTo("NORMAL");
		assertThat(money(row.path("remaining"))).isEqualByComparingTo("1000.00");
	}

	@Test
	@DisplayName("预算的三个维度各自独立：同一笔支出同时算进大类预算与家庭预算")
	void dimensionsAreIndependentAndOverlap() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long transport = topCategoryId(owner, "交通");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveBudgets(owner,
				List.of(item("FAMILY", null, null, "5000.00"), item("CATEGORY", dining, null, "2000.00"),
						item("CATEGORY", transport, null, "500.00"))).code()).isEqualTo("OK");
		record(owner, dining, cash, "600.00");

		assertThat(money(progressOf(owner, "FAMILY").path("used"))).isEqualByComparingTo("600.00");
		assertThat(money(progressByCategory(owner, dining).path("used"))).as("餐饮的钱同时算进总预算，两个进度条互不扣减")
			.isEqualByComparingTo("600.00");
		assertThat(money(progressByCategory(owner, transport).path("used"))).isEqualByComparingTo("0.00");
	}

	@Test
	@DisplayName("类别维度按大类聚合：同一大类下两个小类的钱加在一起")
	void categoryScopeAggregatesSubCategories() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long lunch = subCategoryId(owner, "餐饮", "午餐");
		long dinner = subCategoryId(owner, "餐饮", "晚餐");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveBudgets(owner, List.of(item("CATEGORY", dining, null, "2000.00"))).code()).isEqualTo("OK");
		recordWithSub(owner, dining, lunch, cash, "30.00");
		recordWithSub(owner, dining, dinner, cash, "45.00");

		assertThat(money(progressOf(owner, "CATEGORY").path("used"))).as("流水的小类留没留空都一样，大类恒记在 category_id 上")
			.isEqualByComparingTo("75.00");
	}

	@Test
	@DisplayName("周期记账生成的那笔要算进预算已用")
	void progressIncludesAutoGeneratedRows() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		Map<String, Object> rule = new LinkedHashMap<>();
		rule.put("name", "房租");
		rule.put("amount", "800.00");
		rule.put("categoryId", dining);
		rule.put("accountId", cash);
		rule.put("periodType", "DAILY");
		rule.put("periodValue", Map.of("intervalDays", 1));
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");

		assertThat(postJson(RECURRING_RULES, rule, owner.accessToken()).code()).isEqualTo("OK");
		JsonNode row = progressOf(owner, "FAMILY");
		assertThat(money(row.path("used"))).as("自动记账的钱与手记的钱在预算里没有区别").isEqualByComparingTo("800.00");
		assertThat(row.path("level").asText()).isEqualTo("WARNING");
	}

	@Test
	@DisplayName("查指定月份：只算那个月的流水，剩余天数只对当月给")
	void progressForAnotherMonth() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		LocalDate lastMonth = LocalDate.now().minusMonths(1).withDayOfMonth(10);
		recordOn(owner, dining, cash, "250.00", lastMonth);

		JsonNode then = progressOf(owner, "FAMILY", yearMonth(lastMonth));
		assertThat(then.path("month").asText()).isEqualTo(yearMonth(lastMonth));
		assertThat(money(then.path("used"))).isEqualByComparingTo("250.00");
		assertThat(then.path("remainingDays").asInt()).as("过去月份给 0 而不是负数").isZero();

		assertThat(money(progressOf(owner, "FAMILY").path("used"))).as("当月一笔都没有，上月的不许串进来")
			.isEqualByComparingTo("0.00");
		assertThat(progressOf(owner, "FAMILY").path("remainingDays").asInt())
			.as("建议日均可用金额要靠它算，当月必须给真实天数").isPositive();

		assertThat(getJson(BUDGET_PROGRESS, Map.of("month", "2026-9"), owner.accessToken()).code())
			.as("月份要写成 2026-09").isEqualTo("BAD_REQUEST");
	}

	// ---- 提醒：开关 ----

	@Test
	@DisplayName("开关列表返回 8 项、顺序与枚举一致，只有前六项会进通知栏")
	void settingsListHasSevenItemsInEnumOrder() throws Exception {
		Account owner = register(PHONE_A, "张三");

		List<JsonNode> rows = toList(getJson(REMINDER_SETTINGS, owner.accessToken()).data());
		assertThat(rows.stream().map(row -> row.path("type").asText()).toList()).containsExactly(
				"CAT_DEWORMING_INTERNAL", "CAT_DEWORMING_EXTERNAL", "CAT_FOOD_LOW", "VACCINE_UPCOMING", BUDGET_OVERRUN,
				BUDGET_WARNING, "GROWTH_RECORD_DUE", "BABY_FORMULA_LOW");
		assertThat(rows.stream().filter(row -> row.path("pushed").asBoolean())
				.map(row -> row.path("type").asText()).toList()).as("钉的是「哪几类」而不是「几类」，给错任一项都会红")
				.containsExactly("CAT_DEWORMING_INTERNAL", "CAT_DEWORMING_EXTERNAL", "CAT_FOOD_LOW", "VACCINE_UPCOMING",
						BUDGET_OVERRUN, "BABY_FORMULA_LOW");
		assertThat(rows.get(0).path("label").asText()).as("中文标签由服务端给，前端不硬编码八份中文").isEqualTo("猫咪体内驱虫到期");
	}

	@Test
	@DisplayName("80% 预警默认关，其余七项默认开")
	void budgetWarningIsOffByDefault() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		List<JsonNode> rows = toList(getJson(REMINDER_SETTINGS, owner.accessToken()).data());
		assertThat(rows).filteredOn(row -> row.path("enabled").asBoolean()).hasSize(7);
		assertThat(rows.stream().filter(row -> BUDGET_WARNING.equals(row.path("type").asText())).findFirst()
			.orElseThrow().path("enabled").asBoolean()).as("一到 80% 就发通知太吵，这一档只在 App 内出红点").isFalse();
	}

	@Test
	@DisplayName("开关按用户存、可以单独改，改过的值盖掉默认值")
	void settingsAreSavedPerUserAndOverrideDefaults() throws Exception {
		Account owner = register(PHONE_A, "张三");
		Account stranger = register(PHONE_OTHER, "王五");
		assertThat(saveSettings(owner, List.of(setting(BUDGET_WARNING, true), setting("CAT_FOOD_LOW", false))).code())
			.isEqualTo("OK");

		assertThat(enabledOf(owner, BUDGET_WARNING)).isTrue();
		assertThat(enabledOf(owner, "CAT_FOOD_LOW")).isFalse();
		assertThat(enabledOf(stranger, BUDGET_WARNING)).as("开关是每用户一份，不是每家庭一份").isFalse();

		assertThat(saveSettings(owner, List.of(setting(BUDGET_WARNING, false))).code()).isEqualTo("OK");
		assertThat(enabledOf(owner, BUDGET_WARNING)).as("再提交一次是改值而不是插第二行").isFalse();
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM reminder_setting WHERE user_id = ?",
				Integer.class, owner.userId())).isEqualTo(2);
	}

	@Test
	@DisplayName("提醒类型不认识 400；同一类型传两次 409")
	void unknownTypeAndDuplicateType() throws Exception {
		Account owner = register(PHONE_A, "张三");

		Call unknown = saveSettings(owner, List.of(setting("NOT_A_TYPE", true)));
		assertThat(unknown.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(unknown.message()).as("错误信息要点出是哪一个不认识").contains("NOT_A_TYPE");
		assertThat(saveSettings(owner, List.of(setting(BUDGET_WARNING, true), setting(BUDGET_WARNING, false))).code())
			.isEqualTo("REMINDER_SETTING_DUPLICATED");
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM reminder_setting", Integer.class))
			.as("去重漏了就会撞唯一索引变成一条 500，而那时前一行已经插进去了").isZero();
	}

	@Test
	@DisplayName("提醒开关是全项目唯一不要求有家庭的业务能力")
	void settingsWorkWithoutAFamily() throws Exception {
		Account alone = register(PHONE_ALONE, "独行");

		Call settings = getJson(REMINDER_SETTINGS, alone.accessToken());
		assertThat(settings.status()).isEqualTo(HttpStatus.OK.value());
		assertThat(toList(settings.data())).hasSize(8);
		Call pending = getJson(REMINDER_PENDING, alone.accessToken());
		assertThat(pending.status()).as("没有家庭就没有预算可算，但开关页要能打开").isEqualTo(HttpStatus.OK.value());
		assertThat(pending.data()).isEmpty();
	}

	// ---- 提醒：产出 ----

	@Test
	@DisplayName("pending 的两档互斥：同一个事实只会以「已超支」出现一次")
	void pendingKeepsTheTwoBandsApart() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveSettings(owner, List.of(setting(BUDGET_WARNING, true))).code()).isEqualTo("OK");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		record(owner, dining, cash, "850.00");

		List<JsonNode> warning = toList(getJson(REMINDER_PENDING, owner.accessToken()).data());
		assertThat(warning).hasSize(1);
		assertThat(warning.get(0).path("type").asText()).isEqualTo(BUDGET_WARNING);
		assertThat(warning.get(0).path("route").asText()).isEqualTo("/finance/budgets");
		assertThat(warning.get(0).path("body").asText()).contains("还剩 150.00 元");
		assertThat(warning.get(0).path("fireAt").isNull()).as("App 内红点没有排期时间，那是 S9 本地通知的事").isTrue();

		record(owner, dining, cash, "350.00");
		List<JsonNode> exceeded = toList(getJson(REMINDER_PENDING, owner.accessToken()).data());
		assertThat(exceeded).as("超支之后不再叠一条预警，用户为一个事实只该看到一次").hasSize(1);
		assertThat(exceeded.get(0).path("type").asText()).isEqualTo(BUDGET_OVERRUN);
		assertThat(exceeded.get(0).path("key").asText()).as("去重键不带月份，跨月时前端的「今天已提醒」才不会失效")
			.isEqualTo("BUDGET_OVERRUN:FAMILY");
		assertThat(exceeded.get(0).path("module").asText()).as("客户端按它把角标挂到记账 Tab 上（§4.5.2）")
			.isEqualTo("FINANCE");
	}

	@Test
	@DisplayName("预警档关着时 85% 什么都不产出，超支档仍照常产出")
	void pendingRespectsTheSwitches() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		record(owner, dining, cash, "850.00");

		assertThat(toList(getJson(REMINDER_PENDING, owner.accessToken()).data())).as("默认状态下这一档是关的")
			.isEmpty();
		record(owner, dining, cash, "200.00");
		List<JsonNode> rows = toList(getJson(REMINDER_PENDING, owner.accessToken()).data());
		assertThat(rows).hasSize(1);
		assertThat(rows.get(0).path("type").asText()).isEqualTo(BUDGET_OVERRUN);
		assertThat(rows.get(0).path("body").asText()).contains("超出预算 50.00 元");
	}

	@Test
	@DisplayName("恰好花完额度时不说「超出预算 0.00 元」")
	void exactlySpentBudgetWordsTheBodyDifferently() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		record(owner, dining, cash, "1000.00");

		assertThat(toList(getJson(REMINDER_PENDING, owner.accessToken()).data()).get(0).path("body").asText())
			.contains("本月预算已用完");
	}

	@Test
	@DisplayName("三个维度各自出一条提醒，去重键分别落在类别与成员上")
	void eachBudgetRowProducesItsOwnReminder() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		long dining = topCategoryId(owner, "餐饮");
		long transport = topCategoryId(owner, "交通");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveSettings(owner, List.of(setting(BUDGET_WARNING, true))).code()).isEqualTo("OK");
		assertThat(saveBudgets(owner,
				List.of(item("CATEGORY", dining, null, "100.00"), item("CATEGORY", transport, null, "100.00"),
						item("MEMBER", null, member.userId(), "100.00"))).code()).isEqualTo("OK");
		record(owner, dining, cash, "90.00");
		record(member, transport, cash, "95.00");

		List<JsonNode> rows = toList(getJson(REMINDER_PENDING, owner.accessToken()).data());
		assertThat(rows).as("一笔超支都没有，三条都是预警档").hasSize(3);
		assertThat(rows).allSatisfy(row -> assertThat(row.path("type").asText()).isEqualTo(BUDGET_WARNING));
		assertThat(rows.stream().map(row -> row.path("key").asText()).toList()).containsExactlyInAnyOrder(
				"BUDGET_WARNING:C:" + dining, "BUDGET_WARNING:C:" + transport, "BUDGET_WARNING:M:" + member.userId());
		assertThat(rows.stream().map(row -> row.path("title").asText()).distinct().toList())
			.as("标题不带维度名，具体是谁超了写在正文里").containsExactly("本月预算即将超支");
	}

	@Test
	@DisplayName("预算按家庭隔离：乙家庭看不到甲的预算，也收不到甲带来的提醒")
	void budgetsAreIsolatedBetweenFamilies() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account other = registerWithFamily(PHONE_OTHER, "王五");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		assertThat(saveSettings(owner, List.of(setting(BUDGET_WARNING, true))).code()).isEqualTo("OK");
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "1000.00"))).code()).isEqualTo("OK");
		record(owner, dining, cash, "900.00");

		assertThat(toList(getJson(BUDGETS, other.accessToken()).data())).isEmpty();
		assertThat(toList(getJson(BUDGET_PROGRESS, other.accessToken()).data())).isEmpty();
		assertThat(toList(getJson(REMINDER_PENDING, other.accessToken()).data())).as("提醒的开关跟用户走，但产出跟家庭走")
			.isEmpty();
	}

	@Test
	@DisplayName("接缝 1：成员退出后他的个人预算被删掉，其余维度留着")
	void leavingMemberLosesHisBudget() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		assertThat(saveBudgets(owner, List.of(item("FAMILY", null, null, "5000.00"),
				item("MEMBER", null, member.userId(), "1500.00"))).code()).isEqualTo("OK");

		assertThat(postJson(FAMILIES + "/current/leave", Map.of(), member.accessToken()).code()).isEqualTo("OK");
		List<JsonNode> rows = toList(getJson(BUDGETS, owner.accessToken()).data());
		assertThat(rows).hasSize(1);
		assertThat(rows.get(0).path("scope").asText()).isEqualTo("FAMILY");
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM budget WHERE member_user_id = ?", Integer.class,
				member.userId())).as("额度配置跟着人走，不像周期规则那样保留").isZero();
	}

	// ---- 请求与取值辅助 ----

	private Call saveBudgets(Account account, List<Map<String, Object>> items) throws Exception {
		return putJson(BUDGETS, Map.of("items", items), account.accessToken());
	}

	private static Map<String, Object> item(String scope, Long categoryId, Long memberUserId, String amount) {
		Map<String, Object> item = new LinkedHashMap<>();
		item.put("scope", scope);
		item.put("categoryId", categoryId);
		item.put("memberUserId", memberUserId);
		item.put("amount", amount);
		return item;
	}

	private List<Long> budgetIds(Account account) throws Exception {
		List<Long> ids = new ArrayList<>();
		for (JsonNode row : toList(getJson(BUDGETS, account.accessToken()).data())) {
			ids.add(row.path("id").asLong());
		}
		return ids;
	}

	private JsonNode progressOf(Account account, String scope) throws Exception {
		return progressOf(account, scope, null);
	}

	private JsonNode progressOf(Account account, String scope, String month) throws Exception {
		Call call = (month == null) ? getJson(BUDGET_PROGRESS, account.accessToken())
				: getJson(BUDGET_PROGRESS, Map.of("month", month), account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		List<JsonNode> hits = toList(call.data()).stream()
			.filter(row -> row.path("scope").asText().equals(scope))
			.toList();
		assertThat(hits).as("维度 " + scope + " 的进度应当恰好一条").hasSize(1);
		return hits.get(0);
	}

	private JsonNode progressByCategory(Account account, long categoryId) throws Exception {
		List<JsonNode> hits = toList(getJson(BUDGET_PROGRESS, account.accessToken()).data()).stream()
			.filter(row -> "CATEGORY".equals(row.path("scope").asText()) && row.path("categoryId").asLong() == categoryId)
			.toList();
		assertThat(hits).hasSize(1);
		return hits.get(0);
	}

	private void record(Account account, long categoryId, long accountId, String amount) throws Exception {
		recordOn(account, categoryId, null, accountId, amount, LocalDate.now());
	}

	private void recordOn(Account account, long categoryId, long accountId, String amount, LocalDate bizDate)
			throws Exception {
		recordOn(account, categoryId, null, accountId, amount, bizDate);
	}

	private void recordWithSub(Account account, long categoryId, Long subCategoryId, long accountId, String amount)
			throws Exception {
		recordOn(account, categoryId, subCategoryId, accountId, amount, LocalDate.now());
	}

	private void recordOn(Account account, long categoryId, Long subCategoryId, long accountId, String amount,
			LocalDate bizDate) throws Exception {
		Map<String, Object> payload = new LinkedHashMap<>();
		payload.put("amount", amount);
		payload.put("categoryId", categoryId);
		payload.put("subCategoryId", subCategoryId);
		payload.put("accountId", accountId);
		payload.put("bizDate", bizDate.toString());
		Call call = postJson(TRANSACTIONS, payload, account.accessToken());
		assertThat(call.code()).as("记一笔 %s", payload).isEqualTo("OK");
	}

	private Call saveSettings(Account account, List<Map<String, Object>> items) throws Exception {
		return putJson(REMINDER_SETTINGS, Map.of("items", items), account.accessToken());
	}

	private static Map<String, Object> setting(String type, boolean enabled) {
		return Map.of("type", type, "enabled", enabled);
	}

	private boolean enabledOf(Account account, String type) throws Exception {
		return toList(getJson(REMINDER_SETTINGS, account.accessToken()).data()).stream()
			.filter(row -> row.path("type").asText().equals(type))
			.findFirst()
			.orElseThrow()
			.path("enabled")
			.asBoolean();
	}

	private long subCategoryId(Account account, String topName, String subName) throws Exception {
		Call call = getJson(CATEGORIES + "?type=EXPENSE&enabledOnly=false", account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		for (JsonNode top : call.data()) {
			if (!top.path("name").asText().equals(topName)) {
				continue;
			}
			for (JsonNode child : top.path("children")) {
				if (child.path("name").asText().equals(subName)) {
					return child.path("id").asLong();
				}
			}
		}
		throw new AssertionError("预置类别树里 " + topName + " 下应有小类 " + subName);
	}

	private static String yearMonth(LocalDate date) {
		return date.getYear() + "-" + String.format("%02d", date.getMonthValue());
	}

	private static BigDecimal money(JsonNode node) {
		return new BigDecimal(node.asText());
	}

	private static List<JsonNode> toList(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

}
