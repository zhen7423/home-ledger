package cn.homeledger.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 周期记账执行日志（§4.2.3）。一条规则的一个执行日对应一行，幂等唯一索引 uk_exec_rule_date 就落在这里，
 * 所以本表没有 deleted 列——它是审计轨迹，软删除的行会继续占住唯一索引，那样幂等就退化成「删过的日期永远补不回来」。
 */
@TableName("recurring_execution_log")
public class RecurringExecutionLog {

	@TableId
	private Long id;

	/**
	 * 冗余存一份，为的是首页「今天自动生成 N 笔」直接按 family_id + biz_date 计数，
	 * 不必 JOIN recurring_rule 去问「规则是谁家的」。
	 */
	private Long familyId;

	private Long ruleId;

	private LocalDate bizDate;

	private Long transactionId;

	/** 执行时刻。与 bizDate 的日期差就是「这笔是不是补记出来的」的判据。 */
	private LocalDateTime createdAt;

	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Long getFamilyId() {
		return this.familyId;
	}

	public void setFamilyId(Long familyId) {
		this.familyId = familyId;
	}

	public Long getRuleId() {
		return this.ruleId;
	}

	public void setRuleId(Long ruleId) {
		this.ruleId = ruleId;
	}

	public LocalDate getBizDate() {
		return this.bizDate;
	}

	public void setBizDate(LocalDate bizDate) {
		this.bizDate = bizDate;
	}

	public Long getTransactionId() {
		return this.transactionId;
	}

	public void setTransactionId(Long transactionId) {
		this.transactionId = transactionId;
	}

	public LocalDateTime getCreatedAt() {
		return this.createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

}
