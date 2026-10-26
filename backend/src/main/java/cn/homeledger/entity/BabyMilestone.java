package cn.homeledger.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 一条里程碑（§4.4.5）。
 * <p>
 * title 不加字典：内置常用项是前端一份常量清单，用户选它和自由输入落的是同一列，库里没有区别。
 * <p>
 * created_at / updated_at 都不映射：本模块没有读它们的地方，DDL 的默认值与 ON UPDATE 负责写。
 */
@TableName("baby_milestone")
public class BabyMilestone {

	@TableId
	private Long id;

	private Long familyId;

	private Long babyId;

	private LocalDate occurDate;

	private String title;

	private String description;

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

	public LocalDate getOccurDate() {
		return this.occurDate;
	}

	public void setOccurDate(LocalDate occurDate) {
		this.occurDate = occurDate;
	}

	public String getTitle() {
		return this.title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public String getDescription() {
		return this.description;
	}

	public void setDescription(String description) {
		this.description = description;
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
