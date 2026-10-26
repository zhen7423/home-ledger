package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.common.ErrorCode;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.1.4 家庭的创建与加入、§4.1.5 数据全共享、§4.1.6 家庭生命周期。
 * 覆盖验收用例 1 与 4，以及用例 3 所依赖的昵称快照机制（用例 3 本身要有流水才能验，属 S3）。
 */
class FamilyFlowIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_C = "13800000003";

	private static final String PHONE_D = "13800000004";

	private static final String PHONE_E = "13800000005";

	private static final String PHONE_F = "13800000006";

	@Test
	@DisplayName("验收用例 1：A 创建家庭并开启邀请，B 用邀请码加入后，双方看到的都是同 2 名成员")
	void bothAccountsSeeEachOtherAfterJoin() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");

		FamilyHandle family = createFamily(a, "张家");
		// 第 33 轮：创建家庭不再自动带邀请码，入口默认关闭，开一次邀请才拿到码
		String inviteCode = enableInvite(a);
		assertThat(inviteCode).as("邀请码须为 6 位数字（§4.1.4）").matches("\\d{6}");

		assertThat(joinFamily(b, inviteCode).code()).isEqualTo("OK");

		JsonNode seenByA = currentFamily(a.accessToken()).data();
		JsonNode seenByB = currentFamily(b.accessToken()).data();

		assertThat(seenByA.path("id").asLong()).isEqualTo(family.id());
		assertThat(seenByA.path("name").asText()).isEqualTo("张家");
		assertThat(memberIds(seenByA)).containsExactly(a.userId(), b.userId());
		assertThat(memberIds(seenByB)).as("B 看到的成员集合须与 A 完全一致（§4.1.5 数据全共享）")
			.containsExactly(a.userId(), b.userId());
		assertThat(roleOf(seenByA, a.userId())).isEqualTo("OWNER");
		assertThat(roleOf(seenByA, b.userId())).isEqualTo("MEMBER");
		assertThat(nicknameOf(seenByB, a.userId())).isEqualTo("张三");
	}

	@Test
	@DisplayName("家庭名留空时默认「XX 的家」（§4.1.4）")
	void blankFamilyNameFallsBackToNickname() throws Exception {
		Account a = register(PHONE_A, "张三");

		assertThat(createFamily(a, "  ").name()).isEqualTo("张三的家");
	}

	@Test
	@DisplayName("尚无家庭时 GET /families/current 返回 200 + data:null，404 专用于越权（§8）")
	void currentFamilyReturnsNullDataWhenUserHasNoFamily() throws Exception {
		Account a = register(PHONE_A, "张三");

		Call call = currentFamily(a.accessToken());

		assertThat(call.status()).isEqualTo(HttpStatus.OK.value());
		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.isNullData()).isTrue();
	}

	@Test
	@DisplayName("验收用例 4：已在家庭中的账号再输别的邀请码，得到明确的「你已在一个家庭中」")
	void joiningAnotherFamilyWhileAlreadyInOneIsRejected() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account c = register(PHONE_C, "王五");
		FamilyHandle first = createFamily(a);
		FamilyHandle second = createFamily(c);
		assertThat(inviteAndJoin(a, b).code()).isEqualTo("OK");

		Call joinOther = joinFamily(b, "123456");
		assertThat(joinOther.status()).isEqualTo(HttpStatus.CONFLICT.value());
		assertThat(joinOther.code()).isEqualTo(ErrorCode.ALREADY_IN_FAMILY.code());

		// 同理不能再创一个家庭，否则会同时属于两个家庭
		Call createAnother = postJson(FAMILIES, Map.of("name", "李家"), null, b.accessToken());
		assertThat(createAnother.code()).isEqualTo(ErrorCode.ALREADY_IN_FAMILY.code());
		assertThat(memberIds(currentFamily(b.accessToken()).data())).containsExactly(a.userId(), b.userId());
	}

	@Test
	@DisplayName("§4.1.4 邀请码校验三项分别给出不同文案，不合并为笼统的「邀请码无效」")
	void inviteCodeFailuresAreDistinguishable() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account c = register(PHONE_C, "王五");
		FamilyHandle family = createFamily(a);
		String code = enableInvite(a);

		// 库里此刻只有一个开着邀请的家庭，故任意其他码必然不存在
		assertThat(joinFamily(b, code.equals("123456") ? "654321" : "123456").code())
			.isEqualTo(ErrorCode.INVITE_CODE_NOT_FOUND.code());

		expireInviteCode(family.id());
		assertThat(joinFamily(b, code).code()).isEqualTo(ErrorCode.INVITE_CODE_EXPIRED.code());

		// 第三项「成员已满」由 sixthMemberIsRejected 独立覆盖，此处补「家庭已解散」。
		// 口径解读（需在评审时确认）：§4.1.4 要求三项各给不同文案，实现把「已解散」并入 INVITE_CODE_NOT_FOUND——
		// 解散后的码在业务上已不是一个有效码，且单独回一句「该家庭已解散」等于向外泄露这个码曾经存在过。
		FamilyHandle secondFamily = createFamily(c);
		String secondCode = enableInvite(c);
		disband(c, secondFamily.id());
		Account d = register(PHONE_D, "赵六");
		assertThat(joinFamily(d, secondCode).code()).isEqualTo(ErrorCode.INVITE_CODE_NOT_FOUND.code());
	}

	@Test
	@DisplayName("成员上限 5 人，第 6 人加入被拒并给出明确文案（§4.1.4）")
	void sixthMemberIsRejected() throws Exception {
		Account owner = register(PHONE_A, "成员一");
		FamilyHandle family = createFamily(owner);
		Map<String, String> fourMore = Map.of(PHONE_B, "成员二", PHONE_C, "成员三", PHONE_D, "成员四", PHONE_E, "成员五");
		for (Map.Entry<String, String> entry : fourMore.entrySet()) {
			Account member = register(entry.getKey(), entry.getValue());
			// 第 33 轮：码是一次性的，每加一人要重新开一次邀请拿新码
			assertThat(inviteAndJoin(owner, member).code()).isEqualTo("OK");
		}
		assertThat(memberIds(currentFamily(owner.accessToken()).data())).hasSize(5);

		Account sixth = register(PHONE_F, "成员六");
		Call call = joinFamily(sixth, enableInvite(owner));

		assertThat(call.code()).isEqualTo(ErrorCode.FAMILY_MEMBER_LIMIT.code());
		assertThat(call.message()).contains("5");
		// 成员已满时码不该被消费掉：入口仍开着，创建者换个时机再试仍用得上
		assertThat(currentFamily(owner.accessToken()).data().path("inviteEnabled").asBoolean()).isTrue();
		assertThat(memberIds(currentFamily(owner.accessToken()).data())).hasSize(5);
	}

	@Test
	@DisplayName("邀请码一次性：用过一次即失效并自动关闭邀请入口（第 33 轮）")
	void inviteCodeIsSingleUseAndClosesTheEntry() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account c = register(PHONE_C, "王五");
		FamilyHandle family = createFamily(a);
		String code = enableInvite(a);

		assertThat(joinFamily(b, code).code()).isEqualTo("OK");

		// 入口自动关闭：响应里不再有码，开关也回到 false
		JsonNode afterUse = currentFamily(a.accessToken()).data();
		assertThat(afterUse.path("inviteEnabled").asBoolean()).as("用掉一次即自动关闭邀请入口").isFalse();
		assertThat(afterUse.path("inviteCode").isNull()).as("关闭后不再保留邀请码").isTrue();
		assertThat(jdbcTemplate.queryForObject("SELECT invite_code FROM family WHERE id = ?", String.class, family.id()))
			.isNull();

		// 同一个码不能再用第二次
		assertThat(joinFamily(c, code).code()).isEqualTo(ErrorCode.INVITE_CODE_NOT_FOUND.code());
	}

	@Test
	@DisplayName("建家庭不再自动签发邀请码，入口默认关闭（第 33 轮）")
	void creatingAFamilyLeavesInviteClosed() throws Exception {
		Account a = register(PHONE_A, "张三");
		createFamily(a, "张家");

		JsonNode created = currentFamily(a.accessToken()).data();

		assertThat(created.path("inviteEnabled").asBoolean()).isFalse();
		assertThat(created.path("inviteCode").isNull()).isTrue();
		// 关闭着的时候拿不到码，别人也无从加入
		Account b = register(PHONE_B, "李四");
		assertThat(joinFamily(b, "123456").code()).isEqualTo(ErrorCode.INVITE_CODE_NOT_FOUND.code());
	}

	@Test
	@DisplayName("邀请开关：关掉后旧码立即失效，重开换发新码（第 33 轮）")
	void togglingInviteInvalidatesOldCode() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account c = register(PHONE_C, "王五");
		FamilyHandle family = createFamily(a);
		String first = enableInvite(a);

		// 关：码清空、入口关闭
		JsonNode closed = putJson(FAMILY_CURRENT + "/invite", Map.of("enabled", false), a.accessToken()).data();
		assertThat(closed.path("inviteEnabled").asBoolean()).isFalse();
		assertThat(closed.path("inviteCode").isNull()).isTrue();
		assertThat(joinFamily(b, first).code()).as("关闭后旧码立即失效").isEqualTo(ErrorCode.INVITE_CODE_NOT_FOUND.code());

		// 重开：换发新码，旧码依旧不可用
		String second = enableInvite(a);
		assertThat(second).isNotEqualTo(first);
		assertThat(joinFamily(c, first).code()).isEqualTo(ErrorCode.INVITE_CODE_NOT_FOUND.code());
		assertThat(joinFamily(b, second).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("邀请有效期 24 小时（第 33 轮）：刚签发的码 24 小时内可用，超时即过期")
	void inviteCodeExpiresAfter24Hours() throws Exception {
		Account a = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(a);
		enableInvite(a);

		// 签发即按 24 小时计，允许几十秒的执行误差
		LocalDateTime expireAt = jdbcTemplate.queryForObject(
				"SELECT invite_code_expire_at FROM family WHERE id = ?", LocalDateTime.class, family.id());
		long minutes = Duration.between(LocalDateTime.now(), expireAt).toMinutes();
		assertThat(minutes).as("有效期应为 24 小时，实际 %d 分钟", minutes).isBetween(23 * 60L, 24 * 60L);

		// 过 24 小时后码不可用
		jdbcTemplate.update("UPDATE family SET invite_code_expire_at = DATE_SUB(NOW(), INTERVAL 1 MINUTE) WHERE id = ?",
				family.id());
		Account b = register(PHONE_B, "李四");
		assertThat(joinFamily(b, currentFamily(a.accessToken()).data().path("inviteCode").asText()).code())
			.isEqualTo(ErrorCode.INVITE_CODE_EXPIRED.code());
	}

	@Test
	@DisplayName("用例 3 的机制：成员退出时冻结昵称快照，之后改名也不影响历史记录署名")
	void leavingFreezesNicknameSnapshot() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		assertThat(postJson(FAMILY_CURRENT + "/leave", Map.of(), b.accessToken()).code()).isEqualTo("OK");

		assertThat(jdbcTemplate.queryForObject(
				"SELECT nickname_snapshot FROM family_member WHERE family_id = ? AND user_id = ?", String.class,
				family.id(), b.userId()))
			.as("§4.1.5：退出成员的历史记录须显示退出时的昵称快照")
			.isEqualTo("李四");

		// 退出后改名，快照不动——这正是「快照」的意义，S3 的流水署名依赖它
		patchJson(USERS_ME, Map.of("nickname", "李四改名了"), b.accessToken());
		assertThat(jdbcTemplate.queryForObject(
				"SELECT nickname_snapshot FROM family_member WHERE family_id = ? AND user_id = ?", String.class,
				family.id(), b.userId()))
			.isEqualTo("李四");
		assertThat(jdbcTemplate.queryForObject("SELECT deleted FROM family_member WHERE family_id = ? AND user_id = ?",
				Integer.class, family.id(), b.userId()))
			.isEqualTo(1);
	}

	@Test
	@DisplayName("退出后重新加入同一家庭复活原成员行，而不是撞唯一索引或插入第二行")
	void rejoiningRevivesSoftDeletedMembership() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);
		postJson(FAMILY_CURRENT + "/leave", Map.of(), b.accessToken());

		// 第 33 轮码是一次性的，重开一次邀请让 b 用新码回来
		assertThat(inviteAndJoin(a, b).code()).isEqualTo("OK");

		// uk_member_family_user 覆盖软删行，若走 INSERT 而非复活会直接抛重复键
		assertThat(jdbcTemplate.queryForObject(
				"SELECT COUNT(*) FROM family_member WHERE family_id = ? AND user_id = ?", Integer.class, family.id(),
				b.userId()))
			.isEqualTo(1);
		assertThat(memberIds(currentFamily(a.accessToken()).data())).containsExactly(a.userId(), b.userId());
		assertThat(roleOf(currentFamily(a.accessToken()).data(), b.userId())).as("复活后身份仍是普通成员")
			.isEqualTo("MEMBER");
	}

	@Test
	@DisplayName("创建者不能移除自己，也不能移除不在本家庭的人（§4.1.6）")
	void removeMemberGuards() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account outsider = register(PHONE_C, "王五");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		assertThat(deleteNoBody(FAMILY_CURRENT + "/members/" + a.userId(), a.accessToken()).code())
			.isEqualTo(ErrorCode.CANNOT_REMOVE_SELF.code());
		assertThat(deleteNoBody(FAMILY_CURRENT + "/members/" + outsider.userId(), a.accessToken()).code())
			.isEqualTo(ErrorCode.MEMBER_NOT_FOUND.code());
		assertThat(memberIds(currentFamily(a.accessToken()).data())).containsExactly(a.userId(), b.userId());
	}

	@Test
	@DisplayName("移除成员仅创建者可做，移除后成员列表立刻少一人")
	void onlyOwnerCanRemoveMember() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account c = register(PHONE_C, "王五");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);
		inviteAndJoin(a, c);

		Call forbidden = deleteNoBody(FAMILY_CURRENT + "/members/" + c.userId(), b.accessToken());
		assertThat(forbidden.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(forbidden.code()).isEqualTo(ErrorCode.NOT_FAMILY_OWNER.code());

		assertThat(deleteNoBody(FAMILY_CURRENT + "/members/" + c.userId(), a.accessToken()).code()).isEqualTo("OK");
		assertThat(memberIds(currentFamily(a.accessToken()).data())).containsExactly(a.userId(), b.userId());
	}

	@Test
	@DisplayName("创建者未转让也未解散时不能直接退出（§4.1.6）")
	void ownerCannotLeaveWithoutTransferringOrDisbanding() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		Call call = postJson(FAMILY_CURRENT + "/leave", Map.of(), a.accessToken());

		assertThat(call.code()).isEqualTo(ErrorCode.OWNER_CANNOT_LEAVE.code());
		assertThat(call.message()).contains("转让");
		assertThat(memberIds(currentFamily(a.accessToken()).data())).containsExactly(a.userId(), b.userId());
	}

	@Test
	@DisplayName("普通成员可以主动退出，退出后看不到原家庭")
	void memberCanLeave() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		assertThat(postJson(FAMILY_CURRENT + "/leave", Map.of(), b.accessToken()).code()).isEqualTo("OK");

		assertThat(currentFamily(b.accessToken()).isNullData()).isTrue();
		assertThat(memberIds(currentFamily(a.accessToken()).data())).containsExactly(a.userId());
	}

	@Test
	@DisplayName("转让创建者在单事务内同时改 family.owner_user_id 与两行 role，不出现双 OWNER 或零 OWNER")
	void transferOwnerSwapsRolesAtomically() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		Call call = postJson(FAMILY_CURRENT + "/owner/transfer", Map.of("targetUserId", b.userId()),
				a.accessToken());

		assertThat(call.code()).isEqualTo("OK");
		assertThat(call.data().path("ownerUserId").asLong()).isEqualTo(b.userId());
		assertThat(roleOf(call.data(), b.userId())).isEqualTo("OWNER");
		assertThat(roleOf(call.data(), a.userId())).as("原创建者保留成员身份（§4.1.6）").isEqualTo("MEMBER");
		assertThat(jdbcTemplate.queryForObject("SELECT owner_user_id FROM family WHERE id = ?", Long.class,
				family.id())).isEqualTo(b.userId());
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM family_member WHERE family_id = ? AND role = 'OWNER'",
				Integer.class, family.id()))
			.as("任何时刻有且仅有一个 OWNER")
			.isEqualTo(1);

		// 权限随之易手：原创建者不再能移除成员，新创建者可以
		assertThat(deleteNoBody(FAMILY_CURRENT + "/members/" + b.userId(), a.accessToken()).code())
			.isEqualTo(ErrorCode.NOT_FAMILY_OWNER.code());
		assertThat(deleteNoBody(FAMILY_CURRENT + "/members/" + a.userId(), b.accessToken()).code()).isEqualTo("OK");
	}

	@Test
	@DisplayName("转让目标不能是自己、也不能是已退出或不属于本家庭的人（§4.1.6）")
	void transferOwnerRejectsInvalidTargets() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account outsider = register(PHONE_C, "王五");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		assertThat(postJson(FAMILY_CURRENT + "/owner/transfer", Map.of("targetUserId", a.userId()), a.accessToken())
			.code()).isEqualTo(ErrorCode.CANNOT_TRANSFER_TO_SELF.code());
		assertThat(postJson(FAMILY_CURRENT + "/owner/transfer", Map.of("targetUserId", outsider.userId()),
				a.accessToken())
			.code()).isEqualTo(ErrorCode.MEMBER_NOT_FOUND.code());

		postJson(FAMILY_CURRENT + "/leave", Map.of(), b.accessToken());
		assertThat(postJson(FAMILY_CURRENT + "/owner/transfer", Map.of("targetUserId", b.userId()), a.accessToken())
			.code()).as("已退出者不能再被转让").isEqualTo(ErrorCode.MEMBER_NOT_FOUND.code());

		assertThat(jdbcTemplate.queryForObject("SELECT owner_user_id FROM family WHERE id = ?", Long.class, family.id()))
			.isEqualTo(a.userId());
	}

	@Test
	@DisplayName("非创建者不能转让、不能开关邀请、不能解散家庭")
	void nonOwnerCannotPerformOwnerOnlyActions() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		Account c = register(PHONE_C, "王五");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);
		inviteAndJoin(a, c);

		assertThat(postJson(FAMILY_CURRENT + "/owner/transfer", Map.of("targetUserId", b.userId()), b.accessToken())
			.code()).isEqualTo(ErrorCode.NOT_FAMILY_OWNER.code());
		assertThat(putJson(FAMILY_CURRENT + "/invite", Map.of("enabled", true), b.accessToken()).code())
			.isEqualTo(ErrorCode.NOT_FAMILY_OWNER.code());
		assertThat(putJson(FAMILY_CURRENT + "/invite", Map.of("enabled", false), b.accessToken()).code())
			.isEqualTo(ErrorCode.NOT_FAMILY_OWNER.code());
		assertThat(deleteJson(FAMILY_CURRENT, Map.of("password", PASSWORD), b.accessToken()).code())
			.isEqualTo(ErrorCode.NOT_FAMILY_OWNER.code());
		assertThat(memberIds(currentFamily(a.accessToken()).data())).hasSize(3);
	}

	@Test
	@DisplayName("家庭名任何成员都可改（文档未限定仅创建者），超 20 字符被拒")
	void anyMemberCanRenameFamily() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		assertThat(patchJson(FAMILY_CURRENT, Map.of("name", "李家小院"), b.accessToken()).data().path("name").asText())
			.isEqualTo("李家小院");
		assertThat(patchJson(FAMILY_CURRENT, Map.of("name", "一二三四五六七八九十一二三四五六七八九十一"), b.accessToken()).code())
			.isEqualTo(ErrorCode.VALIDATION_FAILED.code());
		assertThat(patchJson(FAMILY_CURRENT, Map.of("name", "  "), b.accessToken()).code())
			.isEqualTo(ErrorCode.BAD_REQUEST.code());
	}

	@Test
	@DisplayName("解散家庭需密码校验；解散后创建者仍是登录态但已无家庭，家庭与成员行都是逻辑删除")
	void disbandRequiresPasswordAndSoftDeletes() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		assertThat(deleteJson(FAMILY_CURRENT, Map.of("password", "WrongPass123"), a.accessToken()).code())
			.isEqualTo(ErrorCode.PASSWORD_MISMATCH.code());
		assertThat(memberIds(currentFamily(a.accessToken()).data())).as("密码不对时不得产生任何副作用").hasSize(2);

		assertThat(deleteJson(FAMILY_CURRENT, Map.of("password", PASSWORD), a.accessToken()).code()).isEqualTo("OK");

		// §4.1.6：逻辑删除保留 30 天，物理清除任务推迟到 S10
		assertThat(jdbcTemplate.queryForObject("SELECT deleted FROM family WHERE id = ?", Integer.class, family.id()))
			.isEqualTo(1);
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM family_member WHERE family_id = ? AND deleted = 1",
				Integer.class, family.id()))
			.isEqualTo(2);
		// 创建者没被自己的操作踢下线，落到引导页而不是登录页
		assertThat(getJson(USERS_ME, a.accessToken()).code()).isEqualTo("OK");
		assertThat(currentFamily(a.accessToken()).isNullData()).isTrue();
	}

	@Test
	@DisplayName("尚无家庭时调用需要家庭的接口返回 NO_FAMILY，而不是让租户拦截器注入哨兵值查出空结果")
	void requiresFamilyGuardRejectsFamilylessUsers() throws Exception {
		Account a = register(PHONE_A, "张三");

		Call call = patchJson(FAMILY_CURRENT, Map.of("name", "张家"), a.accessToken());

		assertThat(call.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(call.code()).isEqualTo(ErrorCode.NO_FAMILY.code());
	}

	@Test
	@DisplayName("注销账号需密码校验；创建者须先转让或解散才能注销（§4.1.6）")
	void deactivateAccountGuards() throws Exception {
		Account a = register(PHONE_A, "张三");
		Account b = register(PHONE_B, "李四");
		FamilyHandle family = createFamily(a);
		inviteAndJoin(a, b);

		assertThat(deleteJson(USERS_ME, Map.of("password", "WrongPass123"), b.accessToken()).code())
			.isEqualTo(ErrorCode.PASSWORD_MISMATCH.code());
		assertThat(deleteJson(USERS_ME, Map.of("password", PASSWORD), a.accessToken()).code())
			.as("创建者未转让 / 未解散前不能注销")
			.isEqualTo(ErrorCode.OWNER_CANNOT_LEAVE.code());

		assertThat(deleteJson(USERS_ME, Map.of("password", PASSWORD), b.accessToken()).code()).isEqualTo("OK");
		assertThat(jdbcTemplate.queryForObject("SELECT deleted FROM `user` WHERE id = ?", Integer.class, b.userId()))
			.isEqualTo(1);
		// 注销后登录态失效：每请求解析的 AuthContext 查不到未删除的 user 行
		assertThat(getJson(USERS_ME, b.accessToken()).status()).isEqualTo(HttpStatus.UNAUTHORIZED.value());
	}

	private void expireInviteCode(Long familyId) {
		jdbcTemplate.update("UPDATE family SET invite_code_expire_at = DATE_SUB(NOW(), INTERVAL 1 DAY) WHERE id = ?",
				familyId);
	}

	private void disband(Account owner, Long familyId) throws Exception {
		assertThat(deleteJson(FAMILY_CURRENT, Map.of("password", PASSWORD), owner.accessToken()).code())
			.as("解散家庭 %d 应成功", familyId)
			.isEqualTo("OK");
	}

	private static List<Long> memberIds(JsonNode family) {
		List<Long> ids = new ArrayList<>();
		family.path("members").forEach(member -> ids.add(member.path("userId").asLong()));
		return ids;
	}

	private static String roleOf(JsonNode family, Long userId) {
		return findMember(family, userId).path("role").asText();
	}

	private static String nicknameOf(JsonNode family, Long userId) {
		return findMember(family, userId).path("nickname").asText();
	}

	private static JsonNode findMember(JsonNode family, Long userId) {
		for (JsonNode member : family.path("members")) {
			if (member.path("userId").asLong() == userId) {
				return member;
			}
		}
		throw new AssertionError("成员列表里没有 userId=" + userId + "，实际：" + family.path("members"));
	}

}
