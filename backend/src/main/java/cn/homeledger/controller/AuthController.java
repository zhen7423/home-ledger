package cn.homeledger.controller;

import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.dto.ChangePasswordRequest;
import cn.homeledger.dto.LoginRequest;
import cn.homeledger.dto.RefreshTokenRequest;
import cn.homeledger.dto.RegisterRequest;
import cn.homeledger.security.ClientIpResolver;
import cn.homeledger.service.AuthService;
import cn.homeledger.vo.TokenResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

@Tag(name = "认证", description = "§4.1.1 注册、§4.1.2 登录与令牌、§4.1.3 找回密码（本期限制）、§4.1.7 第三方登录预留")
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

	private final AuthService authService;

	private final ClientIpResolver clientIpResolver;

	public AuthController(AuthService authService, ClientIpResolver clientIpResolver) {
		this.authService = authService;
		this.clientIpResolver = clientIpResolver;
	}

	@PostMapping("/register")
	public ApiResponse<TokenResponse> register(@Valid @RequestBody RegisterRequest request,
			HttpServletRequest servletRequest) {
		return ApiResponse.ok(this.authService.register(request, this.clientIpResolver.resolve(servletRequest)));
	}

	@PostMapping("/login")
	public ApiResponse<TokenResponse> login(@Valid @RequestBody LoginRequest request,
			HttpServletRequest servletRequest) {
		return ApiResponse.ok(this.authService.login(request, this.clientIpResolver.resolve(servletRequest)));
	}

	@PostMapping("/refresh")
	public ApiResponse<TokenResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
		return ApiResponse.ok(this.authService.refresh(request));
	}

	@PostMapping("/logout")
	public ApiResponse<Void> logout(@Valid @RequestBody RefreshTokenRequest request) {
		this.authService.logout(AuthContextHolder.require().userId(), request);
		return ApiResponse.ok();
	}

	@Operation(summary = "修改密码", description = "§5.2：成功后递增令牌版本号，本设备由响应中的新令牌无缝续上，其他设备被踢下线。")
	@PatchMapping("/password")
	public ApiResponse<TokenResponse> changePassword(@Valid @RequestBody ChangePasswordRequest request,
			HttpServletRequest servletRequest) {
		return ApiResponse.ok(this.authService.changePassword(AuthContextHolder.require().userId(), request,
				this.clientIpResolver.resolve(servletRequest)));
	}

	@Operation(summary = "找回密码（本期未开放）", description = "§4.1.3：本期无短信通道，不提供用户自助找回密码。"
			+ "忘记密码需由部署者在服务器侧重置。接口先占位，资质就绪后补实现。")
	@PostMapping("/password/reset")
	public ApiResponse<Void> resetPassword() {
		throw new BizException(ErrorCode.NOT_IMPLEMENTED);
	}

	@Operation(summary = "微信登录（本期未开放）", description = "§4.1.7：APK 内拉起微信授权须持有「微信开放平台—移动应用」AppID，"
			+ "该资质仅对企业主体开放。资质就绪前无法上线。")
	@PostMapping("/wechat/login")
	public ApiResponse<Void> wechatLogin() {
		throw new BizException(ErrorCode.NOT_IMPLEMENTED);
	}

	@Operation(summary = "发送短信验证码（本期未开放）", description = "§4.1.7：阿里云/腾讯云短信签名审核要求企业资质或已上架 App / 已备案网站，"
			+ "纯个人主体通常无法通过。")
	@PostMapping("/sms/code")
	public ApiResponse<Void> sendSmsCode() {
		throw new BizException(ErrorCode.NOT_IMPLEMENTED);
	}

	@Operation(summary = "短信验证码登录（本期未开放）", description = "§4.1.7：依赖 /auth/sms/code，同受短信签名资质限制。")
	@PostMapping("/sms/login")
	public ApiResponse<Void> smsLogin() {
		throw new BizException(ErrorCode.NOT_IMPLEMENTED);
	}

}
