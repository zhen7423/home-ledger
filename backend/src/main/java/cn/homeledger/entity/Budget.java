package cn.homeledger.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 三维度预算（§4.2.4）。保存语义是整体替换，所以本表没有 updated_at 与 deleted——
 * 一次 PUT 就是把这家人的预算行全删了重插，改哪一行都看不出区别。
 */
@TableName("budget")
public class Budget {

	@TableId
	private Long id;

	private Long familyId;

	/** FAMILY / CATEGORY / MEMBER。 */
	private String scope;

	/** scope = CATEGORY 时填，且只能是大类。 */
	private Long categoryId;

	/** scope = MEMBER 时填，口径是流水的记录人（A5）。 */
	private Long memberUserId;

	/**
	 * 唯一性载体，由后端按 scope 派生成 FAMILY / C:&lt;id&gt; / M:&lt;id&gt;。
	 * <p>
	 * 不收客户端传入，也不用 UNIQUE(family_id, scope, category_id, member_user_id) 代替：
	 * MySQL 的唯一索引把 NULL 当互不相等，而 FAMILY 那一行的后两列必然是 NULL，
	 * 于是同一家庭可以塞进任意多行家庭总预算。
	 */
	private String bucketKey;

	private BigDecimal amount;

	/** 最后一次保存这批预算的人，不是这一行的创建人——整体替换会让它每次都变。 */
	private Long createdBy;

	private LocalDateTime createdAt;

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

	public String getScope() {
		return this.scope;
	}

	public void setScope(String scope) {
		this.scope = scope;
	}

	public Long getCategoryId() {
		return this.categoryId;
	}

	public void setCategoryId(Long categoryId) {
		this.categoryId = categoryId;
	}

	public Long getMemberUserId() {
		return this.memberUserId;
	}

	public void setMemberUserId(Long memberUserId) {
		this.memberUserId = memberUserId;
	}

	public String getBucketKey() {
		return this.bucketKey;
	}

	public void setBucketKey(String bucketKey) {
		this.bucketKey = bucketKey;
	}

	public BigDecimal getAmount() {
		return this.amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
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

}
