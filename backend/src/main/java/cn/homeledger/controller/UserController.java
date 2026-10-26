package cn.homeledger.controller;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.dto.NicknameRequest;
import cn.homeledger.dto.PasswordVerifyRequest;
import cn.homeledger.service.UserService;
import cn.homeledger.vo.UserProfileResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@Tag(name = "用户", description = "§8 个人信息")
@RestController
@RequestMapping("/api/v1/users")
public class UserController {

	private final UserService userService;

	public UserController(UserService userService) {
		this.userService = userService;
	}

	@GetMapping("/me")
	public ApiResponse<UserProfileResponse> me() {
		return ApiResponse.ok(this.userService.profile(AuthContextHolder.require()));
	}

	@PatchMapping("/me")
	public ApiResponse<UserProfileResponse> updateMe(@Valid @RequestBody NicknameRequest request) {
		return ApiResponse.ok(this.userService.updateNickname(AuthContextHolder.require(), request.nickname()));
	}

	@Operation(summary = "注销账号", description = "§4.1.6：本人操作，需密码校验；创建者须先转让创建者身份或解散家庭。"
			+ "账号逻辑删除，注销后其已签发令牌立即失效。")
	@DeleteMapping("/me")
	public ApiResponse<Void> deactivate(@Valid @RequestBody PasswordVerifyRequest request) {
		this.userService.deactivate(AuthContextHolder.require(), request.password());
		return ApiResponse.ok();
	}

}
