package cn.homeledger.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 一条体内外驱虫记录（§4.3.3）。
 * <p>
 * next_date 在库里是 NOT NULL：算不出下次日期在这里等价于「还没填驱虫日期」，界面该显示输入框而不是空白，
 * 所以不给倒计时与完成度各写一套 null 分支。
 * <p>
 * cat_id 是裸列、库上没有外键：猫可以先删而驱虫历史要留得住（§7.2）。
 */
@TableName("cat_deworming")
public class CatDeworming {

	@TableId
	private Long id;

	private Long familyId;

	private Long catId;

	private String type;

	private LocalDate doneDate;

	private String medicine;

	private String dosage;

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

	public Long getCatId() {
		return this.catId;
	}

	public void setCatId(Long catId) {
		this.catId = catId;
	}

	public String getType() {
		return this.type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public LocalDate getDoneDate() {
		return this.doneDate;
	}

	public void setDoneDate(LocalDate doneDate) {
		this.doneDate = doneDate;
	}

	public String getMedicine() {
		return this.medicine;
	}

	public void setMedicine(String medicine) {
		this.medicine = medicine;
	}

	public String getDosage() {
		return this.dosage;
	}

	public void setDosage(String dosage) {
		this.dosage = dosage;
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
