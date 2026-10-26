package cn.homeledger.controller;

import org.springdoc.core.annotations.ParameterObject;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.TransactionCreateRequest;
import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.dto.TransactionUpdateRequest;
import cn.homeledger.service.StatisticsService;
import cn.homeledger.service.TransactionService;
import cn.homeledger.vo.TransactionPageResponse;
import cn.homeledger.vo.TransactionResponse;
import cn.homeledger.vo.TransactionSummaryResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.2.1 记一笔 + §4.2.5 流水列表。
 * <p>
 * 流水全家共享、任何在籍成员可增删改，{@code created_by} 只做展示与筛选、不构成权限，所以整类都要求已有家庭。
 */
@Tag(name = "收支流水", description = "§4.2.1 记一笔 + §4.2.5 流水列表")
@RestController
@RequestMapping("/api/v1/transactions")
@RequiresFamily
public class TransactionController {

	private final TransactionService transactionService;

	private final StatisticsService statisticsService;

	public TransactionController(TransactionService transactionService, StatisticsService statisticsService) {
		this.transactionService = transactionService;
		this.statisticsService = statisticsService;
	}

	@Operation(summary = "流水分页", description = "§4.2.5：筛选条件全部可选，按 biz_date 倒序。size 默认 30、上限 200。"
			+ "响应里的 monthSummaries 是「同一套筛选下的全量」按月小计，不是当前页 30 条的小结——否则翻到第二页，"
			+ "月份合计就会跟着变。"
			+ "source 取 AUTO（只看周期记账自动生成的）或 MANUAL（只看手工记的），不传即不筛；传别的值报 BAD_REQUEST，"
			+ "不会静默当成没筛。这笔到底是不是自动生成的，看响应里的 ruleId 有没有值，不再另出一个来源字段。")
	@GetMapping
	public ApiResponse<TransactionPageResponse> page(@ParameterObject TransactionQueryRequest query) {
		return ApiResponse.ok(this.transactionService.page(query));
	}

	@Operation(summary = "区间概览",
			description = "收入 / 支出 / 结余 / 日均支出 / 笔数，以及解析之后的区间起止与天数。"
					+ "两个日期都不传即「全部历史」，此时 366 天上限不生效。导出页用它做「共 N 笔」的预查。")
	@GetMapping("/summary")
	public ApiResponse<TransactionSummaryResponse> summary(@ParameterObject TransactionQueryRequest query) {
		return ApiResponse.ok(this.statisticsService.summary(query));
	}

	@Operation(summary = "记一笔", description = "§4.2.1：收支类型由服务端从所选大类读出，客户端不传 type。"
			+ "记录人与三个字典项的名称在写入当时冻结成快照，之后改名、成员退出都不回溯历史（A3、§4.1.5）。"
			+ "金额最多两位小数且必须大于 0；bizDate 不能晚于今天，允许补记过去。")
	@PostMapping
	public ApiResponse<TransactionResponse> create(@Valid @RequestBody TransactionCreateRequest request) {
		return ApiResponse.ok(this.transactionService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "流水详情", description = "§4.2.1：列表项已带齐展示所需字段，这个端点供编辑页回填与深链使用。"
			+ "不属于本家庭或已删除的 id 一律 TRANSACTION_NOT_FOUND，不区分「不存在」与「是他家的」。")
	@GetMapping("/{id}")
	public ApiResponse<TransactionResponse> get(@PathVariable Long id) {
		return ApiResponse.ok(this.transactionService.get(id));
	}

	@Operation(summary = "编辑流水", description = "§4.2.1：整份表单覆盖式提交，null 就真的是空（小类与备注本可留空），"
			+ "不做「null 表示不改」。只有类别或账户相对原值变了才刷新对应名称快照，记录人快照恒不动。"
			+ "挂在已停用大类下的历史流水，只要没换类别就仍然可以改备注保存。")
	@PatchMapping("/{id}")
	public ApiResponse<TransactionResponse> update(@PathVariable Long id,
			@Valid @RequestBody TransactionUpdateRequest request) {
		return ApiResponse.ok(this.transactionService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除流水", description = "§4.2.5：软删除，列表里不再出现，但仍计入类别的「名下有无流水」判定——"
			+ "所以删光流水不能用来绕开「有流水的类别只能停用」这条。二次确认在客户端做。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.transactionService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}
