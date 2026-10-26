package cn.homeledger.controller;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.FamilyNameRequest;
import cn.homeledger.dto.InviteEnableRequest;
import cn.homeledger.dto.JoinFamilyRequest;
import cn.homeledger.dto.PasswordVerifyRequest;
import cn.homeledger.dto.TransferOwnerRequest;
import cn.homeledger.security.ClientIpResolver;
import cn.homeledger.service.FamilyService;
import cn.homeledger.vo.FamilyResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

/**
 * §4.1.4 家庭的创建与加入、§4.1.6 家庭生命周期。
 * <p>
 * 创建、加入、查询当前家庭这三个端点必须对「尚无家庭」的用户开放，因此 @RequiresFamily 逐个方法标注，
 * 不能标在类上。
 */
@Tag(name = "家庭", description = "§4.1.4 创建与加入、§4.1.6 生命周期")
@RestController
@RequestMapping("/api/v1/families")
public class FamilyController {

	private final FamilyService familyService;

	private final ClientIpResolver clientIpResolver;

	public FamilyController(FamilyService familyService, ClientIpResolver clientIpResolver) {
		this.familyService = familyService;
		this.clientIpResolver = clientIpResolver;
	}

	@Operation(summary = "创建家庭", description = "§4.1.4：名称留空则默认「<昵称>的家」。第 33 轮起创建不再自动签发邀请码，"
			+ "邀请入口默认关闭，需创建者在「家庭管理」里手动开启。")
	@PostMapping
	public ApiResponse<FamilyResponse> create(@Valid @RequestBody FamilyNameRequest request) {
		return ApiResponse.ok(this.familyService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "邀请码加入家庭", description = "§4.1.4：入口关闭（码不存在）、已过期、成员已满 5 人分别返回不同文案；"
			+ "邀请码一次性使用（第 33 轮），用掉后入口自动关闭。同一 IP 每分钟最多 10 次。已属于家庭的账号返回 ALREADY_IN_FAMILY。")
	@PostMapping("/join")
	public ApiResponse<FamilyResponse> join(@Valid @RequestBody JoinFamilyRequest request,
			HttpServletRequest servletRequest) {
		return ApiResponse.ok(this.familyService.join(AuthContextHolder.require().userId(), request,
				this.clientIpResolver.resolve(servletRequest)));
	}

	@Operation(summary = "当前家庭信息 + 成员列表", description = "§8：用户尚无家庭时返回 200 且 data 为 null，"
			+ "不返回 404——404 在 §5.2 中专用于跨家庭越权，复用到「尚无家庭」这一正常状态会让前端无法区分该引导建家庭还是该报错。")
	@GetMapping("/current")
	public ApiResponse<FamilyResponse> current() {
		return ApiResponse.ok(this.familyService.current(AuthContextHolder.require().userId()));
	}

	@RequiresFamily
	@PatchMapping("/current")
	public ApiResponse<FamilyResponse> rename(@Valid @RequestBody FamilyNameRequest request) {
		return ApiResponse.ok(this.familyService.rename(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "开关邀请", description = "§4.1.4（第 33 轮）：仅创建者。开启即签发新的 6 位邀请码（24 小时有效、"
			+ "只能使用一次，用掉或到期后自动关闭入口）；关闭则清空邀请码并关上入口。开着时再开一次等价于重置：换发新码并顺延 24 小时。")
	@RequiresFamily
	@PutMapping("/current/invite")
	public ApiResponse<FamilyResponse> setInviteEnabled(@Valid @RequestBody InviteEnableRequest request) {
		return ApiResponse.ok(this.familyService.setInviteEnabled(AuthContextHolder.require().userId(),
				request.enabled()));
	}

	@Operation(summary = "转让创建者", description = "§4.1.6（第 9 轮新增）：仅创建者；目标须是本家庭内在籍成员且不是自己。"
			+ "单事务内同时更新 family.owner_user_id 与两行 family_member.role。原创建者降为 MEMBER，保留成员身份与数据可见性。")
	@RequiresFamily
	@PostMapping("/current/owner/transfer")
	public ApiResponse<FamilyResponse> transferOwner(@Valid @RequestBody TransferOwnerRequest request) {
		return ApiResponse.ok(
				this.familyService.transferOwner(AuthContextHolder.require().userId(), request.targetUserId()));
	}

	@Operation(summary = "移除成员", description = "§4.1.6：仅创建者，不能移除自己。被移除者的登录态立即失效（递增其令牌版本号）；"
			+ "其历史记录全部保留，记录人显示退出时保存的昵称快照。")
	@RequiresFamily
	@DeleteMapping("/current/members/{userId}")
	public ApiResponse<Void> removeMember(@PathVariable Long userId) {
		this.familyService.removeMember(AuthContextHolder.require().userId(), userId);
		return ApiResponse.ok();
	}

	@RequiresFamily
	@PostMapping("/current/leave")
	public ApiResponse<Void> leave() {
		this.familyService.leave(AuthContextHolder.require().userId());
		return ApiResponse.ok();
	}

	@Operation(summary = "解散家庭", description = "§4.1.6：仅创建者，需密码校验。家庭及其成员关系逻辑删除并保留 30 天，"
			+ "期间可由部署者在服务器侧恢复；自动物理清除推迟至 S10。除操作者本人外全体成员的令牌版本号递增。")
	@RequiresFamily
	@DeleteMapping("/current")
	public ApiResponse<Void> disband(@Valid @RequestBody PasswordVerifyRequest request) {
		this.familyService.disband(AuthContextHolder.require().userId(), request.password());
		return ApiResponse.ok();
	}

}
