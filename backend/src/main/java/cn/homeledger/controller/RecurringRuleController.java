package cn.homeledger.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.RecurringRuleCreateRequest;
import cn.homeledger.dto.RecurringRuleUpdateRequest;
import cn.homeledger.service.RecurringRuleService;
import cn.homeledger.vo.RecurringExecutionResponse;
import cn.homeledger.vo.RecurringRuleResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.2.3 周期性记账规则。
 * <p>
 * 规则全家共享、任何在籍成员都能建改停，created_by 只标谁建的，所以整类都要求已有家庭。
 */
@Tag(name = "周期记账", description = "§4.2.3 周期记账规则与执行记录")
@RestController
@RequestMapping("/api/v1/recurring-rules")
@RequiresFamily
public class RecurringRuleController {

	private final RecurringRuleService recurringRuleService;

	public RecurringRuleController(RecurringRuleService recurringRuleService) {
		this.recurringRuleService = recurringRuleService;
	}

	@Operation(summary = "规则列表", description = "§4.2.3：type 可选（EXPENSE / INCOME），不传则两类一起返回，按创建时间倒序。"
			+ "列表项里的类别名与支付方式名是实时解析的，字典改名后规则跟着显示新名。")
	@GetMapping
	public ApiResponse<List<RecurringRuleResponse>> list(@RequestParam(required = false) String type) {
		return ApiResponse.ok(this.recurringRuleService.list(type));
	}

	@Operation(summary = "新建规则", description = "§4.2.3：收支类型由服务端从所选大类读出，客户端不传 type。"
			+ "周期参数按 periodType 分别校验，多给了不属于该类型的字段报 PERIOD_VALUE_INVALID，数值越界报 PERIOD_RANGE_INVALID。"
			+ "startDate 缺省取今天。建成的同一事务内同步跑一次该规则的当天窗口，所以 start_date 已过、"
			+ "本月该生成的流水在创建当场就能在流水列表里看到（A4 当月立即生效）。")
	@PostMapping
	public ApiResponse<RecurringRuleResponse> create(@Valid @RequestBody RecurringRuleCreateRequest request) {
		return ApiResponse.ok(this.recurringRuleService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "规则详情", description = "§4.2.3：供编辑页回填。不属于本家庭或已删除的 id 一律 RECURRING_RULE_NOT_FOUND，"
			+ "不区分「不存在」与「是他家的」。")
	@GetMapping("/{id}")
	public ApiResponse<RecurringRuleResponse> get(@PathVariable Long id) {
		return ApiResponse.ok(this.recurringRuleService.get(id));
	}

	@Operation(summary = "编辑规则", description = "§4.2.3：整份覆盖式提交，null 就是空——把 endDate 清空即改回长期有效。"
			+ "改了周期参数或 startDate 时执行游标跟着重置，只改名称与金额不动游标。")
	@PutMapping("/{id}")
	public ApiResponse<RecurringRuleResponse> update(@PathVariable Long id,
			@Valid @RequestBody RecurringRuleUpdateRequest request) {
		return ApiResponse.ok(this.recurringRuleService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "启用 / 暂停规则", description = "§4.2.3：enabled 取反。从暂停切回启用时同样同步跑一次当天窗口；"
			+ "暂停不会把已经生成的流水删掉，恢复也不会把暂停期整段补出来。")
	@PatchMapping("/{id}/toggle")
	public ApiResponse<RecurringRuleResponse> toggle(@PathVariable Long id) {
		return ApiResponse.ok(this.recurringRuleService.toggle(AuthContextHolder.require().userId(), id));
	}

	@Operation(summary = "删除规则", description = "§4.2.3：逻辑删除，此后不再生成流水。它生成过的流水保留，"
			+ "流水列表里那些行仍带着 ruleId。二次确认在客户端做。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.recurringRuleService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

	@Operation(summary = "执行记录", description = "§4.2.3：按业务日期倒序，backfilled 为真的行是补记出来的"
			+ "（执行日晚于业务日）。数据只来自执行日志表，不 JOIN 流水：用户删掉某笔自动流水后这条记录仍要显示，"
			+ "它是审计轨迹，所以 transactionId 只用于展示、不做下钻。")
	@GetMapping("/{id}/executions")
	public ApiResponse<List<RecurringExecutionResponse>> executions(@PathVariable Long id) {
		return ApiResponse.ok(this.recurringRuleService.executions(id));
	}

}
