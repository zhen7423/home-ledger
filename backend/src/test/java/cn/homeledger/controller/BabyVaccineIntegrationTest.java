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
 * §4.4.4 应种清单与接种记录：双向回写是这一类的核心，也是验收用例 27 与 28 的机器版。
 * <p>
 * 两个动作最容易写反，各有一条专门盯着：「已被标为跳过 / 不适用的行不被自动回写覆盖」与
 * 「撤销跳过要把 skip_reason 真的清成 NULL」。前者靠端点断言「那一刻什么也没变」，
 * 后者必须读库——接口回显的 skipReason 是刚读出来的对象，即使 UPDATE 里漏了那一列也看不出来。
 */
class BabyVaccineIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	private static final String HEP_B = "乙肝疫苗";

	private static final String BCG = "卡介苗";

	private static final String FLU = "流感疫苗";

	@Test
	@DisplayName("建接种记录回写应种项：status = DONE + record_id 互指，展示态变已接种")
	void recordWriteBackSetsDone() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");

		JsonNode record = createRecord(token, babyId, HEP_B, "1", TODAY.toString());

		assertThat(record.path("planId").asLong()).as("记录指向它回写的那一行").isEqualTo(planId);
		assertThat(planRow(planId)).as("应种项被回写成已接种").containsEntry("status", "DONE");
		assertThat(planRow(planId).get("record_id")).isEqualTo(record.path("id").asLong());
		assertThat(planOf(token, babyId, HEP_B, "1").path("displayStatus").asText()).isEqualTo("VACCINATED");
	}

	@Test
	@DisplayName("接种日期不能晚于今天，当天放行")
	void recordGivenDateInFutureRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());

		Call future = postJson(BABY_VACCINE_RECORDS, recordBody(babyId, HEP_B, "1", TODAY.plusDays(1).toString()),
				token);

		assertThat(future.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(future.code()).isEqualTo("BAD_REQUEST");
		assertThat(future.message()).contains("不能晚于今天");
		assertThat(postJson(BABY_VACCINE_RECORDS, recordBody(babyId, HEP_B, "1", TODAY.toString()), token).code())
			.as("当天是合法的接种日").isEqualTo("OK");
	}

	@Test
	@DisplayName("改接种记录时把日期改到未来同样被拒，原日期不变")
	void recordUpdateGivenDateInFutureRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long recordId = createRecord(token, babyId, HEP_B, "1", TODAY.toString()).path("id").asLong();

		Call patched = patchJson(BABY_VACCINE_RECORDS + "/" + recordId,
				recordBody(babyId, HEP_B, "1", TODAY.plusDays(1).toString()), token);

		assertThat(patched.code()).isEqualTo("BAD_REQUEST");
		assertThat(patched.message()).contains("不能晚于今天");
		assertThat(givenDateOf(recordId)).as("被拒后原有的今天不变").isEqualTo(TODAY.toString());
	}

	@Test
	@DisplayName("撤销一条被接种记录回写成 DONE 的应种项被拒，不留下 record_id 残留的分裂态")
	void undoOnRecordBoundPlanRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");
		createRecord(token, babyId, HEP_B, "1", TODAY.toString());

		Call undo = patchPlan(token, planId, "PENDING", null);

		assertThat(undo.code()).isEqualTo("BAD_REQUEST");
		assertThat(undo.message()).contains("接种记录");
		assertThat(planRow(planId)).as("被拒后仍是 DONE，没被改成 PENDING 留下悬挂的反向指针")
			.containsEntry("status", "DONE");
		assertThat(planRow(planId).get("record_id")).isNotNull();
	}

	@Test
	@DisplayName("删接种记录把应种项退回待接种，并清掉 record_id")
	void recordDeleteRevertsToPending() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");
		long recordId = createRecord(token, babyId, HEP_B, "1", TODAY.toString()).path("id").asLong();

		assertThat(deleteNoBody(BABY_VACCINE_RECORDS + "/" + recordId, token).code()).isEqualTo("OK");

		assertThat(planRow(planId)).containsEntry("status", "PENDING");
		assertThat(planRow(planId).get("record_id")).as("录错了要能改回来，反向指针也得断干净").isNull();
		assertThat(planOf(token, babyId, HEP_B, "1").path("displayStatus").asText()).isEqualTo("DUE_SOON");
	}

	@Test
	@DisplayName("标记过的行：接种记录照建，但不回写也不回退，标记态一直在")
	void recordDeleteDoesNotRevertMarked() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, BCG, "1");
		assertThat(patchPlan(token, planId, "SKIPPED", "医嘱暂缓").code()).isEqualTo("OK");

		long recordId = createRecord(token, babyId, BCG, "1", TODAY.toString()).path("id").asLong();
		assertThat(deleteNoBody(BABY_VACCINE_RECORDS + "/" + recordId, token).code()).isEqualTo("OK");

		assertThat(planRow(planId)).as("先撤销标记才谈得上接种").containsEntry("status", "SKIPPED")
			.containsEntry("skip_reason", "医嘱暂缓");
		assertThat(planRow(planId).get("record_id")).isNull();
	}

	@Test
	@DisplayName("被标为跳过的行不被按名称自动匹配的记录覆盖")
	void markedRowNotOverwrittenByAutoMatch() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");
		assertThat(patchPlan(token, planId, "NA", "已患过").code()).isEqualTo("OK");

		JsonNode record = createRecord(token, babyId, HEP_B, "1", TODAY.toString());

		assertThat(record.path("planId").isNull()).as("没写回就没有反向指针，记录独立存在").isTrue();
		assertThat(planRow(planId)).as("什么都不写，连 record_id 也不写").containsEntry("status", "NA");
		assertThat(planRow(planId).get("record_id")).isNull();
		assertThat(planOf(token, babyId, HEP_B, "1").path("displayStatus").asText()).isEqualTo("MARKED");
	}

	@Test
	@DisplayName("显式给了 planId 就以它为准，不按名称匹配")
	void explicitPlanIdWins() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long hepPlan = planIdOf(token, babyId, HEP_B, "1");

		Map<String, Object> body = recordBody(babyId, FLU, "1", TODAY.toString());
		body.put("planId", hepPlan);
		Call call = postJson(BABY_VACCINE_RECORDS, body, token);

		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("planId").asLong()).isEqualTo(hepPlan);
		assertThat(planRow(hepPlan)).as("补种、异地接种、名称写法不同的落点").containsEntry("status", "DONE");
		assertThat(planRow(hepPlan).get("record_id")).isEqualTo(call.data().path("id").asLong());
	}

	@Test
	@DisplayName("匹配不到应种项的记录独立存在，planId 留空且不报错")
	void unmatchedRecordIsStandalone() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());

		JsonNode record = createRecord(token, babyId, FLU, "1", TODAY.toString());

		assertThat(record.path("planId").isNull()).isTrue();
		assertThat(countPlans(babyId, FLU)).as("自费疫苗的首次录入本来就没有对应行可回写").isZero();
	}

	@Test
	@DisplayName("标记只走 SKIPPED / NA，撤销走 PENDING，其余状态名一律拒")
	void planPatchOnlyAcceptsMarkedStatuses() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");

		Call skipped = patchPlan(token, planId, "SKIPPED", "医嘱暂缓");
		assertThat(skipped.code()).isEqualTo("OK");
		assertThat(skipped.data().path("displayStatus").asText()).isEqualTo("MARKED");

		assertThat(patchPlan(token, planId, "NA", "已患病").code()).isEqualTo("OK");
		assertThat(planRow(planId)).containsEntry("status", "NA");

		Call bogus = patchPlan(token, planId, "VACCINATED", "展示态不是落库态");
		assertThat(bogus.code()).isEqualTo("BAD_REQUEST");
		assertThat(bogus.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
	}

	@Test
	@DisplayName("DONE 手工写入即拒：它只由接种记录回写")
	void planPatchRejectsDone() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");

		Call call = patchPlan(token, planId, "DONE", "自己打的");

		assertThat(call.code()).isEqualTo("BAD_REQUEST");
		assertThat(call.message()).contains("接种记录");
		assertThat(planRow(planId)).as("被拒之后一行都没动").containsEntry("status", "PENDING");
	}

	@Test
	@DisplayName("标记跳过 / 不适用时原因必填，空白串不算填了")
	void planPatchRequiresReasonForSkip() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");

		assertThat(patchPlan(token, planId, "SKIPPED", null).message()).isEqualTo("请填写跳过或不适用原因");
		assertThat(patchPlan(token, planId, "NA", "   ").message()).isEqualTo("请填写跳过或不适用原因");
		assertThat(planRow(planId)).containsEntry("status", "PENDING");
	}

	@Test
	@DisplayName("撤销跳过把库里的原因清成 NULL，请求里带的原因也不留")
	void planPatchClearsReasonOnUndo() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");
		assertThat(patchPlan(token, planId, "SKIPPED", "医嘱暂缓").code()).isEqualTo("OK");

		Call undo = patchPlan(token, planId, "PENDING", "上次写的理由");

		assertThat(undo.code()).isEqualTo("OK");
		assertThat(undo.data().path("skipReason").isNull()).isTrue();
		assertThat(planRow(planId).get("skip_reason")).as("清不掉的症状是「撤销了但列表上还挂着上次的跳过原因」").isNull();
		assertThat(undo.data().path("displayStatus").asText()).isEqualTo("DUE_SOON");
	}

	@Test
	@DisplayName("手动自费项可以删，且落库带 manual = 1")
	void manualPlanDeletable() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());

		Call created = postManualPlan(token, babyId, FLU, "1", TODAY.plusDays(30).toString());

		assertThat(created.code()).isEqualTo("OK");
		assertThat(created.data().path("manual").asBoolean()).isTrue();
		long planId = created.data().path("id").asLong();
		assertThat(planRow(planId)).containsEntry("manual", 1);

		assertThat(deleteNoBody(BABY_VACCINE_PLANS + "/" + planId, token).code()).isEqualTo("OK");
		assertThat(findPlan(token, babyId, FLU, "1")).isNull();
	}

	@Test
	@DisplayName("字典生成的行不能删，说明理由并保持原位")
	void generatedPlanNotDeletable() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long planId = planIdOf(token, babyId, HEP_B, "1");

		Call call = deleteNoBody(BABY_VACCINE_PLANS + "/" + planId, token);

		assertThat(call.code()).isEqualTo("BAD_REQUEST");
		assertThat(call.message()).contains("只能跳过");
		assertThat(planOf(token, babyId, HEP_B, "1").path("id").asLong()).isEqualTo(planId);
	}

	@Test
	@DisplayName("同宝宝同 (疫苗名称, 剂次) 撞键即拒，字典行也占着这个键")
	void manualPlanDuplicateKeyRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		assertThat(postManualPlan(token, babyId, FLU, "1", TODAY.plusDays(30).toString()).code()).isEqualTo("OK");

		Call duplicate = postManualPlan(token, babyId, FLU, "1", TODAY.plusDays(60).toString());
		Call clashesWithGenerated = postManualPlan(token, babyId, HEP_B, "1", TODAY.toString());

		assertThat(duplicate.code()).isEqualTo("BAD_REQUEST");
		assertThat(duplicate.message()).contains("已在应种清单里");
		assertThat(clashesWithGenerated.code()).isEqualTo("BAD_REQUEST");
		assertThat(clashesWithGenerated.message()).contains("已在应种清单里");
		assertThat(countPlans(babyId, FLU)).isEqualTo(1);
	}

	@Test
	@DisplayName("手动项的应种日期不能早于出生日期")
	void manualPlanDueDateBeforeBirthRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());

		Call call = postManualPlan(token, babyId, FLU, "1", TODAY.minusDays(1).toString());

		assertThat(call.code()).isEqualTo("BAD_REQUEST");
		assertThat(call.message()).contains("出生日期");
		assertThat(countPlans(babyId, FLU)).isZero();
	}

	@Test
	@DisplayName("改接种记录的疫苗名称或剂次：先撤销旧绑定，再按新键重新匹配")
	void recordPatchRebindsPlan() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		long firstDose = planIdOf(token, babyId, HEP_B, "1");
		long secondDose = planIdOf(token, babyId, HEP_B, "2");
		long recordId = createRecord(token, babyId, HEP_B, "1", TODAY.toString()).path("id").asLong();

		Call patched = patchJson(BABY_VACCINE_RECORDS + "/" + recordId,
				recordBody(babyId, HEP_B, "2", TODAY.toString()), token);

		assertThat(patched.code()).isEqualTo("OK");
		assertThat(patched.data().path("planId").asLong()).isEqualTo(secondDose);
		assertThat(planRow(firstDose)).as("旧的那一行退回待接种").containsEntry("status", "PENDING");
		assertThat(planRow(firstDose).get("record_id")).isNull();
		assertThat(planRow(secondDose)).containsEntry("status", "DONE").containsEntry("record_id", recordId);
	}

	@Test
	@DisplayName("下一针日期按该疫苗下一个未完成剂次推算，没有了就留空")
	void nextDateComputedFromNextPending() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());

		JsonNode first = createRecord(token, babyId, HEP_B, "1", TODAY.toString());
		JsonNode second = createRecord(token, babyId, HEP_B, "2", TODAY.toString());
		JsonNode third = createRecord(token, babyId, HEP_B, "3", TODAY.toString());

		assertThat(first.path("nextDate").asText()).isEqualTo(dueDateOf(token, babyId, HEP_B, "2"));
		assertThat(second.path("nextDate").asText()).isEqualTo(dueDateOf(token, babyId, HEP_B, "3"));
		assertThat(third.path("nextDate").isNull()).as("该疫苗在本宝宝清单里没有未完成剂次了").isTrue();
	}

	@Test
	@DisplayName("请求给了下一针日期就照抄，不按清单回算覆盖")
	void nextDateCopiedWhenGiven() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long babyId = createBaby(token, "小满", "MALE", TODAY.toString());
		String handwritten = TODAY.plusYears(5).toString();

		Map<String, Object> body = recordBody(babyId, HEP_B, "1", TODAY.toString());
		body.put("nextDate", handwritten);
		Call created = postJson(BABY_VACCINE_RECORDS, body, token);

		assertThat(created.code()).isEqualTo("OK");
		assertThat(created.data().path("nextDate").asText()).isEqualTo(handwritten);

		Map<String, Object> edited = recordBody(babyId, HEP_B, "1", TODAY.toString());
		edited.put("nextDate", handwritten);
		Call patched = patchJson(BABY_VACCINE_RECORDS + "/" + created.data().path("id").asLong(), edited, token);

		assertThat(patched.code()).isEqualTo("OK");
		assertThat(patched.data().path("nextDate").asText()).isEqualTo(handwritten);
	}

	@Test
	@DisplayName("跨家庭：清单与记录都看不见，按 id 改删一律 404，本家庭的数据不受影响")
	void crossFamilyPlanAndRecordInvisible() throws Exception {
		Account ownerA = registerWithFamily(PHONE_A, "张三");
		long babyA = createBaby(ownerA.accessToken(), "小满", "MALE", TODAY.toString());
		long planA = planIdOf(ownerA.accessToken(), babyA, HEP_B, "1");
		long recordA = createRecord(ownerA.accessToken(), babyA, HEP_B, "1", TODAY.toString()).path("id").asLong();

		Account ownerB = registerWithFamily(PHONE_B, "李四");
		String tokenB = ownerB.accessToken();
		long babyB = createBaby(tokenB, "阿圆", "FEMALE", TODAY.toString());

		assertThat(getJson(BABY_VACCINE_PLANS, Map.of("babyId", String.valueOf(babyA)), tokenB).data()).isEmpty();
		assertThat(getJson(BABY_VACCINE_RECORDS, Map.of("babyId", String.valueOf(babyA)), tokenB).data()).isEmpty();
		assertThat(getJson(BABY_VACCINE_PLANS, Map.of("babyId", String.valueOf(babyB)), tokenB).data())
			.as("看不见别人的，自己的照旧")
			.isNotEmpty();

		Call patchForeign = patchPlan(tokenB, planA, "SKIPPED", "越权");
		assertThat(patchForeign.code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(patchForeign.status()).isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(deleteNoBody(BABY_VACCINE_PLANS + "/" + planA, tokenB).code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(deleteNoBody(BABY_VACCINE_RECORDS + "/" + recordA, tokenB).code()).isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(patchJson(BABY_VACCINE_RECORDS + "/" + recordA,
				recordBody(babyA, HEP_B, "1", TODAY.toString()), tokenB).code())
			.isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(planRow(planA)).containsEntry("status", "DONE");
	}

	// ---- 辅助 ----

	private JsonNode createRecord(String token, long babyId, String vaccineName, String doseNo, String givenDate)
			throws Exception {
		Call call = postJson(BABY_VACCINE_RECORDS, recordBody(babyId, vaccineName, doseNo, givenDate), token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private Call postManualPlan(String token, long babyId, String vaccineName, String doseNo, String dueDate)
			throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("vaccineName", vaccineName);
		body.put("doseNo", doseNo);
		body.put("dueDate", dueDate);
		return postJson(BABY_VACCINE_PLANS, body, token);
	}

	/** reason 传 null 即请求体里不带这个键——与「传了空串」是两种输入，两边都要被拒。 */
	private Call patchPlan(String token, long planId, String status, String reason) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("status", status);
		if (reason != null) {
			body.put("reason", reason);
		}
		return patchJson(BABY_VACCINE_PLANS + "/" + planId, body, token);
	}

	private JsonNode planOf(String token, long babyId, String vaccineName, String doseNo) throws Exception {
		JsonNode plan = findPlan(token, babyId, vaccineName, doseNo);
		assertThat(plan).as("清单里应有 %s 第 %s 剂", vaccineName, doseNo).isNotNull();
		return plan;
	}

	private JsonNode findPlan(String token, long babyId, String vaccineName, String doseNo) throws Exception {
		Call call = getJson(BABY_VACCINE_PLANS, Map.of("babyId", String.valueOf(babyId)), token);
		assertThat(call.code()).isEqualTo("OK");
		for (JsonNode node : call.data()) {
			if (node.path("vaccineName").asText().equals(vaccineName)
					&& node.path("doseNo").asText().equals(doseNo)) {
				return node;
			}
		}
		return null;
	}

	private String dueDateOf(String token, long babyId, String vaccineName, String doseNo) throws Exception {
		return planOf(token, babyId, vaccineName, doseNo).path("dueDate").asText();
	}

	/** 直接读库：撤销时 skip_reason 是不是真的被 UPDATE 成 NULL，接口回显看不出来。 */
	private Map<String, Object> planRow(long planId) {
		return this.jdbcTemplate.queryForMap(
			"SELECT status, skip_reason, record_id, manual FROM baby_vaccine_plan WHERE id = ?", planId);
	}

	private String givenDateOf(long recordId) {
		return this.jdbcTemplate.queryForObject("SELECT given_date FROM baby_vaccine_record WHERE id = ?", String.class,
				recordId);
	}

	private int countPlans(long babyId, String vaccineName) {
		return this.jdbcTemplate.queryForObject(
			"SELECT COUNT(*) FROM baby_vaccine_plan WHERE baby_id = ? AND vaccine_name = ? AND deleted = 0",
			Integer.class, babyId, vaccineName);
	}

	private static Map<String, Object> recordBody(long babyId, String vaccineName, String doseNo, String givenDate) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("vaccineName", vaccineName);
		body.put("doseNo", doseNo);
		body.put("givenDate", givenDate);
		return body;
	}

}
