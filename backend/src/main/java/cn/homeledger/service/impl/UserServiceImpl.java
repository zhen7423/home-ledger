package cn.homeledger.service.impl;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import cn.homeledger.common.AuthContext;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.entity.User;
import cn.homeledger.mapper.UserMapper;
import cn.homeledger.service.FamilyService;
import cn.homeledger.service.UserService;
import cn.homeledger.vo.UserProfileResponse;

@Service
public class UserServiceImpl implements UserService {

	private static final Logger log = LoggerFactory.getLogger(UserServiceImpl.class);

	private final UserMapper userMapper;

	private final PasswordEncoder passwordEncoder;

	private final FamilyService familyService;

	public UserServiceImpl(UserMapper userMapper, PasswordEncoder passwordEncoder, FamilyService familyService) {
		this.userMapper = userMapper;
		this.passwordEncoder = passwordEncoder;
		this.familyService = familyService;
	}

	@Override
	public UserProfileResponse profile(AuthContext context) {
		User user = requireUser(context.userId());
		return toProfile(user, context);
	}

	@Override
	@Transactional
	public UserProfileResponse updateNickname(AuthContext context, String nickname) {
		User user = requireUser(context.userId());
		String trimmed = nickname.trim();
		User update = new User();
		update.setId(user.getId());
		update.setNickname(trimmed);
		this.userMapper.updateById(update);
		user.setNickname(trimmed);
		return toProfile(user, context);
	}

	/**
	 * 不递增令牌版本号：user 行一旦 deleted = 1，JwtAuthFilter 每请求的登录态解析就返回 null，
	 * 已签发的 Access / Refresh Token 当场失效，再 bump 一次是多余动作（§4.1.6、§5.2）。
	 */
	@Override
	@Transactional
	public void deactivate(AuthContext context, String password) {
		User user = requireUser(context.userId());
		if (!this.passwordEncoder.matches(password, user.getPasswordHash())) {
			throw new BizException(ErrorCode.PASSWORD_MISMATCH);
		}
		this.familyService.leaveForAccountClosure(context.userId());
		this.userMapper.deleteById(context.userId());
		log.info("注销账号 userId={}", context.userId());
	}

	private User requireUser(Long userId) {
		User user = this.userMapper.selectById(userId);
		if (user == null) {
			throw new BizException(ErrorCode.UNAUTHORIZED);
		}
		return user;
	}

	private static UserProfileResponse toProfile(User user, AuthContext context) {
		return new UserProfileResponse(user.getId(), user.getPhone(), user.getNickname(), context.familyId(),
				context.role());
	}

}
