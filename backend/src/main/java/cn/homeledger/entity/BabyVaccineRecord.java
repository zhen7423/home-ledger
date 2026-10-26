package cn.homeledger.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 一条接种记录（§4.4.4）。
 * <p>
 * planId 与 baby_vaccine_plan.record_id 互为反向指针，两者都由服务层在同一事务内维护。
 * planId 为空是正常状态而不是数据不一致：自费疫苗的首次录入、名称写法不同的补种都没有对应行可回写。
 * <p>
 * nextDate 可空且 NULL 有含义——「该疫苗在本宝宝清单里没有未完成剂次」就是空。服务层在请求留空时
 * 按下一个 PENDING 剂次的 dueDate 推算并落库，而不是读时现算：S6 的 cat_deworming.next_date 是同一写法。
 * <p>
 * created_at / updated_at 都不映射：本模块没有读它们的地方，DDL 的默认值与 ON UPDATE 负责写。
 */
@TableName("baby_vaccine_record")
public class BabyVaccineRecord {

	@TableId
	private Long id;

	private Long familyId;

	private Long babyId;

	private Long planId;

	private String vaccineName;

	private String doseNo;

	private LocalDate givenDate;

	private String clinic;

	private String batchNo;

	private String reaction;

	private LocalDate nextDate;

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

	public Long getPlanId() {
		return this.planId;
	}

	public void setPlanId(Long planId) {
		this.planId = planId;
	}

	public String getVaccineName() {
		return this.vaccineName;
	}

	public void setVaccineName(String vaccineName) {
		this.vaccineName = vaccineName;
	}

	public String getDoseNo() {
		return this.doseNo;
	}

	public void setDoseNo(String doseNo) {
		this.doseNo = doseNo;
	}

	public LocalDate getGivenDate() {
		return this.givenDate;
	}

	public void setGivenDate(LocalDate givenDate) {
		this.givenDate = givenDate;
	}

	public String getClinic() {
		return this.clinic;
	}

	public void setClinic(String clinic) {
		this.clinic = clinic;
	}

	public String getBatchNo() {
		return this.batchNo;
	}

	public void setBatchNo(String batchNo) {
		this.batchNo = batchNo;
	}

	public String getReaction() {
		return this.reaction;
	}

	public void setReaction(String reaction) {
		this.reaction = reaction;
	}

	public LocalDate getNextDate() {
		return this.nextDate;
	}

	public void setNextDate(LocalDate nextDate) {
		this.nextDate = nextDate;
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
