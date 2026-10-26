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
import cn.homeledger.dto.BabyMilestoneCreateRequest;
import cn.homeledger.dto.BabyMilestoneUpdateRequest;
import cn.homeledger.service.BabyMilestoneService;
import cn.homeledger.vo.BabyMilestoneResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.4.5 里程碑。全家共享，任何在籍成员可改。
 */
@Tag(name = "宝宝里程碑", description = "§4.4.5 宝宝里程碑")
@RestController
@RequestMapping("/api/v1/baby-milestones")
@RequiresFamily
public class BabyMilestoneController {

	private final BabyMilestoneService babyMilestoneService;

	public BabyMilestoneController(BabyMilestoneService babyMilestoneService) {
		this.babyMilestoneService = babyMilestoneService;
	}

	@Operation(summary = "里程碑列表", description = "§4.4.5：按发生日期升序、同日按 id 升序，不分页。babyId 不传即全家庭。"
			+ "这个顺序就是统计页的里程碑时间轴。没有 GET /baby-milestones/{id}——编辑表单从这份列表里回填。")
	@GetMapping
	public ApiResponse<List<BabyMilestoneResponse>> list(@RequestParam(required = false) Long babyId) {
		return ApiResponse.ok(this.babyMilestoneService.list(babyId));
	}

	@Operation(summary = "新增里程碑", description = "§4.4.5：标题 ≤ 30 字，发生日期不可晚于今天。"
			+ "标题没有字典：内置常用项是前端一份常量清单，点它和自由输入落的是同一列。")
	@PostMapping
	public ApiResponse<BabyMilestoneResponse> create(@Valid @RequestBody BabyMilestoneCreateRequest request) {
		return ApiResponse.ok(this.babyMilestoneService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "编辑里程碑", description = "§4.4.5：整份表单覆盖，不传的描述即清空。归属宝宝改不了——"
			+ "babyId 不在请求体里，多传的键被忽略。")
	@PatchMapping("/{id}")
	public ApiResponse<BabyMilestoneResponse> update(@PathVariable Long id,
			@Valid @RequestBody BabyMilestoneUpdateRequest request) {
		return ApiResponse.ok(this.babyMilestoneService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除里程碑", description = "§4.4.5：软删除，无守卫。里程碑没有归档语义，记错了直接删。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.babyMilestoneService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}
