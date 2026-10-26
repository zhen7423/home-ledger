package cn.homeledger.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 一罐奶粉的开罐记录（§4.5.3），消耗推算与统计的唯一数据源。
 * <p>
 * 表里的 active_started_date 是 STORED 生成列，这里刻意不映射：给生成列赋值会让 insert 直接报错。
 * created_at 由数据库默认值维护写入，但会被映射读取（首页最近动态要按它排序）；updated_at 不映射，与 {@link CatFoodBag} 一致。
 */
@TableName("baby_formula_bag")
public class BabyFormulaBag {

	@TableId
	private Long id;

	private Long familyId;

	private String brand;

	private int packGrams;

	private LocalDate startedDate;

	/**
	 * 开罐具体时间，选填（V20261026130000）。只用于展示「哪天几点开的罐」，不参与天级时间线
	 * 推导与统计——「同一天只能开一罐」的天级唯一口径不变。
	 */
	private LocalTime startedTime;

	/** 开罐时填的预计每天克数，选填；只在没有可用历史罐时兜底（见 ConsumptionEstimate）。 */
	private Integer estimatedDailyGrams;

	private String remark;

	private Long createdBy;

	/**
	 * 写入时刻，由 DDL 默认值填。映射它只为一件事：首页的最近动态要按它排序（§4.6 第 6 条）。
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

	public String getBrand() {
		return this.brand;
	}

	public void setBrand(String brand) {
		this.brand = brand;
	}

	public int getPackGrams() {
		return this.packGrams;
	}

	public void setPackGrams(int packGrams) {
		this.packGrams = packGrams;
	}

	public LocalDate getStartedDate() {
		return this.startedDate;
	}

	public void setStartedDate(LocalDate startedDate) {
		this.startedDate = startedDate;
	}

	public LocalTime getStartedTime() {
		return this.startedTime;
	}

	public void setStartedTime(LocalTime startedTime) {
		this.startedTime = startedTime;
	}

	public Integer getEstimatedDailyGrams() {
		return this.estimatedDailyGrams;
	}

	public void setEstimatedDailyGrams(Integer estimatedDailyGrams) {
		this.estimatedDailyGrams = estimatedDailyGrams;
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