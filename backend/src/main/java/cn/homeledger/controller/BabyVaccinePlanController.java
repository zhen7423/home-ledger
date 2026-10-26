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
import cn.homeledger.dto.BabyVaccinePlanCreateRequest;
import cn.homeledger.dto.BabyVaccinePlanPlannedDateRequest;
import cn.homeledger.dto.BabyVaccinePlanUpdateRequest;
import cn.homeledger.service.BabyVaccinePlanService;
import cn.homeledger.vo.BabyVaccinePlanResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.4.4 应种清单。全家共享，任何在籍成员可改。
 */
@Tag(name = "应种清单", description = "§4.4.4 应种清单")
@RestController
@RequestMapping("/api/v1/baby-vaccine-plans")
@RequiresFamily
public class BabyVaccinePlanController {

	private final BabyVaccinePlanService babyVaccinePlanService;

	public BabyVaccinePlanController(BabyVaccinePlanService babyVaccinePlanService) {
		this.babyVaccinePlanService = babyVaccinePlanService;
	}

	@Operation(summary = "应种清单", description = "§4.4.4：按应种日期升序、同日按 id 升序，不分页。babyId 不传即全家庭。"
			+ "每行带 displayStatus（VACCINATED / MARKED / OVERDUE / DUE_SOON / UPCOMING），它由 dueDate 与今天"
			+ "现场算出、不落库——库里只有 PENDING / DONE / SKIPPED / NA 四态。没有 GET /baby-vaccine-plans/{id}。")
	@GetMapping
	public ApiResponse<List<BabyVaccinePlanResponse>> list(@RequestParam(required = false) Long babyId) {
		return ApiResponse.ok(this.babyVaccinePlanService.list(babyId));
	}

	@Operation(summary = "手动新增自费应种项", description = "§4.4.4：疫苗名称 + 剂次 + 应种日期，落 manual = 1。"
			+ "手动行不参与改出生日期时的整份重算，且可以删除；字典生成的行只能标记跳过 / 不适用。"
			+ "同宝宝已存在同 (疫苗名称, 剂次) 的行即拒，应种日期早于出生日期即拒。")
	@PostMapping
	public ApiResponse<BabyVaccinePlanResponse> create(@Valid @RequestBody BabyVaccinePlanCreateRequest request) {
		return ApiResponse.ok(this.babyVaccinePlanService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "标记跳过 / 不适用 / 撤销", description = "§4.4.4：status 只接受 SKIPPED / NA 与撤销用的 PENDING；"
			+ "DONE 只由接种记录回写，手工写入即拒。标记时 reason 必填，撤销时忽略并清空库里那一列。"
			+ "改应种日期 / 疫苗名称 / 剂次一律不可能——这三个键在请求体里根本不存在，多传的键被忽略。")
	@PatchMapping("/{id}")
	public ApiResponse<BabyVaccinePlanResponse> update(@PathVariable Long id,
			@Valid @RequestBody BabyVaccinePlanUpdateRequest request) {
		return ApiResponse.ok(this.babyVaccinePlanService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "设置 / 清除计划接种日期", description = "2026-10-26 需求②：用户设定的「打算哪天去打」，"
			+ "展示口径（排序 / 逾期判定 / 完成率分母 / 下一针）一律取 plannedDate ?? dueDate；改出生日期重算"
			+ "只动 dueDate，不会平移用户改的期。plannedDate 传 null 表示清除、回到程序表日期。早于出生日期即拒；"
			+ "已接种（recordId 非空）的行拒绝——那一针以接种记录为准。手动行与字典行统一走这里。")
	@PutMapping("/{id}/planned-date")
	public ApiResponse<BabyVaccinePlanResponse> updatePlannedDate(@PathVariable Long id,
			@Valid @RequestBody BabyVaccinePlanPlannedDateRequest request) {
		return ApiResponse.ok(
				this.babyVaccinePlanService.updatePlannedDate(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除手动应种项", description = "§4.4.4：软删除，仅 manual = 1 的行可删；字典生成的行拒绝，"
			+ "并说明原因——下次改出生日期重算会把它补回来，允许删只会让用户以为删除功能坏了。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.babyVaccinePlanService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}
