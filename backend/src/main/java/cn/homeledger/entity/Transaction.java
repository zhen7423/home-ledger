package cn.homeledger.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 收支流水（§4.2.1）。类别名、支付方式名、记录人昵称都存快照，字典改名或成员退出不回溯历史记录。
 */
@TableName("transaction")
public class Transaction {

	@TableId
	private Long id;

	private Long familyId;

	private String type;

	private BigDecimal amount;

	private Long categoryId;

	private String categoryNameSnapshot;

	private Long subCategoryId;

	private String subCategoryNameSnapshot;

	private Long accountId;

	private String accountNameSnapshot;

	private LocalDate bizDate;

	private String remark;

	private Long createdBy;

	private String recorderNameSnapshot;

	/** 周期记账规则 ID，S4 才回填，本期恒为 NULL。 */
	private Long ruleId;

	private LocalDateTime createdAt;

	private LocalDateTime updatedAt;

	@TableLogic
	private Integer deleted;

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

	public String getType() {
		return this.type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public BigDecimal getAmount() {
		return this.amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}

	public Long getCategoryId() {
		return this.categoryId;
	}

	public void setCategoryId(Long categoryId) {
		this.categoryId = categoryId;
	}

	public String getCategoryNameSnapshot() {
		return this.categoryNameSnapshot;
	}

	public void setCategoryNameSnapshot(String categoryNameSnapshot) {
		this.categoryNameSnapshot = categoryNameSnapshot;
	}

	public Long getSubCategoryId() {
		return this.subCategoryId;
	}

	public void setSubCategoryId(Long subCategoryId) {
		this.subCategoryId = subCategoryId;
	}

	public String getSubCategoryNameSnapshot() {
		return this.subCategoryNameSnapshot;
	}

	public void setSubCategoryNameSnapshot(String subCategoryNameSnapshot) {
		this.subCategoryNameSnapshot = subCategoryNameSnapshot;
	}

	public Long getAccountId() {
		return this.accountId;
	}

	public void setAccountId(Long accountId) {
		this.accountId = accountId;
	}

	public String getAccountNameSnapshot() {
		return this.accountNameSnapshot;
	}

	public void setAccountNameSnapshot(String accountNameSnapshot) {
		this.accountNameSnapshot = accountNameSnapshot;
	}

	public LocalDate getBizDate() {
		return this.bizDate;
	}

	public void setBizDate(LocalDate bizDate) {
		this.bizDate = bizDate;
	}

	public String getRemark() {
		return this.remark;
	}

	public void setRemark(String remark) {
		this.remark = remark;
	}

	public Long getCreatedBy() {
		return this.createdBy;
	}

	public void setCreatedBy(Long createdBy) {
		this.createdBy = createdBy;
	}

	public String getRecorderNameSnapshot() {
		return this.recorderNameSnapshot;
	}

	public void setRecorderNameSnapshot(String recorderNameSnapshot) {
		this.recorderNameSnapshot = recorderNameSnapshot;
	}

	public Long getRuleId() {
		return this.ruleId;
	}

	public void setRuleId(Long ruleId) {
		this.ruleId = ruleId;
	}

	public LocalDateTime getCreatedAt() {
		return this.createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	public LocalDateTime getUpdatedAt() {
		return this.updatedAt;
	}

	public void setUpdatedAt(LocalDateTime updatedAt) {
		this.updatedAt = updatedAt;
	}

	public Integer getDeleted() {
		return this.deleted;
	}

	public void setDeleted(Integer deleted) {
		this.deleted = deleted;
	}

}
