package cn.homeledger.service;

import cn.homeledger.dto.CatFoodStatisticsRequest;
import cn.homeledger.vo.CatDewormingStatisticsResponse;
import cn.homeledger.vo.CatFoodConsumptionResponse;

/**
 * §4.3.5 猫咪统计。两条端点<b>入参刻意不对称</b>：消耗那条收区间，驱虫那条什么都不收。
 * <p>
 * {@link #deworming()} 同时是「距下次驱虫 N 天」在全 App 的唯一来源：猫咪总览页与统计页读的是它的
 * 缓存结果，待提醒项的判定也算在它头上——三处同值由这一个方法保证。
 */
public interface CatStatisticsService {

	CatFoodConsumptionResponse foodConsumption(CatFoodStatisticsRequest query);

	CatDewormingStatisticsResponse deworming();

}
