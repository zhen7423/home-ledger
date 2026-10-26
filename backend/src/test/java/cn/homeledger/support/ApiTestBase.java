package cn.homeledger.support;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

import cn.homeledger.config.PhotoProperties;
import cn.homeledger.security.ClientIpResolver;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * S2 集成测试基类：跑在真实 MySQL / Redis（deploy/docker-compose.yml）之上，不用 Testcontainers。
 *
 * 选择真实基础设施而非内嵌替身，是因为本阶段要验证的恰恰是「替换品测不出来」的东西：
 * Flyway 迁移（V1__schema.sql）在 MySQL 8.4 上的实际建表结果、utf8mb4_0900_ai_ci 排序规则下的唯一索引、
 * FOR UPDATE 行锁语义、以及 Redis Lua 脚本的原子性。H2 之类替身会把这些差异抹平。
 *
 * 代价是测试之间会互相留痕，所以每个测试前显式清库清 Redis（见 resetState）。
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("local")
public abstract class ApiTestBase {

	/** 满足 §4.1.1「8–20 位且同时含字母与数字」的固定测试口令。 */
	protected static final String PASSWORD = "Passw0rd123";

	protected static final String AUTH_REGISTER = "/api/v1/auth/register";

	protected static final String AUTH_LOGIN = "/api/v1/auth/login";

	protected static final String AUTH_REFRESH = "/api/v1/auth/refresh";

	protected static final String AUTH_LOGOUT = "/api/v1/auth/logout";

	protected static final String AUTH_PASSWORD = "/api/v1/auth/password";

	protected static final String USERS_ME = "/api/v1/users/me";

	protected static final String FAMILIES = "/api/v1/families";

	protected static final String FAMILY_CURRENT = "/api/v1/families/current";

	protected static final String CATEGORIES = "/api/v1/categories";

	protected static final String PAYMENT_ACCOUNTS = "/api/v1/payment-accounts";

	protected static final String TRANSACTIONS = "/api/v1/transactions";

	protected static final String RECURRING_RULES = "/api/v1/recurring-rules";

	protected static final String BUDGETS = "/api/v1/budgets";

	protected static final String BUDGET_PROGRESS = "/api/v1/budgets/progress";

	protected static final String REMINDER_SETTINGS = "/api/v1/reminders/settings";

	protected static final String REMINDER_PENDING = "/api/v1/reminders/pending";

	/** S9 的模块开关与首页聚合（§3.2、§4.6）。两条都不带 id 子路径。 */
	protected static final String PREFERENCE_MODULES = "/api/v1/preferences/modules";

	protected static final String HOME_OVERVIEW = "/api/v1/home/overview";

	protected static final String TRANSACTION_SUMMARY = "/api/v1/transactions/summary";

	protected static final String STATISTICS_OVERVIEW = "/api/v1/statistics/finance/overview";

	protected static final String EXPORT_TRANSACTIONS = "/api/v1/export/transactions";

	/** S6 猫咪模块（§8 的 11 条路径里测试会打到的那些）。带 id 的子路径由各测试类拼接。 */
	protected static final String CATS = "/api/v1/cats";

	protected static final String CAT_FOOD_BAGS = "/api/v1/cat-food-bags";

	protected static final String CAT_FOOD_BAG_CURRENT = "/api/v1/cat-food-bags/current";

	protected static final String CAT_DEWORMINGS = "/api/v1/cat-dewormings";

	protected static final String CAT_SETTINGS = "/api/v1/cat-settings";

	protected static final String CAT_FOOD_STATISTICS = "/api/v1/statistics/cat/food-consumption";

	protected static final String CAT_DEWORMING_STATISTICS = "/api/v1/statistics/cat/deworming";

	/**
	 * S7 宝宝模块（§8 的 16 条路径里测试会打到的那些）。带 id 的子路径由各测试类拼接。
	 *
	 * 两张静态字典表没有查询端点：疫苗程序表随应种清单下发、生长标准表随曲线响应下发。
	 * 这里不登记字典路径，正是为了让「顺手开一条字典 GET」在编译期就没有落点。
	 */
	protected static final String BABIES = "/api/v1/babies";

	protected static final String BABY_GROWTHS = "/api/v1/baby-growths";

	protected static final String BABY_GROWTH_CURVE = "/api/v1/baby-growths/curve";

	protected static final String BABY_VACCINE_PLANS = "/api/v1/baby-vaccine-plans";

	protected static final String BABY_VACCINE_RECORDS = "/api/v1/baby-vaccine-records";

	protected static final String BABY_MILESTONES = "/api/v1/baby-milestones";

	protected static final String BABY_MEDICALS = "/api/v1/baby-medicals";

	protected static final String BABY_STATS_GROWTH = "/api/v1/statistics/baby/growth";

	protected static final String BABY_STATS_VACCINE = "/api/v1/statistics/baby/vaccine";

	/** S10 档案照片（§4.3.1 / §4.4.1）。{fileId} 是《uuid.扩展名》全名，读取端按归属反查。 */
	protected static final String PHOTOS = "/api/v1/photos";

	/** 第 32 轮 奶粉开罐记录（§4.5.3）。current 是宝宝主页奶粉卡的余量推算。 */
	protected static final String BABY_FORMULA_BAGS = "/api/v1/baby-formula-bags";

	protected static final String BABY_FORMULA_BAG_CURRENT = "/api/v1/baby-formula-bags/current";

	protected static final String BABY_FORMULA_STATISTICS = "/api/v1/statistics/baby/formula";

	@Autowired
	protected MockMvc mockMvc;

	@Autowired
	protected JdbcTemplate jdbcTemplate;

	@Autowired
	protected StringRedisTemplate redis;

	@Autowired
	protected ObjectMapper objectMapper;

	/** S10 档案照片的落盘目录（application-local.yml 指到 java.io.tmpdir 下，随构建清理）。 */
	@Autowired
	protected PhotoProperties photoProperties;

	private final AtomicInteger ipSeq = new AtomicInteger();

	/**
	 * 清空 S2 四张表、S3 三张表、S4 四张表、S6 四张猫表与 S7 六张宝宝表，再把 Redis 里的测试痕迹抹干净。
	 *
	 * 删除顺序必须逆着外键：recurring_execution_log → transaction / recurring_rule / budget /
	 * payment_account / category → family_member → user_auth_binding → family → user。
	 * S3 与 S4 那六张都以 family_id 外键指向 family，漏掉任一张家庭就删不掉；
	 * recurring_execution_log 还额外指向 recurring_rule，必须排在它前面。
	 * S6 四张猫表同样只有 family_id 一个外键，所以只要排在 family 之前即可；
	 * 四者之间另有 cat_id 引用，故按 cat_deworming → cat_food_bag → cat_setting → cat 先清引用方。
	 * S7 六张同理且 baby_id / plan_id 都是裸列，故顺序只为可读性：先清五张挂着宝宝的录入表，最后清 baby。
	 * 这里的 DELETE FROM 是全表清、不看 deleted 列，软删行一并抹掉——
	 * 猫表能在不同测试里反复用同一个名字与同一天的袋子的原因就在这。
	 * S7 两张字典表**不在这里清**：它们是迁移播种的静态数据、没有 family_id，
	 * 清掉这一次等于把同进程里后续所有测试要用的 24 行程序表与 546 行标准表一起抹了。
	 * reminder_setting 没有任何外键，排在 user 之前只是想让「账号没了但偏好还在」这种状态在测试里不出现。
	 * Redis 不在数据库事务里，令牌版本号 / refresh jti / 限流计数 / 统计缓存只能显式清；
	 * 漏清 rl:* 会让上一个测试攒下的计数把下一个测试莫名判成 429。
	 * stats:* 连每家庭的版本号键一起清掉，每个测试才都从「版本号不存在」起算，
	 * 否则上一个测试 INCR 出来的版本号会让本测试第一次查询命中的键与断言里预期的键对不上。
	 */
	@BeforeEach
	void resetState() {
		jdbcTemplate.update("DELETE FROM recurring_execution_log");
		jdbcTemplate.update("DELETE FROM cat_deworming");
		jdbcTemplate.update("DELETE FROM cat_food_bag");
		jdbcTemplate.update("DELETE FROM cat_setting");
		jdbcTemplate.update("DELETE FROM cat");
		jdbcTemplate.update("DELETE FROM baby_growth");
		jdbcTemplate.update("DELETE FROM baby_vaccine_record");
		jdbcTemplate.update("DELETE FROM baby_vaccine_plan");
		jdbcTemplate.update("DELETE FROM baby_milestone");
		jdbcTemplate.update("DELETE FROM baby_medical");
		jdbcTemplate.update("DELETE FROM baby_formula_bag");
		jdbcTemplate.update("DELETE FROM baby");
		jdbcTemplate.update("DELETE FROM `transaction`");
		jdbcTemplate.update("DELETE FROM recurring_rule");
		jdbcTemplate.update("DELETE FROM budget");
		jdbcTemplate.update("DELETE FROM payment_account");
		jdbcTemplate.update("DELETE FROM category");
		jdbcTemplate.update("DELETE FROM reminder_setting");
		jdbcTemplate.update("DELETE FROM family_member");
		jdbcTemplate.update("DELETE FROM user_auth_binding");
		jdbcTemplate.update("DELETE FROM family");
		jdbcTemplate.update("DELETE FROM `user`");
		flushRedis("auth:*");
		flushRedis("rl:*");
		flushRedis("stats:*");
	}

	/**
	 * 清掉 S10 照片测试留在磁盘上的文件。
	 * <p>
	 * 照片文件不在数据库里、不受 resetState 管，而上一个测试留下的文件会让「文件应已删除」的断言
	 * 分不清是删了还是本来就在。文件名是 32 位 UUID，互不重名，所以只删不建也没有跨测试污染。
	 * 调用方（两个照片相关测试）在自己 {@code @BeforeEach} 里调用。
	 */
	protected void clearPhotoFiles() {
		Path dir = this.photoProperties.dir().toAbsolutePath().normalize();
		if (!Files.isDirectory(dir)) {
			return;
		}
		try (Stream<Path> walk = Files.walk(dir)) {
			walk.filter(Files::isRegularFile).forEach(path -> {
				try {
					Files.deleteIfExists(path);
				}
				catch (IOException e) {
					throw new UncheckedIOException(e);
				}
			});
		}
		catch (IOException e) {
			throw new UncheckedIOException(e);
		}
	}

	private void flushRedis(String pattern) {
		Set<String> keys = redis.keys(pattern);
		if (keys != null && !keys.isEmpty()) {
			redis.delete(keys);
		}
	}

	// ---- 客户端 IP ----

	/**
	 * 每次调用返回一个互不相同的 IP。
	 *
	 * MockMvc 的 remoteAddr 恒为 127.0.0.1，若每个测试共用它，注册限流（5 次/分钟/IP）
	 * 会在第三个测试就把后续注册全判成 429，测出来的失败与业务无关。按 IP 区分是限流的
	 * 设计语义，测试模拟不同客户端属于正常用法；限流本身的阈值另有专门的测试盯着。
	 */
	protected String nextIp() {
		int n = ipSeq.incrementAndGet();
		return "10.20." + (n / 250) + "." + (n % 250 + 1);
	}

	// ---- 账号辅助 ----

	protected record Account(Long userId, String phone, String nickname, String accessToken, String refreshToken) {
	}

	/** 注册并顺手取回 userId：令牌载荷里没有 userId，只能再问一次 /users/me。 */
	protected Account register(String phone, String nickname) throws Exception {
		return register(phone, PASSWORD, nickname, nextIp());
	}

	protected Account register(String phone, String password, String nickname, String ip) throws Exception {
		Call call = postJson(AUTH_REGISTER, Map.of("phone", phone, "password", password, "nickname", nickname), ip,
				null);
		String accessToken = call.data().path("accessToken").asText();
		Long userId = getJson(USERS_ME, accessToken).data().path("id").asLong();
		return new Account(userId, phone, nickname, accessToken, call.data().path("refreshToken").asText());
	}

	protected Call login(String phone, String password) throws Exception {
		return login(phone, password, nextIp());
	}

	protected Call login(String phone, String password, String ip) throws Exception {
		return postJson(AUTH_LOGIN, Map.of("phone", phone, "password", password), ip, null);
	}

	/** 同一账号再登录一次，用来模拟第二台设备。 */
	protected Account secondDevice(Account account) throws Exception {
		Call call = login(account.phone(), PASSWORD, nextIp());
		return new Account(account.userId(), account.phone(), account.nickname(), call.data().path("accessToken").asText(),
				call.data().path("refreshToken").asText());
	}

	// ---- 家庭辅助 ----

	/**
	 * 建家庭。第 33 轮起创建不再自动签发邀请码，句柄只带 id 与 name；要让第二人加入，
	 * 先调 {@link #enableInvite} 取新码，或直接 {@link #inviteAndJoin}。
	 */
	protected FamilyHandle createFamily(Account owner, String name) throws Exception {
		JsonNode data = postJson(FAMILIES, Map.of("name", name), null, owner.accessToken()).data();
		return new FamilyHandle(data.path("id").asLong(), data.path("name").asText());
	}

	protected FamilyHandle createFamily(Account owner) throws Exception {
		return createFamily(owner, owner.nickname() + "的家");
	}

	/**
	 * 注册 + 建好家庭。S3 的用例几乎都要这个前置（建家庭时同时装入了预置类别与支付方式）。
	 * 需要邀请码让第二人加入的场景别用它，直接 createFamily + enableInvite / inviteAndJoin。
	 */
	protected Account registerWithFamily(String phone, String nickname) throws Exception {
		Account account = register(phone, nickname);
		createFamily(account);
		return account;
	}

	protected Call joinFamily(Account member, String inviteCode) throws Exception {
		return postJson(FAMILIES + "/join", Map.of("inviteCode", inviteCode), null, member.accessToken());
	}

	/**
	 * 开启邀请并返回新签发的邀请码（第 33 轮）。开着的入口重开一次等价于「重置」：
	 * 换发新码并顺延 24 小时，旧码立即失效。
	 */
	protected String enableInvite(Account owner) throws Exception {
		JsonNode data = putJson(FAMILY_CURRENT + "/invite", Map.of("enabled", true), owner.accessToken()).data();
		return data.path("inviteCode").asText();
	}

	/**
	 * 开一个新邀请并让 member 立即加入。单次使用语义下每加一人要一条新码，
	 * 多成员场景逐人调用本方法即可。
	 */
	protected Call inviteAndJoin(Account owner, Account member) throws Exception {
		return joinFamily(member, enableInvite(owner));
	}

	protected Call currentFamily(String accessToken) throws Exception {
		return getJson(FAMILY_CURRENT, accessToken);
	}

	protected record FamilyHandle(Long id, String name) {
	}

	// ---- 字典辅助 ----

	/**
	 * 按名字取预置支出大类的 id。测试按名字而不是按 id 找字典项：预置清单是产品的一部分，
	 * 但 id 是运行时生成的，写死 id 的测试在另一个库里必然红。
	 */
	protected long topCategoryId(Account account, String name) throws Exception {
		Call call = getJson(CATEGORIES + "?type=EXPENSE&enabledOnly=false", account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		for (JsonNode node : call.data()) {
			if (node.path("name").asText().equals(name)) {
				return node.path("id").asLong();
			}
		}
		throw new AssertionError("预置类别树里应有大类 " + name);
	}

	protected long paymentAccountId(Account account, String name) throws Exception {
		Call call = getJson(PAYMENT_ACCOUNTS + "?enabledOnly=false", account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		for (JsonNode node : call.data()) {
			if (node.path("name").asText().equals(name)) {
				return node.path("id").asLong();
			}
		}
		throw new AssertionError("预置支付方式里应有 " + name);
	}

	// ---- 宝宝辅助 ----

	/**
	 * 建一个宝宝并回它的 id。传 null 的字段不进 body：请求体是整份覆盖语义，
	 * 把 null 显式写进去等于「清空这一项」，而调用方传 null 的意思是「这一项不管」。
	 */
	protected long createBaby(String token, String name, String gender, String birthDate) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		putIfPresent(body, "name", name);
		putIfPresent(body, "gender", gender);
		putIfPresent(body, "birthDate", birthDate);
		Call call = postJson(BABIES, body, token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	/** 建一条身高体重记录。`heightCm` / `weightKg` 传 null 表示这一项不记，列表里那一档的增量随之是 null。 */
	protected long createGrowth(String token, long babyId, String measureDate, String heightCm, String weightKg)
			throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		putIfPresent(body, "measureDate", measureDate);
		putIfPresent(body, "heightCm", heightCm);
		putIfPresent(body, "weightKg", weightKg);
		Call call = postJson(BABY_GROWTHS, body, token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	/**
	 * 该宝宝应种清单里第一条 (疫苗名称, 剂次) 命中的行 id，找不到返回 -1。
	 *
	 * 走端点而不是直连 SQL：直连会绕过租户拦截器，而这里要验的恰恰是「清单是这条端点给出来的」。
	 */
	protected long planIdOf(String token, long babyId, String vaccineName, String doseNo) throws Exception {
		Call call = getJson(BABY_VACCINE_PLANS, Map.of("babyId", String.valueOf(babyId)), token);
		assertThat(call.code()).isEqualTo("OK");
		for (JsonNode node : call.data()) {
			if (node.path("vaccineName").asText().equals(vaccineName)
					&& node.path("doseNo").asText().equals(doseNo)) {
				return node.path("id").asLong();
			}
		}
		return -1;
	}

	private static void putIfPresent(Map<String, Object> body, String key, Object value) {
		if (value != null) {
			body.put(key, value);
		}
	}

	// ---- HTTP 辅助 ----

	protected record Call(int status, JsonNode json) {

		/** 统一响应体的业务码，成功恒为 OK，失败为 ErrorCode 名（§8）。 */
		public String code() {
			return json.path("code").asText();
		}

		public String message() {
			return json.path("message").asText();
		}

		public JsonNode data() {
			return json.path("data");
		}

		public boolean isNullData() {
			return json.path("data").isNull();
		}
	}

	protected Call getJson(String path, String accessToken) throws Exception {
		return execute(get(path), accessToken, null, null);
	}

	/**
	 * 带查询参数的 GET。
	 * <p>
	 * 参数走 MockMvc 的 param 而不是拼在 URL 里：MockMvc 从 URI 上解析查询串时用的字符集与真实容器不同，
	 * 中文筛选词拼进 URL 会得到一串乱码，测出来的「查不到」跟业务无关。生产上这一步由容器按 UTF-8 负责。
	 */
	protected Call getJson(String path, Map<String, String> params, String accessToken) throws Exception {
		MockHttpServletRequestBuilder builder = get(path);
		params.forEach(builder::param);
		return execute(builder, accessToken, null, null);
	}

	/**
	 * 取二进制响应（§8 的 GET /export/transactions）。
	 * <p>
	 * 成功时 body 是文件字节，失败时 body 是统一响应体的 UTF-8 字节——调用方按 status 决定怎么解。
	 * 失败分支要断言错误码时，用基类的 objectMapper 直接把 body 解回来：
	 * {@code objectMapper.readTree(call.body()).path("code").asText()}。
	 * <p>
	 * 与 execute 一样只 perform 一次，理由相同。
	 */
	protected BinaryCall getBytes(String path, Map<String, String> params, String accessToken) throws Exception {
		MockHttpServletRequestBuilder builder = get(path);
		params.forEach(builder::param);
		if (accessToken != null) {
			builder.header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken);
		}
		MvcResult result = mockMvc.perform(builder).andReturn();
		MockHttpServletResponse response = result.getResponse();
		return new BinaryCall(response.getStatus(), response.getContentAsByteArray(), response.getContentType(),
				response.getHeader(HttpHeaders.CONTENT_DISPOSITION));
	}

	/** 二进制响应。contentType 与 contentDisposition 是导出的两个必须核对的响应头（§8）。 */
	protected record BinaryCall(int status, byte[] body, String contentType, String contentDisposition) {
	}

	protected Call postJson(String path, Object payload, String accessToken) throws Exception {
		return execute(post(path), accessToken, nextIp(), payload);
	}

	protected Call postJson(String path, Object payload, String ip, String accessToken) throws Exception {
		return execute(post(path), accessToken, ip, payload);
	}

	protected Call patchJson(String path, Object payload, String accessToken) throws Exception {
		return execute(patch(path), accessToken, null, payload);
	}

	protected Call putJson(String path, Object payload, String accessToken) throws Exception {
		return execute(put(path), accessToken, null, payload);
	}

	protected Call deleteJson(String path, Object payload, String accessToken) throws Exception {
		return execute(delete(path), accessToken, null, payload);
	}

	protected Call deleteNoBody(String path, String accessToken) throws Exception {
		return execute(delete(path), accessToken, null, null);
	}

	/**
	 * 提交 multipart（S10 档案照片上传）。
	 * <p>
	 * 与 execute 一样只 perform 一次：上传写磁盘又写库，执行两遍会留下两个文件、两次翻新 photo_url。
	 * 上传不受 IP 限流场景约束，不需要 nextIp。
	 */
	protected Call uploadMultipart(String path, String accessToken, String partName, String fileName,
			String contentType, byte[] bytes) throws Exception {
		MockMultipartFile file = new MockMultipartFile(partName, fileName, contentType, bytes);
		// Spring Framework 7 里 MockMultipartHttpServletRequestBuilder 与 MockHttpServletRequestBuilder
		// 已不是父子关系，必须用具体类型承接 multipart(...).file(...) 的返回值
		MockMultipartHttpServletRequestBuilder builder = multipart(path).file(file);
		if (accessToken != null) {
			builder.header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken);
		}
		MvcResult result = mockMvc.perform(builder).andReturn();
		String body = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
		return new Call(result.getResponse().getStatus(),
				body.isBlank() ? objectMapper.createObjectNode() : objectMapper.readTree(body));
	}

	private Call execute(MockHttpServletRequestBuilder builder, String accessToken, String ip, Object payload)
			throws Exception {
		if (accessToken != null) {
			builder.header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken);
		}
		if (ip != null) {
			// 走 ClientIpResolver 真正信任的那个头，顺带验证该解析链在集成环境下可用
			builder.header(ClientIpResolver.HEADER, ip);
		}
		if (payload != null) {
			builder.contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(payload));
		}
		// 只 perform 一次：请求有副作用（写库、递增限流计数、递增令牌版本号），执行两遍测出来的行为是假的
		MvcResult result = mockMvc.perform(builder).andReturn();
		String body = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
		return new Call(result.getResponse().getStatus(),
				body.isBlank() ? objectMapper.createObjectNode() : objectMapper.readTree(body));
	}

}
