package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;

import cn.homeledger.service.RecurringGenerationService;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.2.6 记账统计：区间概览与五块图表，外加 §5.1 的缓存行为。
 * <p>
 * 断言都从 HTTP 进出。统计最容易出错的地方恰好是「六个数字互相自洽但都不对」——五块图各算各的、
 * 缓存命中与未命中各返回一份，只有把请求整条路走完，才看得到用户真正拿到的那串数。
 * <p>
 * 日期一律固定成 2026-01-xx 而不是相对今天算：相对日期会让测试跨月即红。唯一的例外是月度趋势那两条，
 * 它按 {@code Clock} 的当月倒推 12 个月，数据必须落在窗口内，所以那两条用 {@code LocalDate.now()} 构造。
 */
class StatisticsIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	/** 十个各有支出的大类，够把 Top 8 截断与「其他」合并这两件事一次测完。 */
	private static final List<String> TEN_TOP_CATEGORIES = List.of("餐饮", "交通", "购物", "居住", "医疗", "教育",
			"娱乐", "宠物", "宝宝", "人情往来");

	@Autowired
	private RecurringGenerationService generationService;

	@Test
	@DisplayName("验收用例 14 前半：自定义区间的五个数与逐笔手算严格一致")
	void summaryOverACustomRangeMatchesTheRows() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long salary = incomeCategoryId(owner, "工资");
		long cash = paymentAccountId(owner, "现金");
		// 区间 2026-01-15 至 2026-02-20：首尾两天的那两笔在界内，界外的两笔不该被算进来
		record(owner, tx(dining, null, cash, "30.00", "2026-01-10", "区间外支出"));
		record(owner, tx(dining, null, cash, "50.00", "2026-01-15", "首日支出"));
		record(owner, tx(salary, null, cash, "200.00", "2026-02-01", "收入"));
		record(owner, tx(dining, null, cash, "20.00", "2026-02-20", "末日支出"));
		record(owner, tx(dining, null, cash, "99.00", "2026-02-25", "区间外支出"));

		JsonNode data = dataOf(summary(owner, range("2026-01-15", "2026-02-20")));
		assertThat(data.path("startDate").asText()).isEqualTo("2026-01-15");
		assertThat(data.path("endDate").asText()).isEqualTo("2026-02-20");
		assertThat(data.path("days").asInt()).as("含首尾共 37 天").isEqualTo(37);
		assertThat(data.path("income").asText()).isEqualTo("200.00");
		assertThat(data.path("expense").asText()).isEqualTo("70.00");
		assertThat(data.path("balance").asText()).isEqualTo("130.00");
		assertThat(data.path("dailyAverageExpense").asText()).as("70.00 / 37 = 1.8918…").isEqualTo("1.89");
		assertThat(data.path("count").asLong()).isEqualTo(3);
	}

	@Test
	@DisplayName("验收用例 14 后半：跨度 367 天挡成 400")
	void summaryRejectsARangeLongerThan366Days() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Call call = summary(owner, range("2025-01-01", "2026-01-02"));
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.code()).isEqualTo("BAD_REQUEST");
		assertThat(call.message()).contains("366");
	}

	@Test
	@DisplayName("起始日期晚于结束日期挡成 400，而不是静默给一个空区间")
	void summaryRejectsAnInvertedRange() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Call call = summary(owner, range("2026-02-20", "2026-02-01"));
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.code()).isEqualTo("BAD_REQUEST");
		assertThat(call.message()).isEqualTo("起始日期不能晚于结束日期");
	}

	@Test
	@DisplayName("两个日期都不传即全部历史：起于最早那笔、止于今天，且 366 天上限不生效")
	void summaryWithoutDatesCoversAllHistory() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		// 横跨 400 天：同时给出起止日期会被上限挡掉，缺省区间必须照样出数
		record(owner, tx(dining, null, cash, "10.00", "2025-01-01", "最早一笔"));
		record(owner, tx(dining, null, cash, "20.00", "2026-02-05", "较近一笔"));

		JsonNode data = dataOf(summary(owner, Map.of()));
		assertThat(data.path("startDate").asText()).as("起始日取家里第一笔的日期").isEqualTo("2025-01-01");
		assertThat(data.path("endDate").asText()).isEqualTo(LocalDate.now().toString());
		assertThat(data.path("days").asInt())
			.isEqualTo((int) ChronoUnit.DAYS.between(LocalDate.of(2025, 1, 1), LocalDate.now()) + 1);
		assertThat(data.path("count").asLong()).isEqualTo(2);
	}

	@Test
	@DisplayName("刚建好家庭一笔没记：天数为 0、日均为 0.00，不做除零")
	void summaryOnAnEmptyFamilyReportsZeroDays() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode data = dataOf(summary(owner, Map.of()));
		assertThat(data.path("days").asInt()).isEqualTo(0);
		assertThat(data.path("dailyAverageExpense").asText()).isEqualTo("0.00");
		assertThat(data.path("startDate").asText()).isEqualTo(LocalDate.now().toString());
		assertThat(data.path("endDate").asText()).isEqualTo(LocalDate.now().toString());
		for (String field : List.of("income", "expense", "balance")) {
			assertThat(new BigDecimal(data.path(field).asText())).as(field).isEqualByComparingTo(BigDecimal.ZERO);
		}
	}

	@Test
	@DisplayName("/transactions/summary 不被 /transactions/{id} 吃掉")
	void summaryDoesNotCollideWithTheDetailRoute() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Call call = summary(owner, Map.of());
		assertThat(call.status()).as("误入 get(@PathVariable Long id) 会因 Long 转换失败成 400").isEqualTo(200);
		assertThat(call.data().has("count")).isTrue();
	}

	@Test
	@DisplayName("统计页一次拿到五块，且响应里没有预算（§4.2.6：预算恒走 /budgets/progress）")
	void overviewReturnsEveryBlockAtOnce() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		JsonNode data = dataOf(overview(owner, range("2026-01-01", "2026-01-31")));
		for (String block : List.of("categoryBreakdown", "monthlyTrend", "dailyTrend", "accountBreakdown",
				"memberComparison")) {
			assertThat(data.has(block)).as(block).isTrue();
			assertThat(data.path(block).isArray()).as(block).isTrue();
		}
		assertThat(data.toString()).as("预算执行不在这个接口里").doesNotContain("budget");
	}

	@Test
	@DisplayName("月度趋势恒为最近 12 个自然月、升序、缺月补 0（数据按当月相对构造）")
	void monthlyTrendIsAlwaysTwelveZeroFilledMonths() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(dining, null, cash, "30.00", LocalDate.now().withDayOfMonth(1).toString(), "当月"));

		JsonNode trend = dataOf(overview(owner, Map.of())).path("monthlyTrend");
		assertThat(trend).hasSize(12);
		List<String> months = new ArrayList<>();
		trend.forEach(node -> months.add(node.path("month").asText()));
		assertThat(months).isSorted();
		assertThat(months.get(0)).isEqualTo(LocalDate.now().withDayOfMonth(1).minusMonths(11).toString().substring(0, 7));
		assertThat(months.get(11)).isEqualTo(LocalDate.now().toString().substring(0, 7));
		for (int i = 0; i < 11; i++) {
			JsonNode month = trend.get(i);
			assertThat(month.path("income").asText()).as("补 0 必须是 0.00 而不是 0").isEqualTo("0.00");
			assertThat(month.path("expense").asText()).isEqualTo("0.00");
			assertThat(month.path("balance").asText()).isEqualTo("0.00");
			assertThat(month.path("count").asLong()).isZero();
		}
	}

	@Test
	@DisplayName("月度趋势不随时间范围选择器变化（数据按当月相对构造）")
	void monthlyTrendIgnoresTheSelectedRange() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		LocalDate lastMonth = LocalDate.now().withDayOfMonth(1).minusMonths(1);
		record(owner, tx(dining, null, cash, "30.00", lastMonth.withDayOfMonth(5).toString(), "上月"));
		record(owner, tx(dining, null, cash, "50.00", LocalDate.now().withDayOfMonth(2).toString(), "当月"));

		String thisMonth = objectMapper
			.writeValueAsString(dataOf(overview(owner,
					range(LocalDate.now().withDayOfMonth(1).toString(), LocalDate.now().toString())))
				.path("monthlyTrend"));
		String previousMonth = objectMapper
			.writeValueAsString(dataOf(overview(owner,
					range(lastMonth.toString(), lastMonth.withDayOfMonth(lastMonth.lengthOfMonth()).toString())))
				.path("monthlyTrend"));
		assertThat(previousMonth).as("换区间只换其余四块，趋势那份是全家近 12 个月").isEqualTo(thisMonth);
	}

	@Test
	@DisplayName("第 9 个及以后的大类合并成「其他」，且它没有小类可下钻")
	void categoryBreakdownMergesEverythingPastTheTopEightIntoOther() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long cash = paymentAccountId(owner, "现金");
		BigDecimal expectedOther = BigDecimal.ZERO;
		for (int i = 0; i < TEN_TOP_CATEGORIES.size(); i++) {
			// 前八个各 100.00，第九、第十是 90.00 与 80.00，正好落在被合并的那一档
			String amount = i < 8 ? "100.00" : (i == 8 ? "90.00" : "80.00");
			if (i >= 8) {
				expectedOther = expectedOther.add(new BigDecimal(amount));
			}
			record(owner, tx(topCategoryId(owner, TEN_TOP_CATEGORIES.get(i)), null, cash, amount, "2026-01-10",
					"第" + i + "笔"));
		}

		JsonNode breakdown = dataOf(overview(owner, range("2026-01-01", "2026-01-31"))).path("categoryBreakdown");
		assertThat(breakdown).as("八个真大类加一个「其他」").hasSize(9);
		JsonNode other = breakdown.get(8);
		assertThat(other.path("categoryId").isNull()).isTrue();
		assertThat(other.path("name").asText()).isEqualTo("其他");
		assertThat(new BigDecimal(other.path("amount").asText())).isEqualByComparingTo(expectedOther);
		assertThat(other.path("subCategories")).isEmpty();
	}

	@Test
	@DisplayName("类别占比用当前字典名，但最长 60 秒里读到的是旧名（§4.2.6 明确接受）")
	void categoryBreakdownUsesCurrentDictionaryNames() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		record(owner, tx(dining, null, paymentAccountId(owner, "现金"), "30.00", "2026-01-10", "改名前的流水"));
		Map<String, String> params = range("2026-01-01", "2026-01-31");

		assertThat(namesOf(dataOf(overview(owner, params)).path("categoryBreakdown"))).contains("餐饮");
		assertThat(patchJson(CATEGORIES + "/" + dining, Map.of("name", "饭菜"), owner.accessToken()).code())
			.isEqualTo("OK");
		// 改名不挂失效钩子，所以新名要靠 TTL 或缓存被清才看得到。这里手动清一次，是为了断言「统计读的是当前字典」，
		// 而不是「改名会自动刷新统计」——后者不是本项目的承诺
		flushStatsCache();

		JsonNode breakdown = dataOf(overview(owner, params)).path("categoryBreakdown");
		assertThat(namesOf(breakdown)).contains("饭菜");
		assertThat(namesOf(breakdown)).doesNotContain("餐饮");
	}

	@Test
	@DisplayName("下钻：同一父大类下有小类与无小类的各成一片，分母是父大类合计")
	void subCategoryDrillDownGroupsUnsubdividedAmountSeparately() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long cash = paymentAccountId(owner, "现金");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		record(owner, tx(dining, subId(tree, "餐饮", "早餐"), cash, "10.00", "2026-01-10", "a"));
		record(owner, tx(dining, subId(tree, "餐饮", "午餐"), cash, "20.00", "2026-01-11", "b"));
		record(owner, tx(dining, null, cash, "30.00", "2026-01-12", "c"));

		JsonNode breakdown = dataOf(overview(owner, range("2026-01-01", "2026-01-31"))).path("categoryBreakdown");
		JsonNode slice = sliceOf(breakdown, dining);
		JsonNode subs = slice.path("subCategories");
		assertThat(subs).hasSize(3);
		assertThat(new BigDecimal(slice.path("amount").asText())).isEqualByComparingTo("60.00");
		int percentSum = 0;
		for (JsonNode sub : subs) {
			percentSum += sub.path("percent").asInt();
		}
		assertThat(percentSum).as("向下取整，加起来可以小于 100 但不能超过").isLessThanOrEqualTo(100);
		JsonNode unsubdivided = null;
		for (JsonNode sub : subs) {
			if (sub.path("categoryId").isNull()) {
				unsubdivided = sub;
			}
		}
		assertThat(unsubdivided).as("没有小类的那一笔要单列成「未细分」").isNotNull();
		assertThat(unsubdivided.path("name").asText()).isEqualTo("未细分");
		assertThat(new BigDecimal(unsubdivided.path("amount").asText())).isEqualByComparingTo("30.00");
		assertThat(unsubdivided.path("percent").asInt()).as("30 / 60 的父大类占比").isEqualTo(50);
	}

	@Test
	@DisplayName("每日支出把区间内每一天补 0，前端不必自己算这个月有几天")
	void dailyTrendZeroFillsEveryDay() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(dining, null, cash, "10.00", "2026-01-02", "有支出"));
		record(owner, tx(dining, null, cash, "20.00", "2026-01-04", "有支出"));

		JsonNode daily = dataOf(overview(owner, range("2026-01-01", "2026-01-05"))).path("dailyTrend");
		assertThat(daily).hasSize(5);
		assertThat(datesOf(daily)).containsExactly("2026-01-01", "2026-01-02", "2026-01-03", "2026-01-04",
				"2026-01-05");
		assertThat(daily.get(0).path("expense").asText()).isEqualTo("0.00");
		assertThat(daily.get(1).path("expense").asText()).isEqualTo("10.00");
		assertThat(daily.get(2).path("expense").asText()).isEqualTo("0.00");
		assertThat(daily.get(4).path("expense").asText()).isEqualTo("0.00");
	}

	@Test
	@DisplayName("支付方式占比不做 Top N 截断，所以不会出现「其他」那一项")
	void accountBreakdownIsNotTruncated() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		List<String> accounts = List.of("现金", "微信", "支付宝", "储蓄卡");
		for (int i = 0; i < accounts.size(); i++) {
			record(owner, tx(dining, null, paymentAccountId(owner, accounts.get(i)), (10 + i) + ".00", "2026-01-10",
					"账户" + i));
		}

		JsonNode breakdown = dataOf(overview(owner, range("2026-01-01", "2026-01-31"))).path("accountBreakdown");
		assertThat(breakdown).hasSize(4);
		for (JsonNode slice : breakdown) {
			assertThat(slice.path("accountId").isNull()).as("没有合并出来的「其他」档").isFalse();
			assertThat(accounts).contains(slice.path("name").asText());
		}
	}

	@Test
	@DisplayName("验收用例 15 后半：移出家庭的成员仍在成员对比里，名字取移出时的快照")
	void memberComparisonIncludesDepartedMembers() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner);
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		record(member, tx(dining, null, cash, "40.00", "2026-01-10", "李四记的"));
		// 张三也得记一笔：成员对比从各人的支出行聚合而来，零支出的人本来就不在图上
		record(owner, tx(dining, null, cash, "25.00", "2026-01-08", "张三记的"));

		// 移出时 markLeft 会把当下的昵称写进快照；移出后再改的名字不该回溯到这张图上
		assertThat(patchJson(USERS_ME, Map.of("nickname", "李四改名"), member.accessToken()).code()).isEqualTo("OK");
		assertThat(deleteNoBody(FAMILIES + "/current/members/" + member.userId(), owner.accessToken()).code())
			.isEqualTo("OK");
		Account departed = secondDevice(member);
		assertThat(patchJson(USERS_ME, Map.of("nickname", "移出后又改"), departed.accessToken()).code())
			.isEqualTo("OK");

		JsonNode comparison = dataOf(overview(owner, range("2026-01-01", "2026-01-31"))).path("memberComparison");
		assertThat(nicknamesOf(comparison)).as("图上是他离开那一刻叫什么").containsExactlyInAnyOrder("张三", "李四改名");
		assertThat(sum(comparison, "total")).isEqualByComparingTo("65.00");
	}

	@Test
	@DisplayName("验收用例 15 的等式：各成员支出合计相加等于类别占比的支出合计")
	void memberTotalsAddUpToTheCategoryTotal() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner);
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		recordSample(owner);
		record(member, tx(topCategoryId(member, "交通"), null, paymentAccountId(member, "微信"), "66.60", "2026-01-13",
				"李四的支出"));

		JsonNode data = dataOf(overview(owner, range("2026-01-01", "2026-01-31")));
		BigDecimal fromMembers = sum(data.path("memberComparison"), "total");
		BigDecimal fromCategories = sum(data.path("categoryBreakdown"), "amount");
		assertThat(fromMembers).as("宁可多画几根柱子，也不能让两个合计数对不上").isEqualByComparingTo(fromCategories);
	}

	@Test
	@DisplayName("成员的 byCategory 与类别占比逐项对齐（前端按下标取颜色）")
	void byCategoryAlignsWithCategoryBreakdown() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long cash = paymentAccountId(owner, "现金");
		for (String name : TEN_TOP_CATEGORIES) {
			record(owner, tx(topCategoryId(owner, name), null, cash, "10.00", "2026-01-10", name));
		}

		JsonNode data = dataOf(overview(owner, range("2026-01-01", "2026-01-31")));
		JsonNode breakdown = data.path("categoryBreakdown");
		assertThat(breakdown).hasSize(9);
		for (JsonNode member : data.path("memberComparison")) {
			JsonNode byCategory = member.path("byCategory");
			assertThat(byCategory).as("同长度").hasSize(breakdown.size());
			for (int i = 0; i < breakdown.size(); i++) {
				assertThat(idOrNullOrText(byCategory.get(i))).as("同下标同 categoryId，含末尾那个 null 档")
					.isEqualTo(idOrNullOrText(breakdown.get(i)));
			}
		}
	}

	@Test
	@DisplayName("验收用例 15 前半：按记录人筛选时概览与四张图一起收窄")
	void recorderFilterNarrowsEveryBlock() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner);
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(dining, null, cash, "30.00", "2026-01-10", "张三的"));
		record(member, tx(dining, null, cash, "70.00", "2026-01-11", "李四的"));

		Map<String, String> filtered = rangeWith("createdBy", String.valueOf(owner.userId()), "2026-01-01",
				"2026-01-31");
		JsonNode data = dataOf(overview(owner, filtered));
		assertThat(data.path("dailyTrend").toString()).doesNotContain("70.00");
		assertThat(sum(data.path("categoryBreakdown"), "amount")).isEqualByComparingTo("30.00");
		assertThat(sum(data.path("accountBreakdown"), "amount")).isEqualByComparingTo("30.00");
		JsonNode comparison = data.path("memberComparison");
		assertThat(comparison).as("成员对比也只剩被筛的那个人").hasSize(1);
		assertThat(comparison.get(0).path("userId").asLong()).isEqualTo(owner.userId());

		JsonNode summaryData = dataOf(summary(owner, filtered));
		assertThat(summaryData.path("expense").asText()).isEqualTo("30.00");
		assertThat(summaryData.path("count").asLong()).isEqualTo(1);
	}

	@Test
	@DisplayName("§5.1：同条件连查两次，命中缓存的那次与未命中逐字段相同")
	void secondReadWithinTheTtlIsIdentical() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		Map<String, String> params = range("2026-01-01", "2026-01-31");
		String first = objectMapper.writeValueAsString(dataOf(overview(owner, params)));
		assertThat(objectMapper.writeValueAsString(dataOf(overview(owner, params)))).as("第二次走的是缓存")
			.isEqualTo(first);
	}

	@Test
	@DisplayName("§5.1：条件相同但参数顺序不同，只占一个缓存键")
	void sameConditionsInDifferentParameterOrderShareOneCacheKey() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		long familyId = familyIdOf(owner);
		summaryRaw(owner, "startDate", "2026-01-01", "endDate", "2026-01-31");
		summaryRaw(owner, "endDate", "2026-01-31", "startDate", "2026-01-01");
		assertThat(redis.keys("stats:fin:summary:" + familyId + ":*")).as("两个键就说明指纹把参数顺序算了进去").hasSize(1);
	}

	@Test
	@DisplayName("记一笔让统计缓存读不到：版本号从不存在涨到 1")
	void writingATransactionInvalidatesTheCache() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long familyId = familyIdOf(owner);
		Map<String, String> params = range("2026-01-01", "2026-01-31");
		assertThat(dataOf(summary(owner, params)).path("count").asLong()).isZero();
		assertThat(redis.opsForValue().get("stats:ver:fin:" + familyId)).as("只读不建版本号键").isNull();

		record(owner, tx(topCategoryId(owner, "餐饮"), null, paymentAccountId(owner, "现金"), "30.00", "2026-01-10",
				"第一笔"));
		assertThat(redis.opsForValue().get("stats:ver:fin:" + familyId)).as("写操作只 INCR 版本号").isEqualTo("1");
		assertThat(dataOf(summary(owner, params)).path("count").asLong()).as("旧键已经读不到").isEqualTo(1);
	}

	@Test
	@DisplayName("编辑与删除同样让统计缓存读不到")
	void editingAndDeletingInvalidateTheCache() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		long first = recordId(owner, tx(dining, null, cash, "30.00", "2026-01-10", "待编辑"));
		record(owner, tx(dining, null, cash, "20.00", "2026-01-11", "待删除"));
		Map<String, String> params = range("2026-01-01", "2026-01-31");
		assertThat(dataOf(summary(owner, params)).path("expense").asText()).isEqualTo("50.00");

		assertThat(patchJson(TRANSACTIONS + "/" + first,
				Map.of("amount", "80.00", "categoryId", dining, "accountId", cash, "bizDate", "2026-01-10"),
				owner.accessToken()).code()).isEqualTo("OK");
		assertThat(dataOf(summary(owner, params)).path("expense").asText()).as("编辑后是 80 + 20").isEqualTo("100.00");

		assertThat(deleteNoBody(TRANSACTIONS + "/" + first, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(dataOf(summary(owner, params)).path("expense").asText()).as("删除后只剩 20").isEqualTo("20.00");
	}

	@Test
	@DisplayName("周期记账生成的流水也让统计缓存读不到")
	void recurringGenerationInvalidatesTheCache() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long familyId = familyIdOf(owner);
		Map<String, String> params = range("2026-01-01", "2026-01-31");
		assertThat(dataOf(summary(owner, params)).path("count").asLong()).isZero();

		seedDailyRule(owner, familyId, LocalDate.of(2026, 1, 15));
		assertThat(generationService.runFor(LocalDate.of(2026, 1, 15))).isEqualTo(1);
		assertThat(redis.opsForValue().get("stats:ver:fin:" + familyId)).as("一次执行只 INCR 一次").isEqualTo("1");
		assertThat(dataOf(summary(owner, params)).path("count").asLong()).as("自动生成的那笔要算进来").isEqualTo(1);
	}

	@Test
	@DisplayName("反向断言：字典改名不挂失效钩子，统计最长 60 秒读到旧名")
	void renamingACategoryDoesNotInvalidateTheCache() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		record(owner, tx(dining, null, paymentAccountId(owner, "现金"), "30.00", "2026-01-10", "旧名流水"));
		Map<String, String> params = range("2026-01-01", "2026-01-31");
		assertThat(namesOf(dataOf(overview(owner, params)).path("categoryBreakdown"))).contains("餐饮");

		assertThat(patchJson(CATEGORIES + "/" + dining, Map.of("name", "饭菜"), owner.accessToken()).code())
			.isEqualTo("OK");
		JsonNode after = dataOf(overview(owner, params));
		assertThat(namesOf(after.path("categoryBreakdown"))).as("失效面就是流水的四个写入处，别顺手扩到改名上")
			.contains("餐饮")
			.doesNotContain("饭菜");
	}

	@Test
	@DisplayName("没有家庭的账号问不到任何统计")
	void statisticsRequireAFamily() throws Exception {
		Account lonely = register(PHONE_A, "独居者");
		assertThat(summary(lonely, Map.of()).status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(summary(lonely, Map.of()).code()).isEqualTo("NO_FAMILY");
		assertThat(overview(lonely, Map.of()).status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(overview(lonely, Map.of()).code()).isEqualTo("NO_FAMILY");
	}

	@Test
	@DisplayName("§5.2：甲家的统计里不含乙家那笔")
	void statisticsNeverLeakAcrossFamilies() throws Exception {
		Account zhang = registerWithFamily(PHONE_A, "张三");
		Account other = registerWithFamily(PHONE_OTHER, "王五");
		record(zhang,
				tx(topCategoryId(zhang, "餐饮"), null, paymentAccountId(zhang, "现金"), "30.00", "2026-01-10", "甲家"));
		record(other, tx(topCategoryId(other, "购物"), null, paymentAccountId(other, "微信"), "900.00", "2026-01-11",
				"乙家"));
		Map<String, String> params = range("2026-01-01", "2026-01-31");

		assertThat(dataOf(summary(zhang, params)).path("expense").asText()).isEqualTo("30.00");
		JsonNode data = dataOf(overview(zhang, params));
		assertThat(data.toString()).as("五块里都不该出现乙家的 900.00").doesNotContain("900.00");
		assertThat(sum(data.path("memberComparison"), "total")).isEqualByComparingTo("30.00");
	}

	// ---- 前置数据 ----

	/** 一个家庭两笔支出加一笔收入，够五块图各出一点数。 */
	private void recordSample(Account owner) throws Exception {
		long cash = paymentAccountId(owner, "现金");
		JsonNode tree = tree(owner, "EXPENSE");
		record(owner, tx(topId(tree, "餐饮"), subId(tree, "餐饮", "午餐"), cash, "30.00", "2026-01-10", "样本一"));
		record(owner, tx(topId(tree, "交通"), null, paymentAccountId(owner, "微信"), "20.00", "2026-01-12", "样本二"));
		record(owner, tx(incomeCategoryId(owner, "工资"), null, cash, "500.00", "2026-01-05", "样本收入"));
	}

	/**
	 * 直接写一行规则，不走 POST /recurring-rules：建规则的接口按 A4 会当场补跑一次，
	 * 那一跑就把失效钩子触发了，测不出「生成引擎自己让缓存读不到」。
	 * 游标钉在 start_date 前一天，等于「这条规则刚从没跑过」。
	 */
	private void seedDailyRule(Account owner, long familyId, LocalDate startDate) throws Exception {
		jdbcTemplate.update("INSERT INTO recurring_rule (id, family_id, name, type, amount, category_id, account_id,"
				+ " period_type, period_value, start_date, enabled, last_processed_date, created_by)"
				+ " VALUES (?, ?, '自动记账', 'EXPENSE', 100.00, ?, ?, 'DAILY', '{\"intervalDays\":1}', ?, 1, ?, ?)",
				IdWorker.getId(), familyId, topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"), startDate,
				startDate.minusDays(1), owner.userId());
	}

	// ---- HTTP 辅助 ----

	private Call summary(Account account, Map<String, String> params) throws Exception {
		return getJson(TRANSACTION_SUMMARY, params, account.accessToken());
	}

	private Call overview(Account account, Map<String, String> params) throws Exception {
		return getJson(STATISTICS_OVERVIEW, params, account.accessToken());
	}

	/** 参数顺序本身要被断言，所以这里绕开 getJson 的 Map（Map.of 按哈希排，传两次的顺序是同一个）。 */
	private void summaryRaw(Account account, String... keyValues) throws Exception {
		MockHttpServletRequestBuilder builder = get(TRANSACTION_SUMMARY);
		for (int i = 0; i < keyValues.length; i += 2) {
			builder.param(keyValues[i], keyValues[i + 1]);
		}
		MvcResult result = mockMvc.perform(builder
			.header(HttpHeaders.AUTHORIZATION, "Bearer " + account.accessToken())).andReturn();
		assertThat(result.getResponse().getStatus()).isEqualTo(200);
	}

	private void flushStatsCache() {
		Set<String> keys = redis.keys("stats:*");
		if (keys != null && !keys.isEmpty()) {
			redis.delete(keys);
		}
	}

	private Map<String, String> range(String start, String end) {
		return Map.of("startDate", start, "endDate", end);
	}

	private Map<String, String> rangeWith(String key, String value, String start, String end) {
		return Map.of(key, value, "startDate", start, "endDate", end);
	}

	private Call record(Account account, Map<String, Object> payload) throws Exception {
		Call call = postJson(TRANSACTIONS, payload, account.accessToken());
		assertThat(call.code()).as("记一笔 %s", payload).isEqualTo("OK");
		return call;
	}

	private long recordId(Account account, Map<String, Object> payload) throws Exception {
		return record(account, payload).data().path("id").asLong();
	}

	private static Map<String, Object> tx(long categoryId, Long subCategoryId, long accountId, String amount,
			String bizDate, String remark) {
		Map<String, Object> payload = new LinkedHashMap<>();
		payload.put("amount", amount);
		payload.put("categoryId", categoryId);
		if (subCategoryId != null) {
			payload.put("subCategoryId", subCategoryId);
		}
		payload.put("accountId", accountId);
		payload.put("bizDate", bizDate);
		payload.put("remark", remark);
		return payload;
	}

	// ---- 取值辅助 ----

	private JsonNode tree(Account account, String type) throws Exception {
		Call call = getJson(CATEGORIES + "?type=" + type + "&enabledOnly=false", account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private long topId(JsonNode tree, String name) {
		for (JsonNode node : tree) {
			if (node.path("name").asText().equals(name)) {
				return node.path("id").asLong();
			}
		}
		throw new AssertionError("类别树里应有大类 " + name);
	}

	private long subId(JsonNode tree, String topName, String subName) {
		for (JsonNode node : tree) {
			if (node.path("name").asText().equals(topName)) {
				for (JsonNode child : node.path("children")) {
					if (child.path("name").asText().equals(subName)) {
						return child.path("id").asLong();
					}
				}
			}
		}
		throw new AssertionError("大类 " + topName + " 下应有小类 " + subName);
	}

	private long incomeCategoryId(Account account, String name) throws Exception {
		return topId(tree(account, "INCOME"), name);
	}

	private long familyIdOf(Account account) {
		return jdbcTemplate.queryForObject("SELECT family_id FROM family_member WHERE user_id = ? AND deleted = 0",
				Long.class, account.userId());
	}

	private JsonNode dataOf(Call call) {
		assertThat(call.code()).as("响应 %s", call.json()).isEqualTo("OK");
		return call.data();
	}

	/** categoryId 为 null 的那一档（「其他」「未细分」）统一成同一个串，好让两边逐项比对。 */
	private String idOrNullOrText(JsonNode node) {
		return node.path("categoryId").isNull() ? "null" : node.path("categoryId").asText();
	}

	private JsonNode sliceOf(JsonNode breakdown, long categoryId) {
		for (JsonNode slice : breakdown) {
			if (slice.path("categoryId").asLong() == categoryId) {
				return slice;
			}
		}
		throw new AssertionError("类别占比里应有大类 " + categoryId);
	}

	private List<String> namesOf(JsonNode slices) {
		List<String> names = new ArrayList<>();
		slices.forEach(node -> names.add(node.path("name").asText()));
		return names;
	}

	private List<String> nicknamesOf(JsonNode slices) {
		List<String> names = new ArrayList<>();
		slices.forEach(node -> names.add(node.path("nickname").asText()));
		return names;
	}

	private List<String> datesOf(JsonNode points) {
		List<String> dates = new ArrayList<>();
		points.forEach(node -> dates.add(node.path("date").asText()));
		return dates;
	}

	private BigDecimal sum(JsonNode nodes, String field) {
		BigDecimal total = BigDecimal.ZERO;
		for (JsonNode node : nodes) {
			total = total.add(new BigDecimal(node.path(field).asText()));
		}
		return total;
	}

}
