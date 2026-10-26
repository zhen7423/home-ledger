package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条驱虫记录（§4.3.3 列表的一行）。
 * <p>
 * daysToDue 与 overdueDays 分成两个字段而不是一个带符号的数：界面对「还有 N 天」和「逾期 N 天」
 * 是两套颜色，用符号判断会把 0（今天该驱）染成红色（§4.3.3 的逾期判定是「今天 &gt; 下次日期」，不含等于）。
 * 未逾期时 overdueDays 为 null，反之 daysToDue 为 null——两个都为 null 不可能出现，因为 next_date 非空。
 * <p>
 * catName 是<b>实时反查</b>而不是落库快照，与 transaction 的名称快照刻意相反：档案名要一直跟着改名走，
 * 而流水是历史凭证。
 */
public record CatDewormingResponse(Long id, Long catId, String catName, String type,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate doneDate, String medicine, String dosage,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate nextDate, Long daysToDue, Long overdueDays,
		String remark) {

}
