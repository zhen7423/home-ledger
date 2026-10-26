package cn.homeledger.controller;

import org.springdoc.core.annotations.ParameterObject;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.CatFoodStatisticsRequest;
import cn.homeledger.service.CatStatisticsService;
import cn.homeledger.vo.CatDewormingStatisticsResponse;
import cn.homeledger.vo.CatFoodConsumptionResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * §4.3.5 猫咪统计。两条端点的入参刻意不对称：消耗那条收区间，驱虫那条固定近 12 个自然月、什么都不收。
 */
@Tag(name = "猫咪统计", description = "§4.3.5 猫粮消耗与驱虫统计")
@RestController
@RequestMapping("/api/v1/statistics/cat")
@RequiresFamily
public class CatStatisticsController {

	private final CatStatisticsService catStatisticsService;

	public CatStatisticsController(CatStatisticsService catStatisticsService) {
		this.catStatisticsService = catStatisticsService;
	}

	@Operation(summary = "猫粮消耗统计", description = "§4.3.5：概览三项（区间天数 / 总克数 / 日均）、品牌占比饼图、"
			+ "固定近 12 个自然月的逐月柱状、每袋用时列表、用完袋数一次返回。区间起止都可缺省，"
			+ "缺省时从最早那袋的开始日算到今天；endDate 晚于今天会截断到今天。")
	@GetMapping("/food-consumption")
	public ApiResponse<CatFoodConsumptionResponse> foodConsumption(@ParameterObject CatFoodStatisticsRequest query) {
		return ApiResponse.ok(this.catStatisticsService.foodConsumption(query));
	}

	@Operation(summary = "驱虫统计", description = "§4.3.5：完成度、时间轴、到期倒计时三块一次返回，窗口固定为近 12 个"
			+ "自然月且<b>不随任何入参变化</b>，所以这条端点没有查询参数。倒计时是全 App 的唯一来源，"
			+ "猫咪总览页与提醒判定读的都是它。")
	@GetMapping("/deworming")
	public ApiResponse<CatDewormingStatisticsResponse> deworming() {
		return ApiResponse.ok(this.catStatisticsService.deworming());
	}

}
