package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;

import cn.homeledger.service.FamilyPurgeService;
import cn.homeledger.support.ApiTestBase;

/**
 * §4.1.6 解散家庭 30 天保留期到期的物理清除（S10）。
 * <p>
 * 直接调 {@link FamilyPurgeService} 而不是等定时任务：任务只报时间，业务全在 service 里（§6.4.1），
 * 测 service 就等价于测任务当天会做什么。造数据用接口 + 直插两种手法结合：能走 API 的走 API
 * （顺便把照片链也验进同一轮清除），周期规则这类接口重的数据直插，与既有测试的 seed 手法一致。
 */
class FamilyPurgeIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000031";

	private static final String PHONE_B = "13800000032";

	private static final int RETENTION_DAYS = 30;

	@Autowired
	private FamilyPurgeService purgeService;

	@BeforeEach
	void cleanPhotoDir() {
		clearPhotoFiles();
	}

	@Test
	@DisplayName("解散满 30 天：十八张表的行全部物理抹除，照片文件删除，用户本人数据原样保留")
	void dissolvedFamilyIsPurgedAfterRetention() throws Exception {
		PurgeFixture fixture = seedFixture();
		backdateDissolution(fixture.familyId(), RETENTION_DAYS + 1);

		int purged = this.purgeService.purgeExpiredFamilies(LocalDateTime.now());
		assertThat(purged).as("恰好这一个家庭到期").isEqualTo(1);

		assertFamilyGone(fixture.familyId());
		assertPhotoFilesGone(fixture);
		assertUserLevelDataSurvives(fixture.owner().userId());
	}

	@Test
	@DisplayName("解散不足 30 天不清除：保留期内任何行都不动，照片文件还在，任务是零命中")
	void familyDissolvedWithinRetentionSurvives() throws Exception {
		PurgeFixture fixture = seedFixture();
		backdateDissolution(fixture.familyId(), RETENTION_DAYS - 1);

		int purged = this.purgeService.purgeExpiredFamilies(LocalDateTime.now());
		assertThat(purged).isZero();

		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM family WHERE id = ?", Integer.class,
			fixture.familyId())).as("保留期内的家庭行还在").isEqualTo(1);
		assertThat(jdbcTemplate.queryForObject("SELECT photo_url FROM cat WHERE id = ?", String.class,
			fixture.catId())).as("照片引用也在").isEqualTo(fixture.catPhoto());
		assertThat(fileOnDisk(fixture.catPhoto())).as("照片文件也在").isTrue();
	}

	@Test
	@DisplayName("软删过的行一并清除：解散本身软删了成员与规则，30 天后它们同样被物理抹掉")
	void softDeletedRowsArePurgedTogether() throws Exception {
		PurgeFixture fixture = seedFixture();
		// 额外造一条已软删的驱虫记录：@TableLogic 默认查询看不到的尸行，物理清除必须照删
		jdbcTemplate.update("INSERT INTO cat_deworming (id, family_id, cat_id, type, done_date, medicine, next_date,"
				+ " created_by, deleted) VALUES (?, ?, ?, 'INTERNAL', '2026-08-01', '拜宠清', '2026-11-01', ?, 1)",
				IdWorker.getId(), fixture.familyId(), fixture.catId(), fixture.owner().userId());
		backdateDissolution(fixture.familyId(), RETENTION_DAYS + 1);

		assertThat(this.purgeService.purgeExpiredFamilies(LocalDateTime.now())).isEqualTo(1);

		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM cat_deworming WHERE family_id = ?", Integer.class,
			fixture.familyId())).as("软删的驱虫行也被物理抹掉").isZero();
		assertFamilyGone(fixture.familyId());
	}

	// ---- 辅助 ----

	private record PurgeFixture(Account owner, long familyId, long catId, String catPhoto, long babyId,
			String babyPhoto) {
	}

	/**
	 * 一个「麻雀虽小五脏俱全」的待清除家庭：猫、猫照片、宝宝、宝宝照片、一笔流水、
	 * 一条周期规则 + 执行日志、一条预算、一个第二成员，以及用户级数据各一行。
	 */
	private PurgeFixture seedFixture() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);

		// 猫 + 照片：走 API，把照片链也纳入清除范围
		Map<String, Object> catBody = new LinkedHashMap<>();
		catBody.put("name", "奶糖");
		catBody.put("gender", "FEMALE");
		catBody.put("birthday", "2024-05-20");
		catBody.put("birthdayEstimated", false);
		catBody.put("neutered", "YES");
		long catId = postJson(CATS, catBody, owner.accessToken()).data().path("id").asLong();
		String catPhoto = uploadMultipart(CATS + "/" + catId + "/photo", owner.accessToken(), "file", "p.jpg",
				"image/jpeg", jpegBytes()).data().path("photoUrl").asText();

		// 宝宝 + 照片
		Map<String, Object> babyBody = new LinkedHashMap<>();
		babyBody.put("name", "小宝");
		babyBody.put("gender", "FEMALE");
		babyBody.put("birthDate", "2024-05-20");
		long babyId = postJson(BABIES, babyBody, owner.accessToken()).data().path("id").asLong();
		String babyPhoto = uploadMultipart(BABIES + "/" + babyId + "/photo", owner.accessToken(), "file", "p.jpg",
				"image/jpeg", jpegBytes()).data().path("photoUrl").asText();

		// 一笔流水（预设大类「餐饮」/ 支付方式「微信」）
		long dining = topCategoryId(owner, "餐饮");
		long wechat = paymentAccountId(owner, "微信");
		Map<String, Object> tx = new LinkedHashMap<>();
		tx.put("amount", "12.50");
		tx.put("categoryId", dining);
		tx.put("accountId", wechat);
		tx.put("bizDate", "2026-01-15");
		tx.put("remark", "午餐");
		assertThat(postJson(TRANSACTIONS, tx, owner.accessToken()).code()).isEqualTo("OK");

		// 周期规则 + 执行日志（FK 依赖顺序的检验对象：日志必须先于规则删）
		seedRecurringRule(family.id(), owner.userId(), dining, wechat);

		// 用户级数据各一行：清除家庭不得波及
		jdbcTemplate.update("INSERT INTO module_preference (id, user_id, module_key, enabled, sort_no)"
				+ " VALUES (?, ?, 'FINANCE', 1, 0)", IdWorker.getId(), owner.userId());
		jdbcTemplate.update("INSERT INTO reminder_setting (id, user_id, type, enabled)"
				+ " VALUES (?, ?, 'CAT_DEWORMING', 1)", IdWorker.getId(), owner.userId());

		// 解散：家庭与成员关系、周期规则在这一步被逻辑删除，30 天后要连尸行一起物理抹掉
		assertThat(deleteJson(FAMILIES + "/current", Map.of("password", PASSWORD), owner.accessToken()).code())
			.isEqualTo("OK");

		return new PurgeFixture(owner, family.id(), catId, catPhoto, babyId, babyPhoto);
	}

	private void seedRecurringRule(long familyId, long creatorUserId, long categoryId, long accountId) {
		long ruleId = IdWorker.getId();
		jdbcTemplate.update("INSERT INTO recurring_rule (id, family_id, name, type, amount, category_id, account_id,"
				+ " period_type, period_value, start_date, enabled, created_by) VALUES (?, ?, '房租', 'EXPENSE',"
				+ " '3000.00', ?, ?, 'MONTHLY', '{\"dayOfMonth\":1}', '2026-01-01', 1, ?)", ruleId, familyId, categoryId,
				accountId, creatorUserId);
		jdbcTemplate.update("INSERT INTO recurring_execution_log (id, family_id, rule_id, biz_date, transaction_id)"
				+ " VALUES (?, ?, ?, '2026-01-01', ?)", IdWorker.getId(), familyId, ruleId, IdWorker.getId());
	}

	private void backdateDissolution(long familyId, int daysAgo) {
		jdbcTemplate.update("UPDATE family SET deleted_at = NOW() - INTERVAL ? DAY WHERE id = ?", daysAgo, familyId);
	}

	private void assertFamilyGone(long familyId) {
		// family 以 id 为主键、没有 family_id 列，单独查；其余 18 张子表都按 family_id 数
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM family WHERE id = ?", Integer.class, familyId))
			.as("family 行应被物理抹除").isZero();
		for (String table : List.of("family_member", "cat", "cat_setting", "cat_food_bag", "cat_deworming",
				"baby", "baby_growth", "baby_vaccine_plan", "baby_vaccine_record", "baby_milestone", "baby_medical",
				"baby_formula_bag", "`transaction`", "recurring_rule", "recurring_execution_log", "budget",
				"payment_account", "category")) {
			assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + table + " WHERE family_id = ?",
				Integer.class, familyId)).as(table + " 的该家庭行应被物理抹除").isZero();
		}
	}

	private void assertPhotoFilesGone(PurgeFixture fixture) {
		assertThat(fileOnDisk(fixture.catPhoto())).as("猫照片文件随家庭清除而删除").isFalse();
		assertThat(fileOnDisk(fixture.babyPhoto())).as("宝宝照片文件随家庭清除而删除").isFalse();
	}

	private void assertUserLevelDataSurvives(long userId) {
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM `user` WHERE id = ?", Integer.class, userId))
			.as("用户本人是全局实体，家庭清除不得波及").isEqualTo(1);
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM module_preference WHERE user_id = ?",
			Integer.class, userId)).as("模块开关是用户级偏好，随用户保留").isEqualTo(1);
		assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM reminder_setting WHERE user_id = ?",
			Integer.class, userId)).as("提醒开关同样保留").isEqualTo(1);
	}

	private boolean fileOnDisk(String photoUrl) {
		Path dir = this.photoProperties.dir().toAbsolutePath().normalize();
		return Files.isRegularFile(dir.resolve(photoUrl.substring("/photos/".length())));
	}

	private static byte[] jpegBytes() {
		byte[] bytes = new byte[64];
		bytes[0] = (byte) 0xFF;
		bytes[1] = (byte) 0xD8;
		bytes[2] = (byte) 0xFF;
		return bytes;
	}

}