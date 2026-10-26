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
import cn.homeledger.dto.CatFoodBagCreateRequest;
import cn.homeledger.dto.CatFoodBagUpdateRequest;
import cn.homeledger.service.CatFoodBagService;
import cn.homeledger.vo.CatFoodBagResponse;
import cn.homeledger.vo.CatFoodCurrentResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.3.2 猫粮袋记录。按 started_date 升序全量返回、不分页：一个家庭最多几十袋，分页在此没有对象。
 */
@Tag(name = "猫粮袋记录", description = "§4.3.2 猫粮袋记录")
@RestController
@RequestMapping("/api/v1/cat-food-bags")
@RequiresFamily
public class CatFoodBagController {

	private final CatFoodBagService catFoodBagService;

	public CatFoodBagController(CatFoodBagService catFoodBagService) {
		this.catFoodBagService = catFoodBagService;
	}

	@Operation(summary = "当前袋与余量推算", description = "§4.3.4 总览页的余量卡。无入参——它是「此刻还剩多少」，"
			+ "给它加时间区间就成了统计。一袋都没有时 bag 与 estimate 都是 null；开了袋但推不出（没有可用历史、"
			+ "也没填预估日均）时只 estimate 为 null，因为界面上这两件事的提示语不同。")
	@GetMapping("/current")
	public ApiResponse<CatFoodCurrentResponse> current() {
		return ApiResponse.ok(this.catFoodBagService.current());
	}

	@Operation(summary = "猫粮袋列表", description = "§4.3.2：按 started_date 升序、不分页。每行除落库字段外必带"
			+ " usageDays / dailyAverage / current 三个派生字段，全部出自服务端的同一份推导，客户端不重算。")
	@GetMapping
	public ApiResponse<List<CatFoodBagResponse>> list() {
		return ApiResponse.ok(this.catFoodBagService.list());
	}

	@Operation(summary = "新开一袋猫粮", description = "§4.3.2：开始喂养日期可回溯填过去、不可晚于今天；"
			+ "一个家庭同一天只能开一袋，应用层查重与库上的 uk_food_bag_family_active 给的是同一句话。")
	@PostMapping
	public ApiResponse<CatFoodBagResponse> create(@Valid @RequestBody CatFoodBagCreateRequest request) {
		return ApiResponse.ok(this.catFoodBagService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "修改一袋猫粮", description = "§4.3.2：整份表单覆盖，备注不传即清空。"
			+ "改开始日只是把这一袋在时间线上挪位置，前后两袋的结束日与使用天数随之重新推导，无需另外发请求。")
	@PatchMapping("/{id}")
	public ApiResponse<CatFoodBagResponse> update(@PathVariable Long id,
			@Valid @RequestBody CatFoodBagUpdateRequest request) {
		return ApiResponse.ok(this.catFoodBagService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除一袋猫粮", description = "§4.3.2：软删除。删掉中间那袋会让前后两袋自动重新闭合；"
			+ "删除会把该行的开始日退出唯一索引，所以补录时用同一个开始日重录一次是允许的。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.catFoodBagService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}
