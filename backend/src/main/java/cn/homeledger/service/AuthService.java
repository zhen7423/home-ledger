package cn.homeledger.service;

import cn.homeledger.dto.ChangePasswordRequest;
import cn.homeledger.dto.LoginRequest;
import cn.homeledger.dto.RefreshTokenRequest;
import cn.homeledger.dto.RegisterRequest;
import cn.homeledger.vo.TokenResponse;

/**
 * §4.1.1 / §4.1.2 / §4.1.3 / §4.1.7 的认证链路。
 * <p>
 * 注册与登录都直接返回令牌对（注册即登录），省掉一次往返；§4.1.1 只要求「注册后不自动创建家庭」，
 * 客户端拿到令牌后进入引导页即可。
 * <p>
 * 各方法的入参 {@code ip} 用于 §5.2 的 IP 维度限流，由 Controller 经 ClientIpResolver 取得后传入，
 * Service 不直接依赖 HttpServletRequest。
 */
public interface AuthService {

	/** §4.1.1 注册。手机号查重与插入之间的并发窗口由 {@code uk_user_phone} 兜住。 */
	TokenResponse register(RegisterRequest request, String ip);

	/**
	 * §4.1.2 登录。「账号不存在」与「密码错误」返回同一错误码与同一文案，否则登录接口就成了手机号遍历探针。
	 * 连续 5 次失败锁定 15 分钟（验收用例 5）。
	 */
	TokenResponse login(LoginRequest request, String ip);

	/** §5.2 续期并轮换 Refresh Token：旧令牌在一次成功续期后立即作废，被窃取的旧令牌因此只能用一次。 */
	TokenResponse refresh(RefreshTokenRequest request);

	/** §4.1.2 登出。幂等：重复登出、拿他人令牌登出都不报错；只吊销 Refresh Token，不递增版本号。 */
	void logout(Long userId, RefreshTokenRequest request);

	/** §5.2 改密码递增令牌版本号，并返回一套新令牌，使执行本次操作的设备无缝续上、其他设备被踢下线。 */
	TokenResponse changePassword(Long userId, ChangePasswordRequest request, String ip);

}
