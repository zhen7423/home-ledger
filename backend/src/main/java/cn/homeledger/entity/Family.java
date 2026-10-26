package cn.homeledger.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 在租户白名单内（§5.2）：家庭行本身不带 family_id，其 id 就是 family_id。
 */
@TableName("family")
public class Family {

	@TableId
	private Long id;

	private String name;

	private Long ownerUserId;

	/** 邀请开关（第 33 轮）：0 关 / 1 开。开着才会有邀请码，关闭或已使用即清码并关入口。 */
	private Integer inviteEnabled;

	private String inviteCode;

	private LocalDateTime inviteCodeExpireAt;

	@TableLogic
	private Integer deleted;

	/** 解散时刻（§4.1.6）。解散时由 markDissolved 写入，30 天物理删除的起点。 */
	private LocalDateTime deletedAt;

	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Long getOwnerUserId() {
		return this.ownerUserId;
	}

	public void setOwnerUserId(Long ownerUserId) {
		this.ownerUserId = ownerUserId;
	}

	public Integer getInviteEnabled() {
		return this.inviteEnabled;
	}

	public void setInviteEnabled(Integer inviteEnabled) {
		this.inviteEnabled = inviteEnabled;
	}

	public String getInviteCode() {
		return this.inviteCode;
	}

	public void setInviteCode(String inviteCode) {
		this.inviteCode = inviteCode;
	}

	public LocalDateTime getInviteCodeExpireAt() {
		return this.inviteCodeExpireAt;
	}

	public void setInviteCodeExpireAt(LocalDateTime inviteCodeExpireAt) {
		this.inviteCodeExpireAt = inviteCodeExpireAt;
	}

	public Integer getDeleted() {
		return this.deleted;
	}

	public void setDeleted(Integer deleted) {
		this.deleted = deleted;
	}

	public LocalDateTime getDeletedAt() {
		return this.deletedAt;
	}

	public void setDeletedAt(LocalDateTime deletedAt) {
		this.deletedAt = deletedAt;
	}

}
