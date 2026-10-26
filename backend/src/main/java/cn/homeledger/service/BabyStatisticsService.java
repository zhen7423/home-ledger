package cn.homeledger.service;

import cn.homeledger.vo.BabyGrowthStatisticsResponse;
import cn.homeledger.vo.BabyVaccineStatisticsResponse;

/**
 * §4.4.6 宝宝统计。两条端点按数据性质切开（第 24 轮 (o)）：{@link #growth} 的数据来自身高体重与标准表，
 * {@link #vaccine} 的来自应种清单、接种记录与里程碑。两条都不回生长曲线。
 * <p>
 * {@link #vaccine} 同时是疫苗提醒在全 App 的唯一数据源：{@code ReminderServiceImpl} 读它的
 * {@code upcoming} 与 {@code overdueList}，不另写一份查询——「哪一针该提醒」因此只有一处实现，
 * 与 S6 的 {@code CatStatisticsService#deworming} 同构。
 * <p>
 * 两条都接受可选的 {@code babyId}，不传 = 全家庭汇总（§4.4.6）。
 */
public interface BabyStatisticsService {

	BabyGrowthStatisticsResponse growth(Long babyId);

	BabyVaccineStatisticsResponse vaccine(Long babyId);

}
