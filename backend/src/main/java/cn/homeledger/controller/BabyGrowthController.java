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
import cn.homeledger.dto.BabyGrowthCreateRequest;
import cn.homeledger.dto.BabyGrowthUpdateRequest;
import cn.homeledger.service.BabyCurveService;
import cn.homeledger.service.BabyGrowthService;
import cn.homeledger.vo.BabyCurveResponse;
import cn.homeledger.vo.BabyGrowthResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.4.2 身高体重记录。列表按测量日期倒序全量返回、不分页：一个宝宝到 7 岁几十条，分页在此没有对象。
 */
@Tag(name = "身高体重记录", description = "§4.4.2 身高体重记录")
@RestController
@RequestMapping("/api/v1/baby-growths")
@RequiresFamily
public class BabyGrowthController {

	private final BabyGrowthService babyGrowthService;

	private final BabyCurveService babyCurveService;

	public BabyGrowthController(BabyGrowthService babyGrowthService, BabyCurveService babyCurveService) {
		this.babyGrowthService = babyGrowthService;
		this.babyCurveService = babyCurveService;
	}

	@Operation(summary = "生长曲线", description = "§4.4.3：实测点 + 每点所处百分位档 + 该性别该指标的标准表全量行 + 免责声明。"
			+ "metric 取 HEIGHT / WEIGHT / WEIGHT_HEIGHT / BMI / HEAD_CIRCUMFERENCE，不传按 HEIGHT；"
			+ "插值与档位判定都在服务端，前端只画。响应里的 standardMetric 是服务端实际选中的表名"
			+ "（体重别身高按年龄落到 WEIGHT_LENGTH 或 WEIGHT_HEIGHT），界面据此写「2 岁以下按身长」。"
			+ "超出标准表覆盖范围的点照常返回、percentileBand 为 null。")
	@GetMapping("/curve")
	public ApiResponse<BabyCurveResponse> curve(@RequestParam Long babyId,
			@RequestParam(required = false) String metric) {
		return ApiResponse.ok(this.babyCurveService.curve(babyId, metric));
	}

	@Operation(summary = "身高体重列表", description = "§4.4.2：测量日期倒序、同日按 id 倒序、不分页，"
			+ "每行带 deltaFromPrevious（较上一次的差值与间隔天数，读时派生）。babyId 不传即全家庭，"
			+ "增量按宝宝各自成链。没有 GET /baby-growths/{id}——编辑表单从这份列表里回填。")
	@GetMapping
	public ApiResponse<List<BabyGrowthResponse>> list(@RequestParam(required = false) Long babyId) {
		return ApiResponse.ok(this.babyGrowthService.list(babyId));
	}

	@Operation(summary = "新增身高体重记录", description = "§4.4.2：测量日期不可晚于今天，同一天允许多条；"
			+ "身高与体重至少填一项（只称体重是常事，两项全空那一行没有含义）。"
			+ "同一天里参与曲线与充当「上一次」的都是当天 id 最大的那条。")
	@PostMapping
	public ApiResponse<BabyGrowthResponse> create(@Valid @RequestBody BabyGrowthCreateRequest request) {
		return ApiResponse.ok(this.babyGrowthService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "修改身高体重记录", description = "§4.4.2：整份表单覆盖，不传的度量列与备注即清空。"
			+ "可连同 babyId 一起改（记录记到了另一个宝宝头上）。改数值或改日期都会自然反映到「较上一次」上。")
	@PatchMapping("/{id}")
	public ApiResponse<BabyGrowthResponse> update(@PathVariable Long id,
			@Valid @RequestBody BabyGrowthUpdateRequest request) {
		return ApiResponse.ok(this.babyGrowthService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "删除身高体重记录", description = "§4.4.2：软删除，无守卫。删掉一条会改这个宝宝后面各条的「较上一次」，"
			+ "所以统计缓存跟着失效。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.babyGrowthService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

}
