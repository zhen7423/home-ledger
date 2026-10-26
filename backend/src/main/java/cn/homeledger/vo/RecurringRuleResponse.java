package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonFormat;

import cn.homeledger.dto.RecurringRuleCreateRequest;

/**
 * 一条周期记账规则（§4.2.3）。
 * <p>
 * 类别名与支付方式名是<b>实时解析</b>出来的，不是记账时冻结的快照——这与 {@link TransactionResponse} 相反。
 * 规则是「将来要记什么」的配置，类别改名后它该显示新名；实时解析之所以安全，靠的是 B8 那条接缝：
 * 被任何未删除规则引用的类别与支付方式不允许删掉。
 */
public record RecurringRuleResponse(Long id, String name, String type,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount, Long categoryId, String categoryName,
		Long subCategoryId, String subCategoryName, Long accountId, String accountName, String periodType,
		RecurringRuleCreateRequest.PeriodValue periodValue,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate startDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate endDate, boolean enabled, LocalDateTime createdAt,
		LocalDateTime updatedAt) {

}
