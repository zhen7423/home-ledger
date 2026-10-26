package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
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
 * §4.2.1 记一笔 + §4.2.5 流水列表。
 * <p>
 * 断言几乎都从 HTTP 进出而不是直接点 Service：租户隔离、名称快照、分页计数这几件事，只有把「请求进来 →
 * 响应出去」整条路走完才算被证明。分页那组租户断言最值得看——列表内容看着对，total 却把别家算了进来，
 * 这种错只有两个家庭同时有数据时才现形，平时点界面永远发现不了。
 */
class TransactionFlowIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	@Test
	@DisplayName("验收用例 2：张三记的一笔，同家庭的李四在列表里看得到，记录人显示张三的昵称")
	void membersShareOneLedger() throws Exception {
		Account zhang = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(zhang);
		Account li = register(PHONE_B, "李四");
		inviteAndJoin(zhang, li);

		JsonNode tree = tree(zhang, "EXPENSE");
		long zhangRow = recordId(zhang,
				tx(topId(tree, "餐饮"), subId(tree, "餐饮", "午餐"), accountId(zhang, "微信"), "38.50", "2026-09-01",
						"team-lunch"));

		List<JsonNode> seen = recordsOf(query(li, ""));
		assertThat(remarks(seen)).as("家庭里只有一本流水，不分谁记的").containsExactly("team-lunch");
		JsonNode row = seen.get(0);
		assertThat(row.path("id").asLong()).isEqualTo(zhangRow);
		assertThat(row.path("recorderName").asText()).isEqualTo("张三");
		assertThat(row.path("createdBy").asLong()).as("记录人由服务端从登录态取").isEqualTo(zhang.userId());
		assertThat(row.path("type").asText()).isEqualTo("EXPENSE");
		assertThat(row.path("categoryName").asText()).isEqualTo("餐饮");
		assertThat(row.path("subCategoryName").asText()).isEqualTo("午餐");
		assertThat(row.path("accountName").asText()).isEqualTo("微信");
		assertThat(row.path("amount").isTextual()).as("金额按字符串收发，别让浮点丢精度").isTrue();
		assertThat(row.path("amount").asText()).isEqualTo("38.50");
	}

	@Test
	@DisplayName("验收用例 3：李四退出家庭，他记的那笔仍留在张三的列表里，记录人显示李四的昵称快照")
	void historyOutlivesTheMemberWhoRecordedIt() throws Exception {
		Account zhang = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(zhang);
		Account li = register(PHONE_B, "李四");
		inviteAndJoin(zhang, li);

		JsonNode tree = tree(zhang, "EXPENSE");
		long id = recordId(li,
				tx(topId(tree, "餐饮"), null, accountId(zhang, "现金"), "20.00", "2026-08-11", "李四代记"));

		assertThat(postJson(FAMILIES + "/current/leave", Map.of(), li.accessToken()).code()).isEqualTo("OK");

		List<JsonNode> seen = recordsOf(query(zhang, ""));
		assertThat(remarks(seen)).as("退人不带走也不抹掉历史流水").containsExactly("李四代记");
		assertThat(seen.get(0).path("recorderName").asText()).as("快照不是现查成员表，退出了也不会变空白").isEqualTo("李四");
		assertThat(seen.get(0).path("createdBy").asLong()).isEqualTo(li.userId());
		assertThat(getJson(TRANSACTIONS + "/" + id, zhang.accessToken()).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("验收用例 6：张三拿别家某条流水的准确 id 来改，404 且那条流水一字未动")
	void rowsOfAnotherFamilyCannotBeTouched() throws Exception {
		Account zhang = registerWithFamily(PHONE_A, "张三");
		Account wang = registerWithFamily(PHONE_OTHER, "王五");

		JsonNode wangTree = tree(wang, "EXPENSE");
		long wangId = recordId(wang,
				tx(topId(wangTree, "交通"), null, accountId(wang, "微信"), "66.00", "2026-09-02", "王五的"));

		JsonNode zhangTree = tree(zhang, "EXPENSE");
		Map<String, Object> tamper = tx(topId(zhangTree, "餐饮"), null, accountId(zhang, "现金"), "1.00", "2026-09-02",
				"被篡改");
		Call patched = patchJson(TRANSACTIONS + "/" + wangId, tamper, zhang.accessToken());
		assertThat(patched.status()).as("越权按不存在处理，不承认这行存在").isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(patched.code()).isEqualTo("TRANSACTION_NOT_FOUND");
		assertThat(getJson(TRANSACTIONS + "/" + wangId, zhang.accessToken()).code()).isEqualTo("TRANSACTION_NOT_FOUND");
		assertThat(deleteNoBody(TRANSACTIONS + "/" + wangId, zhang.accessToken()).code())
			.isEqualTo("TRANSACTION_NOT_FOUND");

		List<JsonNode> rows = recordsOf(query(wang, ""));
		assertThat(remarks(rows)).as("被攻击的那行数据没被动过").containsExactly("王五的");
		assertThat(rows.get(0).path("amount").asText()).isEqualTo("66.00");
		assertThat(rows.get(0).path("categoryName").asText()).isEqualTo("交通");
	}

	@Test
	@DisplayName("分页的租户正确性：两家各 40 条，甲查 size=30 时 total 必须是 40 而不是 80、pages 必须是 2 而不是 3")
	void pagingCountsOnlyTheCurrentFamily() throws Exception {
		Account zhang = registerWithFamily(PHONE_A, "张三");
		Account wang = registerWithFamily(PHONE_OTHER, "王五");
		seedFortyExpenses(zhang, "jia");
		seedFortyExpenses(wang, "yi");

		Call first = query(zhang, "page=1&size=30");
		assertThat(first.data().path("total").asLong()).as("total 只能数本家").isEqualTo(40);
		assertThat(first.data().path("pages").asLong()).isEqualTo(2);
		assertThat(recordsOf(first)).as("当前页仍是 30 条，没有把别家的挤进来").hasSize(30);

		Call second = query(zhang, "page=2&size=30");
		List<String> all = new ArrayList<>(remarks(recordsOf(first)));
		all.addAll(remarks(recordsOf(second)));
		assertThat(all).as("两页拼起来正好是自己那 40 条，一条不漏也不重复").hasSize(40);
		assertThat(all).contains("jia0", "jia39");
		assertThat(all).as("一条别家的都没混进来").noneMatch(remark -> remark.startsWith("yi"));
		assertThat(toList(second.data().path("monthSummaries")))
			.as("月度小计按全量算，翻页时它一个字都不该变").isEqualTo(toList(first.data().path("monthSummaries")));
	}

	@Test
	@DisplayName("月度小计是整套筛选条件下的全量聚合，不是当前页那几条的小结")
	void monthSummariesCoverEverythingTheFilterMatches() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long cash = accountId(owner, "现金");
		for (int i = 0; i < 8; i++) {
			record(owner, tx(dining, null, cash, "10.00", LocalDate.of(2026, 7, 1).plusDays(i).toString(), "七月"));
		}
		for (int i = 0; i < 7; i++) {
			record(owner, tx(dining, null, cash, "20.00", LocalDate.of(2026, 8, 1).plusDays(i).toString(), "八月"));
		}

		Call call = query(owner, "page=1&size=5");
		assertThat(call.data().path("total").asLong()).isEqualTo(15);
		List<JsonNode> summaries = toList(call.data().path("monthSummaries"));
		assertThat(summaries).as("月份倒序").extracting(node -> node.path("month").asText())
			.containsExactly("2026-08", "2026-07");
		assertThat(summaries.get(0).path("count").asLong()).as("当前页只给了 5 条，小计仍要数满 7 条").isEqualTo(7);
		assertThat(summaries.get(0).path("expense").asText()).isEqualTo("140.00");
		assertThat(summaries.get(1).path("count").asLong()).isEqualTo(8);
		assertThat(summaries.get(1).path("expense").asText()).isEqualTo("80.00");
	}

	@Test
	@DisplayName("改一个筛选条件，月度小计跟着变；结余始终等于收入减支出")
	void monthSummariesFollowTheFilter() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode expenseTree = tree(owner, "EXPENSE");
		JsonNode incomeTree = tree(owner, "INCOME");
		long cash = accountId(owner, "现金");
		record(owner, tx(topId(expenseTree, "餐饮"), null, cash, "12.00", "2026-09-03", "支出"));
		record(owner, tx(topId(expenseTree, "交通"), null, cash, "8.00", "2026-09-04", "支出"));
		record(owner, tx(topId(incomeTree, "工资"), null, cash, "500.00", "2026-09-05", "收入"));

		List<JsonNode> all = toList(query(owner, "").data().path("monthSummaries"));
		assertThat(all).hasSize(1);
		assertThat(all.get(0).path("income").asText()).isEqualTo("500.00");
		assertThat(all.get(0).path("expense").asText()).isEqualTo("20.00");
		assertThat(all.get(0).path("balance").asText()).as("结余与收支出自同一次扫描，三者不会自相矛盾").isEqualTo("480.00");
		assertThat(all.get(0).path("count").asLong()).isEqualTo(3);

		List<JsonNode> onlyExpense = toList(query(owner, "type=EXPENSE").data().path("monthSummaries"));
		assertThat(onlyExpense).hasSize(1);
		assertThat(new BigDecimal(onlyExpense.get(0).path("income").asText())).as("只看支出时收入项归零")
			.isEqualByComparingTo(BigDecimal.ZERO);
		assertThat(onlyExpense.get(0).path("expense").asText()).isEqualTo("20.00");
		assertThat(onlyExpense.get(0).path("balance").asText()).as("只有支出时结余是负的").isEqualTo("-20.00");
		assertThat(onlyExpense.get(0).path("count").asLong()).isEqualTo(2);

		List<JsonNode> lateSeptember = toList(query(owner, "startDate=2026-09-04").data().path("monthSummaries"));
		assertThat(lateSeptember.get(0).path("count").asLong()).as("日期区间同样作用于小计").isEqualTo(2);
		assertThat(lateSeptember.get(0).path("income").asText()).isEqualTo("500.00");
	}

	@Test
	@DisplayName("A3 快照冻结：记完一笔再把类别改名，历史流水显示的还是改名前的名字")
	void renamingACategoryLeavesHistoryAlone() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long lunch = subId(tree, "餐饮", "午餐");
		long cash = accountId(owner, "现金");
		record(owner, tx(dining, lunch, cash, "9.00", "2026-09-01", "改名前记的"));

		assertThat(patchJson(CATEGORIES + "/" + dining, Map.of("name", "外食"), owner.accessToken()).code()).isEqualTo("OK");

		JsonNode history = recordsOf(query(owner, "")).get(0);
		assertThat(history.path("categoryName").asText()).as("改名不回溯历史").isEqualTo("餐饮");
		assertThat(history.path("subCategoryName").asText()).isEqualTo("午餐");

		record(owner, tx(topId(tree(owner, "EXPENSE"), "外食"), null, cash, "9.00", "2026-09-02", "改名后记的"));
		assertThat(categoryNames(recordsOf(query(owner, "")))).as("新记的那笔才用得上新名字").containsExactly("外食", "餐饮");
	}

	@Test
	@DisplayName("编辑时只有换了类别或账户才刷新对应快照，记录人连改昵称都不回溯")
	void snapshotsRefreshOnlyForWhatActuallyChanged() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long bus = topId(tree, "交通");
		long taxi = subId(tree, "交通", "打车");
		long wechat = accountId(owner, "微信");
		long cash = accountId(owner, "现金");
		long id = recordId(owner, tx(dining, null, wechat, "15.00", "2026-08-08", "先备注再说"));

		patchJson(TRANSACTIONS + "/" + id, tx(dining, null, wechat, "15.00", "2026-08-08", "改过的备注"),
				owner.accessToken());
		JsonNode afterRemark = dataOf(getJson(TRANSACTIONS + "/" + id, owner.accessToken()));
		assertThat(afterRemark.path("remark").asText()).isEqualTo("改过的备注");
		assertThat(afterRemark.path("categoryName").asText()).as("没换类别就不该重新取名").isEqualTo("餐饮");
		assertThat(afterRemark.path("accountName").asText()).as("没换支付方式就不该重新取名").isEqualTo("微信");
		assertThat(afterRemark.path("recorderName").asText()).isEqualTo("张三");

		patchJson(USERS_ME, Map.of("nickname", "张三丰"), owner.accessToken());
		assertThat(dataOf(getJson(TRANSACTIONS + "/" + id, owner.accessToken())).path("recorderName").asText())
			.as("成员改了昵称不该改写历史流水上的记录人").isEqualTo("张三");

		Call switched = patchJson(TRANSACTIONS + "/" + id, tx(bus, taxi, wechat, "15.00", "2026-08-08", "改过的备注"),
				owner.accessToken());
		assertThat(switched.code()).isEqualTo("OK");
		assertThat(switched.data().path("categoryName").asText()).isEqualTo("交通");
		assertThat(switched.data().path("subCategoryName").asText()).isEqualTo("打车");
		assertThat(switched.data().path("accountName").asText()).isEqualTo("微信");

		Call paidByCash = patchJson(TRANSACTIONS + "/" + id, tx(bus, taxi, cash, "15.00", "2026-08-08", "改过的备注"),
				owner.accessToken());
		assertThat(paidByCash.data().path("accountName").asText()).isEqualTo("现金");
		assertThat(paidByCash.data().path("categoryName").asText()).as("只换账户时类别快照不动").isEqualTo("交通");

		Call cleared = patchJson(TRANSACTIONS + "/" + id, tx(bus, null, cash, "15.00", "2026-08-08", "只留大类"),
				owner.accessToken());
		assertThat(cleared.data().path("subCategoryId").isNull()).isTrue();
		assertThat(cleared.data().path("subCategoryName").isNull()).isTrue();
	}

	@Test
	@DisplayName("停用类别不能再用于新记录，但挂在它下面的历史流水照样能只改备注保存")
	void disabledCategoryBlocksNewRecordsNotHistoryEdits() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long lunch = subId(tree, "餐饮", "午餐");
		long takeaway = subId(tree, "餐饮", "外卖");
		long bus = topId(tree, "交通");
		long cash = accountId(owner, "现金");
		long id = recordId(owner, tx(dining, lunch, cash, "9.00", "2026-08-30", "停用之前记的"));

		assertThat(patchJson(CATEGORIES + "/" + dining + "/toggle", Map.of(), owner.accessToken()).code()).isEqualTo("OK");

		assertThat(postJson(TRANSACTIONS, tx(dining, null, cash, "9.00", "2026-09-01", "停用之后记的"), owner.accessToken())
			.code()).isEqualTo("CATEGORY_DISABLED");
		assertThat(postJson(TRANSACTIONS, tx(dining, lunch, cash, "9.00", "2026-09-01", "停用之后记的"), owner.accessToken())
			.code()).as("连大类带小类一起给，也还是被大类挡住").isEqualTo("CATEGORY_DISABLED");

		Call edit = patchJson(TRANSACTIONS + "/" + id, tx(dining, lunch, cash, "9.00", "2026-08-30", "只是补个备注"),
				owner.accessToken());
		assertThat(edit.code()).as("没换类别就放行，否则用户连备注都改不了").isEqualTo("OK");
		assertThat(edit.data().path("remark").asText()).isEqualTo("只是补个备注");
		assertThat(edit.data().path("categoryName").asText()).as("放行时也不趁机刷新快照").isEqualTo("餐饮");

		assertThat(postJson(TRANSACTIONS, tx(bus, null, cash, "9.00", "2026-09-01", "启用中的"), owner.accessToken()).code())
			.as("同家庭里其他启用中的类别不受影响").isEqualTo("OK");

		// 停用大类把它下面每个小类一起停了，重新启用大类不会把它们带回来（§4.2.2）
		patchJson(CATEGORIES + "/" + dining + "/toggle", Map.of(), owner.accessToken());
		assertThat(postJson(TRANSACTIONS, tx(dining, lunch, cash, "9.00", "2026-09-01", "小类自己停用"),
				owner.accessToken()).code()).as("大类已启用但小类还是停用，照样要拒").isEqualTo("CATEGORY_DISABLED");

		patchJson(CATEGORIES + "/" + takeaway + "/toggle", Map.of(), owner.accessToken());
		assertThat(postJson(TRANSACTIONS, tx(dining, takeaway, cash, "9.00", "2026-09-01", "同级启用中的小类"),
				owner.accessToken()).code()).as("单独启用回来的小类立刻可用").isEqualTo("OK");
	}

	@Test
	@DisplayName("挂在已停用大类下的历史流水，不改大类只清空小类也要能保存")
	void clearingSubCategoryOnDisabledParentIsAllowed() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long lunch = subId(tree, "餐饮", "午餐");
		long cash = accountId(owner, "现金");
		long id = recordId(owner, tx(dining, lunch, cash, "9.00", "2026-08-30", "停用之前记的"));

		// 停用大类会级联停用小类，此刻大类与小类都是停用态
		assertThat(patchJson(CATEGORIES + "/" + dining + "/toggle", Map.of(), owner.accessToken()).code()).isEqualTo("OK");

		// 大类未变，只把小类改回「未细分」：大类启用校验只应由「换了大类」触发，否则这笔编辑会被误拒
		Call cleared = patchJson(TRANSACTIONS + "/" + id, tx(dining, null, cash, "9.00", "2026-08-30", "把小类清掉"),
				owner.accessToken());
		assertThat(cleared.code()).as("没换大类，只是清掉小类，不该被停用的大类挡住").isEqualTo("OK");
		assertThat(cleared.data().path("subCategoryId").isNull()).isTrue();
		assertThat(cleared.data().path("categoryName").asText()).as("没换大类就不刷新快照").isEqualTo("餐饮");
		assertThat(cleared.data().path("remark").asText()).isEqualTo("把小类清掉");
	}

	@Test
	@DisplayName("停用的支付方式不能再用于新记录，历史流水还是照样显示它当时的名称")
	void disabledAccountIsNotUsableForNewRecords() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long credit = accountId(owner, "信用卡");
		record(owner, tx(dining, null, credit, "30.00", "2026-08-20", "停用之前记的"));

		patchJson(PAYMENT_ACCOUNTS + "/" + credit + "/toggle", Map.of(), owner.accessToken());

		Call blocked = postJson(TRANSACTIONS, tx(dining, null, credit, "30.00", "2026-09-01", "停用之后记的"),
				owner.accessToken());
		assertThat(blocked.code()).as("支付方式停用没有专用错误码，但文案要说清是谁").isEqualTo("BAD_REQUEST");
		assertThat(blocked.message()).contains("支付方式");

		List<JsonNode> seen = recordsOf(query(owner, ""));
		assertThat(remarks(seen)).containsExactly("停用之前记的");
		assertThat(seen.get(0).path("accountName").asText()).isEqualTo("信用卡");
	}

	@Test
	@DisplayName("记账日期：晚于今天拒，等于今天允许，过去多久都允许")
	void bizDateAcceptsPastButNeverFuture() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long cash = accountId(owner, "现金");
		LocalDate today = LocalDate.now();

		assertThat(postJson(TRANSACTIONS, tx(dining, null, cash, "5.00", today.plusDays(5).toString(), "未来的"),
				owner.accessToken()).code()).isEqualTo("BIZ_DATE_IN_FUTURE");
		assertThat(record(owner, tx(dining, null, cash, "5.00", today.toString(), "今天的")).code()).isEqualTo("OK");
		assertThat(record(owner, tx(dining, null, cash, "5.00", "2019-12-31", "很多年前的")).code())
			.as("补记历史不设下限").isEqualTo("OK");
	}

	@Test
	@DisplayName("金额：三位小数直接拒绝而不是四舍五入，0 与负数被拒，DECIMAL(12,2) 上限内原样往返")
	void amountIsValidatedAndRoundTrips() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		JsonNode tree = tree(owner, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long cash = accountId(owner, "现金");

		assertThat(postJson(TRANSACTIONS, tx(dining, null, cash, "1.005", "2026-09-01", "三位小数"), owner.accessToken())
			.code()).as("1.005 静默变 1.01 是数据错误，不是精度取舍").isEqualTo("AMOUNT_SCALE_INVALID");
		assertThat(postJson(TRANSACTIONS, tx(dining, null, cash, "0", "2026-09-01", "零"), owner.accessToken()).code())
			.isEqualTo("VALIDATION_FAILED");
		assertThat(postJson(TRANSACTIONS, tx(dining, null, cash, "-5.00", "2026-09-01", "负数"), owner.accessToken()).code())
			.isEqualTo("VALIDATION_FAILED");
		assertThat(postJson(TRANSACTIONS, tx(dining, null, cash, "10000000000.00", "2026-09-01", "超上限"),
				owner.accessToken()).code()).isEqualTo("BAD_REQUEST");

		assertThat(record(owner, tx(dining, null, cash, "9999999999.99", "2026-09-01", "顶格")).data().path("amount")
			.asText()).as("上限内的值存进去再取出来一个字符都不差").isEqualTo("9999999999.99");
		assertThat(record(owner, tx(dining, null, cash, "12.5", "2026-09-01", "一位小数")).data().path("amount").asText())
			.as("落库按两位小数补零").isEqualTo("12.50");
	}

	@Test
	@DisplayName("收支类型取自所选大类；小类不能冒充大类、不能挂错父级，别家的字典项等于不存在")
	void dictionaryReferencesAreValidated() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		JsonNode tree = tree(owner, "EXPENSE");
		JsonNode incomeTree = tree(owner, "INCOME");
		long dining = topId(tree, "餐饮");
		long lunch = subId(tree, "餐饮", "午餐");
		long bus = topId(tree, "交通");
		long busTaxi = subId(tree, "交通", "打车");
		long salary = topId(incomeTree, "工资");
		long cash = accountId(owner, "现金");

		assertThat(recordsOf(query(owner, ""))).as("被拒的写入不该留下残渣").isEmpty();
		assertThat(postJson(TRANSACTIONS, tx(lunch, null, cash, "1.00", "2026-09-01", "小类冒充大类"), owner.accessToken())
			.code()).as("把小类填进 categoryId 会记出一个没有父级的三层引用").isEqualTo("BAD_REQUEST");
		assertThat(postJson(TRANSACTIONS, tx(dining, busTaxi, cash, "1.00", "2026-09-01", "挂错父级"), owner.accessToken())
			.code()).as("小类必须属于所选大类").isEqualTo("CATEGORY_PARENT_MISMATCH");
		assertThat(postJson(TRANSACTIONS, tx(9999001L, null, cash, "1.00", "2026-09-01", "不存在"), owner.accessToken())
			.code()).isEqualTo("CATEGORY_NOT_FOUND");
		assertThat(postJson(TRANSACTIONS, tx(bus, null, 9999002L, "1.00", "2026-09-01", "不存在"), owner.accessToken())
			.code()).isEqualTo("PAYMENT_ACCOUNT_NOT_FOUND");
		assertThat(
				postJson(TRANSACTIONS, tx(dining, null, accountId(outsider, "现金"), "1.00", "2026-09-01", "借别家账户"),
						owner.accessToken()).code()).as("别家预置的现金与本家同名不同 id，按不存在处理").isEqualTo("PAYMENT_ACCOUNT_NOT_FOUND");
		assertThat(postJson(TRANSACTIONS, tx(topId(tree(outsider, "EXPENSE"), "餐饮"), null, cash, "1.00", "2026-09-01", "借别家类别"),
				owner.accessToken()).code()).isEqualTo("CATEGORY_NOT_FOUND");
		assertThat(recordsOf(query(owner, ""))).as("上面这些一条都没落库").isEmpty();

		Call salaryRow = record(owner, tx(salary, null, cash, "100.00", "2026-09-01", "收入侧"));
		assertThat(salaryRow.data().path("type").asText()).as("同一份载荷，换个大类就换了收支类型").isEqualTo("INCOME");
	}

	@Test
	@DisplayName("流水软删除后列表里看不见了，但仍算在类别和账户名下：那两行还是只能停用不能删除")
	void softDeletedRowsStillPinTheirDictionaryEntries() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long car = createTop(owner, "养车");
		long service = createSub(owner, car, "保养");
		long wechat = accountId(owner, "微信");
		long id = recordId(owner, tx(car, service, wechat, "9.90", "2026-09-03", "删掉的也要算"));

		assertThat(deleteNoBody(TRANSACTIONS + "/" + id, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(recordsOf(query(owner, ""))).as("列表不再出现").isEmpty();
		assertThat(query(owner, "").data().path("total").asLong()).as("月度小计也不再算它").isZero();
		assertThat(toList(query(owner, "").data().path("monthSummaries"))).isEmpty();
		assertThat(getJson(TRANSACTIONS + "/" + id, owner.accessToken()).code()).isEqualTo("TRANSACTION_NOT_FOUND");
		assertThat(jdbcTemplate.queryForObject("SELECT deleted FROM `transaction` WHERE id = ?", Integer.class, id))
			.as("是打了删除标记而不是真删").isEqualTo(1);

		assertThat(deleteNoBody(CATEGORIES + "/" + service, owner.accessToken()).code())
			.as("否则删光流水就能把有历史的类别物理删掉").isEqualTo("CATEGORY_HAS_TRANSACTIONS");
		assertThat(deleteNoBody(PAYMENT_ACCOUNTS + "/" + wechat, owner.accessToken()).code())
			.isEqualTo("PAYMENT_ACCOUNT_IN_USE");
		assertThat(patchJson(CATEGORIES + "/" + service + "/toggle", Map.of(), owner.accessToken()).code())
			.as("停用这条路始终可用").isEqualTo("OK");
		assertThat(topId(tree(owner, "EXPENSE"), "养车")).as("被拒的两次删除都没把行弄掉").isPositive();
	}

	@Test
	@DisplayName("筛选条件逐个生效，组合起来只留同时满足的；size 超限收敛到 200 而不是报错")
	void filtersNarrowTheList() throws Exception {
		Account zhang = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(zhang);
		Account li = register(PHONE_B, "李四");
		inviteAndJoin(zhang, li);

		JsonNode expenseTree = tree(zhang, "EXPENSE");
		JsonNode incomeTree = tree(zhang, "INCOME");
		long dining = topId(expenseTree, "餐饮");
		long lunch = subId(expenseTree, "餐饮", "午餐");
		long bus = topId(expenseTree, "交通");
		long salary = topId(incomeTree, "工资");
		long wechat = accountId(zhang, "微信");
		long cash = accountId(zhang, "现金");
		long card = accountId(zhang, "储蓄卡");
		record(zhang, tx(dining, lunch, wechat, "12.00", "2026-08-05", "团队午餐"));
		record(li, tx(bus, null, cash, "30.00", "2026-08-20", "机场打车"));
		record(zhang, tx(salary, null, card, "8000.00", "2026-09-01", "九月工资"));

		assertThat(remarks(recordsOf(query(zhang, "")))).as("默认按业务日期倒序，同一天再按 id").containsExactly("九月工资", "机场打车",
				"团队午餐");
		assertThat(remarks(recordsOf(query(zhang, "startDate=2026-08-10&endDate=2026-09-30"))))
			.containsExactlyInAnyOrder("九月工资", "机场打车");
		assertThat(remarks(recordsOf(query(zhang, "startDate=2026-08-01&endDate=2026-08-31")))).as("区间两端都含")
			.containsExactlyInAnyOrder("机场打车", "团队午餐");
		assertThat(remarks(recordsOf(query(zhang, "type=EXPENSE")))).containsExactlyInAnyOrder("机场打车", "团队午餐");
		assertThat(remarks(recordsOf(query(zhang, "categoryId=" + dining)))).as("按大类筛不出收入")
			.containsExactly("团队午餐");
		assertThat(remarks(recordsOf(query(zhang, "subCategoryId=" + lunch)))).containsExactly("团队午餐");
		assertThat(remarks(recordsOf(query(zhang, "accountId=" + wechat)))).containsExactly("团队午餐");
		assertThat(remarks(recordsOf(query(zhang, "createdBy=" + li.userId())))).as("记录人筛出李四代记的那笔")
			.containsExactly("机场打车");
		assertThat(remarks(recordsOf(query(zhang, "amount=30.00")))).containsExactly("机场打车");
		assertThat(remarks(recordsOf(queryBy(zhang, Map.of("keyword", "午餐"))))).containsExactly("团队午餐");
		assertThat(remarks(recordsOf(queryBy(zhang,
				Map.of("type", "EXPENSE", "startDate", "2026-08-10", "keyword", "打车"))))).containsExactly("机场打车");
		assertThat(remarks(recordsOf(query(zhang, "type=INCOME&amount=12.00")))).as("条件互斥时是空集而不是全量").isEmpty();
		assertThat(query(li, "").data().path("total").asLong()).as("李四视角看到的同样是全部 3 条").isEqualTo(3);
		assertThat(query(zhang, "size=1000").data().path("size").asLong()).as("超大 size 收敛到上限").isEqualTo(200);
	}

	// ---- 前置数据 ----

	/** 给某个家庭灌 40 条支出，从 2026-08-01 起每天一条，跨到 9 月，好让分页和月度聚合都有东西可数。 */
	private void seedFortyExpenses(Account account, String remarkPrefix) throws Exception {
		JsonNode tree = tree(account, "EXPENSE");
		long dining = topId(tree, "餐饮");
		long cash = accountId(account, "现金");
		LocalDate start = LocalDate.of(2026, 8, 1);
		for (int i = 0; i < 40; i++) {
			record(account, tx(dining, null, cash, "10.00", start.plusDays(i).toString(), remarkPrefix + i));
		}
	}

	// ---- HTTP 辅助 ----

	private JsonNode tree(Account account, String type) throws Exception {
		Call call = getJson(CATEGORIES + "?type=" + type + "&enabledOnly=false", account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	/** 自建类别。软删除那条用例要用自定义行，预置行删不掉的第一个原因是「预置不可删」，看不到流水判定。 */
	private long createTop(Account account, String name) throws Exception {
		Call call = postJson(CATEGORIES, Map.of("type", "EXPENSE", "name", name), account.accessToken());
		assertThat(call.code()).as("新建大类 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private long createSub(Account account, long parentId, String name) throws Exception {
		Call call = postJson(CATEGORIES, Map.of("type", "EXPENSE", "parentId", parentId, "name", name),
				account.accessToken());
		assertThat(call.code()).as("新建小类 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private Call query(Account account, String filter) throws Exception {
		return getJson(TRANSACTIONS + (filter.isEmpty() ? "" : "?" + filter), account.accessToken());
	}

	/** 带中文的筛选词只能走这个：拼在 URL 上会经 MockMvc 的 URI 解析拿到乱码。 */
	private Call queryBy(Account account, Map<String, String> params) throws Exception {
		return getJson(TRANSACTIONS, params, account.accessToken());
	}

	private Call record(Account account, Map<String, Object> payload) throws Exception {
		Call call = postJson(TRANSACTIONS, payload, account.accessToken());
		assertThat(call.code()).as("记一笔 %s", payload).isEqualTo("OK");
		return call;
	}

	private long recordId(Account account, Map<String, Object> payload) throws Exception {
		return record(account, payload).data().path("id").asLong();
	}

	/**
	 * 记一笔的载荷。收支类型不在里面——它由服务端从 categoryId 指向的大类读出，所以收入与支出用同一份载荷，
	 * 换个大类就换了类型，这正是 {@link #dictionaryReferencesAreValidated} 要钉的东西。
	 */
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

	private long accountId(Account account, String name) throws Exception {
		Call call = getJson(PAYMENT_ACCOUNTS + "?enabledOnly=false", account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		for (JsonNode node : call.data()) {
			if (node.path("name").asText().equals(name)) {
				return node.path("id").asLong();
			}
		}
		throw new AssertionError("预置支付方式里应有 " + name);
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

	private List<JsonNode> recordsOf(Call call) {
		assertThat(call.code()).as("流水列表查询应成功").isEqualTo("OK");
		return toList(call.data().path("records"));
	}

	private JsonNode dataOf(Call call) {
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private List<JsonNode> toList(JsonNode array) {
		List<JsonNode> nodes = new ArrayList<>();
		array.forEach(nodes::add);
		return nodes;
	}

	private List<String> remarks(List<JsonNode> rows) {
		return rows.stream().map(node -> node.path("remark").asText()).toList();
	}

	private List<String> categoryNames(List<JsonNode> rows) {
		return rows.stream().map(node -> node.path("categoryName").asText()).toList();
	}

}
