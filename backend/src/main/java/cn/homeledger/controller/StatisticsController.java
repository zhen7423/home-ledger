package cn.homeledger.controller;

import org.springdoc.core.annotations.ParameterObject;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.service.StatisticsService;
import cn.homeledger.vo.FinanceStatisticsResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * §4.2.6 记账统计。五块图表一次返回，不给前端拼装的责任；预算执行不在这个接口里，恒走 /budgets/progress。
 */
@Tag(name = "统计", description = "记账统计（§4.2.6）")
@RestController
@RequestMapping("/api/v1/statistics/finance")
@RequiresFamily
public class StatisticsController {

	private final StatisticsService statisticsService;

	public StatisticsController(StatisticsService statisticsService) {
		this.statisticsService = statisticsService;
	}

	@Operation(summary = "记账统计一次拿全",
			description = "类别占比（含每个大类内联的小类下钻）、最近 12 个自然月的收支趋势、区间内每日支出、"
					+ "支付方式占比、成员支出对比，五块一次返回。入参与流水列表完全相同，页面只用其中的时间范围与记录人两项。"
					+ "不含预算执行——那一块恒为当月，前端直接调 GET /budgets/progress。")
	@GetMapping("/overview")
	public ApiResponse<FinanceStatisticsResponse> overview(@ParameterObject TransactionQueryRequest query) {
		return ApiResponse.ok(this.statisticsService.financeOverview(query));
	}

}
