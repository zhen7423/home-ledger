package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 区间概览（§4.2.6 概览卡片、§8 的 GET /transactions/summary）。
 * <p>
 * startDate / endDate 是<b>解析之后</b>的区间，不是回显入参：两个日期都不传时这里给的是
 * 「家里第一笔流水的日期 → 今天」，导出页要靠它把「共 N 笔」与它下面那份文件覆盖的区间对上。
 * <p>
 * days 为 0 只出现在一笔流水都没有的时候，此时 dailyAverageExpense 也恒为 0（除数不能是 0）。
 */
public record TransactionSummaryResponse(@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate startDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate endDate, int days,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal income,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal expense,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal balance,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal dailyAverageExpense, long count) {

}
