package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一笔流水（§4.2.1）。
 * <p>
 * 名称字段不带 snapshot 后缀：对客户端来说它就是类别名 / 支付方式名 / 记录人名，存快照是服务端
 * 为了「改名与成员退出不回溯历史」的实现手段。
 * <p>
 * ruleId 非空即这笔由周期记账自动生成，为空就是手工记的。「来源」不另出一个字段：那只是 ruleId
 * 有没有值的另一种写法，多一处两个字段互不一致的可能。
 */
public record TransactionResponse(Long id, String type,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount, Long categoryId, String categoryName,
		Long subCategoryId, String subCategoryName, Long accountId, String accountName,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate bizDate, String remark, Long createdBy,
		String recorderName, Long ruleId, LocalDateTime createdAt, LocalDateTime updatedAt) {

}
