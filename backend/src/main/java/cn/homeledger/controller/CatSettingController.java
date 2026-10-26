package cn.homeledger.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.CatSettingUpdateRequest;
import cn.homeledger.service.CatSettingService;
import cn.homeledger.vo.CatSettingResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.3.3 猫咪设置：驱虫默认周期与预估日均克数，家庭级共享，每家庭至多一行。
 */
@Tag(name = "猫咪设置", description = "§4.3.3 猫咪设置")
@RestController
@RequestMapping("/api/v1/cat-settings")
@RequiresFamily
public class CatSettingController {

	private final CatSettingService catSettingService;

	public CatSettingController(CatSettingService catSettingService) {
		this.catSettingService = catSettingService;
	}

	@Operation(summary = "读取猫咪设置", description = "§4.3.3：本家庭还没存过时按默认值回（内驱 3 个月、外驱 1 个月、"
			+ "预估日均留空），并且不建那一行——打开一次设置页不是写入事件。")
	@GetMapping
	public ApiResponse<CatSettingResponse> get() {
		return ApiResponse.ok(this.catSettingService.get());
	}

	@Operation(summary = "保存猫咪设置", description = "§4.3.3：整体覆盖，三栏一次给全，预估日均留空即清空。"
			+ "响应回保存后的值，前端不必再发一次 GET。改了只影响之后新建的驱虫记录，已有记录的下次日期不追溯重算。")
	@PutMapping
	public ApiResponse<CatSettingResponse> save(@Valid @RequestBody CatSettingUpdateRequest request) {
		return ApiResponse.ok(this.catSettingService.save(AuthContextHolder.require().userId(), request));
	}

}
