package cn.homeledger.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 宝宝档案（§4.4.1）。
 * <p>
 * 归档走 enabled = 0 而不是 deleted = 1：归档的宝宝要继续出现在生长曲线、历史统计与既有接种记录里，
 * 而 {@link TableLogic} 的软删会让它在每一次查询中整体消失。deleted 只表达「这条记录不该存在」，
 * enabled 表达「不再参与新记录」。
 * <p>
 * createdAt 被映射是因为它参与业务计算——档案列表「在册的在前、其后按建档先后」的第二个排序键就是它，
 * 不是审计字段顺带带出来的。updated_at 不映射：DDL 的 ON UPDATE 负责它，而本模块没有读它的地方。
 */
@TableName("baby")
public class Baby {

	@TableId
	private Long id;

	private Long familyId;

	private String name;

	private String gender;

	private LocalDate birthDate;

	private BigDecimal birthHeight;

	private BigDecimal birthWeight;

	private String remark;

	/** 档案照片相对路径，由上传端点写入；overwrite 不动它。 */
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

	public LocalDate getBirthDate() {
		return this.birthDate;
	}

	public void setBirthDate(LocalDate birthDate) {
		this.birthDate = birthDate;
	}

	public BigDecimal getBirthHeight() {
		return this.birthHeight;
	}

	public void setBirthHeight(BigDecimal birthHeight) {
		this.birthHeight = birthHeight;
	}

	public BigDecimal getBirthWeight() {
		return this.birthWeight;
	}

	public void setBirthWeight(BigDecimal birthWeight) {
		this.birthWeight = birthWeight;
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
