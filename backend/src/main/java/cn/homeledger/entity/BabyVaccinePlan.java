package cn.homeledger.entity;

import java.time.LocalDate;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 应种清单的一行（§4.4.4）。
 * <p>
 * status 只落四态 PENDING / DONE / SKIPPED / NA。「待接种 / 即将接种 / 逾期」不落库，由 dueDate 与
 * 今天现场算出——落库就得每天批量回写，跨天后库里仍是旧值，展示与存储随时自相矛盾，
 * 而这三个态本来不含任何用户输入。
 * <p>
 * manual 区分「用户手动建的自费项」与「字典生成的行」：它决定 DELETE 放不放行，
 * 也决定改生日重算时哪些行不参与对齐。
 * <p>
 * created_at / updated_at 都不映射：本模块没有读它们的地方，DDL 的默认值与 ON UPDATE 负责写。
 */
@TableName("baby_vaccine_plan")
public class BabyVaccinePlan {

	@TableId
	private Long id;

	private Long familyId;

	private Long babyId;

	private String vaccineName;

	private String doseNo;

	private LocalDate dueDate;

	/**
	 * 用户设定的计划接种日期（V20261026140000，2026-10-26 需求②），可空。
	 * <p>
	 * 与 {@code dueDate} 是<b>两层</b>：dueDate 是「程序表 + 出生日期」推导的原定应种日，改出生日期
	 * 整份重算只重写它；plannedDate 是用户「打算哪天去打」的覆盖值（约的接种门诊、错峰安排）。
	 * 重算<b>不碰</b> plannedDate——碰了等于把用户改的期悄悄平移掉。NULL = 未覆盖，按 dueDate 展示。
	 */
	private LocalDate plannedDate;

	private String status;

	private String skipReason;

	private Long recordId;

	private Integer manual;

	private Long createdBy;

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

	public LocalDate getDueDate() {
		return this.dueDate;
	}

	public void setDueDate(LocalDate dueDate) {
		this.dueDate = dueDate;
	}

	public LocalDate getPlannedDate() {
		return this.plannedDate;
	}

	public void setPlannedDate(LocalDate plannedDate) {
		this.plannedDate = plannedDate;
	}

	/**
	 * 展示口径的唯一定义：清单排序、展示态（逾期/即将/待接种）、完成率分母、「下一针」全部取它。
	 * 各调用方不得自己写 {@code plannedDate != null ? plannedDate : dueDate}——写三遍就是三个
	 * 可能互相矛盾的口径（与 BabyVaccineDisplay「只在算一次」同一条规矩）。
	 */
	public LocalDate effectiveDate() {
		return this.plannedDate != null ? this.plannedDate : this.dueDate;
	}

	public String getStatus() {
		return this.status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getSkipReason() {
		return this.skipReason;
	}

	public void setSkipReason(String skipReason) {
		this.skipReason = skipReason;
	}

	public Long getRecordId() {
		return this.recordId;
	}

	public void setRecordId(Long recordId) {
		this.recordId = recordId;
	}

	public Integer getManual() {
		return this.manual;
	}

	public void setManual(Integer manual) {
		this.manual = manual;
	}

	public Long getCreatedBy() {
		return this.createdBy;
	}

	public void setCreatedBy(Long createdBy) {
		this.createdBy = createdBy;
	}

	public Integer getDeleted() {
		return this.deleted;
	}

	public void setDeleted(Integer deleted) {
		this.deleted = deleted;
	}

}
