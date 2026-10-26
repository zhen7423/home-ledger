package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import cn.homeledger.config.TimeConfig;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.4.6 宝宝统计的两条端点（验收用例 28 的机器版）。
 * <p>
 * 日期一律相对今天：判的是「离今天还有几天」，写死日期明天就测不到那条边界了。
 * <p>
 * 三处最容易写错的各有一条专门盯着：完成率的分母（远期剂次不得进、已标记的不得进）、
 * 体重别身高按<b>这一行的月龄</b>选表（不是按今天）、以及缓存命中（同条件第二次调用必须读到旧值）。
 */
class BabyStatisticsIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	private static final String HEP_B = "乙肝疫苗";

	private static final String BCG = "卡介苗";

	private static final String IPV = "脊灰灭活疫苗";

	private static final String FLU = "流感疫苗";

	private static final String CHICKENPOX = "水痘疫苗";

	private static final String ROTAVIRUS = "轮状病毒疫苗";

	private static final String PCV = "肺炎球菌疫苗";

	private static final int TOTAL_PLAN_ROWS = 24;

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	// ---- 完成率与状态分布 ----

	@Test
	@DisplayName("验收用例 28：完成率的分母只算已到期的剂次，刚出生那两针录完就是 100%")
	void completionRateExcludesFutureDoses() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		vaccinated(token, babyId, HEP_B, "1");
		vaccinated(token, babyId, BCG, "1");

		JsonNode baby = onlyBaby(vaccine(owner), babyId);

		assertThat(baby.path("completionRate").asInt()).as("分母是出生当天该打的那两针，不是 24 针")
			.isEqualTo(100);
		assertThat(planCount(token, babyId)).as("远期剂次整份生成，它们只是不进分母").isEqualTo(TOTAL_PLAN_ROWS);
		JsonNode counts = baby.path("statusCounts");
		assertThat(counts.path("vaccinated").asInt()).isEqualTo(2);
		assertThat(counts.path("dueSoon").asInt()).as("另外那 22 针都在 14 天窗口之外").isZero();
		assertThat(counts.path("upcoming").asInt()).isEqualTo(TOTAL_PLAN_ROWS - 2);
		assertThat(counts.path("overdue").asInt()).isZero();
	}

	@Test
	@DisplayName("跳过一针未接种的到期剂次：它同时退出分子与分母，比率因此上升而不是下降")
	void completionRateAfterSkipShrinksTheDenominator() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(2).toString());
		vaccinated(token, babyId, HEP_B, "1");

		assertThat(babyOf(owner, babyId).path("completionRate").asInt()).as("到期的五针里录了一针").isEqualTo(20);

		assertThat(skip(token, planIdOf(token, babyId, IPV, "1")).code()).isEqualTo("OK");

		assertThat(babyOf(owner, babyId).path("completionRate").asInt())
			.as("分母掉到四针、分子还是一针——「跳过」的意思本来就不该做").isEqualTo(25);
	}

	@Test
	@DisplayName("撤销跳过之后分母还原，完成率回到跳过之前的那个数")
	void completionRateRestoredAfterUndo() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(2).toString());
		vaccinated(token, babyId, HEP_B, "1");
		long planId = planIdOf(token, babyId, IPV, "1");
		assertThat(skip(token, planId).code()).isEqualTo("OK");

		assertThat(patchPlan(token, planId, "PENDING").code()).isEqualTo("OK");

		assertThat(babyOf(owner, babyId).path("completionRate").asInt()).isEqualTo(20);
	}

	@Test
	@DisplayName("已标记的行四个计数一个都不进，四数之和因此小于清单总行数")
	void statusCountsExcludeMarked() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		assertThat(sumOf(babyOf(owner, babyId).path("statusCounts"))).as("一针都没标时四数之和就是 24")
			.isEqualTo(TOTAL_PLAN_ROWS);

		assertThat(skip(token, planIdOf(token, babyId, BCG, "1")).code()).isEqualTo("OK");

		JsonNode counts = babyOf(owner, babyId).path("statusCounts");
		assertThat(sumOf(counts)).as("被跳过的那一针从 dueSoon 里消失，不进其他三段").isEqualTo(TOTAL_PLAN_ROWS - 1);
		assertThat(counts.path("dueSoon").asInt()).isEqualTo(1);
	}

	@Test
	@DisplayName("四数之和恒等于两张列表的长度之和：分段条与下面的清单数得出同一个数")
	void statusCountsMatchListLengths() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(6).toString());
		manual(token, babyId, FLU, "1", TODAY.minusDays(10));

		JsonNode baby = babyOf(owner, babyId);
		JsonNode counts = baby.path("statusCounts");

		assertThat(toList(baby.path("upcoming"))).hasSize(counts.path("dueSoon").asInt());
		assertThat(toList(baby.path("overdueList"))).hasSize(counts.path("overdue").asInt());
		assertThat(counts.path("overdue").asInt()).as("半岁宝宝身上欠着出生以来那几针").isPositive();
	}

	// ---- 待种与逾期两张列表 ----

	@Test
	@DisplayName("待种列表是今天起 14 天：第 15 天的不进，按日期升序")
	void upcomingWithin14DaysAscending() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		manual(token, babyId, FLU, "1", TODAY.plusDays(1));
		manual(token, babyId, CHICKENPOX, "1", TODAY.plusDays(5));
		manual(token, babyId, ROTAVIRUS, "1", TODAY.plusDays(14));
		manual(token, babyId, PCV, "1", TODAY.plusDays(15));

		List<JsonNode> upcoming = toList(babyOf(owner, babyId).path("upcoming"));

		assertThat(upcoming.stream().map(row -> row.path("daysToDue").asLong()).toList())
			.as("两针出生剂次是 0 天，15 天那条不在窗口内").containsExactly(0L, 0L, 1L, 5L, 14L);
		assertThat(namesOf(upcoming)).contains(FLU, CHICKENPOX, ROTAVIRUS).doesNotContain(PCV);
	}

	@Test
	@DisplayName("逾期列表取全部未完成的历史剂次，逾期最久的在最前，今天到期的不算逾期")
	void overdueListAscending() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(6).toString());
		manual(token, babyId, ROTAVIRUS, "1", TODAY.minusDays(10));
		manual(token, babyId, CHICKENPOX, "1", TODAY.minusDays(3));
		manual(token, babyId, FLU, "1", TODAY.minusDays(1));

		JsonNode baby = babyOf(owner, babyId);
		List<JsonNode> overdueList = toList(baby.path("overdueList"));

		assertThat(overdueList.stream().map(row -> row.path("dueDate").asText()).toList())
			.as("清单按 due_date 升序读出来，这一列自然升序").isSorted();
		assertThat(overdueList.stream().map(row -> row.path("dueDate").asText()).toList())
			.endsWith(TODAY.minusDays(10).toString(), TODAY.minusDays(3).toString(), TODAY.minusDays(1).toString());
		assertThat(overdueList.stream().map(row -> row.path("overdueDays").asLong()).toList())
			.as("最后三条是刚建的那三针，越欠得久越靠前").endsWith(10L, 3L, 1L);
		assertThat(overdueList.stream().map(row -> row.path("daysToDue").isNull()).toList())
			.as("逾期的行只有 overdueDays，没有 daysToDue").containsOnly(true);

		JsonNode today = toList(baby.path("upcoming")).stream()
			.filter(row -> row.path("dueDate").asText().equals(TODAY.toString()))
			.findFirst()
			.orElseThrow(() -> new AssertionError("半岁那天该打的那几针应落在待种列表里"));
		assertThat(today.path("daysToDue").asLong()).as("当天归未到期那一支：今天应接种，不是逾期 0 天").isZero();
		assertThat(today.path("overdueDays").isNull()).isTrue();
	}

	@Test
	@DisplayName("接种时间轴只回近 12 个月，倒序，机构原样带上")
	void recordTimelineWithin12MonthsDescending() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(13).toString());
		record(token, babyId, HEP_B, "1", TODAY.minusMonths(13), "社区卫生服务中心");
		record(token, babyId, HEP_B, "2", TODAY.minusMonths(1), "妇幼保健院");

		List<JsonNode> timeline = toList(babyOf(owner, babyId).path("recordTimeline"));

		assertThat(timeline).as("13 个月前那一针出了窗口").hasSize(1);
		assertThat(timeline.get(0).path("vaccineName").asText()).isEqualTo(HEP_B);
		assertThat(timeline.get(0).path("givenDate").asText()).isEqualTo(TODAY.minusMonths(1).toString());
		assertThat(timeline.get(0).path("clinic").asText()).isEqualTo("妇幼保健院");
	}

	@Test
	@DisplayName("里程碑时间轴是顶层、跨宝宝的，按日期升序，带宝宝名")
	void milestoneTimelineAscending() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long first = createBaby(token, "小满", "MALE", TODAY.minusMonths(13).toString());
		long second = createBaby(token, "阿圆", "FEMALE", TODAY.minusMonths(5).toString());
		milestone(token, first, TODAY.minusMonths(2), "会走路了");
		milestone(token, second, TODAY.minusMonths(12), "第一次翻身");

		List<JsonNode> timeline = toList(vaccine(owner).path("milestoneTimeline"));

		assertThat(timeline.stream().map(row -> row.path("occurDate").asText()).toList())
			.as("顶层一张表，两个宝宝的排在同一根时间轴上").isSorted();
		assertThat(timeline.get(0).path("babyId").asLong()).isEqualTo(second);
		assertThat(timeline.get(0).path("babyName").asText()).isEqualTo("阿圆");
		assertThat(timeline.get(0).path("title").asText()).isEqualTo("第一次翻身");
		assertThat(timeline.get(1).path("babyName").asText()).isEqualTo("小满");
	}

	// ---- 体格与增长 ----

	@Test
	@DisplayName("最新一档的五个百分位段：年龄别三项按今天月龄、体重别身高按这一行的月龄")
	void growthLatestBandsFiveMetrics() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(12).toString());
		growthRow(token, babyId, TODAY, "76.0", "9.50", "46.0");

		JsonNode latest = onlyBaby(growth(owner), babyId).path("latest");

		assertThat(latest.path("measureDate").asText()).isEqualTo(TODAY.toString());
		assertThat(latest.path("heightCm").asText()).as("实测值一律是字符串（§1.4 第 15 条）").isEqualTo("76.0");
		assertThat(latest.path("weightKg").asText()).isEqualTo("9.50");
		assertThat(latest.path("headCm").asText()).isEqualTo("46.0");
		JsonNode bands = latest.path("bands");
		assertThat(bands.path("height").asText()).isEqualTo("P25–P50");
		assertThat(bands.path("weight").asText()).isEqualTo("P25–P50");
		assertThat(bands.path("weightHeight").asText()).as("12 个月走身长别体重那张表，横轴 76 cm").isEqualTo("P25–P50");
		assertThat(bands.path("bmi").asText()).as("BMI = 9.5 ÷ 0.76² = 16.45").isEqualTo("P25–P50");
		assertThat(bands.path("headCircumference").asText()).isEqualTo("P25–P50");
	}

	@Test
	@DisplayName("体重别身高按这一行的月龄选表：25 个月、105 cm 只有身高别体重那张表装得下")
	void weightHeightPicksTableByMeasurementAge() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(25).toString());
		growthRow(token, babyId, TODAY, "105.0", "16.00", null);

		JsonNode bands = onlyBaby(growth(owner), babyId).path("latest").path("bands");

		assertThat(bands.path("weightHeight").asText())
			.as("身长别体重那张表的横轴止于 100 cm，取到值就说明选的是身高别体重那张").isEqualTo("P25–P50");
	}

	@Test
	@DisplayName("三段增长：较上次是最近两条，近 3 个月与近 12 个月各取窗口内首末两条")
	void growthSinceLastAndWindows() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(13).toString());
		growthRow(token, babyId, TODAY.minusMonths(13), "60.0", "7.00", null);
		growthRow(token, babyId, TODAY.minusMonths(5), "63.0", "8.00", null);
		growthRow(token, babyId, TODAY.minusMonths(2), "66.0", "9.00", null);
		growthRow(token, babyId, TODAY, "72.0", "10.00", null);

		JsonNode windows = onlyBaby(growth(owner), babyId).path("growth");

		assertThat(windows.path("sinceLast").path("heightCm").asText()).as("最近两条之差").isEqualTo("6.0");
		assertThat(windows.path("sinceLast").path("weightKg").asText()).isEqualTo("1.00");
		assertThat(windows.path("last3Months").path("heightCm").asText()).as("窗口内的第一条是 2 个月前那条")
			.isEqualTo("6.0");
		assertThat(windows.path("last12Months").path("heightCm").asText()).as("窗口从 5 个月前那条起算")
			.isEqualTo("9.0");
		assertThat(windows.path("last12Months").path("weightKg").asText()).isEqualTo("2.00");
		assertThat(windows.path("sinceLast").path("days").asInt())
			.isEqualTo((int) java.time.temporal.ChronoUnit.DAYS.between(TODAY.minusMonths(2), TODAY));
		assertThat(windows.path("sinceLast").path("headCm").isNull()).as("四次都没量头围").isTrue();
	}

	@Test
	@DisplayName("只有一条记录时三段增量全空：窗口里凑不齐两条")
	void singleMeasurementLeavesAllDeltasNull() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(13).toString());
		growthRow(token, babyId, TODAY, "72.0", "10.00", null);

		JsonNode baby = onlyBaby(growth(owner), babyId);

		assertThat(baby.path("latest").path("heightCm").asText()).isEqualTo("72.0");
		JsonNode windows = baby.path("growth");
		assertThat(windows.path("sinceLast").isNull()).isTrue();
		assertThat(windows.path("last3Months").isNull()).isTrue();
		assertThat(windows.path("last12Months").isNull()).isTrue();
	}

	@Test
	@DisplayName("两条统计都不回生长曲线：整张标准表不并进统计的离线快照")
	void curveNotIncludedInEither() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(12).toString());
		growthRow(token, babyId, TODAY, "76.0", "9.50", "46.0");

		assertThat(growth(owner).toString()).doesNotContain("standard").doesNotContain("points");
		assertThat(vaccine(owner).toString()).doesNotContain("standard").doesNotContain("points");
	}

	// ---- 筛选、缓存与隔离 ----

	@Test
	@DisplayName("babyId 是筛选条件：不传回两个宝宝，传了只回那一个")
	void babyIdFilterWorks() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long first = createBaby(token, "小满", "MALE", TODAY.minusMonths(13).toString());
		createBaby(token, "阿圆", "FEMALE", TODAY.minusMonths(5).toString());

		assertThat(toList(growth(owner).path("perBaby"))).hasSize(2);
		assertThat(toList(vaccine(owner).path("perBaby"))).hasSize(2);

		List<JsonNode> filtered = toList(growth(owner, first).path("perBaby"));
		assertThat(filtered).hasSize(1);
		assertThat(filtered.get(0).path("babyId").asLong()).isEqualTo(first);
		assertThat(toList(vaccine(owner, first).path("perBaby"))).hasSize(1);
	}

	@Test
	@DisplayName("同条件第二次调用读缓存：绕过服务层直接写库，第二次拿到的还是旧值")
	void cacheHitOnSecondCall() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long familyId = familyId(owner);
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(12).toString());
		assertThat(growth(owner, babyId).path("perBaby").get(0).path("latest").isNull()).isTrue();
		String version = versionOf("baby", familyId);

		// 直接写库：绕过 BabyGrowthService 的失效，缓存因此仍是第一次算出来的那一份
		this.jdbcTemplate.update(
			"INSERT INTO baby_growth (id, family_id, baby_id, measure_date, height_cm, weight_kg, created_by) "
					+ "VALUES (?, ?, ?, ?, ?, ?, ?)",
			8888000000000000001L, familyId, babyId, TODAY, new java.math.BigDecimal("76.0"),
			new java.math.BigDecimal("9.50"), owner.userId());

		assertThat(growth(owner, babyId).path("perBaby").get(0).path("latest").isNull())
			.as("第二次没重算，所以看不到刚插进去的那一行").isTrue();
		assertThat(versionOf("baby", familyId)).as("两条读端点都不该递增版本号").isEqualTo(version);

		growthRow(token, babyId, TODAY.minusDays(1), "75.0", "9.40", null);

		assertThat(versionOf("baby", familyId)).as("走服务层写一次就该打脏这一版").isNotEqualTo(version);
		assertThat(growth(owner, babyId).path("perBaby").get(0).path("latest").path("heightCm").asText())
			.as("重算之后两条记录都在，最新那条按测量日期取").isEqualTo("76.0");
	}

	@Test
	@DisplayName("他家的宝宝一条都不出现在本家庭的统计里，拿别人的 babyId 也筛不出东西")
	void crossFamilyStatisticsExcluded() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long foreignBaby = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(12).toString());
		growthRow(owner.accessToken(), foreignBaby, TODAY, "76.0", "9.50", "46.0");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");

		assertThat(toList(growth(outsider).path("perBaby"))).isEmpty();
		assertThat(toList(vaccine(outsider).path("perBaby"))).isEmpty();
		assertThat(toList(vaccine(outsider).path("milestoneTimeline"))).isEmpty();
		assertThat(toList(growth(outsider, foreignBaby).path("perBaby"))).as("筛选条件命中不了别家的 id").isEmpty();
	}

	@Test
	@DisplayName("归档的宝宝留住体格统计，但不再进待办类统计")
	void archivedBabyKeepsGrowthButLosesTodoLists() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(12).toString());
		growthRow(token, babyId, TODAY, "76.0", "9.50", "46.0");
		assertThat(patchJson(BABIES + "/" + babyId + "/archive", null, token).code()).isEqualTo("OK");

		assertThat(onlyBaby(growth(owner), babyId).path("latest").path("heightCm").asText())
			.as("抹掉归档宝宝的历史等于抹数据").isEqualTo("76.0");
		assertThat(toList(vaccine(owner).path("perBaby"))).as("待办类统计不该给归档宝宝留一个永远做不完的格子")
			.isEmpty();
	}

	@Test
	@DisplayName("无家庭的账号碰两条统计端点都是 NO_FAMILY")
	void statisticsRequireAFamily() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		assertThat(getJson(BABY_STATS_GROWTH, lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
		assertThat(getJson(BABY_STATS_VACCINE, lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
	}

	// ---- 辅助 ----

	private JsonNode growth(Account account) throws Exception {
		Call call = getJson(BABY_STATS_GROWTH, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private JsonNode growth(Account account, long babyId) throws Exception {
		Call call = getJson(BABY_STATS_GROWTH, Map.of("babyId", String.valueOf(babyId)), account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private JsonNode vaccine(Account account) throws Exception {
		Call call = getJson(BABY_STATS_VACCINE, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private JsonNode vaccine(Account account, long babyId) throws Exception {
		Call call = getJson(BABY_STATS_VACCINE, Map.of("babyId", String.valueOf(babyId)), account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private JsonNode babyOf(Account account, long babyId) throws Exception {
		return onlyBaby(vaccine(account), babyId);
	}

	private JsonNode onlyBaby(JsonNode data, long babyId) {
		List<JsonNode> hits = toList(data.path("perBaby")).stream()
			.filter(node -> node.path("babyId").asLong() == babyId)
			.toList();
		assertThat(hits).as("perBaby 里应当恰好有一条 babyId=" + babyId).hasSize(1);
		return hits.get(0);
	}

	private int sumOf(JsonNode counts) {
		return counts.path("vaccinated").asInt() + counts.path("upcoming").asInt()
				+ counts.path("dueSoon").asInt() + counts.path("overdue").asInt();
	}

	private List<String> namesOf(List<JsonNode> rows) {
		return rows.stream().map(row -> row.path("vaccineName").asText()).toList();
	}

	private int planCount(String token, long babyId) throws Exception {
		Call call = getJson(BABY_VACCINE_PLANS, Map.of("babyId", String.valueOf(babyId)), token);
		assertThat(call.code()).isEqualTo("OK");
		return toList(call.data()).size();
	}

	/** 走端点而不是直连 SQL：直连会绕过租户拦截器，而这里要验的恰恰是清单是这条端点给出来的。 */
	private JsonNode growthRow(String token, long babyId, LocalDate measureDate, String heightCm, String weightKg,
			String headCm) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("measureDate", measureDate.toString());
		putIfPresent(body, "heightCm", heightCm);
		putIfPresent(body, "weightKg", weightKg);
		putIfPresent(body, "headCm", headCm);
		Call call = postJson(BABY_GROWTHS, body, token);
		assertThat(call.code()).as("身高体重记录建不出来，后面的断言都没有意义").isEqualTo("OK");
		return call.data();
	}

	private void vaccinated(String token, long babyId, String vaccineName, String doseNo) throws Exception {
		record(token, babyId, vaccineName, doseNo, TODAY, null);
	}

	private void record(String token, long babyId, String vaccineName, String doseNo, LocalDate givenDate,
			String clinic) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("vaccineName", vaccineName);
		body.put("doseNo", doseNo);
		body.put("givenDate", givenDate.toString());
		putIfPresent(body, "clinic", clinic);
		assertThat(postJson(BABY_VACCINE_RECORDS, body, token).code()).as("接种记录建不出来，后面的断言都没有意义")
			.isEqualTo("OK");
	}

	private void manual(String token, long babyId, String vaccineName, String doseNo, LocalDate dueDate)
			throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("vaccineName", vaccineName);
		body.put("doseNo", doseNo);
		body.put("dueDate", dueDate.toString());
		assertThat(postJson(BABY_VACCINE_PLANS, body, token).code()).isEqualTo("OK");
	}

	private void milestone(String token, long babyId, LocalDate occurDate, String title) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("occurDate", occurDate.toString());
		body.put("title", title);
		assertThat(postJson(BABY_MILESTONES, body, token).code()).isEqualTo("OK");
	}

	private Call skip(String token, long planId) throws Exception {
		return patchJson(BABY_VACCINE_PLANS + "/" + planId, Map.of("status", "SKIPPED", "reason", "医嘱暂缓"), token);
	}

	private Call patchPlan(String token, long planId, String status) throws Exception {
		return patchJson(BABY_VACCINE_PLANS + "/" + planId, Map.of("status", status), token);
	}

	private static void putIfPresent(Map<String, Object> body, String key, Object value) {
		if (value != null) {
			body.put(key, value);
		}
	}

	/** 与 {@code StatisticsCache} 同一口径：从没写过数据的家庭没有版本号键，读成 "0"。 */
	private String versionOf(String module, long familyId) {
		String raw = this.redis.opsForValue().get("stats:ver:" + module + ":" + familyId);
		return raw == null ? "0" : raw;
	}

	private long familyId(Account account) throws Exception {
		return currentFamily(account.accessToken()).data().path("id").asLong();
	}

	private List<JsonNode> toList(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

}
