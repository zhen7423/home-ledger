package cn.homeledger.service.impl;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.UncheckedIOException;
import java.io.Writer;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.springframework.stereotype.Service;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.DateRanges;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.ExportFormat;
import cn.homeledger.config.ExportProperties;
import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.entity.Transaction;
import cn.homeledger.mapper.TransactionMapper;
import cn.homeledger.service.TransactionExportService;
import cn.idev.excel.ExcelWriter;
import cn.idev.excel.FastExcel;
import cn.idev.excel.metadata.data.DataFormatData;
import cn.idev.excel.support.ExcelTypeEnum;
import cn.idev.excel.write.metadata.WriteSheet;
import cn.idev.excel.write.metadata.style.WriteCellStyle;
import cn.idev.excel.write.style.HorizontalCellStyleStrategy;

/**
 * §4.2.7 流水明细导出。xlsx 走 FastExcel 流式写、CSV 手写，两种格式共用同一套十列与同一套分批读取。
 */
@Service
public class TransactionExportServiceImpl implements TransactionExportService {

	/** §4.2.7 固定十列，顺序不许动——用户会把上一次导出的文件与这一次的并排比。 */
	private static final List<String> HEAD = List.of("记账日期", "收支类型", "大类", "小类", "金额", "支付方式", "备注",
			"记录人", "创建时间", "数据来源");

	private static final String TYPE_EXPENSE = "EXPENSE";

	private static final String TYPE_EXPENSE_LABEL = "支出";

	private static final String TYPE_INCOME_LABEL = "收入";

	/** 按 rule_id 有没有值判定（§4.2.7），与流水列表的「来源」是同一个判据。 */
	private static final String SOURCE_AUTO_LABEL = "周期自动";

	private static final String SOURCE_MANUAL_LABEL = "手动";

	/** 末行汇总的 A 列（§4.2.7）。 */
	private static final String TOTAL_LABEL = "合计";

	private static final String SHEET_NAME = "流水";

	private static final DateTimeFormatter CREATED_AT_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

	/** Excel 靠这三个字节认出 UTF-8，缺了它中文一律按本地代码页解，打开就是乱码（§4.2.7）。 */
	private static final byte[] UTF8_BOM = { (byte) 0xEF, (byte) 0xBB, (byte) 0xBF };

	/** RFC 4180 要求 CRLF。只写 \n 的话 Excel 在 Windows 上可能把整份文件当成一行。 */
	private static final String CRLF = "\r\n";

	/** 金额列的数字格式。文本单元格会忽略它，所以整列套用是安全的。 */
	private static final String MONEY_FORMAT = "0.00";

	private final TransactionMapper transactionMapper;

	private final ExportProperties properties;

	private final Clock clock;

	public TransactionExportServiceImpl(TransactionMapper transactionMapper, ExportProperties properties,
			Clock clock) {
		this.transactionMapper = transactionMapper;
		this.properties = properties;
		this.clock = clock;
	}

	@Override
	public Preparation prepare(TransactionQueryRequest query, ExportFormat format) {
		Long familyId = currentFamilyId();
		DateRanges.assertRange(query.startDate(), query.endDate());
		long rowCount = this.transactionMapper.sumFiltered(query, familyId).count();
		if (rowCount > this.properties.maxRows()) {
			throw new BizException(ErrorCode.BAD_REQUEST,
					"本次要导出 " + rowCount + " 笔，超过上限 " + this.properties.maxRows() + " 笔，请缩小时间区间后再试");
		}
		String filename = filename(query, format);
		return new Preparation(rowCount, filename, format.contentType(), contentDisposition(filename, format));
	}

	/**
	 * 家记流水_{起}_{止}.xlsx。两个日期都没给（导出全部）时写成「家记流水_全部_{导出当天}」——
	 * 直接拼 null 会得到一个用户看得见的「家记流水_null_null」（验收用例 16 要核文件名）。
	 */
	private String filename(TransactionQueryRequest query, ExportFormat format) {
		LocalDate end = query.endDate() != null ? query.endDate() : LocalDate.now(this.clock);
		String span = query.startDate() == null ? "全部_" + end : query.startDate() + "_" + end;
		return "家记流水_" + span + "." + format.extension();
	}

	/**
	 * RFC 5987。前面那个纯 ASCII 的 filename 是给不认识 filename* 的老客户端兜底的，
	 * 后面 {@code UTF-8''} 里的两个单引号是语言标签留空，不是笔误。
	 * <p>
	 * URLEncoder 是给表单用的，它把空格编成 {@code +}；RFC 5987 要的是百分号编码，所以要再换回 {@code %20}。
	 * 文件名里现在没有空格，但用户哪天在区间里塞不进的东西谁也说不准，这一行不能省。
	 */
	private static String contentDisposition(String filename, ExportFormat format) {
		String encoded = URLEncoder.encode(filename, StandardCharsets.UTF_8).replace("+", "%20");
		return "attachment; filename=\"transactions." + format.extension() + "\"; filename*=UTF-8''" + encoded;
	}

	@Override
	public void write(TransactionQueryRequest query, ExportFormat format, OutputStream out) {
		Long familyId = currentFamilyId();
		// 汇总行要的收入 / 支出合计与 prepare 里的 COUNT 是同一条聚合，这里再跑一次：
		// 两步之间隔着一整个响应头的写出，把 Totals 从 prepare 传到 write 会让接口签名带一个只在内部有意义的对象
		TransactionMapper.Totals totals = this.transactionMapper.sumFiltered(query, familyId);
		try {
			if (format == ExportFormat.CSV) {
				writeCsv(query, familyId, totals, out);
			}
			else {
				writeXlsx(query, familyId, totals, out);
			}
		}
		catch (IOException e) {
			// 第一个字节写出去之后 HTTP 200 就已经发出去了，此后失败只能把文件截断，没有第二种选择。
			// 不吞也不伪装成功，让它冒到 GlobalExceptionHandler——那里的 ApiResponseWriter 会按
			// response.isCommitted() 决定还补不补得上一个错误响应体
			throw new UncheckedIOException(e);
		}
	}

	/** 与 Consumer 的唯一区别是允许抛 IOException：写出本来就可能失败，包一层只会把原始原因埋掉。 */
	@FunctionalInterface
	private interface BatchConsumer {

		void accept(List<List<Object>> batch) throws IOException;

	}

	/**
	 * 分批读取（§4.2.7）。一次把 5 万行拉进内存再加上 xlsx 的写出缓冲会顶穿容器堆，
	 * 所以每批 batchSize 行、读完立刻交给 consumer、不攒第二份。
	 * <p>
	 * 终止条件是「这一批不满」而不是「offset 超过总数」：总数在 prepare 时查过一次，
	 * 但导出期间可能有人新记一笔，拿一个可能已经过期的总数当循环上界会漏行或死循环。
	 */
	private void eachBatch(TransactionQueryRequest query, Long familyId, BatchConsumer consumer) throws IOException {
		int batchSize = this.properties.batchSize();
		for (int offset = 0;; offset += batchSize) {
			List<Transaction> rows = this.transactionMapper.selectForExport(query, familyId, offset, batchSize);
			if (rows.isEmpty()) {
				return;
			}
			consumer.accept(rows.stream().map(TransactionExportServiceImpl::row).toList());
			if (rows.size() < batchSize) {
				return;
			}
		}
	}

	/**
	 * 一条流水的十列（§4.2.7）。
	 * <p>
	 * <b>必须用 Arrays.asList 而不是 List.of</b>：小类、备注都能为空，{@code List.of} 遇到 null 直接抛
	 * NullPointerException，症状是「有备注的流水导得出，没备注的导不出」——一个只看错误日志几乎猜不到的分支。
	 * <p>
	 * 金额放的是 BigDecimal 本体而不是字符串：xlsx 要把它写成<b>数值单元格</b>，否则用户拿 Excel
	 * 对 E 列求和得到的是 0（§4.2.7 把汇总行放在 B/C/D 而不是 E 列的整套理由，都建立在 E 列可求和之上）。
	 * 名称一律取流水上的快照字段，不用当前字典名——导出是历史凭证，与流水列表一致。
	 */
	private static List<Object> row(Transaction transaction) {
		return Arrays.asList(transaction.getBizDate().toString(),
				TYPE_EXPENSE.equals(transaction.getType()) ? TYPE_EXPENSE_LABEL : TYPE_INCOME_LABEL,
				transaction.getCategoryNameSnapshot(), transaction.getSubCategoryNameSnapshot(),
				transaction.getAmount(), transaction.getAccountNameSnapshot(), transaction.getRemark(),
				transaction.getRecorderNameSnapshot(), transaction.getCreatedAt().format(CREATED_AT_FORMAT),
				transaction.getRuleId() == null ? SOURCE_MANUAL_LABEL : SOURCE_AUTO_LABEL);
	}

	/**
	 * 末行汇总（§4.2.7）：A 列「合计」，B/C/D 是收入 / 支出 / 结余，<b>E 列（金额列）及其后各列留空</b>。
	 * 用户拿 Excel 对 E 列求和是本能操作，金额列里混进三个合计数会让这个求和直接翻倍出错；
	 * B/C/D 是文本列（收支类型、大类、小类），不会被误算。
	 */
	private static List<Object> summaryRow(TransactionMapper.Totals totals) {
		return Arrays.asList(TOTAL_LABEL, totals.income(), totals.expense(), totals.income().subtract(totals.expense()),
				"", "", "", "", "", "");
	}

	private void writeXlsx(TransactionQueryRequest query, Long familyId, TransactionMapper.Totals totals,
			OutputStream out) throws IOException {
		WriteCellStyle contentStyle = new WriteCellStyle();
		DataFormatData numberFormat = new DataFormatData();
		numberFormat.setFormat(MONEY_FORMAT);
		contentStyle.setDataFormatData(numberFormat);
		List<List<String>> head = HEAD.stream().map(List::of).toList();
		try (ExcelWriter writer = FastExcel.write(out)
			.excelType(ExcelTypeEnum.XLSX)
			// 不能让它关流：关的是 Servlet 的 OutputStream，容器就没机会补 trailer 了
			.autoCloseStream(false)
			.head(head)
			// 头样式传 null 表示「表头保持 FastExcel 默认」，HorizontalCellStyleStrategy#setHeadCellStyle
			// 在 head 为 null 时直接 return，不会 NPE（已核过 1.3.0 的源码，见 §3.12）
			.registerWriteHandler(new HorizontalCellStyleStrategy(null, contentStyle))
			.build()) {
			WriteSheet sheet = FastExcel.writerSheet(0, SHEET_NAME).build();
			eachBatch(query, familyId, batch -> writer.write(batch, sheet));
			writer.write(List.of(summaryRow(totals)), sheet);
		}
	}

	private void writeCsv(TransactionQueryRequest query, Long familyId, TransactionMapper.Totals totals,
			OutputStream out) throws IOException {
		out.write(UTF8_BOM);
		Writer writer = new BufferedWriter(new OutputStreamWriter(out, StandardCharsets.UTF_8));
		writeLine(writer, new ArrayList<>(HEAD));
		eachBatch(query, familyId, batch -> {
			for (List<Object> row : batch) {
				writeLine(writer, row);
			}
		});
		writeLine(writer, summaryRow(totals));
		// flush 而不是 close：close 会连带关掉 out，而那是要留给容器的
		writer.flush();
	}

	private static void writeLine(Writer writer, List<Object> cells) throws IOException {
		StringBuilder line = new StringBuilder();
		for (int i = 0; i < cells.size(); i++) {
			if (i > 0) {
				line.append(',');
			}
			line.append(escape(cells.get(i)));
		}
		writer.write(line.append(CRLF).toString());
	}

	/**
	 * RFC 4180 的转义只有三条：含逗号 / 双引号 / 换行的字段用双引号包起来，字段内的双引号写成两个双引号。
	 * 为这三条引一个 OpenCSV 不值当，而引了之后 BOM 与 CRLF 还是要自己盯（§4.2.7）。
	 * <p>
	 * \r 也要触发引号：备注是从多行输入框来的，只查 \n 会让一个以 \r 结尾的备注把 CSV 撕成两行。
	 * <p>
	 * 公式注入：字符串字段以 {@code = + - @} 或制表符开头时前置一个 {@code '}，让 Excel/WPS 把它当文本
	 * 而不是当成 {@code =HYPERLINK(...)} 之类的公式执行——备注是 ≤200 字符的用户自由文本，同一家庭的
	 * 恶意成员可借此攻击打开导出文件的家人（扫描报告 P1-6）。只对字符串做：金额是 BigDecimal，
	 * 负数 "-123.45" 加撇号会被迫变成文本、丢数字格式。
	 */
	private static String escape(Object cell) {
		if (cell == null) {
			return "";
		}
		String value = cell instanceof BigDecimal amount ? amount.toPlainString() : cell.toString();
		if (cell instanceof String text && !text.isEmpty()) {
			char first = text.charAt(0);
			if (first == '=' || first == '+' || first == '-' || first == '@' || first == '\t' || first == '\r') {
				value = "'" + value;
			}
		}
		if (value.indexOf(',') < 0 && value.indexOf('"') < 0 && value.indexOf('\n') < 0 && value.indexOf('\r') < 0) {
			return value;
		}
		return '"' + value.replace("\"", "\"\"") + '"';
	}

	private static Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

}
