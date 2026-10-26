package cn.homeledger.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.service.BabyFormulaStatisticsService;
import cn.homeledger.service.BabyStatisticsService;
import cn.homeledger.vo.BabyFormulaStatisticsResponse;
import cn.homeledger.vo.BabyGrowthStatisticsResponse;
import cn.homeledger.vo.BabyVaccineStatisticsResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * §4.4.6 宝宝统计。两条端点都收同一个可选 {@code babyId}：两个统计页各带一个宝宝筛选，
 * 缺省时返回全家庭——「全家庭」不是另一条端点，只是入参为空的同一条。
 */
@Tag(name = "宝宝统计", description = "§4.4.6 体格成长与疫苗接种统计")
@RestController
@RequestMapping("/api/v1/statistics/baby")
@RequiresFamily
public class BabyStatisticsController {

	private final BabyStatisticsService babyStatisticsService;

	private final BabyFormulaStatisticsService babyFormulaStatisticsService;

	public BabyStatisticsController(BabyStatisticsService babyStatisticsService,
			BabyFormulaStatisticsService babyFormulaStatisticsService) {
		this.babyStatisticsService = babyStatisticsService;
		this.babyFormulaStatisticsService = babyFormulaStatisticsService;
	}

	@Operation(summary = "体格成长统计", description = "§4.4.6：每个宝宝的最新一档与百分位段、三段增量（与上次、近 3 个月、"
			+ "近 12 个月）一次返回。百分位段由服务端按内置标准表插值算好，标准表本身不下发——"
			+ "曲线那条端点才带 546 行原始数据。babyId 缺省为全家庭，传了只返回那一个。")
	@GetMapping("/growth")
	public ApiResponse<BabyGrowthStatisticsResponse> growth(@RequestParam(required = false) Long babyId) {
		return ApiResponse.ok(this.babyStatisticsService.growth(babyId));
	}

	@Operation(summary = "疫苗接种统计", description = "§4.4.6：完成率、四态计数、待种与逾期两张小列表、近 12 个月接种时间轴，"
			+ "外加跨宝宝的里程碑时间轴。待种与逾期两张列表是全 App 疫苗提醒的唯一来源，"
			+ "宝宝总览页与提醒判定读的都是它。babyId 缺省为全家庭，传了只返回那一个。")
	@GetMapping("/vaccine")
	public ApiResponse<BabyVaccineStatisticsResponse> vaccine(@RequestParam(required = false) Long babyId) {
		return ApiResponse.ok(this.babyStatisticsService.vaccine(babyId));
	}

	@Operation(summary = "奶粉消耗统计", description = "§4.5.3：累计消耗、累计使用天数、区间日均与近 6 个月逐月消耗。"
			+ "家庭整体口径（奶粉按家庭记录，不按宝宝分），无入参；分辨率粗粒度按模块缓存。")
	@GetMapping("/formula")
	public ApiResponse<BabyFormulaStatisticsResponse> formula() {
		return ApiResponse.ok(this.babyFormulaStatisticsService.formula());
	}

}
