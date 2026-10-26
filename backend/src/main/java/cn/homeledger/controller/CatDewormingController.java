package cn.homeledger.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.CatDewormingCreateRequest;
import cn.homeledger.dto.CatDewormingUpdateRequest;
import cn.homeledger.service.CatDewormingService;
import cn.homeledger.vo.CatDewormingResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.3.3 体内外驱虫记录。按 done_date 倒序全量返回、不分页：一只猫一辈子几十条，分页在此没有对象。
 */
@Tag(name = "驱虫记录", description = "§4.3.3 体内外驱虫记录")
@RestController
@RequestMapping("/api/v1/cat-dewormings")
@RequiresFamily
public class CatDewormingController {

	private final CatDewormingService catDewormingService;

	public CatDewormingController(CatDewormingService catDewormingService) {
		this.catDewormingService = catDewormingService;
	}

	@Operation(summary = "驱虫记录列表", description = "§4.3.3：驱虫日期倒序、不分页，每行带 daysToDue / overdueDays "
			+ "两个互斥的倒计时字段。catId 不传即全家庭（时间轴视图要它）。归档猫的记录照旧出现，"
			+ "没有 GET /cat-dewormings/{id}——编辑表单从这份列表里回填。")
	@GetMapping
	public ApiResponse<List<CatDewormingResponse>> list(@RequestParam(required = false) Long catId) {
		return ApiResponse.ok(this.catDewormingService.list(catId));
	}

	@Operation(summary = "新增驱虫记录", description = "§4.3.3：驱虫日期不可晚于今天；下次驱虫日期不传就由服务端"
			+ "从驱虫日期按 cat_setting 的对应月数推算，传了则照抄不回算（用户手动覆盖）。已归档的猫不接受新记录。")
	@PostMapping
	public ApiResponse<CatDewormingResponse> create(@Valid @RequestBody CatDewormingCreateRequest request) {
		return ApiResponse.ok(this.catDewormingService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "修改驱虫记录", description = "§4.3.3：整份表单覆盖，规格/剂量与备注不传即清空。"
			+ "下次驱虫日期的可空含义与新建一致，改历史条目不会被猫后来的归档挡住。")
	@PatchMapping("/{id}")
	public ApiResponse<CatDewormingResponse> update(@PathVariable Long id,
			@Valid @RequestBody CatDewormingUpdateRequest request) {
		return ApiResponse.ok(this.catDewormingService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除驱虫记录", description = "§4.3.3：软删除，无守卫。删掉一条会同时改掉倒计时与驱虫完成度，"
			+ "所以统计缓存跟着失效。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.catDewormingService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}
