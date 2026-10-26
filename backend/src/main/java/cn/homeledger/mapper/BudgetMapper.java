package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.Budget;

/**
 * budget 不在租户白名单内（§5.2），自定义 SQL 照项目约定显式写 family_id。
 * <p>
 * 本表没有 deleted 列，所以这里的删除是真删除——保存预算的语义是整体替换，留旧行没有任何意义，
 * 反倒会让 uk_budget_bucket 挡住重写同一维度。
 */
@Mapper
public interface BudgetMapper extends BaseMapper<Budget> {

	/** 整体替换的第一步：清掉这个家庭现有的全部预算行。 */
	int deleteAllByFamily(@Param("familyId") Long familyId);

	/**
	 * 成员退出家庭时删掉以他为维度的预算（B8）。
	 * <p>
	 * 只删 MEMBER 一行，不动 CATEGORY：他退出后「买菜」这一类照样要占家庭预算。
	 */
	int deleteMemberBudgets(@Param("familyId") Long familyId, @Param("userId") Long userId);

}
