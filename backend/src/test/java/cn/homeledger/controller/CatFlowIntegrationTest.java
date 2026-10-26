package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;

import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.3.1 猫咪档案。这份清单全家共享一份，不是每人各记一份，所以家庭隔离与「在册上限 10 只」是这里的两条主线。
 * <p>
 * 驱虫记录一律直接落库而不走接口：要验的正是「名下有没有记录」的判定含不含软删的行，
 * 走接口造数据会把要验的那件事变成前提。
 */
class CatFlowIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final String PHONE_OTHER = "13800000003";

	private static final String PHONE_ALONE = "13800000004";

	@Test
	@DisplayName("A 建的档案 B 读得到：回的是同一只猫，不是各人一份清单")
	void twoCatsAreVisibleToBothMembers() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);

		long id = create(owner, "奶糖");

		List<JsonNode> seenByMember = list(member, true);
		assertThat(names(seenByMember)).as("建档的是 A，B 读到的却是同一只").containsExactly("奶糖");
		JsonNode cat = seenByMember.get(0);
		assertThat(cat.path("id").asLong()).isEqualTo(id);
		assertThat(cat.path("gender").asText()).isEqualTo("FEMALE");
		assertThat(cat.path("birthday").asText()).isEqualTo("2024-05-20");
		assertThat(cat.path("birthdayEstimated").asBoolean()).isFalse();
		assertThat(cat.path("weightKg").asText()).isEqualTo("4.25");
		assertThat(cat.path("neutered").asText()).isEqualTo("YES");
		assertThat(cat.path("archived").asBoolean()).isFalse();
		assertThat(cat.path("createdAt").isMissingNode())
			.as("驱虫完成度的「应做次数」以建档日为起点，这一列得出到接口上").isFalse();
	}

	@Test
	@DisplayName("归档只把它从在册清单里摘掉：档案行与已有的驱虫记录都不动")
	void archivedCatHidesFromTheDefaultListButStaysInHistory() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		long catId = create(owner, "奶糖");
		seedDeworming(family.id(), catId, owner.userId(), false);

		assertThat(patchJson(CATS + "/" + catId + "/archive", Map.of(), owner.accessToken()).code()).isEqualTo("OK");

		assertThat(names(list(owner, false))).as("默认清单里没有它，记账与驱虫表单就此选不到").doesNotContain("奶糖");
		JsonNode archived = findById(list(owner, true), catId);
		assertThat(archived).as("includeArchived 的清单仍在，档案管理要能把它恢复回来").isNotNull();
		assertThat(archived.path("archived").asBoolean()).isTrue();

		assertThat(jdbcTemplate.queryForObject("SELECT deleted FROM cat WHERE id = ?", Integer.class, catId))
			.as("归档落 enabled = 0，不是软删").isZero();
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM cat_deworming WHERE cat_id = ?", Integer.class,
				catId)).as("归档不碰记录行，那条驱虫仍算在这只猫头上").isEqualTo(1);
	}

	@Test
	@DisplayName("在册满 10 只即拒第 11 只，归档一只之后就放行：名额数的是在册的猫")
	void eleventhActiveCatIsRefused() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		for (int i = 1; i <= 10; i++) {
			create(owner, "猫" + i);
		}

		Call eleventh = postJson(CATS, cat("猫11"), owner.accessToken());
		assertThat(eleventh.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(eleventh.message()).as("文案要指出归档这条路").contains("归档");
		assertThat(names(list(owner, true))).hasSize(10);

		archiveFirstOf(owner);
		assertThat(create(owner, "猫11")).as("归档让出的名额要能被用上").isPositive();
		assertThat(list(owner, true)).as("总数到了 11，在册仍是 10").hasSize(11);
		assertThat(list(owner, true).stream().filter(node -> !node.path("archived").asBoolean()).count())
			.isEqualTo(10);
	}

	@Test
	@DisplayName("恢复在册同样受上限约束：归档一只、补建一只、再恢复就被拒，腾出名额后才恢复得了")
	void restoringACatRespectsTheCap() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		for (int i = 1; i <= 10; i++) {
			create(owner, "猫" + i);
		}
		long archived = archiveFirstOf(owner);
		create(owner, "猫11");

		Call restore = patchJson(CATS + "/" + archived + "/archive", Map.of(), owner.accessToken());
		assertThat(restore.code()).isEqualTo("BAD_REQUEST");
		assertThat(restore.message()).as("要说清是先归档一只，跟建档被拒那句区分开").contains("恢复");
		assertThat(findById(list(owner, true), archived).path("archived").asBoolean()).as("被拒之后仍是归档态")
			.isTrue();

		archiveFirstOf(owner);
		assertThat(patchJson(CATS + "/" + archived + "/archive", Map.of(), owner.accessToken()).code()).isEqualTo("OK");
		assertThat(findById(list(owner, true), archived).path("archived").asBoolean())
			.as("腾出名额后同一只猫能恢复回来").isFalse();
	}

	@Test
	@DisplayName("昵称家庭内唯一：带空格的算重名、改名撞别的猫也算，改回自己的名字不算")
	void duplicateNameIsRejectedWithinTheFamily() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long id = create(owner, "奶糖");

		assertThat(createExpectingFailure(owner, " 奶糖 ")).as("先 trim 再查重，否则同名不同串能建两只")
			.isEqualTo("BAD_REQUEST");
		assertThat(createExpectingFailure(owner, "奶糖")).isEqualTo("BAD_REQUEST");

		long otherId = create(owner, "芝麻");
		assertThat(patchJson(CATS + "/" + otherId, cat("奶糖"), owner.accessToken()).code())
			.as("把芝麻改成奶糖是撞别的猫").isEqualTo("BAD_REQUEST");

		JsonNode row = findById(list(owner, true), id);
		assertThat(row.path("name").asText()).as("被拒的三次都没改动数据").isEqualTo("奶糖");
		assertThat(patchJson(CATS + "/" + id, cat("奶糖"), owner.accessToken()).code())
			.as("整份表单回传自己原来的名字不该算重名").isEqualTo("OK");
	}

	@Test
	@DisplayName("两个家庭各建一只同名猫都成功：唯一性的范围是家庭，不是全站")
	void anotherFamilyMayReuseTheName() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account other = registerWithFamily(PHONE_OTHER, "王五");

		long firstId = create(owner, "奶糖");
		long secondId = create(other, "奶糖");

		assertThat(secondId).isPositive();
		assertThat(names(list(owner, true))).containsExactly("奶糖");
		assertThat(names(list(other, true))).containsExactly("奶糖");
		assertThat(findById(list(owner, true), firstId).has("familyId")).as("响应里不带 family_id 那一列").isFalse();
	}

	@Test
	@DisplayName("名下有过驱虫记录（连已软删的记录也算）就只能归档，没有记录的可以软删")
	void deleteRefusesWhenTheCatHasDewormingRecordsEvenIfSoftDeleted() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		long catId = create(owner, "奶糖");
		seedDeworming(family.id(), catId, owner.userId(), true);

		Call call = deleteNoBody(CATS + "/" + catId, owner.accessToken());
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.message()).as("文案要指向归档").contains("归档");
		assertThat(jdbcTemplate.queryForObject("SELECT deleted FROM cat WHERE id = ?", Integer.class, catId))
			.as("全项目唯一一条证据：判定含软删的记录行，这条 SQL 没跟着逻辑删除一起被过滤").isZero();

		jdbcTemplate.update("DELETE FROM cat_deworming WHERE cat_id = ?", catId);
		assertThat(deleteNoBody(CATS + "/" + catId, owner.accessToken()).code()).isEqualTo("OK");
		assertThat(names(list(owner, true))).as("删掉的猫从两份清单里一起消失").doesNotContain("奶糖");
		assertThat(jdbcTemplate.queryForObject("SELECT deleted FROM cat WHERE id = ?", Integer.class, catId))
			.as("是打删除标记而不是物删，历史记录里的猫名反查还要落到位").isOne();
	}

	@Test
	@DisplayName("别家的猫按 id 改名、归档、删除一律 404，本家的数据一个字段都不动")
	void catFromAnotherFamilyIsNotFound() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");
		long catId = create(owner, "奶糖");

		assertThat(patchJson(CATS + "/" + catId, cat("被篡改"), outsider.accessToken()).status())
			.isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(patchJson(CATS + "/" + catId + "/archive", Map.of(), outsider.accessToken()).code())
			.isEqualTo("RESOURCE_NOT_FOUND");
		assertThat(deleteNoBody(CATS + "/" + catId, outsider.accessToken()).code()).isEqualTo("RESOURCE_NOT_FOUND");

		JsonNode untouched = findById(list(owner, true), catId);
		assertThat(untouched.path("name").asText()).isEqualTo("奶糖");
		assertThat(untouched.path("archived").asBoolean()).isFalse();
		assertThat(names(list(outsider, true))).as("外人自己的清单里也没多出这么一只").isEmpty();
	}

	@Test
	@DisplayName("无家庭的账号碰猫咪端点返回 NO_FAMILY，而不是让租户拦截器注入哨兵值查出一份空清单")
	void catsRequireAFamily() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call listed = getJson(CATS, lonely.accessToken());
		assertThat(listed.status()).isEqualTo(HttpStatus.FORBIDDEN.value());
		assertThat(listed.code()).isEqualTo("NO_FAMILY");
		assertThat(postJson(CATS, cat("奶糖"), lonely.accessToken()).code()).isEqualTo("NO_FAMILY");
	}

	@Test
	@DisplayName("整份表单覆盖会把清空的可空栏位真写成 NULL，而不是静默留着旧值")
	void patchClearsTheNullableColumns() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long id = create(owner, "奶糖");

		Map<String, Object> cleared = cat("奶糖");
		cleared.put("birthday", null);
		cleared.put("breed", null);
		cleared.put("weightKg", null);
		cleared.put("remark", null);
		assertThat(patchJson(CATS + "/" + id, cleared, owner.accessToken()).code()).isEqualTo("OK");

		JsonNode row = findById(list(owner, true), id);
		assertThat(row.path("birthday").isNull()).as("生日从有到无是真清空").isTrue();
		assertThat(row.path("breed").isNull()).isTrue();
		assertThat(row.path("weightKg").isNull()).isTrue();
		assertThat(row.path("remark").isNull()).isTrue();
		assertThat(row.path("gender").asText()).as("表单里给得出值的栏位照旧覆盖").isEqualTo("FEMALE");
	}

	// ---- 辅助 ----

	private List<JsonNode> list(Account account, boolean includeArchived) throws Exception {
		Call call = getJson(CATS + "?includeArchived=" + includeArchived, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		List<JsonNode> nodes = new ArrayList<>();
		call.data().forEach(nodes::add);
		return nodes;
	}

	private long create(Account account, String name) throws Exception {
		Call call = postJson(CATS, cat(name), account.accessToken());
		assertThat(call.code()).as("建档 %s", name).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private String createExpectingFailure(Account account, String name) throws Exception {
		return postJson(CATS, cat(name), account.accessToken()).code();
	}

	private long archiveFirstOf(Account account) throws Exception {
		long id = list(account, false).get(0).path("id").asLong();
		assertThat(patchJson(CATS + "/" + id + "/archive", Map.of(), account.accessToken()).code()).isEqualTo("OK");
		return id;
	}

	/** 一份填全了的表单：{@code patchClearsTheNullableColumns} 从它上面挖空，所以四栏可空字段都得先有值。 */
	private static Map<String, Object> cat(String name) {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("name", name);
		body.put("gender", "FEMALE");
		body.put("birthday", "2024-05-20");
		body.put("birthdayEstimated", false);
		body.put("breed", "英短");
		body.put("weightKg", "4.25");
		body.put("neutered", "YES");
		body.put("remark", "偏瘦，注意控制食量");
		return body;
	}

	private void seedDeworming(long familyId, long catId, long creatorUserId, boolean deleted) {
		jdbcTemplate.update("INSERT INTO cat_deworming (id, family_id, cat_id, type, done_date, medicine, next_date,"
				+ " created_by, deleted) VALUES (?, ?, ?, 'INTERNAL', '2026-08-01', '拜宠清', '2026-11-01', ?, ?)",
				IdWorker.getId(), familyId, catId, creatorUserId, deleted ? 1 : 0);
	}

	private JsonNode findById(List<JsonNode> cats, long id) {
		return cats.stream().filter(node -> node.path("id").asLong() == id).findFirst().orElse(null);
	}

	private List<String> names(List<JsonNode> cats) {
		return cats.stream().map(node -> node.path("name").asText()).toList();
	}

}
