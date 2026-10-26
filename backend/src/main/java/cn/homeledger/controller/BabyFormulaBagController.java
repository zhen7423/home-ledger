package cn.homeledger.controller;

import java.util.List;

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
import cn.homeledger.dto.BabyFormulaBagCreateRequest;
import cn.homeledger.dto.BabyFormulaBagUpdateRequest;
import cn.homeledger.service.BabyFormulaBagService;
import cn.homeledger.vo.BabyFormulaBagResponse;
import cn.homeledger.vo.BabyFormulaCurrentResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.5.3 奶粉开罐记录。按 started_date 升序全量返回、不分页：一个家庭最多几十罐，分页在此没有对象。
 */
@Tag(name = "奶粉开罐记录", description = "§4.5.3 奶粉开罐记录")
@RestController
@RequestMapping("/api/v1/baby-formula-bags")
@RequiresFamily
public class BabyFormulaBagController {

	private final BabyFormulaBagService babyFormulaBagService;

	public BabyFormulaBagController(BabyFormulaBagService babyFormulaBagService) {
		this.babyFormulaBagService = babyFormulaBagService;
	}

	@Operation(summary = "当前罐与余量推算", description = "§4.5.3 宝宝主页的奶粉卡。无入参——它是「此刻还剩多少」。"
			+ "一罐都还没有时 bag 与 estimate 都是 null；开了罐但推不出（没有可用历史罐、也没填预估日均）时"
			+ "只 estimate 为 null，因为界面上这两件事的提示语不同。")
	@GetMapping("/current")
	public ApiResponse<BabyFormulaCurrentResponse> current() {
		return ApiResponse.ok(this.babyFormulaBagService.current());
	}

	@Operation(summary = "奶粉开罐列表", description = "§4.5.3：按 started_date 升序、不分页。每行除落库字段外必带"
			+ " usageDays / dailyAverage / current 三个派生字段，全部出自服务端的同一份推导，客户端不重算。")
	@GetMapping
	public ApiResponse<List<BabyFormulaBagResponse>> list() {
		return ApiResponse.ok(this.babyFormulaBagService.list());
	}

	@Operation(summary = "新开一罐奶粉", description = "§4.5.3：开罐日期可回溯填过去、不可晚于今天；"
			+ "一个家庭同一天只能开一罐，应用层查重与库上的 uk_formula_bag_family_active 给的是同一句话。"
			+ "预估日均选填，只在没有可用历史罐时兜底。")
	@PostMapping
	public ApiResponse<BabyFormulaBagResponse> create(@Valid @RequestBody BabyFormulaBagCreateRequest request) {
		return ApiResponse.ok(this.babyFormulaBagService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "修改一罐奶粉", description = "§4.5.3：整份表单覆盖，预估日均与备注不传即清空。"
			+ "改开罐日只是把这一罐在时间线上挪位置，前后两罐的结束日与使用天数随之重新推导，无需另外发请求。")
	@PatchMapping("/{id}")
	public ApiResponse<BabyFormulaBagResponse> update(@PathVariable Long id,
			@Valid @RequestBody BabyFormulaBagUpdateRequest request) {
		return ApiResponse.ok(this.babyFormulaBagService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除一罐奶粉", description = "§4.5.3：软删除。删掉中间那罐会让前后两罐自动重新闭合；"
			+ "删除会把该行的开罐日退出唯一索引，所以补录时用同一个开罐日重录一次是允许的。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.babyFormulaBagService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}