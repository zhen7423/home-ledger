package cn.homeledger.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 解散家庭的物理清除（§4.1.6：解散保留 30 天后物理删除，需求 §12 S10）。
 * <p>
 * 与业务层的软删是两条互不干涉的轨道：软删（{@code @TableLogic} / 手写 deleted = 0）是常态，
 * 这里全部是真 DELETE，且不带 deleted 条件——要物理抹掉一个家庭，软删过的行和没删过的行一样得死。
 * <p>
 * 租户拦截器对这几张表照常注入 {@code family_id}（它们都不在白名单里），与手写条件重复但等值；
 * 调用方（{@code FamilyPurgeServiceImpl}）必须先把 {@code AuthContextHolder} 切到该家庭再调用，
 * 否则注入的是 -1 哨兵值，整个清除静默落空。切回形状照抄 PresetFinanceDictServiceImpl（R4 同源）。
 * <p>
 * 照片文件不在库里，清库只是断引用；磁盘上的照片由 service 层在事务提交后按这里收集到的
 * {@code photo_url} 逐个删。收集必须发生在删除之前，所以驱动顺序在 service 里，不依赖本接口。
 */
@Mapper
public interface PurgeMapper {

	/** 收集该家庭全部猫照片的相对路径（含已软删的猫 —— 反正整家都要抹掉）。 */
	List<String> collectCatPhotos(@Param("familyId") Long familyId);

	/** 收集该家庭全部宝宝照片的相对路径（含已归档与已软删的，口径同 {@link #collectCatPhotos}）。 */
	List<String> collectBabyPhotos(@Param("familyId") Long familyId);

	// 以下 19 个 delete 是同一批数据的固定顺序（FK 依赖 ⇒ 先删子表），全部在一个事务里执行：
	// recurring_execution_log 外键指 recurring_rule，必须先于它；其余表只挂 family_id，谁先谁后无碍，
	// 顺序固定只是让回滚日志与排查路径可预期。family 最后删——前面任何一张表删失败都要整体回滚。

	int deleteExecutionLogByFamily(@Param("familyId") Long familyId);

	int deleteRuleByFamily(@Param("familyId") Long familyId);

	int deleteTransactionByFamily(@Param("familyId") Long familyId);

	int deleteBudgetByFamily(@Param("familyId") Long familyId);

	int deleteAccountByFamily(@Param("familyId") Long familyId);

	int deleteCategoryByFamily(@Param("familyId") Long familyId);

	int deleteCatSettingByFamily(@Param("familyId") Long familyId);

	int deleteCatFoodBagByFamily(@Param("familyId") Long familyId);

	int deleteCatDewormingByFamily(@Param("familyId") Long familyId);

	int deleteCatByFamily(@Param("familyId") Long familyId);

	int deleteBabyGrowthByFamily(@Param("familyId") Long familyId);

	int deleteBabyPlanByFamily(@Param("familyId") Long familyId);

	int deleteBabyRecordByFamily(@Param("familyId") Long familyId);

	int deleteBabyMilestoneByFamily(@Param("familyId") Long familyId);

	int deleteBabyMedicalByFamily(@Param("familyId") Long familyId);

	int deleteBabyFormulaBagByFamily(@Param("familyId") Long familyId);

	int deleteBabyByFamily(@Param("familyId") Long familyId);

	int deleteMemberByFamily(@Param("familyId") Long familyId);

	int deleteFamilyRow(@Param("familyId") Long familyId);

}