package cn.homeledger.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.dto.ReminderSettingSaveRequest;
import cn.homeledger.service.ReminderService;
import cn.homeledger.vo.PendingReminderResponse;
import cn.homeledger.vo.ReminderSettingResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * 提醒设置与待提醒项。
 * <p>
 * 类上没有 @RequiresFamily，这是全项目唯一一个这样的业务 Controller：reminder_setting 是用户级偏好，
 * 没有家庭的人也应该能设置它（他迟早会加入家庭）。给整个类挂上家庭校验，等于要求用户先有家庭才能打开通知设置页。
 * <p>
 * pending 同样不挂：没有家庭时它返回空列表，一个「此刻什么都没有」的提醒中心是正确的空态，403 不是。
 */
@Tag(name = "提醒", description = "§4.5.1 提醒开关与待提醒项")
@RestController
@RequestMapping("/api/v1/reminders")
public class ReminderController {

	private final ReminderService reminderService;

	public ReminderController(ReminderService reminderService) {
		this.reminderService = reminderService;
	}

	@Operation(summary = "取当前用户的提醒开关", description = "返回全部 7 类，按枚举声明顺序（猫 → 疫苗 → 预算 → 成长）；"
			+ "库里没有的行按默认值补齐，其中 BUDGET_WARNING 默认关——80% 就发通知太吵，它只在 App 内出红点。"
			+ "pushed 由服务端给，表示这类提醒会不会进通知栏，用户改不了。无家庭也可调用。")
	@GetMapping("/settings")
	public ApiResponse<List<ReminderSettingResponse>> settings() {
		return ApiResponse.ok(this.reminderService.settings(AuthContextHolder.require().userId()));
	}

	@Operation(summary = "保存提醒开关", description = "逐项 upsert，未提交的类型保持原值。"
			+ "type 不认识报 BAD_REQUEST，同一 type 在一次提交里出现两次报 REMINDER_SETTING_DUPLICATED。无家庭也可调用。")
	@PutMapping("/settings")
	public ApiResponse<Void> saveSettings(@Valid @RequestBody ReminderSettingSaveRequest request) {
		this.reminderService.saveSettings(AuthContextHolder.require().userId(), request);
		return ApiResponse.ok();
	}

	@Operation(summary = "取待提醒项", description = "七类全通：预算两档、猫咪三档、疫苗、成长记录待补。"
			+ "一条预算在一个档位上只出一条：到 100% 以上只报「已超支」，不会再叠一条「即将超支」。"
			+ "key 是前端的去重键、不带月份。有到期日的两类（驱虫、疫苗）按 §4.5.1 的触发日给出 fireAt："
			+ "今天正是触发日时为空（客户端立即弹），否则是下一个触发日的上午 9 点（客户端定时弹）；"
			+ "预算、猫粮见底与成长记录待补三类恒为空，它们是「此刻的状态」而不是某个该做某事的时刻。"
			+ "无家庭时返回空列表而非 403。")
	@GetMapping("/pending")
	public ApiResponse<List<PendingReminderResponse>> pending() {
		return ApiResponse.ok(this.reminderService.pending(AuthContextHolder.require().userId()));
	}

}
