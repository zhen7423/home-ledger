package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;

import cn.homeledger.service.RecurringGenerationService;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.2.7 流水明细导出。xlsx 用 POI 读回来核，CSV 直接按文本核。
 * <p>
 * 导出的价值全在「拿去能不能用」上：金额列是不是数值单元格、CSV 有没有 BOM、中文文件名能不能还原，
 * 这三件事错了，文件照样能下载下来，用户却在 Excel 里对着一列求不出的和。所以断言落在文件内容上，
 * 不落在水印级的「状态码 200」。
 */
class ExportIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	private static final List<String> HEAD = List.of("记账日期", "收支类型", "大类", "小类", "金额", "支付方式", "备注",
			"记录人", "创建时间", "数据来源");

	@Autowired
	private RecurringGenerationService generationService;

	@Test
	@DisplayName("验收用例 16：表头十格逐字与顺序都对")
	void xlsxHasTheTenColumnsInOrder() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);

		try (XSSFWorkbook workbook = xlsx(export(owner, xlsxRange()))) {
			Row head = workbook.getSheetAt(0).getRow(0);
			assertThat(lastCellNum(head)).isEqualTo(HEAD.size());
			List<String> labels = new ArrayList<>();
			for (int i = 0; i < HEAD.size(); i++) {
				labels.add(text(head, i));
			}
			assertThat(labels).isEqualTo(HEAD);
		}
	}

	@Test
	@DisplayName("金额列是数值单元格：这是汇总行放 B/C/D 的整套理由的地基")
	void xlsxAmountIsANumericCell() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		record(owner, tx(topCategoryId(owner, "餐饮"), null, paymentAccountId(owner, "现金"), "123.45", "2026-01-10",
				"一顿饭"));

		try (XSSFWorkbook workbook = xlsx(export(owner, xlsxRange()))) {
			assertThat(numeric(detailRows(workbook.getSheetAt(0)).get(0), 4)).isEqualByComparingTo("123.45");
		}
	}

	@Test
	@DisplayName("末行汇总：A 合计、B/C/D 三个数，E 列往后是空串而不是合计数")
	void xlsxSummaryRowPutsTotalsInBcdAndLeavesAmountEmpty() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(topCategoryId(owner, "餐饮"), null, cash, "70.00", "2026-01-10", "支出"));
		record(owner, tx(incomeCategoryId(owner, "工资"), null, cash, "200.00", "2026-01-11", "收入"));

		try (XSSFWorkbook workbook = xlsx(export(owner, xlsxRange()))) {
			Sheet sheet = workbook.getSheetAt(0);
			Row summary = sheet.getRow(sheet.getLastRowNum());
			assertThat(text(summary, 0)).isEqualTo("合计");
			assertThat(numeric(summary, 1)).isEqualByComparingTo("200.00");
			assertThat(numeric(summary, 2)).isEqualByComparingTo("70.00");
			assertThat(numeric(summary, 3)).isEqualByComparingTo("130.00");
			assertThat(lastCellNum(summary)).as("十列都得存在，否则用户在 Excel 里横向选中会少几列").isEqualTo(10);
			for (int i = 4; i < 10; i++) {
				assertThat(text(summary, i)).as("第 %d 列", i).isEmpty();
			}
		}
	}

	@Test
	@DisplayName("验收用例 16：软删除的流水不出现在明细里，也不进汇总")
	void xlsxExcludesSoftDeletedRows() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		recordId(owner, tx(dining, null, cash, "10.00", "2026-01-10", "留着"));
		long deleted = recordId(owner, tx(dining, null, cash, "999.00", "2026-01-11", "删掉"));
		recordId(owner, tx(dining, null, cash, "20.00", "2026-01-12", "留着"));

		assertThat(deleteNoBody(TRANSACTIONS + "/" + deleted, owner.accessToken()).code()).isEqualTo("OK");
		try (XSSFWorkbook workbook = xlsx(export(owner, xlsxRange()))) {
			Sheet sheet = workbook.getSheetAt(0);
			assertThat(detailRows(sheet)).as("明细恰两行").hasSize(2);
			assertThat(numeric(sheet.getRow(sheet.getLastRowNum()), 2)).as("支出合计只含留着的两笔").isEqualByComparingTo("30.00");
		}
	}

	@Test
	@DisplayName("收支类型与数据来源都是中文，来源按 rule_id 判定")
	void xlsxLabelsTypeAndSourceInChinese() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner);
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(topCategoryId(owner, "餐饮"), null, cash, "30.00", "2026-01-10", "手记支出"));
		record(owner, tx(incomeCategoryId(owner, "工资"), null, cash, "500.00", "2026-01-11", "手记收入"));
		seedDailyRule(family.id(), owner, LocalDate.of(2026, 1, 15));
		assertThat(generationService.runFor(LocalDate.of(2026, 1, 15))).isEqualTo(1);

		try (XSSFWorkbook workbook = xlsx(export(owner, xlsxRange()))) {
			List<String> labels = new ArrayList<>();
			for (Row row : detailRows(workbook.getSheetAt(0))) {
				labels.add(text(row, 1) + "|" + text(row, 9));
			}
			assertThat(labels).containsExactlyInAnyOrder("支出|手动", "收入|手动", "支出|周期自动");
		}
	}

	@Test
	@DisplayName("导出用名称快照不用当前字典名：与统计那条正好相反")
	void xlsxUsesSnapshotsNotCurrentDictionaryNames() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		record(owner, tx(dining, null, paymentAccountId(owner, "现金"), "30.00", "2026-01-10", "改名前的流水"));
		assertThat(patchJson(CATEGORIES + "/" + dining, Map.of("name", "饭菜"), owner.accessToken()).code())
			.isEqualTo("OK");

		try (XSSFWorkbook workbook = xlsx(export(owner, xlsxRange()))) {
			assertThat(text(detailRows(workbook.getSheetAt(0)).get(0), 2)).as("导出是历史凭证").isEqualTo("餐饮");
		}
	}

	@Test
	@DisplayName("验收用例 16：明细按记账日期升序、同日按 id 升序")
	void detailsAreOrderedByDateAscendingThenIdAscending() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(dining, null, cash, "10.00", "2026-03-01", "三月"));
		record(owner, tx(dining, null, cash, "20.00", "2026-01-01", "同一天先记的"));
		record(owner, tx(dining, null, cash, "30.00", "2026-01-01", "同一天后记的"));

		try (XSSFWorkbook workbook = xlsx(export(owner,
				Map.of("format", "xlsx", "startDate", "2026-01-01", "endDate", "2026-03-31")))) {
			List<String> remarks = new ArrayList<>();
			for (Row row : detailRows(workbook.getSheetAt(0))) {
				remarks.add(text(row, 6));
			}
			assertThat(remarks).as("区间盖不住三笔的记账日，断言就变成在测过滤而不是排序").containsExactly("同一天先记的",
					"同一天后记的", "三月");
		}
	}

	@Test
	@DisplayName("验收用例 16：CSV 以 UTF-8 BOM 开头")
	void csvStartsWithAUtf8Bom() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		BinaryCall call = export(owner, withFormat(xlsxRange(), "csv"));
		assertThat(call.status()).isEqualTo(200);
		assertThat(call.body()[0]).isEqualTo((byte) 0xEF);
		assertThat(call.body()[1]).isEqualTo((byte) 0xBB);
		assertThat(call.body()[2]).isEqualTo((byte) 0xBF);
	}

	@Test
	@DisplayName("CSV 按 RFC 4180 转义逗号、双引号与换行")
	void csvEscapesCommasQuotesAndNewlines() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		record(owner, tx(topCategoryId(owner, "餐饮"), null, paymentAccountId(owner, "现金"), "30.00", "2026-01-10",
				"他说\"贵\",然后\n换行"));

		List<String> lines = csvLines(export(owner, withFormat(xlsxRange(), "csv")));
		assertThat(lines).as("备注里的换行不能把一条记录撕成两行").hasSize(4);
		assertThat(lines.get(1)).as("原文里两个双引号各翻倍一次").contains("\"他说\"\"贵\"\",然后\n换行\"");
	}

	@Test
	@DisplayName("CSV 用 CRLF 分行")
	void csvUsesCrlfLineEndings() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long dining = topCategoryId(owner, "餐饮");
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(dining, null, cash, "10.00", "2026-01-10", "一"));
		record(owner, tx(dining, null, cash, "20.00", "2026-01-11", "二"));

		List<String> lines = csvLines(export(owner, withFormat(xlsxRange(), "csv")));
		assertThat(lines).as("表头 + 两行明细 + 汇总 + 末尾空串").hasSize(5);
		assertThat(lines.get(0)).isEqualTo(String.join(",", HEAD));
		assertThat(new String(export(owner, withFormat(xlsxRange(), "csv")).body(), StandardCharsets.UTF_8)).doesNotContain("\n\r");
	}

	@Test
	@DisplayName("CSV 的汇总行与 xlsx 的末行同形：后六个字段为空")
	void csvSummaryRowMatchesTheXlsxOne() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(topCategoryId(owner, "餐饮"), null, cash, "70.00", "2026-01-10", "支出"));
		record(owner, tx(incomeCategoryId(owner, "工资"), null, cash, "200.00", "2026-01-11", "收入"));

		List<String> lines = csvLines(export(owner, withFormat(xlsxRange(), "csv")));
		assertThat(lines.get(lines.size() - 2)).isEqualTo("合计,200.00,70.00,130.00,,,,,,");
	}

	@Test
	@DisplayName("验收用例 16：中文文件名按 RFC 5987 编码，解回来是原样")
	void filenameIsChineseAndRfc5987Encoded() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		String disposition = export(owner, xlsxRange()).contentDisposition();
		assertThat(disposition).startsWith("attachment;");
		assertThat(disposition).contains("filename*=UTF-8''");
		assertThat(decodedFilename(disposition)).isEqualTo("家记流水_2026-01-01_2026-01-31.xlsx");
	}

	@Test
	@DisplayName("不带日期导出全部时文件名换成「全部_{今天}」，不含 null 字样")
	void exportAllUsesADifferentFilename() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		String disposition = export(owner, Map.of("format", "xlsx")).contentDisposition();
		assertThat(decodedFilename(disposition)).isEqualTo("家记流水_全部_" + LocalDate.now() + ".xlsx");
	}

	@Test
	@DisplayName("两种格式各配自己的 MIME")
	void contentTypeMatchesTheFormat() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		assertThat(export(owner, xlsxRange()).contentType())
			.startsWith("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
		assertThat(export(owner, withFormat(xlsxRange(), "csv")).contentType()).startsWith("text/csv");
	}

	@Test
	@DisplayName("format 大小写不敏感")
	void formatIsCaseInsensitive() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		assertThat(export(owner, Map.of("format", "XLSX", "startDate", "2026-01-01", "endDate", "2026-01-31")).status())
			.isEqualTo(200);
		assertThat(export(owner, Map.of("format", "xlsx", "startDate", "2026-01-01", "endDate", "2026-01-31")).status())
			.isEqualTo(200);
	}

	@Test
	@DisplayName("未知格式 400，且响应体是 JSON 而不是半个文件")
	void unknownFormatIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		BinaryCall call = export(owner, Map.of("format", "pdf"));
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		JsonNode body = objectMapper.readTree(new String(call.body(), StandardCharsets.UTF_8));
		assertThat(body.path("code").asText()).isEqualTo("BAD_REQUEST");
		assertThat(body.path("message").asText()).contains("xlsx 与 csv");
	}

	@Test
	@DisplayName("不带 format 同样 400，不静默回落成 xlsx")
	void missingFormatIsRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		recordSample(owner);
		BinaryCall call = getBytes(EXPORT_TRANSACTIONS, Map.of(), owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(objectMapper.readTree(new String(call.body(), StandardCharsets.UTF_8)).path("code").asText())
			.isEqualTo("BAD_REQUEST");
	}

	@Test
	@DisplayName("导出与流水列表共用同一套筛选：同条件下行数等于列表的 total")
	void exportHonoursTheSameFiltersAsTheList() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner);
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		long dining = topCategoryId(owner, "餐饮");
		long transport = topCategoryId(owner, "交通");
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(dining, null, cash, "10.00", "2026-01-10", "机场打车"));
		record(owner, tx(transport, null, cash, "20.00", "2026-01-11", "机场大巴"));
		record(member, tx(dining, null, cash, "30.00", "2026-01-12", "机场盒饭"));

		Map<String, String> filters = Map.of("startDate", "2026-01-01", "endDate", "2026-01-31", "keyword", "机场",
				"categoryId", String.valueOf(dining), "createdBy", String.valueOf(owner.userId()));
		long total = getJson(TRANSACTIONS, filters, owner.accessToken()).data().path("total").asLong();
		try (XSSFWorkbook workbook = xlsx(export(owner, withFormat(filters, "xlsx")))) {
			assertThat(detailRows(workbook.getSheetAt(0))).hasSize((int) total);
			assertThat(text(detailRows(workbook.getSheetAt(0)).get(0), 6)).isEqualTo("机场打车");
		}
		assertThat(total).as("三条筛选条件确实收窄到一条").isEqualTo(1);
	}

	@Test
	@DisplayName("没有家庭的账号导出不了任何东西，报的是 JSON 不是文件")
	void exportRequiresAFamily() throws Exception {
		Account lonely = register(PHONE_A, "独居者");
		BinaryCall call = getBytes(EXPORT_TRANSACTIONS, Map.of("format", "xlsx"), lonely.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(objectMapper.readTree(new String(call.body(), StandardCharsets.UTF_8)).path("code").asText())
			.isEqualTo("NO_FAMILY");
	}

	@Test
	@DisplayName("§5.2：甲家导出的文件里没有乙家那笔")
	void exportNeverLeakAcrossFamilies() throws Exception {
		Account zhang = registerWithFamily(PHONE_A, "张三");
		Account other = registerWithFamily(PHONE_OTHER, "王五");
		record(zhang, tx(topCategoryId(zhang, "餐饮"), null, paymentAccountId(zhang, "现金"), "30.00", "2026-01-10",
				"甲家的备注"));
		record(other, tx(topCategoryId(other, "购物"), null, paymentAccountId(other, "微信"), "900.00", "2026-01-11",
				"乙家的备注"));

		// 用 CSV 来核字节：xlsx 里的文本在 zip 里是压缩过的，搜不到不等于没漏
		String text = new String(export(zhang, withFormat(Map.of(), "csv")).body(), StandardCharsets.UTF_8);
		assertThat(text).contains("甲家的备注").doesNotContain("乙家的备注").doesNotContain("900.00");
	}

	// ---- 前置数据 ----

	private void recordSample(Account owner) throws Exception {
		long cash = paymentAccountId(owner, "现金");
		record(owner, tx(topCategoryId(owner, "餐饮"), null, cash, "30.00", "2026-01-10", "样本一"));
		record(owner, tx(topCategoryId(owner, "交通"), null, cash, "20.00", "2026-01-12", "样本二"));
	}

	/** 与统计那组同一个理由：走接口建规则会当场补跑一次，直接把要测的状态改掉。 */
	private void seedDailyRule(long familyId, Account owner, LocalDate startDate) throws Exception {
		jdbcTemplate.update("INSERT INTO recurring_rule (id, family_id, name, type, amount, category_id, account_id,"
				+ " period_type, period_value, start_date, enabled, last_processed_date, created_by)"
				+ " VALUES (?, ?, '自动记账', 'EXPENSE', 100.00, ?, ?, 'DAILY', '{\"intervalDays\":1}', ?, 1, ?, ?)",
				IdWorker.getId(), familyId, topCategoryId(owner, "餐饮"), paymentAccountId(owner, "现金"), startDate,
				startDate.minusDays(1), owner.userId());
	}

	// ---- 请求辅助 ----

	private BinaryCall export(Account account, Map<String, String> params) throws Exception {
		return getBytes(EXPORT_TRANSACTIONS, params, account.accessToken());
	}

	private static Map<String, String> xlsxRange() {
		return Map.of("format", "xlsx", "startDate", "2026-01-01", "endDate", "2026-01-31");
	}

	private static Map<String, String> withFormat(Map<String, String> params, String format) {
		Map<String, String> withFormat = new LinkedHashMap<>(params);
		withFormat.put("format", format);
		return Map.copyOf(withFormat);
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

	private long incomeCategoryId(Account account, String name) throws Exception {
		Call call = getJson(CATEGORIES + "?type=INCOME&enabledOnly=false", account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		for (JsonNode node : call.data()) {
			if (node.path("name").asText().equals(name)) {
				return node.path("id").asLong();
			}
		}
		throw new AssertionError("预置类别树里应有收入大类 " + name);
	}

	private static XSSFWorkbook xlsx(BinaryCall call) throws Exception {
		assertThat(call.status()).as("导出失败，响应体 %s", new String(call.body(), StandardCharsets.UTF_8)).isEqualTo(200);
		return new XSSFWorkbook(new ByteArrayInputStream(call.body()));
	}

	/** 表头之下、末行汇总之上的那几行。 */
	private static List<Row> detailRows(Sheet sheet) {
		List<Row> rows = new ArrayList<>();
		for (int i = 1; i < sheet.getLastRowNum(); i++) {
			rows.add(sheet.getRow(i));
		}
		return rows;
	}

	private static String decodedFilename(String contentDisposition) {
		int marker = contentDisposition.indexOf("filename*=UTF-8''");
		return URLDecoder.decode(contentDisposition.substring(marker + "filename*=UTF-8''".length()),
				StandardCharsets.UTF_8);
	}

	private static List<String> csvLines(BinaryCall call) {
		assertThat(call.status()).isEqualTo(200);
		String text = new String(call.body(), StandardCharsets.UTF_8);
		assertThat(text).as("BOM 会被解成一个 \\uFEFF，切行之前先去掉").startsWith("\uFEFF");
		return List.of(text.substring(1).split("\r\n", -1));
	}

	/** POI 的 getLastCellNum 是 short，语义还是「最后一格的下标加一」，转成 int 才好跟列数比。 */
	private static int lastCellNum(Row row) {
		return row.getLastCellNum();
	}

	private static String text(Row row, int index) {
		Cell cell = row.getCell(index);
		if (cell == null) {
			return "";
		}
		return switch (cell.getCellType()) {
			case STRING -> cell.getStringCellValue();
			case NUMERIC -> String.valueOf(cell.getNumericCellValue());
			default -> "";
		};
	}

	private static BigDecimal numeric(Row row, int index) {
		Cell cell = row.getCell(index);
		assertThat(cell).as("第 %d 列", index).isNotNull();
		assertThat(cell.getCellType()).as("第 %d 列必须是数值单元格，否则用户拿 Excel 求和得到 0", index)
			.isEqualTo(CellType.NUMERIC);
		return BigDecimal.valueOf(cell.getNumericCellValue()).setScale(2, RoundingMode.HALF_UP);
	}

}
