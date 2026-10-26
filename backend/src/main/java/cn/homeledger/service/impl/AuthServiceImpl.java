package cn.homeledger.service.impl;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.dto.ChangePasswordRequest;
import cn.homeledger.dto.LoginRequest;
import cn.homeledger.dto.RefreshTokenRequest;
import cn.homeledger.dto.RegisterRequest;
import cn.homeledger.entity.User;
import cn.homeledger.mapper.UserMapper;
import cn.homeledger.security.JwtService;
import cn.homeledger.security.JwtService.IssuedRefreshToken;
import cn.homeledger.security.JwtService.ParsedToken;
import cn.homeledger.security.RateLimitService;
import cn.homeledger.security.RefreshTokenStore;
import cn.homeledger.security.TokenVersionService;
import cn.homeledger.service.AuthService;
import cn.homeledger.vo.TokenResponse;

@Service
public class AuthServiceImpl implements AuthService {

	private static final Logger log = LoggerFactory.getLogger(AuthServiceImpl.class);

	private final UserMapper userMapper;

	private final PasswordEncoder passwordEncoder;

	private final JwtService jwtService;

	private final TokenVersionService tokenVersionService;

	private final RefreshTokenStore refreshTokenStore;

	private final RateLimitService rateLimitService;

	public AuthServiceImpl(UserMapper userMapper, PasswordEncoder passwordEncoder, JwtService jwtService,
			TokenVersionService tokenVersionService, RefreshTokenStore refreshTokenStore,
			RateLimitService rateLimitService) {
		this.userMapper = userMapper;
		this.passwordEncoder = passwordEncoder;
		this.jwtService = jwtService;
		this.tokenVersionService = tokenVersionService;
		this.refreshTokenStore = refreshTokenStore;
		this.rateLimitService = rateLimitService;
	}

	@Override
	public TokenResponse register(RegisterRequest request, String ip) {
		this.rateLimitService.checkRegister(ip);
		String phone = request.phone().trim();
		if (countByPhone(phone) > 0) {
			throw new BizException(ErrorCode.PHONE_ALREADY_REGISTERED);
		}
		User user = new User();
		user.setPhone(phone);
		user.setPasswordHash(this.passwordEncoder.encode(request.password()));
		user.setNickname(request.nickname().trim());
		try {
			this.userMapper.insert(user);
		}
		catch (DuplicateKeyException ex) {
			// 查重与插入之间的并发注册由 uk_user_phone 兜住，对外仍表现为同一个明确错误
			throw new BizException(ErrorCode.PHONE_ALREADY_REGISTERED);
		}
		log.info("注册成功 userId={}", user.getId());
		return issueTokens(user.getId(), this.tokenVersionService.current(user.getId()));
	}

	@Override
	public TokenResponse login(LoginRequest request, String ip) {
		this.rateLimitService.checkLogin(ip);
		String phone = request.phone().trim();
		// 必须在校验密码之前：验收用例 5 要求锁定期内即使密码正确也拒绝
		this.rateLimitService.assertNotLocked(phone);
		User user = this.userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getPhone, phone));
		if (user == null || !this.passwordEncoder.matches(request.password(), user.getPasswordHash())) {
			this.rateLimitService.recordLoginFailure(phone);
			// 不区分「账号不存在」与「密码错误」，否则登录接口就成了手机号遍历探针
			throw new BizException(ErrorCode.LOGIN_BAD_CREDENTIAL);
		}
		this.rateLimitService.clearLoginFailures(phone);
		return issueTokens(user.getId(), this.tokenVersionService.current(user.getId()));
	}

	@Override
	public TokenResponse refresh(RefreshTokenRequest request) {
		ParsedToken parsed = this.jwtService.parseRefreshToken(request.refreshToken());
		Long owner = this.refreshTokenStore.findUserId(parsed.jti());
		if (owner == null || !owner.equals(parsed.userId())) {
			throw new BizException(ErrorCode.REFRESH_TOKEN_INVALID);
		}
		long currentVersion = this.tokenVersionService.current(parsed.userId());
		if (parsed.tokenVersion() != currentVersion) {
			this.refreshTokenStore.revoke(parsed.jti());
			throw new BizException(ErrorCode.TOKEN_REVOKED);
		}
		if (this.userMapper.selectById(parsed.userId()) == null) {
			this.refreshTokenStore.revoke(parsed.jti());
			throw new BizException(ErrorCode.REFRESH_TOKEN_INVALID, "账号已注销，请重新登录");
		}
		// 轮换：旧 refresh token 在一次成功续期后立即作废，被窃取的旧令牌因此只能用一次
		this.refreshTokenStore.revoke(parsed.jti());
		return issueTokens(parsed.userId(), currentVersion);
	}

	@Override
	public void logout(Long userId, RefreshTokenRequest request) {
		try {
			ParsedToken parsed = this.jwtService.parseRefreshToken(request.refreshToken());
			if (userId.equals(parsed.userId()) && userId.equals(this.refreshTokenStore.findUserId(parsed.jti()))) {
				this.refreshTokenStore.revoke(parsed.jti());
			}
		}
		catch (BizException ex) {
			// 令牌已过期或非法：登出的目的（服务端不再承认它）本就已达成，登出必须幂等成功
			log.info("登出时 refreshToken 已不可用 userId={} code={}", userId, ex.errorCode().code());
		}
	}

	@Override
	public TokenResponse changePassword(Long userId, ChangePasswordRequest request, String ip) {
		this.rateLimitService.checkChangePassword(ip);
		User user = this.userMapper.selectById(userId);
		if (user == null) {
			throw new BizException(ErrorCode.UNAUTHORIZED);
		}
		if (!this.passwordEncoder.matches(request.oldPassword(), user.getPasswordHash())) {
			throw new BizException(ErrorCode.PASSWORD_MISMATCH, "原密码不正确");
		}
		User update = new User();
		update.setId(userId);
		update.setPasswordHash(this.passwordEncoder.encode(request.newPassword()));
		this.userMapper.updateById(update);
		// §5.2：改密码后已签发的全部令牌立即失效。这里用新版本号重新签发一对，
		// 使执行本次操作的设备无缝续上，其他设备按预期被踢下线。
		long newVersion = this.tokenVersionService.bump(userId);
		log.info("密码已修改，令牌版本号递增至 {} userId={}", newVersion, userId);
		return issueTokens(userId, newVersion);
	}

	private long countByPhone(String phone) {
		Long count = this.userMapper.selectCount(new LambdaQueryWrapper<User>().eq(User::getPhone, phone));
		return (count == null) ? 0L : count;
	}

	private TokenResponse issueTokens(Long userId, long tokenVersion) {
		String accessToken = this.jwtService.issueAccessToken(userId, tokenVersion);
		IssuedRefreshToken refresh = this.jwtService.issueRefreshToken(userId, tokenVersion);
		this.refreshTokenStore.save(refresh.jti(), userId, this.jwtService.refreshTtl());
		return TokenResponse.bearer(accessToken, this.jwtService.accessTtl().toSeconds(), refresh.token(),
				this.jwtService.refreshTtl().toSeconds());
	}

}
