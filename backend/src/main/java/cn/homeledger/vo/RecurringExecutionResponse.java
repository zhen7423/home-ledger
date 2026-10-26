package cn.homeledger.vo;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条周期记账的执行记录（§4.2.3 规则详情页的「执行记录」区块）。
 * <p>
 * 只来自 recurring_execution_log，不 JOIN 流水：流水被用户删掉之后这条记录仍然要显示，它是审计轨迹。
 * 因此 transactionId 只是一个 id，界面上不做下钻。
 */
public record RecurringExecutionResponse(Long id,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate bizDate, Long transactionId,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate executedDate, boolean backfilled) {

}
