package cn.homeledger.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 在租户白名单内（§5.2）：登录态本身要靠这张表解析出 familyId，若对它注入租户条件会形成鸡生蛋问题。
 * 因此本表的每一次访问都必须在应用层显式带上 family_id 或 user_id 条件，代码评审重点核对。
 */
@TableName("family_member")
public class FamilyMember {

	@TableId
	private Long id;

	private Long familyId;

	private Long userId;

	private String nicknameSnapshot;

	private String role;

	private LocalDateTime joinedAt;

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

	public Long getUserId() {
		return this.userId;
	}

	public void setUserId(Long userId) {
		this.userId = userId;
	}

	public String getNicknameSnapshot() {
		return this.nicknameSnapshot;
	}

	public void setNicknameSnapshot(String nicknameSnapshot) {
		this.nicknameSnapshot = nicknameSnapshot;
	}

	public String getRole() {
		return this.role;
	}

	public void setRole(String role) {
		this.role = role;
	}

	public LocalDateTime getJoinedAt() {
		return this.joinedAt;
	}

	public void setJoinedAt(LocalDateTime joinedAt) {
		this.joinedAt = joinedAt;
	}

	public Integer getDeleted() {
		return this.deleted;
	}

	public void setDeleted(Integer deleted) {
		this.deleted = deleted;
	}

}
