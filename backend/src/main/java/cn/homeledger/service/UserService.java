package cn.homeledger.service;

import cn.homeledger.common.AuthContext;
import cn.homeledger.vo.UserProfileResponse;

/**
 * §8 用户分组。方法接收 AuthContext 而不是自己查库：登录态已由 JwtAuthFilter 每请求解析过一次，
 * 再查一遍既浪费也让 Service 依赖线程本地的请求作用域。
 */
public interface UserService {

	UserProfileResponse profile(AuthContext context);

	UserProfileResponse updateNickname(AuthContext context, String nickname);

	/** §4.1.6 注销账号：本人操作 + 密码二次校验；创建者须先转让创建者身份或解散家庭。 */
	void deactivate(AuthContext context, String password);

}
