package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.config.TimeConfig;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.4.5 里程碑与就诊记录：两套形状相同的 CRUD，外加两条「这一条不需要代码」的旁证。
 * <p>
 * 两处排序方向刻意相反（里程碑升序是成长轴、就诊降序是回看），各有一条测试盯着——它们都只是在
 * {@code LambdaQueryWrapper} 里换一个方法名，写错不会有任何报错，只会让列表看起来"就是那个顺序"。
 * <p>
 * {@code medicalPatchCanClearEveryOptionalField} 读库而不读接口回显：整份表单覆盖的失败模式是
 * UPDATE 里漏了一列，而接口回的正是刚读出来的那个对象，漏了也看不出来。
 */
class BabyRecordIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("里程碑列表按发生日期升序：成长轴从左到右")
	void milestoneCreateAndList() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());
		createMilestone(token, babyId, TODAY.minusMonths(6).toString(), "会坐", "独自坐稳");
		createMilestone(token, babyId, TODAY.minusMonths(9).toString(), "抬头", null);

		JsonNode rows = milestoneRows(token, babyId);

		assertThat(rows).hasSize(2);
		assertThat(rows.get(0).path("title").asText()).isEqualTo("抬头");
		assertThat(rows.get(1).path("title").asText()).isEqualTo("会坐");
		assertThat(rows.get(0).path("occurDate").asText()).isEqualTo(TODAY.minusMonths(9).toString());
		assertThat(rows.get(0).path("description").isNull()).as("选填项不传就是空").isTrue();
	}

	@Test
	@DisplayName("改里程碑：整份覆盖，描述能真的清空")
	void milestonePatch() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());
		long milestoneId = createMilestone(token, babyId, TODAY.minusMonths(6).toString(), "会坐", "独自坐稳");

		Call call = patchJson(BABY_MILESTONES + "/" + milestoneId,
				milestoneBody(TODAY.minusMonths(5).toString(), "会爬", null), token);

		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("occurDate").asText()).isEqualTo(TODAY.minusMonths(5).toString());
		assertThat(call.data().path("title").asText()).isEqualTo("会爬");
		assertThat(call.data().path("description").isNull()).isTrue();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT description FROM baby_milestone WHERE id = ?", String.class, milestoneId))
			.as("清不掉的症状是「删了描述但列表里还挂着一句」")
			.isNull();
	}

	@Test
	@DisplayName("删里程碑：软删除，列表里立刻不见")
	void milestoneDelete() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());
		long milestoneId = createMilestone(token, babyId, TODAY.minusMonths(6).toString(), "会坐", null);

		assertThat(deleteNoBody(BABY_MILESTONES + "/" + milestoneId, token).code()).isEqualTo("OK");

		assertThat(milestoneRows(token, babyId)).isEmpty();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT deleted FROM baby_milestone WHERE id = ?", Integer.class, milestoneId)).isEqualTo(1);
	}

	@Test
	@DisplayName("里程碑标题允许自由输入：内置常用项与自造的字在库里没有区别")
	void milestoneTitleCustomTextAllowed() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());

		long milestoneId = createMilestone(token, babyId, TODAY.minusDays(3).toString(), "第一次自己拿勺子", null);

		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT title FROM baby_milestone WHERE id = ?", String.class, milestoneId))
			.isEqualTo("第一次自己拿勺子");
	}

	@Test
	@DisplayName("里程碑：未来的日期被拒，别的家庭看不见也改不动")
	void milestoneGuards() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(10).toString());
		long milestoneId = createMilestone(owner.accessToken(), babyId, TODAY.minusMonths(6).toString(), "会坐", null);

		Call future = postJson(BABY_MILESTONES,
				milestoneBody(babyId, TODAY.plusDays(1).toString(), "会走", null), owner.accessToken());
		assertThat(future.code()).isEqualTo("BAD_REQUEST");
		assertThat(future.message()).contains("不能晚于今天");

		Account ownerB = registerWithFamily(PHONE_B, "李四");
		String tokenB = ownerB.accessToken();
		createBaby(tokenB, "阿圆", "FEMALE", TODAY.minusMonths(4).toString());

		assertThat(getJson(BABY_MILESTONES, Map.of("babyId", String.valueOf(babyId)), tokenB).data()).isEmpty();
		assertThat(patchJson(BABY_MILESTONES + "/" + milestoneId,
				milestoneBody(TODAY.toString(), "偷改", null), tokenB).status())
			.isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(deleteNoBody(BABY_MILESTONES + "/" + milestoneId, tokenB).code())
			.isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(milestoneRows(owner.accessToken(), babyId)).as("原记录一行未动").hasSize(1);
	}

	@Test
	@DisplayName("就诊记录列表按就诊日期降序：就诊是回看")
	void medicalCreateAndList() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());
		createMedical(token, babyId, medicalBody(TODAY.minusDays(30).toString(), "市妇幼", "儿科", "感冒", "小儿氨酚黄那敏", "38.50", "三天后复诊"));
		createMedical(token, babyId, medicalBody(TODAY.minusDays(2).toString(), "社区医院", null, null, null, null, null));

		JsonNode rows = medicalRows(token, babyId);

		assertThat(rows).hasSize(2);
		assertThat(rows.get(0).path("visitDate").asText()).isEqualTo(TODAY.minusDays(2).toString());
		assertThat(rows.get(1).path("hospital").asText()).isEqualTo("市妇幼");
		assertThat(rows.get(1).path("costAmount").asText()).as("金额按字符串下发，不带精度尾巴").isEqualTo("38.50");
	}

	@Test
	@DisplayName("改就诊记录：除就诊日期外每一列都能清空（含费用）")
	void medicalPatchCanClearEveryOptionalField() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());
		long medicalId = createMedical(token, babyId,
				medicalBody(TODAY.minusDays(30).toString(), "市妇幼", "儿科", "感冒", "小儿氨酚黄那敏", "38.50", "三天后复诊"));

		Call call = patchJson(BABY_MEDICALS + "/" + medicalId,
				medicalBody(TODAY.minusDays(28).toString(), null, null, null, null, null, null), token);

		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("visitDate").asText()).isEqualTo(TODAY.minusDays(28).toString());
		assertThat(this.jdbcTemplate.queryForMap(
				"SELECT hospital, department, diagnosis, medicine, cost_amount, remark FROM baby_medical WHERE id = ?",
				medicalId))
			.as("整份表单覆盖：漏了哪一列，哪一列就留在库里")
			.containsEntry("hospital", null)
			.containsEntry("department", null)
			.containsEntry("diagnosis", null)
			.containsEntry("medicine", null)
			.containsEntry("cost_amount", null)
			.containsEntry("remark", null);
	}

	@Test
	@DisplayName("就诊记录：未来的日期被拒，别的家庭看不见也改不动")
	void medicalGuards() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(10).toString());
		long medicalId = createMedical(owner.accessToken(), babyId,
				medicalBody(TODAY.minusDays(2).toString(), "社区医院", null, null, null, null, null));

		Call future = postJson(BABY_MEDICALS,
				medicalBody(babyId, TODAY.plusDays(1).toString(), "社区医院", null, null, null, null, null),
				owner.accessToken());
		assertThat(future.code()).isEqualTo("BAD_REQUEST");
		assertThat(future.message()).contains("不能晚于今天");

		Account ownerB = registerWithFamily(PHONE_B, "李四");
		String tokenB = ownerB.accessToken();
		createBaby(tokenB, "阿圆", "FEMALE", TODAY.minusMonths(4).toString());

		assertThat(getJson(BABY_MEDICALS, Map.of("babyId", String.valueOf(babyId)), tokenB).data()).isEmpty();
		assertThat(deleteNoBody(BABY_MEDICALS + "/" + medicalId, tokenB).code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(medicalRows(owner.accessToken(), babyId)).hasSize(1);
	}

	@Test
	@DisplayName("删就诊记录后列表里不见，别的家庭的账本也不受影响")
	void medicalDelete() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());
		long medicalId = createMedical(token, babyId,
				medicalBody(TODAY.minusDays(2).toString(), "社区医院", null, null, null, "12.00", null));

		assertThat(deleteNoBody(BABY_MEDICALS + "/" + medicalId, token).code()).isEqualTo("OK");

		assertThat(medicalRows(token, babyId)).isEmpty();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT deleted FROM baby_medical WHERE id = ?", Integer.class, medicalId)).isEqualTo(1);
	}

	@Test
	@DisplayName("就诊费用只是记录：不替它生成任何流水")
	void medicalCostIsNotRecordedAsTransaction() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());
		createMedical(token, babyId,
				medicalBody(TODAY.minusDays(2).toString(), "市妇幼", "儿科", "感冒", null, "238.00", null));

		assertThat(this.jdbcTemplate.queryForObject("SELECT COUNT(*) FROM `transaction` WHERE family_id = ?",
				Integer.class, familyIdOf(babyId)))
			.as("§4.4.5：就诊与记账是两件事，种下同步会让删掉就诊记录时那条流水留在账上")
			.isZero();
	}

	@Test
	@DisplayName("金额为负被拒，两套记录都拦得住不属于本家庭或不存在的东西")
	void medicalCostNegativeRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.minusMonths(10).toString());

		Call negative = postJson(BABY_MEDICALS,
				medicalBody(babyId, TODAY.toString(), "社区医院", null, null, null, "-0.01", null), token);
		assertThat(negative.code()).isEqualTo("VALIDATION_FAILED");
		assertThat(negative.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
	}

	@Test
	@DisplayName("两类记录都记不到别的家庭的宝宝头上")
	void babyOfAnotherFamilyRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(10).toString());

		Account ownerB = registerWithFamily(PHONE_B, "李四");
		String tokenB = ownerB.accessToken();
		createBaby(tokenB, "阿圆", "FEMALE", TODAY.minusMonths(4).toString());

		assertThat(postJson(BABY_MILESTONES, milestoneBody(babyId, TODAY.toString(), "抬头", null), tokenB).code())
			.isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(postJson(BABY_MEDICALS,
				medicalBody(babyId, TODAY.toString(), "社区医院", null, null, null, null, null), tokenB).code())
			.isEqualTo("RESOURCE_NOT_FOUND");
	}

	// ---- 辅助 ----

	private long createMilestone(String token, long babyId, String occurDate, String title, String description)
			throws Exception {
		Call call = postJson(BABY_MILESTONES, milestoneBody(babyId, occurDate, title, description), token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private long createMedical(String token, long babyId, Map<String, Object> body) throws Exception {
		body.put("babyId", babyId);
		Call call = postJson(BABY_MEDICALS, body, token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private JsonNode milestoneRows(String token, long babyId) throws Exception {
		Call call = getJson(BABY_MILESTONES, Map.of("babyId", String.valueOf(babyId)), token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private JsonNode medicalRows(String token, long babyId) throws Exception {
		Call call = getJson(BABY_MEDICALS, Map.of("babyId", String.valueOf(babyId)), token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private long familyIdOf(long babyId) {
		return this.jdbcTemplate.queryForObject("SELECT family_id FROM baby WHERE id = ?", Long.class, babyId);
	}

	private static Map<String, Object> milestoneBody(long babyId, String occurDate, String title, String description) {
		Map<String, Object> body = milestoneBody(occurDate, title, description);
		body.put("babyId", babyId);
		return body;
	}

	private static Map<String, Object> milestoneBody(String occurDate, String title, String description) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("occurDate", occurDate);
		body.put("title", title);
		putIfPresent(body, "description", description);
		return body;
	}

	private static Map<String, Object> medicalBody(String visitDate, String hospital, String department,
			String diagnosis, String medicine, String costAmount, String remark) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("visitDate", visitDate);
		putIfPresent(body, "hospital", hospital);
		putIfPresent(body, "department", department);
		putIfPresent(body, "diagnosis", diagnosis);
		putIfPresent(body, "medicine", medicine);
		putIfPresent(body, "costAmount", costAmount);
		putIfPresent(body, "remark", remark);
		return body;
	}

	private static Map<String, Object> medicalBody(long babyId, String visitDate, String hospital, String department,
			String diagnosis, String medicine, String costAmount, String remark) {
		Map<String, Object> body = medicalBody(visitDate, hospital, department, diagnosis, medicine, costAmount, remark);
		body.put("babyId", babyId);
		return body;
	}

	private static void putIfPresent(Map<String, Object> body, String key, Object value) {
		if (value != null) {
			body.put(key, value);
		}
	}

}
