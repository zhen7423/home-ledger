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
 * §4.3.5 猫咪统计的两条端点（验收用例 17 与 20），外加 §5.1 缓存模块段的跨模块验收。
 * <p>
 * 模块隔离在 HTTP 响应上是观察不到的——重算出来的数一模一样，只有 Redis 里那两个版本号键能说话，
 * 所以这条证据只能写在集成测试里。
 * <p>
 * 猫粮那几组的日期一律相对今天写：当前袋的结束日就是今天，写死日期会让期望值跟着日历漂。
 * 唯一的例外是跨自然月分摊那一条，它就是需求文档 §4.3.5 举的那个例子本身，数字与日期照抄。
 */
class CatStatisticsIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("验收用例 17 前半：品牌占比按消耗克数算，袋数多的品牌不因此靠前")
	void case17_brandShareIsByGramsNotByBagCount() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		seedThreeBags(owner);

		List<JsonNode> slices = toList(food(owner, Map.of()).path("brandBreakdown"));
		assertThat(slices).hasSize(2);
		assertThat(slices.get(0).path("brand").asText()).as("看的是克数，2000g 的那个大袋在第一片").isEqualTo("B牌");
		assertThat(slices.get(0).path("grams").asInt()).isEqualTo(2000);
		assertThat(slices.get(1).path("grams").asInt()).as("另一个品牌两袋合计 1000g，袋数是它的两倍而克数是一半").isEqualTo(1000);
		assertThat(slices.get(0).path("percent").asInt()).as("HALF_UP(2000×100÷3000)").isEqualTo(67);
		assertThat(slices.get(1).path("percent").asInt()).as("HALF_UP(1000×100÷3000)").isEqualTo(33);
		assertThat(slices.get(0).path("percent").asInt())
			.isGreaterThanOrEqualTo(slices.get(1).path("percent").asInt());
		int percentSum = slices.stream().mapToInt(node -> node.path("percent").asInt()).sum();
		assertThat(percentSum).as("各自取整未必凑得满 100，所以断区间而不是断等号").isBetween(99, 100);
	}

	@Test
	@DisplayName("验收用例 17 后半：一袋跨自然月时按月分摊，1 月 600g、2 月 1400g")
	void case17_monthlyTrendSplitsACrossMonthBag() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		createBag(owner, "皇家", 2000, LocalDate.of(2026, 1, 20));
		createBag(owner, "渴望", 1000, LocalDate.of(2026, 3, 1));

		JsonNode trend = food(owner, Map.of()).path("monthlyTrend");
		assertThat(toList(trend)).as("固定 12 根柱子，没有消耗的月份补 0").hasSize(12);
		assertThat(monthGrams(trend, "2026-01")).as("1 月 20 日到 31 日共 12 天 × 日均 50g").isEqualTo(600);
		assertThat(monthGrams(trend, "2026-02")).as("2 月整月 28 天 × 日均 50g").isEqualTo(1400);
	}

	@Test
	@DisplayName("逐月柱子的总和恒等于概览卡的总克数：分摊只取整一次")
	void monthlyTrendSumsUpToTheIntervalTotal() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		seedThreeBags(owner);

		JsonNode data = food(owner, Map.of("startDate", TODAY.withDayOfMonth(1).minusMonths(11).toString(),
				"endDate", TODAY.toString()));
		int buckets = toList(data.path("monthlyTrend")).stream().mapToInt(node -> node.path("grams").asInt()).sum();
		assertThat(buckets).as("各段自己 floor 一次会留下几克的毛刺，这条就是它的哨兵").isEqualTo(3000)
			.isEqualTo(data.path("totalGrams").asInt());
	}

	@Test
	@DisplayName("逐月趋势不随区间变化：查本月与查近十二个月得到同样的十二根柱子")
	void monthlyTrendIgnoresTheRequestedRange() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		seedThreeBags(owner);

		JsonNode thisMonth = food(owner,
				Map.of("startDate", TODAY.withDayOfMonth(1).toString(), "endDate", TODAY.toString()));
		JsonNode wholeWindow = food(owner, Map.of("startDate", TODAY.withDayOfMonth(1).minusMonths(11).toString(),
				"endDate", TODAY.toString()));
		assertThat(thisMonth.path("monthlyTrend")).as("柱子与区间求交会得到十一根零柱加一根有值的柱子").isEqualTo(wholeWindow.path("monthlyTrend"));
		assertThat(thisMonth.path("totalGrams").asInt()).isNotEqualTo(wholeWindow.path("totalGrams").asInt());
	}

	@Test
	@DisplayName("endDate 晚于今天时截断到今天：分母按今天算，克数与不传 endDate 时相同")
	void intervalEndingInTheFutureIsTruncatedToToday() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		seedThreeBags(owner);

		JsonNode future = food(owner, Map.of("startDate", TODAY.minusDays(59).toString(), "endDate",
				TODAY.plusDays(30).toString()));
		assertThat(future.path("endDate").asText()).isEqualTo(TODAY.toString());
		assertThat(future.path("days").asInt()).as("今天−59 到今天，含首尾 60 天").isEqualTo(60);
		assertThat(future.path("totalGrams").asInt()).isEqualTo(food(owner, Map.of()).path("totalGrams").asInt());
		assertThat(future.path("dailyAverage").asInt()).as("3000 ÷ 60，摊进未来的 30 天就会算成 32").isEqualTo(50);
	}

	@Test
	@DisplayName("用完袋数只数已闭合的袋，当前在用的那一袋不算")
	void finishedBagsExcludesTheCurrentBag() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		seedThreeBags(owner);

		assertThat(food(owner, Map.of()).path("finishedBags").asInt())
			.as("三袋里最后一袋还在吃，把它数进去「用完 N 袋」就虚了一格").isEqualTo(2);
	}

	@Test
	@DisplayName("驱虫统计没有日期入参：传了也不改变窗口")
	void dewormingStatisticsIgnoreAnyDateParam() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "大橘", null);
		createDeworming(owner, catId, "EXTERNAL", TODAY.minusDays(10));

		JsonNode plain = deworming(owner, Map.of());
		assertThat(deworming(owner, Map.of("startDate", "2020-01-01", "endDate", "2020-12-31"))).isEqualTo(plain);
		assertThat(plain.path("windowStart").asText())
			.isEqualTo(TODAY.minusMonths(11).withDayOfMonth(1).toString());
		assertThat(plain.path("windowEnd").asText()).isEqualTo(TODAY.toString());
	}

	@Test
	@DisplayName("验收用例 20：应做次数从建档日起步，而不是把整个窗口当成应做次数")
	void case20_completionCountsFromTheRegistrationDate() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		saveSettings(owner, 3, 1);
		// 生日早于建档日是补录旧猫的常态，起点取两者里较晚的那个，所以这一格量的还是建档日
		long catId = createCat(owner, "大橘", LocalDate.of(2019, 5, 1));

		JsonNode external = completionOf(owner, catId, "EXTERNAL");
		assertThat(external.path("due").asInt()).as("周期 1 个月、起点就是今天，窗口内只有一次").isEqualTo(1);
		assertThat(external.path("due").asInt()).as("拿窗口起点当起点会算成 12").isLessThan(12);
		assertThat(external.path("done").asInt()).isZero();
		assertThat(external.path("rate").asInt()).isZero();
	}

	@Test
	@DisplayName("一条记录都没有的猫也在完成度里占两格，但不出现在倒计时里")
	void aCatWithNoRecordsAtAllStillReportsDue() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "刚领回来的猫", null);

		JsonNode data = deworming(owner, Map.of());
		List<JsonNode> rows = toList(data.path("completion")).stream()
			.filter(row -> row.path("catId").asLong() == catId)
			.toList();
		assertThat(rows).as("内驱与外驱各一行").hasSize(2);
		for (JsonNode row : rows) {
			assertThat(row.path("due").asInt()).isPositive();
			assertThat(row.path("done").asInt()).isZero();
			assertThat(row.path("rate").asInt()).as("due 为 0 才给 100，这里应做 1 次而实做 0 次").isZero();
			assertThat(row.path("overdueDays").isNull()).as("没有下次日期就谈不上逾期").isTrue();
		}
		assertThat(toList(data.path("dueCountdown"))).as("倒计时里放一个空白格子不如不放").isEmpty();
	}

	@Test
	@DisplayName("时间轴倒序且含归档猫的历史，完成度与倒计时却只算在册的猫")
	void timelineOrderedNewestFirst() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catA = createCat(owner, "大橘", null);
		long catB = createCat(owner, "小花", null);
		createDeworming(owner, catB, "INTERNAL", TODAY.minusDays(70));
		createDeworming(owner, catA, "EXTERNAL", TODAY.minusDays(15));
		createDeworming(owner, catB, "EXTERNAL", TODAY.minusDays(15));
		assertThat(patchJson(CATS + "/" + catB + "/archive", null, owner.accessToken()).code()).isEqualTo("OK");

		JsonNode data = deworming(owner, Map.of());
		List<JsonNode> timeline = toList(data.path("timeline"));
		assertThat(timeline).as("抹掉归档猫的历史等于抹数据").hasSize(3);
		assertThat(timeline.get(0).path("doneDate").asText()).as("最近的一次在顶上").isEqualTo(TODAY.minusDays(15).toString());
		assertThat(timeline.get(0).path("catId").asLong()).as("同一天按 catId 定序，否则换库就可能换序").isEqualTo(catA);
		assertThat(timeline.get(1).path("catId").asLong()).isEqualTo(catB);
		assertThat(timeline.get(2).path("doneDate").asText()).isEqualTo(TODAY.minusDays(70).toString());
		assertThat(toList(data.path("completion")).stream().filter(row -> row.path("catId").asLong() == catB).toList())
			.as("完成度回答的是「接下来该给谁驱」，归档猫不占一个永远做不完的格子").isEmpty();
	}

	@Test
	@DisplayName("统计缓存的版本号按模块分段：记一笔流水打不脏猫咪统计，反之也一样")
	void statisticsCacheIsolatesModules() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long familyId = familyId(owner);
		assertThat(deworming(owner, Map.of()).path("windowEnd").asText()).isEqualTo(TODAY.toString());
		assertThat(getJson(STATISTICS_OVERVIEW, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(versionOf("cat", familyId)).as("两条读端点都不该递增版本号").isEqualTo("0");
		assertThat(versionOf("fin", familyId)).isEqualTo("0");

		createBag(owner, "皇家", 1000, TODAY.minusDays(3));
		assertThat(versionOf("cat", familyId)).as("开一袋猫粮只递增猫咪那一版").isEqualTo("1");
		assertThat(versionOf("fin", familyId)).as("财务统计与猫粮袋毫无关系").isEqualTo("0");

		record(owner, topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"));
		assertThat(versionOf("fin", familyId)).as("记一笔流水只递增财务那一版").isEqualTo("1");
		assertThat(versionOf("cat", familyId)).as("共用一个版本号会让两者互相打脏，那是这条断言要挡住的实现").isEqualTo("1");
	}

	@Test
	@DisplayName("他家的猫、袋子与驱虫记录一条都不出现在本家庭的统计里")
	void statisticsAreFamilyScoped() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		seedThreeBags(owner);
		long catId = createCat(owner, "大橘", null);
		createDeworming(owner, catId, "EXTERNAL", TODAY.minusDays(5));

		JsonNode food = food(outsider, Map.of());
		assertThat(food.path("totalGrams").asInt()).isZero();
		assertThat(food.path("dailyAverage").asInt()).isZero();
		assertThat(food.path("finishedBags").asInt()).isZero();
		assertThat(toList(food.path("brandBreakdown"))).as("没有消耗就是空饼，不是一片 0%").isEmpty();
		assertThat(toList(food.path("bagUsages"))).isEmpty();
		assertThat(toList(food.path("monthlyTrend")).stream().mapToInt(node -> node.path("grams").asInt()).sum())
			.isZero();

		JsonNode deworming = deworming(outsider, Map.of());
		assertThat(toList(deworming.path("completion"))).isEmpty();
		assertThat(toList(deworming.path("timeline"))).isEmpty();
		assertThat(toList(deworming.path("dueCountdown"))).isEmpty();
	}

	@Test
	@DisplayName("无家庭的账号碰两条统计端点都是 NO_FAMILY")
	void statisticsRequireAFamily() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call call = getJson(CAT_FOOD_STATISTICS, lonely.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(call.code()).isEqualTo("NO_FAMILY");
		assertThat(getJson(CAT_DEWORMING_STATISTICS, lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
	}

	@Test
	@DisplayName("跨度超 366 天复用共用的区间校验，报错文案与记账统计同一句")
	void spanOver366DaysIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		Call call = getJson(CAT_FOOD_STATISTICS,
				Map.of("startDate", "2025-01-01", "endDate", "2026-01-02"), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.code()).isEqualTo("BAD_REQUEST");
		assertThat(call.message()).contains("时间区间最长 366 天");
	}

	// ---- 辅助 ----

	/** A牌 两个小袋各 10 天共 1000g、B牌 一个大袋 40 天 2000g，三袋铺满最近 60 天，每个数都能口算。 */
	private void seedThreeBags(Account account) throws Exception {
		createBag(account, "A牌", 500, TODAY.minusDays(59));
		createBag(account, "A牌", 500, TODAY.minusDays(49));
		createBag(account, "B牌", 2000, TODAY.minusDays(39));
	}

	private JsonNode food(Account account, Map<String, String> params) throws Exception {
		Call call = getJson(CAT_FOOD_STATISTICS, params, account.accessToken());
		assertThat(call.code()).as("猫粮消耗统计 %s", params).isEqualTo("OK");
		return call.data();
	}

	private JsonNode deworming(Account account, Map<String, String> params) throws Exception {
		Call call = getJson(CAT_DEWORMING_STATISTICS, params, account.accessToken());
		assertThat(call.code()).as("驱虫统计 %s", params).isEqualTo("OK");
		return call.data();
	}

	private JsonNode completionOf(Account account, long catId, String type) throws Exception {
		return toList(deworming(account, Map.of()).path("completion")).stream()
			.filter(row -> row.path("catId").asLong() == catId && row.path("type").asText().equals(type))
			.findFirst()
			.orElseThrow(() -> new AssertionError("完成度里应有 " + catId + " 号猫的 " + type + " 那一行"));
	}

	private long createBag(Account account, String brand, int packGrams, LocalDate startedDate) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("brand", brand);
		body.put("packGrams", packGrams);
		body.put("startedDate", startedDate.toString());
		body.put("remark", null);
		Call call = postJson(CAT_FOOD_BAGS, body, account.accessToken());
		assertThat(call.code()).as("开一袋 %s", brand).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private long createCat(Account account, String name, LocalDate birthday) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("name", name);
		body.put("gender", "FEMALE");
		body.put("birthday", birthday);
		body.put("birthdayEstimated", false);
		body.put("neutered", "YES");
		Call call = postJson(CATS, body, account.accessToken());
		assertThat(call.code()).as("建档 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private void createDeworming(Account account, long catId, String type, LocalDate doneDate) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("catId", catId);
		body.put("type", type);
		body.put("doneDate", doneDate.toString());
		body.put("medicine", "拜宠清");
		body.put("dosage", "按体重 4kg 用 1 支");
		body.put("nextDate", null);
		body.put("remark", null);
		Call call = postJson(CAT_DEWORMINGS, body, account.accessToken());
		assertThat(call.code()).as("记一次 %s 驱虫", type).isEqualTo("OK");
	}

	private void saveSettings(Account account, int internalMonths, int externalMonths) throws Exception {
		assertThat(putJson(CAT_SETTINGS,
				Map.of("internalMonths", internalMonths, "externalMonths", externalMonths), account.accessToken())
			.code()).isEqualTo("OK");
	}

	private void record(Account account, long categoryId, long accountId) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("amount", "30.00");
		body.put("categoryId", categoryId);
		body.put("accountId", accountId);
		body.put("bizDate", TODAY.toString());
		assertThat(postJson(TRANSACTIONS, body, account.accessToken()).code()).isEqualTo("OK");
	}

	/** 与 {@code StatisticsCache} 同一口径：从没写过数据的家庭没有版本号键，读成 "0"。 */
	private String versionOf(String module, long familyId) {
		String raw = redis.opsForValue().get("stats:ver:" + module + ":" + familyId);
		return raw == null ? "0" : raw;
	}

	private long familyId(Account account) throws Exception {
		return currentFamily(account.accessToken()).data().path("id").asLong();
	}

	private int monthGrams(JsonNode trend, String month) {
		for (JsonNode bucket : trend) {
			if (bucket.path("month").asText().equals(month)) {
				return bucket.path("grams").asInt();
			}
		}
		throw new AssertionError("逐月趋势里应有 " + month + " 这一根柱子");
	}

	private List<JsonNode> toList(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

}
