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
import cn.homeledger.dto.BabyVaccineRecordCreateRequest;
import cn.homeledger.dto.BabyVaccineRecordUpdateRequest;
import cn.homeledger.service.BabyVaccineRecordService;
import cn.homeledger.vo.BabyVaccineRecordResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.4.4 接种记录。全家共享，任何在籍成员可改。
 */
@Tag(name = "接种记录", description = "§4.4.4 接种记录")
@RestController
@RequestMapping("/api/v1/baby-vaccine-records")
@RequiresFamily
public class BabyVaccineRecordController {

	private final BabyVaccineRecordService babyVaccineRecordService;

	public BabyVaccineRecordController(BabyVaccineRecordService babyVaccineRecordService) {
		this.babyVaccineRecordService = babyVaccineRecordService;
	}

	@Operation(summary = "接种记录列表", description = "§4.4.4：接种日期倒序、同日按 id 倒序，不分页。babyId 不传即全家庭。"
			+ "nextDate 是落库值（该疫苗下一个未完成剂次的应种日期），只读展示。"
			+ "没有 GET /baby-vaccine-records/{id}——编辑表单从这份列表里回填。")
	@GetMapping
	public ApiResponse<List<BabyVaccineRecordResponse>> list(@RequestParam(required = false) Long babyId) {
		return ApiResponse.ok(this.babyVaccineRecordService.list(babyId));
	}

	@Operation(summary = "新增接种记录", description = "§4.4.4：planId 给了就以它为准，没给就按「疫苗名称 + 剂次」自动匹配该宝宝的应种项。"
			+ "匹配到则同一事务内回写 status = DONE + record_id；匹配不到不报错，只记一条独立记录、planId 留空。"
			+ "已被标为跳过 / 不适用的行不被回写，要接种得先撤销标记。"
			+ "nextDate 留空时按该疫苗下一个 PENDING 剂次的应种日期推算，给了则照抄不回算。")
	@PostMapping
	public ApiResponse<BabyVaccineRecordResponse> create(@Valid @RequestBody BabyVaccineRecordCreateRequest request) {
		return ApiResponse.ok(this.babyVaccineRecordService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "修改接种记录", description = "§4.4.4：整份表单覆盖，不传的栏位即清空。允许改疫苗名称与剂次。"
			+ "改了就在同一事务内先撤销旧绑定（退回 PENDING + 清 record_id，标记过的旧行不动）、再按新键重新匹配。"
			+ "所以这条端点既能修正录错的疫苗名，也能把记录挪到另一个宝宝头上。")
	@PatchMapping("/{id}")
	public ApiResponse<BabyVaccineRecordResponse> update(@PathVariable Long id,
			@Valid @RequestBody BabyVaccineRecordUpdateRequest request) {
		return ApiResponse.ok(this.babyVaccineRecordService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除接种记录", description = "§4.4.4：软删除，并把对应应种项退回 PENDING + 清 record_id；"
			+ "已被手动标为跳过 / 不适用的行不回退，planId 为空时无副作用。录错了要能改回来，"
			+ "否则一次误录会让那一针永久显示已接种。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.babyVaccineRecordService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}
