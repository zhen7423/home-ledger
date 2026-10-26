package cn.homeledger.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 身高体重记录（§4.4.2）。
 * <p>
 * babyId 是裸列、不建外键：宝宝可被软删而历史记录要留得住，加了外键要么删不动宝宝、要么逼记录级联改。
 * <p>
 * 三个度量列都可空，「身高与体重至少填一项」由服务层跨字段判（§4.4.2）——这个约束库上表达不了「两列里
 * 至少一个非空」，而且写成 CHECK 也只会让违反者以 SQL 错误的形式冒成 500，而 §3.4 要求这类失败一律是
 * BAD_REQUEST 加一句明确文案。
 * <p>
 * created_at / updated_at 都不映射：本模块没有读它们的地方，DDL 的默认值与 ON UPDATE 负责写。
 */
@TableName("baby_growth")
public class BabyGrowth {

	@TableId
	private Long id;

	private Long familyId;

	private Long babyId;

	private LocalDate measureDate;

	private BigDecimal heightCm;

	private BigDecimal weightKg;

	private BigDecimal headCm;

	private String remark;

	private Long createdBy;

	/**
	 * 写入时刻，由 DDL 默认值填。映射它只为一件事：首页的最近动态要按它排序（§4.6 第 6 条）。
	 * 业务日期（{@code measure_date}）不能用——补录一条上个月的测量值，动态里该显示的是「刚记的」。
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

	public Long getBabyId() {
		return this.babyId;
	}

	public void setBabyId(Long babyId) {
		this.babyId = babyId;
	}

	public LocalDate getMeasureDate() {
		return this.measureDate;
	}

	public void setMeasureDate(LocalDate measureDate) {
		this.measureDate = measureDate;
	}

	public BigDecimal getHeightCm() {
		return this.heightCm;
	}

	public void setHeightCm(BigDecimal heightCm) {
		this.heightCm = heightCm;
	}

	public BigDecimal getWeightKg() {
		return this.weightKg;
	}

	public void setWeightKg(BigDecimal weightKg) {
		this.weightKg = weightKg;
	}

	public BigDecimal getHeadCm() {
		return this.headCm;
	}

	public void setHeadCm(BigDecimal headCm) {
		this.headCm = headCm;
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
