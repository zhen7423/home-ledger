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
import cn.homeledger.dto.PaymentAccountCreateRequest;
import cn.homeledger.dto.PaymentAccountSortRequest;
import cn.homeledger.dto.PaymentAccountUpdateRequest;
import cn.homeledger.service.PaymentAccountService;
import cn.homeledger.vo.PaymentAccountResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.2.1 支付方式字典。全家共享、任何在籍成员可改。
 */
@Tag(name = "支付方式", description = "§4.2.1 支付方式字典")
@RestController
@RequestMapping("/api/v1/payment-accounts")
@RequiresFamily
public class PaymentAccountController {

	private final PaymentAccountService paymentAccountService;

	public PaymentAccountController(PaymentAccountService paymentAccountService) {
		this.paymentAccountService = paymentAccountService;
	}

	@Operation(summary = "支付方式列表", description = "§4.2.1：按 sort_no 升序。enabledOnly=true 只返回启用中的项，供记账表单用；"
			+ "管理页要把停用的也一并显示出来，否则没法重新启用。")
	@GetMapping
	public ApiResponse<List<PaymentAccountResponse>> list(@RequestParam(defaultValue = "false") boolean enabledOnly) {
		return ApiResponse.ok(this.paymentAccountService.list(enabledOnly));
	}

	@Operation(summary = "新建支付方式", description = "§4.2.1：名称 ≤ 8 字、去空格后在本家庭内不可重名。新建出来的项一律不是默认项，"
			+ "要设默认走 PATCH。")
	@PostMapping
	public ApiResponse<PaymentAccountResponse> create(@Valid @RequestBody PaymentAccountCreateRequest request) {
		return ApiResponse.ok(this.paymentAccountService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "改名 / 设为默认", description = "§8「默认项不单开端点」：name 与 isDefault 都可空，空表示不改。"
			+ "isDefault=true 时同一事务内先清掉旧默认再置本行，家庭里恒有一行为默认；已停用的项不能设为默认。")
	@PatchMapping("/{id}")
	public ApiResponse<PaymentAccountResponse> update(@PathVariable Long id,
			@Valid @RequestBody PaymentAccountUpdateRequest request) {
		return ApiResponse.ok(this.paymentAccountService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "启用 / 停用支付方式", description = "§4.2.1：当前默认项不可停用，要先把它换成别的。"
			+ "停用的项不能再用于新记录，历史记录照旧显示它当时的名称快照。")
	@PatchMapping("/{id}/toggle")
	public ApiResponse<PaymentAccountResponse> toggle(@PathVariable Long id) {
		return ApiResponse.ok(this.paymentAccountService.toggle(AuthContextHolder.require().userId(), id));
	}

	@Operation(summary = "删除支付方式", description = "§4.2.1：物理删除。名下有任何流水（含已软删除）即返回 PAYMENT_ACCOUNT_IN_USE，"
			+ "只能停用；当前默认项须先让位。预置的 8 项没有 is_preset 标记，无流水时可以删除。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.paymentAccountService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

	@Operation(summary = "支付方式拖拽排序", description = "§4.2.1：orderedIds 必须给全家庭内每一行（含停用的），服务端按数组顺序把 "
			+ "sort_no 重写为 1…n，少给或多给都返回 SORT_IDS_MISMATCH。")
	@PutMapping("/sort")
	public ApiResponse<Void> sort(@Valid @RequestBody PaymentAccountSortRequest request) {
		this.paymentAccountService.sort(AuthContextHolder.require().userId(), request);
		return ApiResponse.ok();
	}

}
