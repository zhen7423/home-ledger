package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

import java.nio.charset.StandardCharsets;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockHttpServletResponse;

import cn.homeledger.common.ErrorCode;
import cn.homeledger.support.ApiTestBase;

/**
 * §4.1.1 注册、§4.1.2 登录与令牌、§5.2 限流与密码错误锁定。
 * 覆盖验收用例 5；用例 2 / 3 / 6 依赖 S3 的流水表，不在本阶段。
 */
class AuthFlowIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	@Test
	@DisplayName("注册即登录：返回 Bearer 令牌对，有效期为 §4.1.2 规定的 2 小时 / 30 天")
	void registerReturnsTokenPair() throws Exception {
		Call call = postJson(AUTH_REGISTER, Map.of("phone", PHONE_A, "password", PASSWORD, "nickname", "张三"), nextIp(),
				null);

		assertThat(call.status()).isEqualTo(HttpStatus.OK.value());
		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("tokenType").asText()).isEqualTo("Bearer");
		assertThat(call.data().path("accessToken").asText()).isNotBlank();
		assertThat(call.data().path("refreshToken").asText()).isNotBlank();
		assertThat(call.data().path("accessExpiresInSeconds").asLong()).isEqualTo(2 * 60 * 60);
		assertThat(call.data().path("refreshExpiresInSeconds").asLong()).isEqualTo(30L * 24 * 60 * 60);

		// 注册后不自动建家庭（§4.1.1），应落到「创建 / 加入家庭」引导页
		Call me = getJson(USERS_ME, call.data().path("accessToken").asText());
		assertThat(me.data().path("phone").asText()).isEqualTo(PHONE_A);
		assertThat(me.data().path("nickname").asText()).isEqualTo("张三");
		assertThat(me.data().path("familyId").isNull()).isTrue();
	}

	@Test
	@DisplayName("同一手机号重复注册返回 409，而非 500 或静默覆盖")
	void registerRejectsDuplicatePhone() throws Exception {
		register(PHONE_A, "张三");

		Call duplicate = postJson(AUTH_REGISTER, Map.of("phone", PHONE_A, "password", PASSWORD, "nickname", "李四"),
				nextIp(), null);

		assertThat(duplicate.status()).isEqualTo(HttpStatus.CONFLICT.value());
		assertThat(duplicate.code()).isEqualTo(ErrorCode.PHONE_ALREADY_REGISTERED.code());
	}

	@Test
	@DisplayName("密码规则服务端二次校验：过短、纯字母、纯数字全部拒绝（§4.1.1、§5.2）")
	void registerRejectsWeakPassword() throws Exception {
		for (String weak : new String[] { "Ab1", "abcdefgh", "12345678" }) {
			Call call = postJson(AUTH_REGISTER, Map.of("phone", PHONE_A, "password", weak, "nickname", "张三"), nextIp(),
					null);
			assertThat(call.code()).as("口令 %s 应被拒绝", weak).isEqualTo(ErrorCode.VALIDATION_FAILED.code());
		}
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM `user`", Integer.class)).isZero();
	}

	@Test
	@DisplayName("手机号格式与昵称长度在服务端校验，绕过前端也拦得住")
	void registerRejectsMalformedInput() throws Exception {
		assertThat(postJson(AUTH_REGISTER, Map.of("phone", "12345678901", "password", PASSWORD, "nickname", "张三"),
				nextIp(), null).code()).isEqualTo(ErrorCode.VALIDATION_FAILED.code());
		assertThat(postJson(AUTH_REGISTER, Map.of("phone", PHONE_A, "password", PASSWORD, "nickname", ""), nextIp(),
				null).code()).isEqualTo(ErrorCode.VALIDATION_FAILED.code());
		assertThat(postJson(AUTH_REGISTER,
				Map.of("phone", PHONE_A, "password", PASSWORD, "nickname", "一二三四五六七八九十一二三"), nextIp(), null)
				.code()).isEqualTo(ErrorCode.VALIDATION_FAILED.code());
	}

	@Test
	@DisplayName("账号不存在与密码错误返回同一个码：不给手机号枚举留探针")
	void loginDoesNotRevealWhetherPhoneExists() throws Exception {
		register(PHONE_A, "张三");

		Call unknownPhone = login(PHONE_B, PASSWORD);
		Call wrongPassword = login(PHONE_A, "WrongPass123");

		assertThat(unknownPhone.code()).isEqualTo(ErrorCode.LOGIN_BAD_CREDENTIAL.code());
		assertThat(wrongPassword.code()).isEqualTo(ErrorCode.LOGIN_BAD_CREDENTIAL.code());
		assertThat(unknownPhone.message()).isEqualTo(wrongPassword.message());
	}

	@Test
	@DisplayName("验收用例 5：连续 5 次密码错误后锁定，第 6 次即使密码正确也被拒绝")
	void accountLockedAfterFiveWrongPasswords() throws Exception {
		register(PHONE_A, "张三");
		// 六次尝试共用同一个 IP，顺带证明锁定是按账号而非按 IP：攻击者换 IP 也绕不过去
		String ip = "10.30.0.1";

		for (int attempt = 1; attempt <= 5; attempt++) {
			Call call = login(PHONE_A, "WrongPass123", ip);
			assertThat(call.code()).as("第 %d 次错误口令", attempt).isEqualTo(ErrorCode.LOGIN_BAD_CREDENTIAL.code());
		}

		Call sixthWithCorrectPassword = login(PHONE_A, PASSWORD, ip);
		assertThat(sixthWithCorrectPassword.status()).isEqualTo(HttpStatus.LOCKED.value());
		assertThat(sixthWithCorrectPassword.code()).isEqualTo(ErrorCode.ACCOUNT_LOCKED.code());
	}

	@Test
	@DisplayName("锁定状态写在 Redis 且带 TTL，不给 user 表加 locked_until 字段（§4.1.2）")
	void lockStateLivesInRedisWithTtl() throws Exception {
		register(PHONE_A, "张三");
		for (int i = 0; i < 5; i++) {
			login(PHONE_A, "WrongPass123", "10.30.0.2");
		}

		Long ttl = redis.getExpire("auth:lock:" + PHONE_A);
		assertThat(ttl).as("锁定键须靠 TTL 自动解锁，不能永不过期").isBetween(1L, 15L * 60);
		assertThat(jdbcTemplate.queryForList("SHOW COLUMNS FROM `user` LIKE 'locked_until'")).isEmpty();
	}

	@Test
	@DisplayName("登录成功清空失败计数：4 次错误后再错 4 次仍不该锁定")
	void successfulLoginClearsFailureCounter() throws Exception {
		register(PHONE_A, "张三");
		String ip = "10.30.0.3";

		for (int i = 0; i < 4; i++) {
			login(PHONE_A, "WrongPass123", ip);
		}
		assertThat(login(PHONE_A, PASSWORD, ip).code()).isEqualTo("OK");

		for (int i = 0; i < 4; i++) {
			login(PHONE_A, "WrongPass123", ip);
		}
		// 计数若没被清空，这里累计到 8 次，第 6 次起就会是 ACCOUNT_LOCKED
		assertThat(login(PHONE_A, PASSWORD, ip).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("续期轮换 Refresh Token，旧的一次性失效，防重放（§4.1.2）")
	void refreshRotatesRefreshToken() throws Exception {
		Account account = register(PHONE_A, "张三");

		Call refreshed = postJson(AUTH_REFRESH, Map.of("refreshToken", account.refreshToken()), null);
		assertThat(refreshed.code()).isEqualTo("OK");
		String newRefresh = refreshed.data().path("refreshToken").asText();
		assertThat(newRefresh).isNotEqualTo(account.refreshToken());

		Call replay = postJson(AUTH_REFRESH, Map.of("refreshToken", account.refreshToken()), null);
		assertThat(replay.status()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
		assertThat(replay.code()).isEqualTo(ErrorCode.REFRESH_TOKEN_INVALID.code());

		// 轮换出来的新令牌仍可继续续期
		assertThat(postJson(AUTH_REFRESH, Map.of("refreshToken", newRefresh), null).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("Access Token 不能当 Refresh Token 用：typ 声明分开校验")
	void accessTokenRejectedAsRefreshToken() throws Exception {
		Account account = register(PHONE_A, "张三");

		Call call = postJson(AUTH_REFRESH, Map.of("refreshToken", account.accessToken()), null);

		assertThat(call.status()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
		assertThat(call.code()).isEqualTo(ErrorCode.REFRESH_TOKEN_INVALID.code());
	}

	@Test
	@DisplayName("退出登录吊销 Refresh Token，但不连带杀死尚未过期的 Access Token（§4.1.2）")
	void logoutRevokesRefreshTokenOnly() throws Exception {
		Account account = register(PHONE_A, "张三");

		assertThat(postJson(AUTH_LOGOUT, Map.of("refreshToken", account.refreshToken()), account.accessToken()).code())
			.isEqualTo("OK");

		assertThat(postJson(AUTH_REFRESH, Map.of("refreshToken", account.refreshToken()), null).code())
			.isEqualTo(ErrorCode.REFRESH_TOKEN_INVALID.code());
		assertThat(getJson(USERS_ME, account.accessToken()).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("退出登录是幂等的：重复退出、退出他人令牌都不报错")
	void logoutIsIdempotent() throws Exception {
		Account account = register(PHONE_A, "张三");
		Account other = register(PHONE_B, "李四");

		assertThat(postJson(AUTH_LOGOUT, Map.of("refreshToken", account.refreshToken()), account.accessToken()).code())
			.isEqualTo("OK");
		assertThat(postJson(AUTH_LOGOUT, Map.of("refreshToken", account.refreshToken()), account.accessToken()).code())
			.isEqualTo("OK");
		// 拿别人的令牌来退出，不能把别人的登录态搞掉
		assertThat(postJson(AUTH_LOGOUT, Map.of("refreshToken", other.refreshToken()), account.accessToken()).code())
			.isEqualTo("OK");
		assertThat(getJson(USERS_ME, other.accessToken()).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("原密码不正确时拒绝改密，且不波及自己其他设备的登录态")
	void changePasswordRejectsWrongOldPassword() throws Exception {
		Account account = register(PHONE_A, "张三");
		// 版本号递增只能通过「另一台设备是否还活着」观测到：同设备令牌本来就有效，断言它没意义
		Account otherDevice = secondDevice(account);

		Call call = patchJson(AUTH_PASSWORD, Map.of("oldPassword", "WrongPass123", "newPassword", "NewPass456"),
				account.accessToken());

		assertThat(call.code()).isEqualTo(ErrorCode.PASSWORD_MISMATCH.code());
		assertThat(getJson(USERS_ME, otherDevice.accessToken()).code()).isEqualTo("OK");
		assertThat(login(PHONE_A, PASSWORD).code()).as("改密失败后原口令仍应可用").isEqualTo("OK");
	}

	@Test
	@DisplayName("改密成功后新口令生效、旧口令失效，且当前设备拿到一套新令牌可无感继续（§5.2）")
	void changePasswordTakesEffect() throws Exception {
		Account account = register(PHONE_A, "张三");

		Call call = patchJson(AUTH_PASSWORD, Map.of("oldPassword", PASSWORD, "newPassword", "NewPass456"),
				account.accessToken());

		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("accessToken").asText()).as("响应须带新令牌对，当前设备才不用被踢去重新登录")
			.isNotBlank();
		assertThat(login(PHONE_A, "NewPass456").code()).isEqualTo("OK");
		assertThat(login(PHONE_A, PASSWORD).code()).isEqualTo(ErrorCode.LOGIN_BAD_CREDENTIAL.code());
		assertThat(jdbcTemplate.queryForObject("SELECT password_hash FROM `user` WHERE phone = ?", String.class,
				PHONE_A)).as("服务端只存 BCrypt 摘要，不得明文落库")
			.startsWith("$2")
			.hasSize(60);
	}

	@Test
	@DisplayName("无令牌访问受保护接口返回统一响应体的 401，不是 Spring Security 默认空响应")
	void unauthenticatedRequestReturnsUnified401() throws Exception {
		Call call = getJson(USERS_ME, null);

		assertThat(call.status()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
		assertThat(call.code()).isEqualTo(ErrorCode.UNAUTHORIZED.code());
		assertThat(call.json().has("traceId")).isTrue();
	}

	@Test
	@DisplayName("浏览器导航（Accept 含 text/html 或 Sec-Fetch-Mode: navigate）未登录时 302 到 /login-required 提示页")
	void browserNavigationRedirectsToLoginRequiredPage() throws Exception {
		MockHttpServletResponse byAccept = mockMvc
			.perform(get(USERS_ME).header(HttpHeaders.ACCEPT, "text/html,application/xhtml+xml"))
			.andReturn().getResponse();
		assertThat(byAccept.getStatus()).isEqualTo(HttpStatus.FOUND.value());
		assertThat(byAccept.getHeader(HttpHeaders.LOCATION)).isEqualTo("/login-required");

		MockHttpServletResponse bySecFetchMode = mockMvc
			.perform(get(USERS_ME).header("Sec-Fetch-Mode", "navigate"))
			.andReturn().getResponse();
		assertThat(bySecFetchMode.getStatus()).isEqualTo(HttpStatus.FOUND.value());
		assertThat(bySecFetchMode.getHeader(HttpHeaders.LOCATION)).isEqualTo("/login-required");
	}

	@Test
	@DisplayName("/login-required 提示页可匿名访问，输出 UTF-8 的 HTML 说明段落，而不是 JSON")
	void loginRequiredPageRendersHtmlParagraph() throws Exception {
		MockHttpServletResponse response = mockMvc
			.perform(get("/login-required").header(HttpHeaders.ACCEPT, "text/html"))
			.andReturn().getResponse();

		assertThat(response.getStatus()).isEqualTo(HttpStatus.OK.value());
		assertThat(response.getContentType()).isEqualTo("text/html;charset=UTF-8");
		assertThat(response.getContentAsString(StandardCharsets.UTF_8))
			.contains("这个地址是「家记」的后端服务接口")
			.contains("请打开手机上的「家记」App 登录后使用")
			.doesNotContain("\"code\"");
	}

	@Test
	@DisplayName("伪造与篡改的令牌一律 401，且响应不回显任何令牌内容")
	void tamperedTokenRejected() throws Exception {
		Account account = register(PHONE_A, "张三");
		String token = account.accessToken();
		String tampered = token.substring(0, token.length() - 2) + (token.endsWith("A") ? "BB" : "AA");

		Call call = getJson(USERS_ME, tampered);

		assertThat(call.status()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
		assertThat(call.code()).isEqualTo(ErrorCode.UNAUTHORIZED.code());
		assertThat(call.message()).doesNotContain(token);
	}

	@Test
	@DisplayName("健康检查在 Security 之后仍可匿名访问，否则 Docker healthcheck 会判容器不健康")
	void actuatorHealthIsPublic() throws Exception {
		assertThat(getJson("/actuator/health", null).status()).isEqualTo(HttpStatus.OK.value());
	}

	@Test
	@DisplayName("§4.1.3 / §4.1.7 本期不开放的四个端点占位返回 501，而不是 404 让人以为路由写错")
	void deferredEndpointsReturn501() throws Exception {
		for (String path : new String[] { "/api/v1/auth/password/reset", "/api/v1/auth/wechat/login",
				"/api/v1/auth/sms/code", "/api/v1/auth/sms/login" }) {
			assertThat(postJson(path, Map.of(), null).status()).as(path).isEqualTo(HttpStatus.NOT_IMPLEMENTED.value());
		}
	}

}
