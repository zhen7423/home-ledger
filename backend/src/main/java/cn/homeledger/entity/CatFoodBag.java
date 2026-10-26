package cn.homeledger.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 一袋猫粮的喂养记录（§4.3.2），消耗推算的唯一数据源。
 * <p>
 * 表里的 active_started_date 是 STORED 生成列，这里刻意不映射：给生成列赋值会让 insert 直接报错。
 * created_at / updated_at 同样不映射，由数据库默认值维护，与 {@link PaymentAccount} 一致。
 */
@TableName("cat_food_bag")
public class CatFoodBag {

	@TableId
	private Long id;

	private Long familyId;

	private String brand;

	private int packGrams;

	private LocalDate startedDate;

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
