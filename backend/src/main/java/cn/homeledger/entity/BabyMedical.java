package cn.homeledger.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 一条就诊记录（§4.4.5）。
 * <p>
 * costAmount 只是记录，不同步生成流水（§4.4.5）——就诊与记账是两件事，种下同步会让删掉就诊记录时
 * 那条流水留在账上，或者反过来被删掉，两边都不该由另一边决定。
 * <p>
 * created_at / updated_at 都不映射：本模块没有读它们的地方，DDL 的默认值与 ON UPDATE 负责写。
 */
@TableName("baby_medical")
public class BabyMedical {

	@TableId
	private Long id;

	private Long familyId;

	private Long babyId;

	private LocalDate visitDate;

	private String hospital;

	private String department;

	private String diagnosis;

	private String medicine;

	private BigDecimal costAmount;

	private String remark;

	private Long createdBy;

	/**
	 * 写入时刻，由 DDL 默认值填。映射它只为一件事：首页的最近动态要按它排序（§4.6 第 6 条）。
	 * 业务日期不能用——补录一条上个月的记录，动态里该显示的是「刚记的」。
	 */
	private LocalDateTime createdAt;

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

	public Long getBabyId() {
		return this.babyId;
	}

	public void setBabyId(Long babyId) {
		this.babyId = babyId;
	}

	public LocalDate getVisitDate() {
		return this.visitDate;
	}

	public void setVisitDate(LocalDate visitDate) {
		this.visitDate = visitDate;
	}

	public String getHospital() {
		return this.hospital;
	}

	public void setHospital(String hospital) {
		this.hospital = hospital;
	}

	public String getDepartment() {
		return this.department;
	}

	public void setDepartment(String department) {
		this.department = department;
	}

	public String getDiagnosis() {
		return this.diagnosis;
	}

	public void setDiagnosis(String diagnosis) {
		this.diagnosis = diagnosis;
	}

	public String getMedicine() {
		return this.medicine;
	}

	public void setMedicine(String medicine) {
		this.medicine = medicine;
	}

	public BigDecimal getCostAmount() {
		return this.costAmount;
	}

	public void setCostAmount(BigDecimal costAmount) {
		this.costAmount = costAmount;
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

	public LocalDateTime getCreatedAt() {
		return this.createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	public Integer getDeleted() {
		return this.deleted;
	}

	public void setDeleted(Integer deleted) {
		this.deleted = deleted;
	}

}
