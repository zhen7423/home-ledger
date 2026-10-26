package cn.homeledger.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 用户级提醒开关（§4.5.1）。没有 family_id，因为同一家庭里两个人可以一个开一个关；
 * 本表在租户白名单里，拦截器不会替任何一条 SQL 补条件。
 * <p>
 * 行是懒创建的：没设置过的类型不在库里，由 service 用 {@code ReminderType} 的默认值补齐。
 */
@TableName("reminder_setting")
public class ReminderSetting {

	@TableId
	private Long id;

	private Long userId;

	/** ReminderType 枚举名。 */
	private String type;

	private Integer enabled;

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

	public String getType() {
		return this.type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public Integer getEnabled() {
		return this.enabled;
	}

	public void setEnabled(Integer enabled) {
		this.enabled = enabled;
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
