package cn.homeledger.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 猫咪档案（§4.3.1）。
 * <p>
 * 归档走 enabled = 0 而不是 deleted = 1：归档的猫要继续出现在历史统计、驱虫完成度和已有的猫粮袋归属里，
 * 而 {@link TableLogic} 的软删会让它在每一次查询中整体消失。deleted 只表达「这条记录不该存在」，
 * enabled 表达「不再参与新记录」。
 * <p>
 * createdAt 被映射是因为它参与业务计算——驱虫完成度的「应做次数」以建档日为起点（§4.3.5），
 * 不是审计字段顺带带出来的。updated_at 不映射：DDL 的 ON UPDATE 负责它，而本模块没有读它的地方。
 */
@TableName("cat")
public class Cat {

	@TableId
	private Long id;

	private Long familyId;

	private String name;

	private String gender;

	private LocalDate birthday;

	private Integer birthdayEstimated;

	private String breed;

	private BigDecimal weightKg;

	private String neutered;

	private String remark;

	/** 档案照片相对路径，由上传端点写入；整份表单覆盖的 overwrite 不动它（照片是独立操作）。 */
	private String photoUrl;

	private Integer enabled;

	private Long createdBy;

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

	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getGender() {
		return this.gender;
	}

	public void setGender(String gender) {
		this.gender = gender;
	}

	public LocalDate getBirthday() {
		return this.birthday;
	}

	public void setBirthday(LocalDate birthday) {
		this.birthday = birthday;
	}

	public Integer getBirthdayEstimated() {
		return this.birthdayEstimated;
	}

	public void setBirthdayEstimated(Integer birthdayEstimated) {
		this.birthdayEstimated = birthdayEstimated;
	}

	public String getBreed() {
		return this.breed;
	}

	public void setBreed(String breed) {
		this.breed = breed;
	}

	public BigDecimal getWeightKg() {
		return this.weightKg;
	}

	public void setWeightKg(BigDecimal weightKg) {
		this.weightKg = weightKg;
	}

	public String getNeutered() {
		return this.neutered;
	}

	public void setNeutered(String neutered) {
		this.neutered = neutered;
	}

	public String getRemark() {
		return this.remark;
	}

	public void setRemark(String remark) {
		this.remark = remark;
	}

	public String getPhotoUrl() {
		return this.photoUrl;
	}

	public void setPhotoUrl(String photoUrl) {
		this.photoUrl = photoUrl;
	}

	public Integer getEnabled() {
		return this.enabled;
	}

	public void setEnabled(Integer enabled) {
		this.enabled = enabled;
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
