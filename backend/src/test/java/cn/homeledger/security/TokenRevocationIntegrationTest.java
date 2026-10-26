package cn.homeledger.security;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.common.ErrorCode;
import cn.homeledger.support.ApiTestBase;

/**
 * §5.2 令牌即时吊销：Redis 每用户令牌版本号写入 JWT claim、每请求比对，不一致即 401。
 * 目的是让「被移除 / 家庭解散 / 改密码」立即生效，而不是等 Access Token 自然过期的 2 小时。
 *
 * 每个用例都同时验 Access 与 Refresh 两条链路：只吊 Access 的话，客户端静默续期一次就满血复活了。
 */
class TokenRevocationIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_C = "13800000003";

	@Test
	@DisplayName("§4.1.6 被移除者的登录态立即失效：Access 与 Refresh 双双 401")
	void removedMemberIsRevokedImmediately() throws Exception {
		Account owner = register(PHONE_A, "张三");
		Account member = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(owner);
		inviteAndJoin(owner, member);

		assertThat(deleteNoBody(FAMILY_CURRENT + "/members/" + member.userId(), owner.accessToken()).code())
			.isEqualTo("OK");

		Call access = getJson(USERS_ME, member.accessToken());
		assertThat(access.status()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
		assertThat(access.code()).isEqualTo(ErrorCode.TOKEN_REVOKED.code());

		Call refresh = postJson(AUTH_REFRESH, Map.of("refreshToken", member.refreshToken()), null);
		assertThat(refresh.status()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
		assertThat(refresh.code()).as("只吊 Access 的话续期一次就复活了").isEqualTo(ErrorCode.TOKEN_REVOKED.code());

		// 移除操作不影响其余成员
		assertThat(getJson(USERS_ME, owner.accessToken()).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("改密码踢掉自己其他设备，但当前设备凭响应里的新令牌无感继续（§5.2 已确认的可接受副作用）")
	void changePasswordKicksOtherDevicesOnly() throws Exception {
		Account device1 = register(PHONE_A, "张三");
		Account device2 = secondDevice(device1);

		Call changed = patchJson(AUTH_PASSWORD, Map.of("oldPassword", PASSWORD, "newPassword", "NewPass456"),
				device1.accessToken());
		String freshToken = changed.data().path("accessToken").asText();
		String freshRefresh = changed.data().path("refreshToken").asText();

		assertThat(getJson(USERS_ME, device2.accessToken()).code()).isEqualTo(ErrorCode.TOKEN_REVOKED.code());
		assertThat(postJson(AUTH_REFRESH, Map.of("refreshToken", device2.refreshToken()), null).code())
			.isEqualTo(ErrorCode.TOKEN_REVOKED.code());

		assertThat(getJson(USERS_ME, device1.accessToken()).code()).as("操作方自己的旧令牌同样已被版本号作废")
			.isEqualTo(ErrorCode.TOKEN_REVOKED.code());
		assertThat(getJson(USERS_ME, freshToken).code()).isEqualTo("OK");
		assertThat(postJson(AUTH_REFRESH, Map.of("refreshToken", freshRefresh), null).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("解散家庭踢掉全部成员，唯独不踢执行解散的创建者——否则用户会被自己的操作弹回登录页")
	void disbandRevokesEveryoneButActingOwner() throws Exception {
		Account owner = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account c = register(PHONE_C, "王五");
		FamilyHandle family = createFamily(owner);
		inviteAndJoin(owner, b);
		inviteAndJoin(owner, c);

		assertThat(deleteJson(FAMILY_CURRENT, Map.of("password", PASSWORD), owner.accessToken()).code()).isEqualTo("OK");

		for (Account member : new Account[] { b, c }) {
			assertThat(getJson(USERS_ME, member.accessToken()).code()).isEqualTo(ErrorCode.TOKEN_REVOKED.code());
			assertThat(postJson(AUTH_REFRESH, Map.of("refreshToken", member.refreshToken()), null).code())
				.isEqualTo(ErrorCode.TOKEN_REVOKED.code());
		}

		// 创建者保留登录态，落到「创建 / 加入家庭」引导页
		assertThat(getJson(USERS_ME, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(currentFamily(owner.accessToken()).isNullData()).isTrue();
	}

	@Test
	@DisplayName("注销账号后登录态失效：另一台设备的 Access 与 Refresh 双双不可用")
	void deactivatedAccountIsRevoked() throws Exception {
		Account account = register(PHONE_A, "张三");
		Account otherDevice = secondDevice(account);

		assertThat(deleteJson(USERS_ME, Map.of("password", PASSWORD), account.accessToken()).code()).isEqualTo("OK");

		assertThat(getJson(USERS_ME, otherDevice.accessToken()).status())
			.isEqualTo(HttpStatus.UNAUTHORIZED.value());
		assertThat(postJson(AUTH_REFRESH, Map.of("refreshToken", otherDevice.refreshToken()), null).code())
			.isEqualTo(ErrorCode.REFRESH_TOKEN_INVALID.code());
	}

	/**
	 * 实施中发现的需求空白，需在评审时定夺：§4.1.6 只写了「账号逻辑删除」，没规定注销后本人能否用同一手机号
	 * 重新注册。当前实现是**不能**——uk_user_phone 唯一索引覆盖软删行，逻辑删除不释放手机号。
	 * 这条测试如实钉住现状；若产品口径改为「可以重新注册」，就需要再写一版迁移在注销时把 phone 改写成
	 * 墓碑值（如 {@code #<id>}）来腾出唯一索引，届时本测试要一起改。
	 */
	@Test
	@DisplayName("注销后同一手机号无法自助重新注册（逻辑删除不释放唯一索引）")
	void deactivatedPhoneCannotSelfReregister() throws Exception {
		Account account = register(PHONE_A, "张三");
		deleteJson(USERS_ME, Map.of("password", PASSWORD), account.accessToken());

		Call call = postJson(AUTH_REGISTER, Map.of("phone", PHONE_A, "password", PASSWORD, "nickname", "张三二号"),
				nextIp(), null);

		assertThat(call.status()).isEqualTo(HttpStatus.CONFLICT.value());
		assertThat(call.code()).isEqualTo(ErrorCode.PHONE_ALREADY_REGISTERED.code());
	}

	@Test
	@DisplayName("令牌版本号只在 Redis，不给 user 表加字段；键不带 TTL，否则会比 30 天的 Refresh Token 先过期")
	void tokenVersionLivesInRedisWithoutTtl() throws Exception {
		Account owner = register(PHONE_A, "张三");
		Account member = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(owner);
		inviteAndJoin(owner, member);

		deleteNoBody(FAMILY_CURRENT + "/members/" + member.userId(), owner.accessToken());

		String key = "auth:token-ver:" + member.userId();
		assertThat(redis.hasKey(key)).isTrue();
		assertThat(redis.getExpire(key)).as("版本号必须活得比 30 天的 Refresh Token 久，不能设 TTL").isEqualTo(-1L);
		assertThat(jdbcTemplate.queryForList("SHOW COLUMNS FROM `user` LIKE 'token_version'")).isEmpty();
	}

	@Test
	@DisplayName("转让创建者不递增版本号：角色每请求实时解析，无需靠踢下线来刷新缓存")
	void transferOwnerDoesNotRevokeAnyone() throws Exception {
		Account owner = register(PHONE_A, "张三");
		Account member = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(owner);
		inviteAndJoin(owner, member);

		assertThat(postJson(FAMILY_CURRENT + "/owner/transfer", Map.of("targetUserId", member.userId()),
				owner.accessToken())
			.code()).isEqualTo("OK");

		// 两端都保持登录：转让是家庭内部事务，不该把任何人弹回登录页
		assertThat(getJson(USERS_ME, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(getJson(USERS_ME, member.accessToken()).code()).isEqualTo("OK");

		// §4.1.6 要求「两端缓存的角色立即刷新」——每请求解析已经无条件满足，且比版本号更强：
		// 原创建者下一次调用创建者专属操作时立刻被拒，不存在任何缓存窗口
		assertThat(getJson(USERS_ME, owner.accessToken()).data().path("role").asText()).isEqualTo("MEMBER");
		assertThat(getJson(USERS_ME, member.accessToken()).data().path("role").asText()).isEqualTo("OWNER");
		assertThat(deleteNoBody(FAMILY_CURRENT + "/members/" + member.userId(), owner.accessToken()).code())
			.isEqualTo(ErrorCode.NOT_FAMILY_OWNER.code());
	}

}
