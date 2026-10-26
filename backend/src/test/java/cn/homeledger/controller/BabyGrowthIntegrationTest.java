package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.config.TimeConfig;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.4.2 身高体重记录：列表排序、读时派生的「较上一次」、三项校验与整份覆盖。
 * <p>
 * 「上一次」的每一档都从端点读、不直连 SQL：待验的就是端点算出来的那份增量，
 * 用 SQL 自己算一遍等于把要验的口径复写第二遍。只有验证「UPDATE 真的写成了 NULL」时反过来——
 * 那一条的响应是内存里那份实体拼的，不回读一次就不知道库里是什么。
 */
class BabyGrowthIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	@Test
	@DisplayName("列表按测量日期降序、同日按 id 降序全量返回")
	void listOrderedByDateThenIdDesc() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		long first = createGrowth(owner.accessToken(), babyId, "2026-01-01", "55.0", "4.50");
		long second = createGrowth(owner.accessToken(), babyId, "2026-05-01", "62.4", "6.25");
		long third = createGrowth(owner.accessToken(), babyId, "2026-05-01", "62.6", "6.30");

		JsonNode rows = listOf(owner.accessToken(), babyId);

		assertThat(rows).as("全量返回、不分页").hasSize(3);
		assertThat(idsOf(rows)).containsExactly(third, second, first);
		assertThat(datesOf(rows)).containsExactly("2026-05-01", "2026-05-01", "2026-01-01");
	}

	@Test
	@DisplayName("较上一次的增量与间隔天数按自然日算")
	void deltaAgainstPreviousDay() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		createGrowth(owner.accessToken(), babyId, "2026-01-01", "60.0", "6.00");
		createGrowth(owner.accessToken(), babyId, "2026-02-01", "62.4", "6.25");

		JsonNode rows = listOf(owner.accessToken(), babyId);
		JsonNode delta = rows.get(0).path("deltaFromPrevious");

		assertThat(delta.path("days").asLong()).as("2026-01-01 到 2026-02-01 共 31 天").isEqualTo(31);
		assertThat(delta.path("heightCm").asText()).isEqualTo("2.4");
		assertThat(delta.path("weightKg").asText()).isEqualTo("0.25");
		assertThat(delta.path("headCm").isNull()).as("两次都没量头围").isTrue();
		assertThat(rows.get(1).path("deltaFromPrevious").isNull()).as("首条没有上一次").isTrue();
	}

	@Test
	@DisplayName("同一天的多条记录共享同一个「上一次」，不互相当基准")
	void sameDayRowsShareSamePrevious() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		createGrowth(owner.accessToken(), babyId, "2026-01-01", "60.0", null);
		createGrowth(owner.accessToken(), babyId, "2026-02-01", "61.0", null);
		createGrowth(owner.accessToken(), babyId, "2026-02-01", "62.0", null);

		JsonNode rows = listOf(owner.accessToken(), babyId);

		assertThat(rows.get(0).path("deltaFromPrevious").path("days").asLong()).as("后一条也是拿 01-01 当上一次，不是同一天的前一条")
			.isEqualTo(31);
		assertThat(rows.get(1).path("deltaFromPrevious").path("days").asLong()).isEqualTo(31);
		assertThat(rows.get(0).path("deltaFromPrevious").path("heightCm").asText()).as("同日代表行是 id 最大的那条：62.0 − 60.0")
			.isEqualTo("2.0");
		assertThat(rows.get(1).path("deltaFromPrevious").path("heightCm").asText()).isEqualTo("1.0");
	}

	@Test
	@DisplayName("首条记录没有「上一次」")
	void firstRowHasNullDelta() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		createGrowth(owner.accessToken(), babyId, "2026-01-01", "60.0", "6.00");

		JsonNode rows = listOf(owner.accessToken(), babyId);

		assertThat(rows).hasSize(1);
		assertThat(rows.get(0).path("deltaFromPrevious").isNull()).isTrue();
	}

	@Test
	@DisplayName("列表每行带五个指标的百分之多少：量了的非空、没量的为空（问题单：直接写 25%）")
	void rowsCarryPercentiles() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		createGrowth(owner.accessToken(), babyId, "2026-01-01", "57.0", "6.00");
		createGrowth(owner.accessToken(), babyId, "2026-05-01", "62.4", "6.25");

		JsonNode rows = listOf(owner.accessToken(), babyId);
		JsonNode percentiles = rows.get(0).path("percentiles");

		assertThat(percentiles.isObject()).as("列表行带具体百分位，口径同统计页「当前体格」").isTrue();
		assertThat(percentiles.path("height").asText()).as("量了的身高给具体百分位（一位小数）").matches("\\d+(\\.\\d+)?%|>[0-9]+(\\.\\d+)?%|<[0-9]+(\\.\\d+)?%");
		assertThat(percentiles.path("weight").asText()).matches("\\d+(\\.\\d+)?%|>[0-9]+(\\.\\d+)?%|<[0-9]+(\\.\\d+)?%");
		assertThat(percentiles.path("headCircumference").isNull()).as("没量头围，那一格为空").isTrue();
		assertThat(rows.get(1).path("percentiles").path("height").asText()).matches("\\d+(\\.\\d+)?%|>[0-9]+(\\.\\d+)?%|<[0-9]+(\\.\\d+)?%");
	}

	@Test
	@DisplayName("上一次没量那一项时该档增量为空，不是 0")
	void deltaNullWhenPreviousMissingThatMeasure() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		createGrowth(owner.accessToken(), babyId, "2026-01-01", "60.0", null);
		createGrowth(owner.accessToken(), babyId, "2026-02-01", "62.0", "6.50");

		JsonNode delta = listOf(owner.accessToken(), babyId).get(0).path("deltaFromPrevious");

		assertThat(delta.path("heightCm").asText()).as("两行都有身高").isEqualTo("2.0");
		assertThat(delta.path("weightKg").isNull()).as("上一次没称体重").isTrue();
		assertThat(delta.path("days").asLong()).isEqualTo(31);
	}

	@Test
	@DisplayName("身高与体重两项全空被拒；只称体重放行，只给头围不算数")
	void atLeastOneOfHeightWeight() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");

		Call empty = postGrowth(owner.accessToken(), babyId, "2026-01-01", null, null, null);
		assertThat(empty.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(empty.code()).as("§3.4：跨字段走 Service，不新增错误码").isEqualTo("BAD_REQUEST");
		assertThat(empty.message()).contains("至少填一项");

		assertThat(postGrowth(owner.accessToken(), babyId, "2026-01-01", null, null, "42.5").code())
			.as("头围单独存在不算数：至少一项说的是身高与体重")
			.isEqualTo("BAD_REQUEST");
		assertThat(postGrowth(owner.accessToken(), babyId, "2026-01-01", null, "6.20", null).code())
			.as("只称体重是常事")
			.isEqualTo("OK");
	}

	@Test
	@DisplayName("身高/体重/头围越界走 VALIDATION_FAILED，边界值含在内")
	void heightRangeEnforced() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		String token = owner.accessToken();

		assertThat(postGrowth(token, babyId, "2026-01-01", "19.9", null, null).code()).isEqualTo("VALIDATION_FAILED");
		assertThat(postGrowth(token, babyId, "2026-01-01", "200.0", null, null).code()).as("上边界含在内").isEqualTo("OK");
		assertThat(postGrowth(token, babyId, "2026-01-01", "200.1", null, null).code()).isEqualTo("VALIDATION_FAILED");
		assertThat(postGrowth(token, babyId, "2026-01-01", null, "0.99", null).code()).isEqualTo("VALIDATION_FAILED");
		assertThat(postGrowth(token, babyId, "2026-01-01", null, "100.00", null).code()).isEqualTo("OK");
		assertThat(postGrowth(token, babyId, "2026-01-01", null, "100.01", null).code()).isEqualTo("VALIDATION_FAILED");
		assertThat(postGrowth(token, babyId, "2026-01-01", null, null, "29.9").code()).isEqualTo("VALIDATION_FAILED");
		assertThat(postGrowth(token, babyId, "2026-01-01", null, "6.20", "60.0").code()).isEqualTo("OK");
		assertThat(postGrowth(token, babyId, "2026-01-01", null, "6.20", "60.1").code()).isEqualTo("VALIDATION_FAILED");
	}

	@Test
	@DisplayName("测量日期晚于今天被拒，当天放行")
	void measureDateInFutureRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		String today = LocalDate.now(TimeConfig.ZONE).toString();

		Call future = postGrowth(owner.accessToken(), babyId, LocalDate.now(TimeConfig.ZONE).plusDays(1).toString(),
				"60.0", null, null);

		assertThat(future.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(future.code()).isEqualTo("BAD_REQUEST");
		assertThat(future.message()).contains("不能晚于今天");
		assertThat(postGrowth(owner.accessToken(), babyId, today, "60.0", null, null).code()).as("当天是合法的测量日")
			.isEqualTo("OK");
	}

	@Test
	@DisplayName("PATCH 是整份覆盖：不传头围与备注就真的写空")
	void patchCanClearHeadAndRemark() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		Map<String, Object> create = growthBody(babyId, "2026-01-01", "60.0", "6.00", "42.5", "偏瘦");
		Call created = postJson(BABY_GROWTHS, create, owner.accessToken());
		assertThat(created.code()).isEqualTo("OK");
		long id = created.data().path("id").asLong();

		Call patched = patchJson(BABY_GROWTHS + "/" + id, growthBody(babyId, "2026-01-01", "60.0", "6.00", null, null),
				owner.accessToken());

		assertThat(patched.code()).isEqualTo("OK");
		assertThat(patched.data().path("headCm").isNull()).isTrue();
		assertThat(patched.data().path("remark").isNull()).isTrue();
		// 回读才作数：响应是内存里那份实体拼的，updateById 跳过 null 时它照样显示空
		assertThat(this.jdbcTemplate.queryForObject("SELECT head_cm FROM baby_growth WHERE id = ?", BigDecimal.class, id))
			.as("头围那一列要真的写成 NULL")
			.isNull();
		assertThat(this.jdbcTemplate.queryForObject("SELECT remark FROM baby_growth WHERE id = ?", String.class, id)).isNull();
		assertThat(this.jdbcTemplate.queryForObject("SELECT height_cm FROM baby_growth WHERE id = ?", BigDecimal.class, id))
			.as("同一次提交里的身高照旧写上")
			.isEqualByComparingTo("60.0");
		assertThat(listOf(owner.accessToken(), babyId).get(0).path("headCm").isNull()).isTrue();
	}

	@Test
	@DisplayName("B 家庭读不到 A 家庭的记录，写、改、删也进不去")
	void crossFamilyGrowthIsInvisible() throws Exception {
		Account ownerA = registerWithFamily(PHONE_A, "张三");
		long babyA = createBaby(ownerA.accessToken(), "小满", "MALE", "2026-01-01");
		long growthA = createGrowth(ownerA.accessToken(), babyA, "2026-01-01", "60.0", "6.00");

		Account ownerB = registerWithFamily(PHONE_B, "李四");
		String tokenB = ownerB.accessToken();

		assertThat(listOf(tokenB, babyA)).as("按别人的 babyId 过滤也是空").isEmpty();
		assertThat(getJson(BABY_GROWTHS, tokenB).data()).isEmpty();
		assertThat(postGrowth(tokenB, babyA, "2026-02-01", "61.0", null, null).code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(patchJson(BABY_GROWTHS + "/" + growthA, growthBody(babyA, "2026-02-01", "61.0", null, null, null), tokenB)
			.code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(deleteNoBody(BABY_GROWTHS + "/" + growthA, tokenB).code()).isEqualTo("RESOURCE_NOT_FOUND");
	}

	@Test
	@DisplayName("babyId 过滤只看自己那份，增量不跨宝宝成链")
	void babyIdFilterWorks() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long firstBaby = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		long secondBaby = createBaby(owner.accessToken(), "阿圆", "FEMALE", "2026-01-01");
		createGrowth(owner.accessToken(), firstBaby, "2026-01-01", "60.0", "6.00");
		createGrowth(owner.accessToken(), firstBaby, "2026-02-01", "62.0", "6.50");
		createGrowth(owner.accessToken(), secondBaby, "2026-03-01", "58.0", "5.50");

		JsonNode firstRows = listOf(owner.accessToken(), firstBaby);
		JsonNode secondRows = listOf(owner.accessToken(), secondBaby);
		JsonNode all = getJson(BABY_GROWTHS, owner.accessToken()).data();

		assertThat(firstRows).hasSize(2);
		assertThat(secondRows).hasSize(1);
		assertThat(all).as("不传 babyId 即全家庭").hasSize(3);
		assertThat(secondRows.get(0).path("deltaFromPrevious").isNull())
			.as("另一个宝宝的第一条不该拿别人的记录当上一次")
			.isTrue();
	}

	@Test
	@DisplayName("新建与修改后回的那一行自己也带增量")
	void respondedRowCarriesDelta() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");

		Call first = postGrowth(owner.accessToken(), babyId, "2026-01-01", "60.0", null, null);
		Call second = postGrowth(owner.accessToken(), babyId, "2026-03-01", "63.5", null, null);

		assertThat(first.data().path("deltaFromPrevious").isNull()).isTrue();
		assertThat(second.data().path("deltaFromPrevious").path("days").asLong()).as("2026 不是闰年，01-01 到 03-01 共 59 天")
			.isEqualTo(59);
		assertThat(second.data().path("deltaFromPrevious").path("heightCm").asText()).isEqualTo("3.5");
	}

	@Test
	@DisplayName("删除是软删：列表里消失、库里留行")
	void deleteRemovesRow() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		long id = createGrowth(owner.accessToken(), babyId, "2026-01-01", "60.0", "6.00");

		assertThat(deleteNoBody(BABY_GROWTHS + "/" + id, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(listOf(owner.accessToken(), babyId)).isEmpty();
		assertThat(this.jdbcTemplate.queryForObject("SELECT COUNT(*) FROM baby_growth WHERE id = ?", Integer.class, id))
			.as("物理行要留着：宝宝档案的删除守卫数的正是这些行")
			.isEqualTo(1);
		assertThat(this.jdbcTemplate.queryForObject("SELECT deleted FROM baby_growth WHERE id = ?", Integer.class, id))
			.isEqualTo(1);
	}

	private Call postGrowth(String token, long babyId, String measureDate, String heightCm, String weightKg,
			String headCm) throws Exception {
		return postJson(BABY_GROWTHS, growthBody(babyId, measureDate, heightCm, weightKg, headCm, null), token);
	}

	/** null 的项不进 body：请求体是整份覆盖语义，显式写 null 与不写在这一层是同一件事，但让 body 短一点更好读。 */
	private static Map<String, Object> growthBody(long babyId, String measureDate, String heightCm, String weightKg,
			String headCm, String remark) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("measureDate", measureDate);
		body.put("heightCm", heightCm);
		body.put("weightKg", weightKg);
		body.put("headCm", headCm);
		body.put("remark", remark);
		body.values().removeIf(Objects::isNull);
		return body;
	}

	private JsonNode listOf(String token, long babyId) throws Exception {
		Call call = getJson(BABY_GROWTHS, Map.of("babyId", String.valueOf(babyId)), token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private static List<Long> idsOf(JsonNode rows) {
		List<Long> ids = new ArrayList<>();
		rows.forEach(row -> ids.add(row.path("id").asLong()));
		return ids;
	}

	private static List<String> datesOf(JsonNode rows) {
		List<String> dates = new ArrayList<>();
		rows.forEach(row -> dates.add(row.path("measureDate").asText()));
		return dates;
	}

}
