package cn.homeledger.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 周期性记账规则（§4.2.3）。规则本身不生成任何流水，是引擎每天读取的配置，
 * 所以类别与支付方式在这里存 id 而不是快照——类别改名后规则要跟着显示新名，与流水的语义相反。
 */
@TableName("recurring_rule")
public class RecurringRule {

	@TableId
	private Long id;

	private Long familyId;

	private String name;

	private String type;

	private BigDecimal amount;

	private Long categoryId;

	private Long subCategoryId;

	private Long accountId;

	private String periodType;

	/**
	 * 周期参数的 JSON 文本。四种 periodType 用的字段各不相同，反序列化成什么对象由 service 按
	 * periodType 决定，实体上不做翻译——否则一个字段要同时兼容四种形状。
	 */
	private String periodValue;

	private LocalDate startDate;

	private LocalDate endDate;

	private Integer enabled;

	/**
	 * 引擎已处理到的业务日期。补记窗口起点取 max(startDate, today-6, lastProcessedDate+1)，
	 * 缺这一列的话暂停半年的规则一恢复就会把整段历史补出来。
	 */
	private LocalDate lastProcessedDate;

	private Long createdBy;

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

	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
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

	public Long getSubCategoryId() {
		return this.subCategoryId;
	}

	public void setSubCategoryId(Long subCategoryId) {
		this.subCategoryId = subCategoryId;
	}

	public Long getAccountId() {
		return this.accountId;
	}

	public void setAccountId(Long accountId) {
		this.accountId = accountId;
	}

	public String getPeriodType() {
		return this.periodType;
	}

	public void setPeriodType(String periodType) {
		this.periodType = periodType;
	}

	public String getPeriodValue() {
		return this.periodValue;
	}

	public void setPeriodValue(String periodValue) {
		this.periodValue = periodValue;
	}

	public LocalDate getStartDate() {
		return this.startDate;
	}

	public void setStartDate(LocalDate startDate) {
		this.startDate = startDate;
	}

	public LocalDate getEndDate() {
		return this.endDate;
	}

	public void setEndDate(LocalDate endDate) {
		this.endDate = endDate;
	}

	public Integer getEnabled() {
		return this.enabled;
	}

	public void setEnabled(Integer enabled) {
		this.enabled = enabled;
	}

	public LocalDate getLastProcessedDate() {
		return this.lastProcessedDate;
	}

	public void setLastProcessedDate(LocalDate lastProcessedDate) {
		this.lastProcessedDate = lastProcessedDate;
	}

	public Long getCreatedBy() {
		return this.createdBy;
	}

	public void setCreatedBy(Long createdBy) {
		this.createdBy = createdBy;
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
