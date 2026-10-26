package cn.homeledger.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 猫咪模块的家庭级设置（§4.3.3 A8）：驱虫周期月数与没有任何真实袋子时的兜底日均克数。
 * <p>
 * 本表没有 deleted 列，所以本类也没有（§7.2 例外清单）：PUT 是整份 upsert，留着软删列会让它命中软删行时
 * 查不到而行、转去 INSERT 撞 uk_cat_setting_family，留下一个用户在界面上永远修不掉的 500。
 * <p>
 * estimatedDailyGrams 用包装类型：null 是「用户没填」，而 0 是非法值，两者不能塌成一个。
 * created_at / updated_at 不映射，由数据库默认值维护。
 */
@TableName("cat_setting")
public class CatSetting {

	@TableId
	private Long id;

	private Long familyId;

	private int internalMonths;

	private int externalMonths;

	private Integer estimatedDailyGrams;

	private Long createdBy;

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

	public int getInternalMonths() {
		return this.internalMonths;
	}

	public void setInternalMonths(int internalMonths) {
		this.internalMonths = internalMonths;
	}

	public int getExternalMonths() {
		return this.externalMonths;
	}

	public void setExternalMonths(int externalMonths) {
		this.externalMonths = externalMonths;
	}

	public Integer getEstimatedDailyGrams() {
		return this.estimatedDailyGrams;
	}

	public void setEstimatedDailyGrams(Integer estimatedDailyGrams) {
		this.estimatedDailyGrams = estimatedDailyGrams;
	}

	public Long getCreatedBy() {
		return this.createdBy;
	}

	public void setCreatedBy(Long createdBy) {
		this.createdBy = createdBy;
	}

}
