package cn.homeledger.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 用户级模块开关与 Tab 顺序（§3.2、A1）。没有 family_id，因为同一家庭里两个人可以各看各的 Tab；
 * 本表在租户白名单里，拦截器不会替任何一条 SQL 补条件。
 * <p>
 * 行是懒创建的：没设置过的模块不在库里，由 service 用 {@code ModuleKey} 的默认值补齐。
 * 也正因为懒创建，读出来之后要按「库里有就用库里的、没有就用默认」合并一次，不能直接返回查询结果。
 */
@TableName("module_preference")
public class ModulePreference {

	@TableId
	private Long id;

	private Long userId;

	/** ModuleKey 枚举名。 */
	private String moduleKey;

	private Integer enabled;

	/** 中间三个 Tab 的展示顺序，由 PUT 的数组顺序派生。 */
	private Integer sortNo;

	private LocalDateTime createdAt;

	private LocalDateTime updatedAt;

	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Long getUserId() {
		return this.userId;
	}

	public void setUserId(Long userId) {
		this.userId = userId;
	}

	public String getModuleKey() {
		return this.moduleKey;
	}

	public void setModuleKey(String moduleKey) {
		this.moduleKey = moduleKey;
	}

	public Integer getEnabled() {
		return this.enabled;
	}

	public void setEnabled(Integer enabled) {
		this.enabled = enabled;
	}

	public Integer getSortNo() {
		return this.sortNo;
	}

	public void setSortNo(Integer sortNo) {
		this.sortNo = sortNo;
	}

	public LocalDateTime getCreatedAt() {
		return this.createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	public LocalDateTime getUpdatedAt() {
		return this.updatedAt;
	}

	public void setUpdatedAt(LocalDateTime updatedAt) {
		this.updatedAt = updatedAt;
	}

}
