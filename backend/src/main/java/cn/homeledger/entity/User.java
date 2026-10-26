package cn.homeledger.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * created_at / updated_at 由 DDL 的 DEFAULT CURRENT_TIMESTAMP 与 ON UPDATE 维护，
 * 不映射进实体，避免应用侧与数据库侧两处都在写时间而出现不一致。
 */
@TableName("user")
public class User {

	@TableId
	private Long id;

	private String phone;

	private String passwordHash;

	private String nickname;

	@TableLogic
	private Integer deleted;

	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getPhone() {
		return this.phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public String getPasswordHash() {
		return this.passwordHash;
	}

	public void setPasswordHash(String passwordHash) {
		this.passwordHash = passwordHash;
	}

	public String getNickname() {
		return this.nickname;
	}

	public void setNickname(String nickname) {
		this.nickname = nickname;
	}

	public Integer getDeleted() {
		return this.deleted;
	}

	public void setDeleted(Integer deleted) {
		this.deleted = deleted;
	}

}
