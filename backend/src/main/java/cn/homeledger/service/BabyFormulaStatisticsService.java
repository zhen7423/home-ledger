package cn.homeledger.service;

import cn.homeledger.vo.BabyFormulaStatisticsResponse;

/**
 * §4.5.3 奶粉消耗统计。家庭整体口径（不按宝宝分：奶粉与猫粮一样按家庭消耗记录，见
 * {@code BabyFormulaBagService}），因此没有可选的 `babyId` 入参。
 */
public interface BabyFormulaStatisticsService {

	BabyFormulaStatisticsResponse formula();

}