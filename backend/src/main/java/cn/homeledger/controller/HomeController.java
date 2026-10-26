package cn.homeledger.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.service.HomeService;
import cn.homeledger.vo.HomeOverviewResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * §4.6 首页聚合。一条端点换掉首页原来的两次请求（自动记账块、预算块）。
 * <p>
 * 要求家庭上下文：首页看的是家庭账。无家庭的人走不到首页，路由守卫会把他送去引导页，
 * 这里跟着返回 403 是同一件事在两端各说一遍。
 */
@Tag(name = "首页", description = "§4.6 首页聚合数据")
@RestController
@RequestMapping("/api/v1/home")
@RequiresFamily
public class HomeController {

	private final HomeService homeService;

	public HomeController(HomeService homeService) {
		this.homeService = homeService;
	}

	@Operation(summary = "首页聚合数据", description = "概要（本月收支结余、当月已记录天数、今日自动生成笔数）"
			+ "+ 家庭全部预算维度 + 最近 5 条动态，一次返回。"
			+ "**待办提醒不在其中**：那份数据由 GET /reminders/pending 出，首页的提醒卡片区与红点读同一份，"
			+ "因为「今天已经划掉」是设备级状态，只有客户端手里那份列表滤得掉。"
			+ "最近动态按调用者的模块开关过滤——关掉猫咪模块就不会出现猫咪条目（§4.6 第 6 条）。")
	@GetMapping("/overview")
	public ApiResponse<HomeOverviewResponse> overview() {
		return ApiResponse.ok(this.homeService.overview(AuthContextHolder.require().userId()));
	}

}
