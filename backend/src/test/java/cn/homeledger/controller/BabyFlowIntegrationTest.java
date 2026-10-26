package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;

import cn.homeledger.common.BabyAge;
import cn.homeledger.config.TimeConfig;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.4.1 宝宝档案与 §4.4.4 应种清单的生成与整份重算。
 * <p>
 * 清单的落库结果一律直连 SQL 读：本类要验的是「生成器与重算写下的行对不对」，
 * 用清单端点来读等于把要验的那件事当成前提。读出侧的列装配另有测试类盯着。
 */
class BabyFlowIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	@Test
	@DisplayName("建档即按内置程序表整份生成清单：24 条剂次、全部待接种、全部非手动")
	void createGeneratesWholePlan() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "奶糖", "MALE", "2026-01-01");

		assertThat(planRows(babyId)).as("11 个疫苗种类、24 条剂次行，逐条转录自 2026 年版程序表").hasSize(24);
		assertThat(countByStatus(babyId, "PENDING")).as("新建的行没有用户输入，一律待接种").isEqualTo(24);
		assertThat(countByManual(babyId, 0)).as("manual = 0 才是字典生成的行，它决定 DELETE 放不放行").isEqualTo(24);
	}

	@Test
	@DisplayName("应种日期逐条对表：乙肝三剂、卡介苗、百白破第 5 剂、2vHPV 两剂都落在官方月龄上")
	void planDueDatesMatchOfficialProgram() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");

		assertThat(dueDateOf(babyId, "乙肝疫苗", "1")).as("0 月龄").isEqualTo("2026-01-01");
		assertThat(dueDateOf(babyId, "乙肝疫苗", "2")).as("1 月龄").isEqualTo("2026-02-01");
		assertThat(dueDateOf(babyId, "乙肝疫苗", "3")).as("6 月龄").isEqualTo("2026-07-01");
		assertThat(dueDateOf(babyId, "卡介苗", "1")).as("0 月龄").isEqualTo("2026-01-01");
		assertThat(dueDateOf(babyId, "麻腮风疫苗", "1")).as("8 月龄").isEqualTo("2026-09-01");
		assertThat(dueDateOf(babyId, "百白破疫苗", "5")).as("72 月龄，覆盖到 6 岁").isEqualTo("2032-01-01");
		assertThat(dueDateOf(babyId, "双价人乳头瘤病毒疫苗", "1")).as("156 月龄 = 13 岁").isEqualTo("2039-01-01");
		assertThat(dueDateOf(babyId, "双价人乳头瘤病毒疫苗", "2")).as("162 月龄：第 1 剂应种日 + 6 个月")
			.isEqualTo("2039-07-01");
	}

	@Test
	@DisplayName("每类疫苗的剂次数与官方表一致：3/1/2/2/5/2/2/2/2/1/2")
	void planCountGroupedByVaccineMatches() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");

		Map<String, Integer> counts = new LinkedHashMap<>();
		for (Map<String, Object> row : planRows(babyId)) {
			counts.merge((String) row.get("vaccine_name"), 1, Integer::sum);
		}

		assertThat(counts).isEqualTo(Map.ofEntries(
				Map.entry("乙肝疫苗", 3),
				Map.entry("卡介苗", 1),
				Map.entry("脊灰灭活疫苗", 2),
				Map.entry("脊灰减毒活疫苗", 2),
				Map.entry("百白破疫苗", 5),
				Map.entry("麻腮风疫苗", 2),
				Map.entry("乙脑减毒活疫苗", 2),
				Map.entry("A 群流脑多糖疫苗", 2),
				Map.entry("A 群 C 群流脑多糖疫苗", 2),
				Map.entry("甲肝减毒活疫苗", 1),
				Map.entry("双价人乳头瘤病毒疫苗", 2)));
	}

	@Test
	@DisplayName("在册满 5 个即拒第 6 个、归档一个后放行：名额数的是在册的")
	void archivedBabyFreesTheCap() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long first = 0;
		for (int i = 1; i <= 5; i++) {
			first = createBaby(owner.accessToken(), "宝宝" + i, "MALE", "2026-01-01");
		}

		Call sixth = postJson(BABIES, babyBody("宝宝6", "MALE", "2026-01-01"), owner.accessToken());
		assertThat(sixth.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(sixth.code()).as("§3.4：不新增错误码").isEqualTo("BAD_REQUEST");
		assertThat(sixth.message()).as("文案要指出归档这条路").contains("归档");
		assertThat(listNames(owner.accessToken())).hasSize(5);

		assertThat(patchJson(BABIES + "/" + first + "/archive", Map.of(), owner.accessToken()).code()).isEqualTo("OK");
		assertThat(listNames(owner.accessToken())).as("归档的不再出现在默认清单里").hasSize(4);
		assertThat(listNames(owner.accessToken(), true)).as("includeArchived 的清单仍在，档案管理要能恢复它").hasSize(5);
		assertThat(planRows(first)).as("归档不碰清单").hasSize(24);

		assertThat(createBaby(owner.accessToken(), "宝宝6", "MALE", "2026-01-01")).as("归档让出的名额要能被用上")
			.isPositive();
	}

	@Test
	@DisplayName("同名只在在册的宝宝之间撞：都在册即拒，归档的腾出名字")
	void archivedBabyFreesTheName() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long first = createBaby(owner.accessToken(), "奶糖", "MALE", "2026-01-01");

		Call duplicated = postJson(BABIES, babyBody("奶糖", "FEMALE", "2025-03-01"), owner.accessToken());
		assertThat(duplicated.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(duplicated.code()).isEqualTo("BAD_REQUEST");
		assertThat(duplicated.message()).contains("同名");

		patchJson(BABIES + "/" + first + "/archive", Map.of(), owner.accessToken());
		assertThat(createBaby(owner.accessToken(), "奶糖", "FEMALE", "2025-03-01")).as("归档的腾出同名").isPositive();
		assertThat(listNames(owner.accessToken())).containsExactly("奶糖");
	}

	@Test
	@DisplayName("出生日期与出生身高体重都在入口拦住：明天、19.9 与 200.1 各有各的码")
	void babyFieldsAreValidated() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String tomorrow = LocalDate.now(TimeConfig.ZONE).plusDays(1).toString();

		Call future = postJson(BABIES, babyBody("小满", "MALE", tomorrow), owner.accessToken());
		assertThat(future.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(future.code()).isEqualTo("BAD_REQUEST");
		assertThat(future.message()).contains("出生日期");

		assertThat(birthHeightRejection(owner, "小满", "19.9")).as("下限之下一分也不行").isEqualTo("VALIDATION_FAILED");
		assertThat(birthHeightRejection(owner, "阿圆", "200.1")).as("上限之上同理").isEqualTo("VALIDATION_FAILED");
	}

	@Test
	@DisplayName("出生身高的两个端点值本身是可用的：20.0 与 200.0 通过")
	void birthHeightBoundsAreInclusive() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		assertThat(birthHeightRejection(owner, "小满", "20.0")).isNull();
		assertThat(birthHeightRejection(owner, "阿圆", "200.0")).isNull();
	}

	@Test
	@DisplayName("改生日整份平移：行数与 id 集合一个不少，只是应种日期跟着挪")
	void planRecomputedOnBirthDateChange() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		Set<Long> before = planIds(babyId);

		Call call = patchJson(BABIES + "/" + babyId, babyBody("小满", "MALE", "2026-03-01"), owner.accessToken());
		assertThat(call.code()).isEqualTo("OK");

		assertThat(planIds(babyId)).as("重算是对齐老行，不是删了重建").containsExactlyInAnyOrderElementsOf(before);
		assertThat(planRows(babyId)).hasSize(24);
		assertThat(dueDateOf(babyId, "乙肝疫苗", "1")).isEqualTo("2026-03-01");
		assertThat(dueDateOf(babyId, "双价人乳头瘤病毒疫苗", "2")).isEqualTo("2039-09-01");
	}

	@Test
	@DisplayName("重算保留已接种与已跳过：只改应种日期，状态、原因、回写指针一字不动")
	void planRealignKeepsDoneAndSkipped() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		long donePlan = planRowId(babyId, "乙肝疫苗", "1");
		long skippedPlan = planRowId(babyId, "卡介苗", "1");
		long recordId = IdWorker.getId();
		this.jdbcTemplate.update("UPDATE baby_vaccine_plan SET status = 'DONE', record_id = ? WHERE id = ?", recordId,
				donePlan);
		this.jdbcTemplate.update("UPDATE baby_vaccine_plan SET status = 'SKIPPED', skip_reason = ? WHERE id = ?",
				"医生建议推迟", skippedPlan);

		Call call = patchJson(BABIES + "/" + babyId, babyBody("小满", "MALE", "2026-03-01"), owner.accessToken());
		assertThat(call.code()).isEqualTo("OK");

		Map<String, Object> done = planRow(donePlan);
		assertThat(done.get("due_date")).as("已接种的行照样跟着生日平移").hasToString("2026-03-01");
		assertThat(done.get("status")).isEqualTo("DONE");
		assertThat(((Number) done.get("record_id")).longValue()).isEqualTo(recordId);

		Map<String, Object> skipped = planRow(skippedPlan);
		assertThat(skipped.get("due_date")).hasToString("2026-03-01");
		assertThat(skipped.get("status")).isEqualTo("SKIPPED");
		assertThat(skipped.get("skip_reason")).isEqualTo("医生建议推迟");
		assertThat(skipped.get("record_id")).as("标记过的行没有回写指针，重算不该凭空造一个").isNull();
	}

	@Test
	@DisplayName("重算保留手动建的自费项：它不在程序表里，重算根本走不到它")
	void planRealignKeepsManualRows() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		insertManualPlan(babyId, "十三价肺炎球菌多糖结合疫苗", "1", "2026-05-05");

		Call call = patchJson(BABIES + "/" + babyId, babyBody("小满", "MALE", "2026-03-01"), owner.accessToken());
		assertThat(call.code()).isEqualTo("OK");

		assertThat(countByManual(babyId, 1)).as("自费项仍在，且仍标着手动").isEqualTo(1);
		assertThat(dueDateOf(babyId, "十三价肺炎球菌多糖结合疫苗", "1")).as("用户填的应种日期不被平移")
			.isEqualTo("2026-05-05");
		assertThat(planRows(babyId)).as("24 条字典行 + 1 条自费项").hasSize(25);
	}

	@Test
	@DisplayName("手动行与字典行撞同一个键时各走各的：手动行不动，字典行照旧跟着生日平移")
	void manualRowOnDictKeyIsNotRescheduled() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		// 应种日期刻意早于字典行的 2027-07-01：对齐时这一行会先被取到
		insertManualPlan(babyId, "麻腮风疫苗", "2", "2026-02-02");

		assertThat(patchJson(BABIES + "/" + babyId, babyBody("小满", "MALE", "2026-03-01"), owner.accessToken())
			.code()).isEqualTo("OK");

		assertThat(dueDatesOf(babyId, "麻腮风疫苗", "2")).as("用户填的日期留在原处，字典行平移到 18 月龄")
			.containsExactlyInAnyOrder("2026-02-02", "2027-09-01");
		assertThat(countByManual(babyId, 1)).as("不为手动行另插一条字典行").isEqualTo(1);
		assertThat(planRows(babyId)).as("24 条字典行 + 1 条手动行").hasSize(25);
		assertThat(dueDateOf(babyId, "乙肝疫苗", "1")).as("其余行照旧平移，证明重算确实跑过").isEqualTo("2026-03-01");
	}

	@Test
	@DisplayName("名下有过身高体重记录即拒删，只能归档")
	void deleteBlockedByGrowthRecord() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		insertGrowth(babyId, "2026-02-01", 0);

		Call call = deleteNoBody(BABIES + "/" + babyId, owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.message()).contains("归档");
		assertThat(countBaby(babyId)).isEqualTo(1);
	}

	@Test
	@DisplayName("已软删的记录也算「有过记录」：删掉的那条曾经真实存在过")
	void deleteBlockedBySoftDeletedRecord() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		insertGrowth(babyId, "2026-02-01", 1);

		assertThat(deleteNoBody(BABIES + "/" + babyId, owner.accessToken()).code()).isEqualTo("BAD_REQUEST");
	}

	@Test
	@DisplayName("清单不算「记录」：只有派生出来的 24 行时删得掉，清单随之软删")
	void deleteAllowedWhenOnlyPlanExists() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", "2026-01-01");
		assertThat(planRows(babyId)).hasSize(24);

		assertThat(deleteNoBody(BABIES + "/" + babyId, owner.accessToken()).code()).isEqualTo("OK");

		assertThat(planRows(babyId)).as("清单没有宝宝的档案就没有含义，随档案一起软删").isEmpty();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT COUNT(*) FROM baby_vaccine_plan WHERE baby_id = ?", Integer.class, babyId))
			.as("软删不是物理删除，行还在")
			.isEqualTo(24);
		assertThat(this.jdbcTemplate.queryForObject("SELECT deleted FROM baby WHERE id = ?", Integer.class, babyId))
			.as("档案本身是软删，历史记录将来还要能指回来")
			.isEqualTo(1);
		assertThat(listNames(owner.accessToken())).isEmpty();
	}

	@Test
	@DisplayName("跨家庭不可见：B 家的列表里没有 A 家的宝宝，改、归档、删都回资源不存在")
	void crossFamilyBabyIsInvisible() throws Exception {
		Account ownerA = register(PHONE_A, "张三");
		createFamily(ownerA, "张家");
		long babyId = createBaby(ownerA.accessToken(), "奶糖", "MALE", "2026-01-01");

		Account ownerB = register(PHONE_B, "李四");
		createFamily(ownerB, "李家");

		assertThat(listNames(ownerB.accessToken())).isEmpty();
		assertThat(patchJson(BABIES + "/" + babyId, babyBody("偷改", "MALE", "2026-01-01"), ownerB.accessToken())
			.code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(patchJson(BABIES + "/" + babyId + "/archive", Map.of(), ownerB.accessToken()).code())
			.isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(deleteNoBody(BABIES + "/" + babyId, ownerB.accessToken()).code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(listNames(ownerA.accessToken())).as("A 家的档案毫发无损").containsExactly("奶糖");
	}

	@Test
	@DisplayName("ageText 由服务端按出生日期算好下发：两种写法都与 BabyAge 一致")
	void ageTextFromServer() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		LocalDate today = LocalDate.now(TimeConfig.ZONE);
		long infant = createBaby(owner.accessToken(), "小满", "MALE", today.minusMonths(3).toString());
		long toddler = createBaby(owner.accessToken(), "阿圆", "FEMALE", today.minusMonths(30).toString());

		assertThat(babyRow(owner.accessToken(), infant).path("ageText").asText())
			.isEqualTo(BabyAge.ageText(today.minusMonths(3), today))
			.matches("\\d+ 个月 \\d+ 天");
		assertThat(babyRow(owner.accessToken(), toddler).path("ageText").asText())
			.isEqualTo(BabyAge.ageText(today.minusMonths(30), today))
			.matches("\\d+ 岁 \\d+ 个月");
	}

	// ---- 辅助 ----

	/** 出生身高提交一次，返回接口回的 code；通过时返回 null。名字要各叫各的，通过的调用会真的建出一个宝宝。 */
	private String birthHeightRejection(Account owner, String name, String birthHeight) throws Exception {
		Map<String, Object> body = babyBody(name, "MALE", "2026-01-01");
		body.put("birthHeight", birthHeight);
		Call call = postJson(BABIES, body, owner.accessToken());
		return call.code().equals("OK") ? null : call.code();
	}

	private List<Map<String, Object>> planRows(long babyId) {
		return this.jdbcTemplate.queryForList("SELECT id, vaccine_name, dose_no, due_date, status, skip_reason,"
				+ " record_id FROM baby_vaccine_plan WHERE baby_id = ? AND deleted = 0 ORDER BY due_date, id", babyId);
	}

	private Map<String, Object> planRow(long planId) {
		return this.jdbcTemplate.queryForMap(
			"SELECT due_date, status, skip_reason, record_id FROM baby_vaccine_plan WHERE id = ?", planId);
	}

	private Set<Long> planIds(long babyId) {
		return Set.copyOf(this.jdbcTemplate.queryForList(
			"SELECT id FROM baby_vaccine_plan WHERE baby_id = ? AND deleted = 0", Long.class, babyId));
	}

	private String dueDateOf(long babyId, String vaccineName, String doseNo) {
		List<String> dates = dueDatesOf(babyId, vaccineName, doseNo);
		assertThat(dates).as("%s第 %s 剂在清单里应有且只有一行", vaccineName, doseNo).hasSize(1);
		return dates.get(0);
	}

	/** 同一个 (疫苗名称, 剂次) 允许有多行——(baby_id, vaccine_name, dose_no) 上没有唯一索引（§7.1）。 */
	private List<String> dueDatesOf(long babyId, String vaccineName, String doseNo) {
		return this.jdbcTemplate.queryForList("SELECT due_date FROM baby_vaccine_plan"
				+ " WHERE baby_id = ? AND vaccine_name = ? AND dose_no = ? AND deleted = 0", String.class, babyId,
				vaccineName, doseNo);
	}

	private long planRowId(long babyId, String vaccineName, String doseNo) {
		return this.jdbcTemplate.queryForObject("SELECT id FROM baby_vaccine_plan"
				+ " WHERE baby_id = ? AND vaccine_name = ? AND dose_no = ? AND deleted = 0", Long.class, babyId,
				vaccineName, doseNo);
	}

	private int countByStatus(long babyId, String status) {
		return this.jdbcTemplate.queryForObject(
			"SELECT COUNT(*) FROM baby_vaccine_plan WHERE baby_id = ? AND status = ? AND deleted = 0", Integer.class,
			babyId, status);
	}

	private int countByManual(long babyId, int manual) {
		return this.jdbcTemplate.queryForObject(
			"SELECT COUNT(*) FROM baby_vaccine_plan WHERE baby_id = ? AND manual = ? AND deleted = 0", Integer.class,
			babyId, manual);
	}

	private int countBaby(long babyId) {
		return this.jdbcTemplate.queryForObject("SELECT COUNT(*) FROM baby WHERE id = ? AND deleted = 0", Integer.class,
				babyId);
	}

	/**
	 * 手动建一条自费项。应种清单的手动建项端点另有测试类，这里要验的是重算怎么对待这类行，
	 * 走端点造数据会把「它是不是手动行」也变成端点的事。
	 */
	private void insertManualPlan(long babyId, String vaccineName, String doseNo, String dueDate) {
		this.jdbcTemplate.update("INSERT INTO baby_vaccine_plan (id, family_id, baby_id, vaccine_name, dose_no,"
				+ " due_date, status, manual, created_by) VALUES (?, ?, ?, ?, ?, ?, 'PENDING', 1, ?)", IdWorker.getId(),
				familyIdOf(babyId), babyId, vaccineName, doseNo, Date.valueOf(dueDate), 1L);
	}

	private void insertGrowth(long babyId, String measureDate, int deleted) {
		this.jdbcTemplate.update("INSERT INTO baby_growth (id, family_id, baby_id, measure_date, height_cm, weight_kg,"
				+ " created_by, deleted) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", IdWorker.getId(), familyIdOf(babyId), babyId,
				Date.valueOf(measureDate), new BigDecimal("55.5"), new BigDecimal("5.20"), 1L, deleted);
	}

	private long familyIdOf(long babyId) {
		return this.jdbcTemplate.queryForObject("SELECT family_id FROM baby WHERE id = ?", Long.class, babyId);
	}

	private static Map<String, Object> babyBody(String name, String gender, String birthDate) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("name", name);
		body.put("gender", gender);
		body.put("birthDate", birthDate);
		return body;
	}

	private List<String> listNames(String accessToken) throws Exception {
		return listNames(accessToken, false);
	}

	private List<String> listNames(String accessToken, boolean includeArchived) throws Exception {
		Call call = getJson(BABIES, Map.of("includeArchived", String.valueOf(includeArchived)), accessToken);
		assertThat(call.code()).isEqualTo("OK");
		List<String> names = new ArrayList<>();
		for (JsonNode node : call.data()) {
			names.add(node.path("name").asText());
		}
		return names;
	}

	private JsonNode babyRow(String accessToken, long babyId) throws Exception {
		Call call = getJson(BABIES, accessToken);
		assertThat(call.code()).isEqualTo("OK");
		for (JsonNode node : call.data()) {
			if (node.path("id").asLong() == babyId) {
				return node;
			}
		}
		throw new AssertionError("列表里应有宝宝 " + babyId);
	}

}
