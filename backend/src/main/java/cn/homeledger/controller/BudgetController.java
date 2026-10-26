package cn.homeledger.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.BudgetSaveRequest;
import cn.homeledger.service.BudgetService;
import cn.homeledger.vo.BudgetProgressResponse;
import cn.homeledger.vo.BudgetResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.2.4 三维度预算。
 * <p>
 * 预算是整个家庭共用的「这个月打算花多少」，不是各人各一份，所以只有一个 GET 与一个整份覆盖的 PUT，
 * 没有按 id 的单条改删。
 */
@Tag(name = "预算", description = "§4.2.4 总额 / 类别 / 成员三维度预算与执行情况")
@RestController
@RequestMapping("/api/v1/budgets")
@RequiresFamily
public class BudgetController {

	private final BudgetService budgetService;

	public BudgetController(BudgetService budgetService) {
		this.budgetService = budgetService;
	}

	@Operation(summary = "预算列表", description = "§4.2.4：本家庭的全部预算行，按创建先后排列。"
			+ "类别名与成员名实时解析，字典改大类名、成员改昵称后这里跟着显示新名。没设过预算返回空数组。")
	@GetMapping
	public ApiResponse<List<BudgetResponse>> list() {
		return ApiResponse.ok(this.budgetService.list());
	}

	@Operation(summary = "保存预算", description = "§4.2.4：整份覆盖式提交——列表里没出现的维度就等于删掉，"
			+ "items 传空数组（或 null）就是清空全部预算。所以客户端每次要把界面上留着的行全带上，"
			+ "不能只提交本次改动的那一条。"
			+ "维度与字段必须严格对齐：FAMILY 两个 id 都不许带，CATEGORY 只带 categoryId，MEMBER 只带 memberUserId，"
			+ "对不上报 BUDGET_SCOPE_INVALID；类别预算设在小类上报 BUDGET_CATEGORY_NOT_MAJOR，"
			+ "但设在大类且该大类已停用是允许的（历史流水还在往里记）；成员不在本家庭报 BUDGET_MEMBER_NOT_IN_FAMILY；"
			+ "同一维度在一份请求里出现两次报 BUDGET_DUPLICATED。"
			+ "<b>落库是先物理删干净再重插，所以每次保存后所有预算行的 id 都会变</b>——"
			+ "前端不要持有 id 做任何事（没有按 id 的接口），也不要把 id 当缓存键。")
	@PutMapping
	public ApiResponse<Void> save(@Valid @RequestBody BudgetSaveRequest request) {
		this.budgetService.save(AuthContextHolder.require().userId(), request);
		return ApiResponse.ok();
	}

	@Operation(summary = "执行情况", description = "§4.2.4：把每条预算在指定月份里的已用 / 剩余 / 百分比算出来。"
			+ "month 形如 2026-09，缺省取当月；格式不对报 BAD_REQUEST。过去和未来的月份都允许查，"
			+ "只是 remainingDays 只对当月有意义，其余一律 0。"
			+ "已用只统计 EXPENSE（收入不进预算口径），类别维度按大类汇总——流水无论填没填小类，"
			+ "大类恒记在 category_id 上，所以小类的钱天然算进所属大类；成员维度按流水的 created_by 归人。"
			+ "usedPercent 向下取整，档位 level 用未取整的比值判定（≥80% 且 <100% 为 WARNING，≥100% 为 EXCEEDED），"
			+ "所以不会出现「显示 80% 却还没进预警」。remaining 超支时为负数，前端照原样显示。")
	@GetMapping("/progress")
	public ApiResponse<List<BudgetProgressResponse>> progress(@RequestParam(required = false) String month) {
		return ApiResponse.ok(this.budgetService.progress(month));
	}

}
