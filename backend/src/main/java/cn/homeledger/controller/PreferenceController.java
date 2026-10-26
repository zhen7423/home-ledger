package cn.homeledger.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.dto.ModulePreferenceSaveRequest;
import cn.homeledger.service.ModulePreferenceService;
import cn.homeledger.vo.ModulePreferenceResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * 模块开关与 Tab 顺序（§3.2、§4.7）。
 * <p>
 * 与 {@code ReminderController} 同一口径：类上不挂 {@code @RequiresFamily}。模块开关是用户级偏好
 * （A1），没有家庭的人也该能调它；而设置页在没有家庭时进不去，是前端路由守卫的事，不是这两条端点该管的事。
 */
@Tag(name = "偏好", description = "§3.2 模块开关与 Tab 顺序")
@RestController
@RequestMapping("/api/v1/preferences")
public class PreferenceController {

	private final ModulePreferenceService modulePreferenceService;

	public PreferenceController(ModulePreferenceService modulePreferenceService) {
		this.modulePreferenceService = modulePreferenceService;
	}

	@Operation(summary = "取模块开关与 Tab 顺序", description = "恒返回全部 3 个模块，按 sortNo 升序；"
			+ "库里没有的行按默认值补齐（三项默认全开、顺序记账→猫咪→宝宝）。无家庭也可调用。")
	@GetMapping("/modules")
	public ApiResponse<List<ModulePreferenceResponse>> modules() {
		return ApiResponse.ok(this.modulePreferenceService.modules(AuthContextHolder.require().userId()));
	}

	@Operation(summary = "保存模块开关与 Tab 顺序", description = "数组顺序即展示顺序，sortNo 由服务端派生、不收客户端传入。"
			+ "未列出的模块沿用已存的值（没存过用默认值），所以提交半份不会静默关掉另外两个。"
			+ "moduleKey 不认识报 BAD_REQUEST，同一模块提交两次也报 BAD_REQUEST。无家庭也可调用。")
	@PutMapping("/modules")
	public ApiResponse<Void> saveModules(@Valid @RequestBody ModulePreferenceSaveRequest request) {
		this.modulePreferenceService.saveModules(AuthContextHolder.require().userId(), request);
		return ApiResponse.ok();
	}

}
