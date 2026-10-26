package cn.homeledger.vo;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一个月的小计，同时是 TransactionMapper.selectMonthSummaries 的投影目标（列别名须与组件名一致）。
 * <p>
 * month 形如 {@code 2026-09}。结余由带符号的同一次求和得到，与 income / expense 出自同一扫描，
 * 不会出现三者自相矛盾。金额一律按字符串收发，与 {@link TransactionResponse#amount} 同口径。
 */
public record MonthSummary(String month, @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal income,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal expense,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal balance, long count) {

}
