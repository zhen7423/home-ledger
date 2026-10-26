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
import cn.homeledger.dto.BabyMedicalCreateRequest;
import cn.homeledger.dto.BabyMedicalUpdateRequest;
import cn.homeledger.service.BabyMedicalService;
import cn.homeledger.vo.BabyMedicalResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.4.5 就诊记录。全家共享，任何在籍成员可改。
 */
@Tag(name = "宝宝就诊记录", description = "§4.4.5 宝宝就诊记录")
@RestController
@RequestMapping("/api/v1/baby-medicals")
@RequiresFamily
public class BabyMedicalController {

	private final BabyMedicalService babyMedicalService;

	public BabyMedicalController(BabyMedicalService babyMedicalService) {
		this.babyMedicalService = babyMedicalService;
	}

	@Operation(summary = "就诊记录列表", description = "§4.4.5：按就诊日期降序、同日按 id 降序，不分页（就诊是回看）。"
			+ "babyId 不传即全家庭。没有 GET /baby-medicals/{id}——编辑表单从这份列表里回填。")
	@GetMapping
	public ApiResponse<List<BabyMedicalResponse>> list(@RequestParam(required = false) Long babyId) {
		return ApiResponse.ok(this.babyMedicalService.list(babyId));
	}

	@Operation(summary = "新增就诊记录", description = "§4.4.5：除宝宝与就诊日期外全是选填。费用金额按字符串收发，"
			+ "不可为负；它只是记录，不同步生成流水——就诊与记账是两件事。")
	@PostMapping
	public ApiResponse<BabyMedicalResponse> create(@Valid @RequestBody BabyMedicalCreateRequest request) {
		return ApiResponse.ok(this.babyMedicalService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "编辑就诊记录", description = "§4.4.5：整份表单覆盖，除就诊日期外每一列不传即清空（含费用）。"
			+ "归属宝宝改不了——babyId 不在请求体里，多传的键被忽略。")
	@PatchMapping("/{id}")
	public ApiResponse<BabyMedicalResponse> update(@PathVariable Long id,
			@Valid @RequestBody BabyMedicalUpdateRequest request) {
		return ApiResponse.ok(this.babyMedicalService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除就诊记录", description = "§4.4.5：软删除，无守卫。删的只是一条就诊记录，"
			+ "当初也没有替它记过账，所以账本不动。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.babyMedicalService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}
