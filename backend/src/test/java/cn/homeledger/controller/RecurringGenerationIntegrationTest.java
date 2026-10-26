package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;

import cn.homeledger.common.AuthContext;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.service.RecurringGenerationService;
import cn.homeledger.support.ApiTestBase;

/**
 * §4.2.3 周期记账的生成引擎。覆盖验收用例 10（月末钳制）与 11（补记窗口）。
 * <p>
 * 这里一律直接 {@code @Autowired} 引擎、把「今天」当参数喂进去，不经 Controller 也不等 cron：窗口、游标、
 * 幂等这三件事全部只依赖传入的那一天，脱离调度才测得准。规则也不走 POST /recurring-rules 建，原因见
 * {@link #seedRule}。规则的 CRUD 与 A4 的当场补跑本身在 RecurringRuleIntegrationTest 里测。
 */
class RecurringGenerationIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	@Autowired
	private RecurringGenerationService generationService;

	@Test
	@DisplayName("验收用例 10：每月 31 日在二月钳制到月末那天，三月仍按 31 日")
	void monthlyOnThe31stClampsToTheShortMonths() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[31]}", LocalDate.of(2026, 2, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 2, 28))).as("二月只补到月末那一个执行日").isEqualTo(1);
		assertThat(datesOf(rule)).containsExactly("2026-02-28");

		assertThat(generationService.runFor(LocalDate.of(2026, 3, 31))).isEqualTo(1);
		assertThat(datesOf(rule)).containsExactly("2026-02-28", "2026-03-31");
	}

	@Test
	@DisplayName("闰年：每月 31 日的规则在 2028-02-29 钳制到 29 日")
	void leapYearFebruaryClampsToThe29th() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[31]}", LocalDate.of(2028, 2, 1));

		assertThat(generationService.runFor(LocalDate.of(2028, 2, 29))).isEqualTo(1);
		assertThat(datesOf(rule)).containsExactly("2028-02-29");
	}

	@Test
	@DisplayName("[28, 31] 在平年二月只生成一笔：两个值钳到同一天，而不是各生成一笔")
	void twoValuesClampedToOneDayProduceOneRow() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[28,31]}", LocalDate.of(2026, 2, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 2, 28))).as("28 既按字面命中、又是 31 钳制后的落点")
			.isEqualTo(1);
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM recurring_execution_log WHERE rule_id = ?",
				Integer.class, rule)).as("「月末特例」那种写法会在这里生成两笔").isEqualTo(1);
	}

	@Test
	@DisplayName("幂等：同一天跑两次，第二次不重复出流水")
	void runningTheSameDayTwiceChangesNothing() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[15]}", LocalDate.of(2026, 9, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 15))).isEqualTo(1);
		assertThat(generationService.runFor(LocalDate.of(2026, 9, 15))).as("游标已推到 15 日，窗口起点越过今天").isZero();
		assertThat(datesOf(rule)).containsExactly("2026-09-15");
	}

	@Test
	@DisplayName("验收用例 11：删掉自动生成的流水，当天不补回、下一周期照出")
	void deletingAGeneratedRowNeitherComesBackNorBlocksTheNextPeriod() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[15]}", LocalDate.of(2026, 9, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 15))).isEqualTo(1);
		// 用户在 App 里删那笔走的是软删，行还在表里；判重看的是执行日志而不是流水，
		// 所以「判重改成查流水」的那种写法会在当天就把这笔补回来。
		jdbcTemplate.update("UPDATE `transaction` SET deleted = 1 WHERE rule_id = ?", rule);

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 15))).as("删掉的当天不能被补回来").isZero();
		assertThat(generationService.runFor(LocalDate.of(2026, 10, 15))).as("删流水不影响下一周期").isEqualTo(1);
		assertThat(datesOf(rule)).containsExactly("2026-09-15", "2026-10-15");
		assertThat(jdbcTemplate.queryForObject(
				"SELECT COUNT(*) FROM `transaction` WHERE rule_id = ? AND deleted = 0", Integer.class, rule))
			.as("被删的那笔不会复活").isEqualTo(1);
	}

	@Test
	@DisplayName("补记窗口只有 7 天：停机半个月后重启，只补最近一周而不是整段灌进来")
	void backfillStopsAtSevenDays() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[1]}", LocalDate.of(2026, 9, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 15))).as("窗口起点被抬到 09-09，1 日已在外面").isZero();
		assertThat(datesOf(rule)).isEmpty();
	}

	@Test
	@DisplayName("A4 当月立即生效（引擎侧）：起始日在窗口内就补出来，并标上「系统补记」")
	void executionDayInsideTheWindowGetsBackfilled() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[1]}", LocalDate.of(2026, 9, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 5))).isEqualTo(1);
		assertThat(datesOf(rule)).containsExactly("2026-09-01");
		assertThat(jdbcTemplate.queryForObject("SELECT remark FROM `transaction` WHERE rule_id = ?", String.class, rule))
			.as("补的账要看得出是补的").isEqualTo("（系统补记）");
	}

	@Test
	@DisplayName("暂停期不整段补出来：游标停在暂停那天，恢复时窗口起点随之收窄")
	void pausedDaysAreNeverBackfilled() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[1]}", LocalDate.of(2026, 9, 1));
		assertThat(generationService.runFor(LocalDate.of(2026, 9, 5))).isEqualTo(1);
		assertThat(cursorOf(rule)).isEqualTo(LocalDate.of(2026, 9, 5));

		setEnabled(rule, false);
		assertThat(generationService.runFor(LocalDate.of(2026, 9, 20))).as("停用的规则根本不在扫描结果里").isZero();
		assertThat(cursorOf(rule)).as("暂停期间游标一步都不走").isEqualTo(LocalDate.of(2026, 9, 5));

		setEnabled(rule, true);
		assertThat(generationService.runFor(LocalDate.of(2026, 9, 20))).as("窗口 09-14 到 09-20 里没有 1 号")
			.isZero();
		assertThat(datesOf(rule)).as("暂停那半个月没有被整段补成流水").containsExactly("2026-09-01");
	}

	@Test
	@DisplayName("截止日：end_date 是含当天的，过完最后一天就再也不出账")
	void endDateIsInclusiveAndThenTheRuleStops() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[10]}", LocalDate.of(2026, 9, 1),
				LocalDate.of(2026, 9, 10));

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 10))).as("end_date 当天仍要出账").isEqualTo(1);
		assertThat(datesOf(rule)).containsExactly("2026-09-10");
		// 游标被推到窗口末尾（09-10），下一次跑到 09-11 起算，10 号已过去，于是永远不再命中
		assertThat(generationService.runFor(LocalDate.of(2026, 9, 16))).isZero();
		assertThat(datesOf(rule)).hasSize(1);
	}

	@Test
	@DisplayName("每 3 天以 start_date 为锚，不是以 1970-01-01 为锚")
	void dailyIntervalIsAnchoredOnTheStartDate() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "DAILY", "{\"intervalDays\":3}", LocalDate.of(2026, 9, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 7))).as("09-01 是起始日，当天就算，之后每三天一笔")
			.isEqualTo(3);
		assertThat(datesOf(rule)).containsExactly("2026-09-01", "2026-09-04", "2026-09-07");
	}

	@Test
	@DisplayName("每周几：weekdays 用 ISO 编号，5 是周五")
	void weeklyMatchesByIsoWeekday() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "WEEKLY", "{\"weekdays\":[5]}", LocalDate.of(2026, 9, 1));

		// 2026-09-01 是周二，所以 04 与 11 是周五；窗口从 09-08 起算，只补得到 11 日那一笔
		assertThat(generationService.runFor(LocalDate.of(2026, 9, 14))).isEqualTo(1);
		assertThat(datesOf(rule)).containsExactly("2026-09-11");
	}

	@Test
	@DisplayName("每年几月几日：只在指定月份命中，短月同样走钳制")
	void yearlyNeedsBothMonthAndDay() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "YEARLY", "{\"daysOfMonth\":[29],\"month\":2}", LocalDate.of(2026, 1, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 2, 28))).as("平年没有 2 月 29 日，钳到月末的 28 日")
			.isEqualTo(1);
		assertThat(datesOf(rule)).containsExactly("2026-02-28");

		assertThat(generationService.runFor(LocalDate.of(2026, 3, 31))).as("月份不对，一个月里一天都不出").isZero();
		assertThat(datesOf(rule)).hasSize(1);
	}

	@Test
	@DisplayName("生成的流水按 A5 记在建规则的人名下，名称快照取生成那一刻的字典名")
	void generatedRowsCarryTheCreatorAndTheNamesOfThatMoment() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long rule = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[1]}", LocalDate.of(2026, 9, 1));
		long dining = topCategoryId(owner, "餐饮");

		assertThat(patchJson(CATEGORIES + "/" + dining, Map.of("name", "外食"), owner.accessToken()).code())
			.isEqualTo("OK");
		assertThat(generationService.runFor(LocalDate.of(2026, 9, 5))).isEqualTo(1);

		Map<String, Object> row = jdbcTemplate.queryForMap(
				"SELECT type, amount, category_name_snapshot, account_name_snapshot, recorder_name_snapshot, created_by, rule_id"
						+ " FROM `transaction` WHERE rule_id = ?",
				rule);
		assertThat(row.get("type")).isEqualTo("EXPENSE");
		assertThat(String.valueOf(row.get("amount"))).isEqualTo("100.00");
		assertThat(row.get("category_name_snapshot")).as("改名不回溯历史，但生成时它已叫这个名").isEqualTo("外食");
		assertThat(row.get("account_name_snapshot")).isEqualTo("现金");
		assertThat(row.get("recorder_name_snapshot")).isEqualTo("张三");
		assertThat(row.get("created_by")).as("A5：记录人是建规则的人").isEqualTo(owner.userId());
		assertThat(row.get("rule_id")).isEqualTo(rule);
	}

	@Test
	@DisplayName("两个家庭各一条规则，一次扫描两家各出一笔，且互相查不到对方的流水")
	void oneScanCoversEveryFamilyWithoutLeaking() throws Exception {
		Account zhang = registerWithFamily(PHONE_A, "张三");
		Account wang = registerWithFamily(PHONE_OTHER, "王五");
		long zhangRule = seedRule(zhang, "MONTHLY", "{\"daysOfMonth\":[5]}", LocalDate.of(2026, 9, 1));
		long wangRule = seedRule(wang, "MONTHLY", "{\"daysOfMonth\":[5]}", LocalDate.of(2026, 9, 1));

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 5))).as("跨家庭扫描一次跑完两家").isEqualTo(2);
		assertThat(datesOf(zhangRule)).containsExactly("2026-09-05");
		assertThat(datesOf(wangRule)).containsExactly("2026-09-05");

		assertThat(getJson(TRANSACTIONS, zhang.accessToken()).data().path("total").asLong()).isEqualTo(1);
		assertThat(getJson(TRANSACTIONS, wang.accessToken()).data().path("total").asLong()).isEqualTo(1);
	}

	@Test
	@DisplayName("扫描线程跑完要把登录态恢复原样：漏了恢复会让下一个定时任务带着上一个家庭的身份跑")
	void authContextIsAlwaysRestored() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[5]}", LocalDate.of(2026, 9, 1));

		generationService.runFor(LocalDate.of(2026, 9, 5));
		assertThat(AuthContextHolder.get()).as("定时任务线程本来没有登录态，跑完还得是 null").isNull();

		AuthContext requestContext = new AuthContext(owner.userId(), familyIdOf(owner), AuthContext.ROLE_MEMBER);
		AuthContextHolder.set(requestContext);
		try {
			generationService.runFor(LocalDate.of(2026, 9, 12));
			assertThat(AuthContextHolder.get()).as("请求线程进来时那份上下文要原样还回去").isSameAs(requestContext);
		}
		finally {
			AuthContextHolder.clear();
		}
	}

	@Test
	@DisplayName("一条规则的执行参数坏了不能带崩同天的其他规则")
	void oneBrokenRuleDoesNotRollBackTheOthers() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long broken = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[5]}", LocalDate.of(2026, 9, 1));
		long healthy = seedRule(owner, "MONTHLY", "{\"daysOfMonth\":[4]}", LocalDate.of(2026, 9, 1));
		jdbcTemplate.update("UPDATE recurring_rule SET period_value = '{oops' WHERE id = ?", broken);

		assertThat(generationService.runFor(LocalDate.of(2026, 9, 5))).as("坏那条只丢自己，扫描整体不抛异常").isEqualTo(1);
		assertThat(datesOf(healthy)).containsExactly("2026-09-04");
		assertThat(datesOf(broken)).isEmpty();
	}

	// ---- 前置数据 ----

	/**
	 * 直接写一行规则，不走 POST /recurring-rules。
	 * <p>
	 * 建规则的接口按 A4 会当场补跑一次，把游标推到真实日期的窗口末尾——而这一组用例喂给引擎的是二月、去年九月
	 * 这类历史日期，游标一旦停在真实日期，那些日子就全在窗口之外，测出来的「0 笔」跟引擎对不对毫无关系。
	 * 所以游标钉在 start_date 前一天，等于「这条规则刚从没跑过」的初始状态。
	 */
	private long seedRule(Account owner, String periodType, String periodValue, LocalDate startDate) throws Exception {
		return seedRule(owner, periodType, periodValue, startDate, null);
	}

	private long seedRule(Account owner, String periodType, String periodValue, LocalDate startDate,
			LocalDate endDate) throws Exception {
		long id = IdWorker.getId();
		jdbcTemplate.update("INSERT INTO recurring_rule (id, family_id, name, type, amount, category_id, account_id,"
				+ " period_type, period_value, start_date, end_date, enabled, last_processed_date, created_by)"
				+ " VALUES (?, ?, '自动记账', 'EXPENSE', 100.00, ?, ?, ?, ?, ?, ?, 1, ?, ?)", id, familyIdOf(owner),
				topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"), periodType, periodValue, startDate, endDate,
				startDate.minusDays(1), owner.userId());
		return id;
	}

	// ---- 取值与状态辅助 ----

	private List<String> datesOf(long ruleId) {
		return jdbcTemplate.queryForList(
				"SELECT CAST(biz_date AS CHAR) FROM recurring_execution_log WHERE rule_id = ? ORDER BY biz_date",
				String.class, ruleId);
	}

	private LocalDate cursorOf(long ruleId) {
		return jdbcTemplate.queryForObject("SELECT last_processed_date FROM recurring_rule WHERE id = ?",
				LocalDate.class, ruleId);
	}

	private void setEnabled(long ruleId, boolean enabled) {
		jdbcTemplate.update("UPDATE recurring_rule SET enabled = ? WHERE id = ?", enabled ? 1 : 0, ruleId);
	}

	private long familyIdOf(Account account) {
		return jdbcTemplate.queryForObject("SELECT family_id FROM family_member WHERE user_id = ? AND deleted = 0",
				Long.class, account.userId());
	}

}
