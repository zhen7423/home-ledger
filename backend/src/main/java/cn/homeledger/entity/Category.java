package cn.homeledger.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 两级收支类别（§4.2.2）。parent_id 为 NULL 的是大类，收入与支出两棵树互相独立。
 * <p>
 * icon_key 与 color_index 落库而不按 sort_no 现算：拖拽排序会改变 sort_no，若颜色跟着排序走，
 * 饼图跨月对比时同一个类别会换色。
 */
@TableName("category")
public class Category {

	@TableId
	private Long id;

	private Long familyId;

	private Long parentId;

	private String type;

	private String name;

	private String iconKey;

	private Integer colorIndex;

	private Integer sortNo;

	private Integer enabled;

	private Integer isPreset;

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

	public Long getParentId() {
		return this.parentId;
	}

	public void setParentId(Long parentId) {
		this.parentId = parentId;
	}

	public String getType() {
		return this.type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getIconKey() {
		return this.iconKey;
	}

	public void setIconKey(String iconKey) {
		this.iconKey = iconKey;
	}

	public Integer getColorIndex() {
		return this.colorIndex;
	}

	public void setColorIndex(Integer colorIndex) {
		this.colorIndex = colorIndex;
	}

	public Integer getSortNo() {
		return this.sortNo;
	}

	public void setSortNo(Integer sortNo) {
		this.sortNo = sortNo;
	}

	public Integer getEnabled() {
		return this.enabled;
	}

	public void setEnabled(Integer enabled) {
		this.enabled = enabled;
	}

	public Integer getIsPreset() {
		return this.isPreset;
	}

	public void setIsPreset(Integer isPreset) {
		this.isPreset = isPreset;
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
