package cn.homeledger.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.baomidou.mybatisplus.extension.plugins.inner.TenantLineInnerInterceptor;

import cn.homeledger.common.AuthContext;
import cn.homeledger.common.AuthContextHolder;

/**
 * §5.2 / 风险 R4（家庭级数据隔离疏漏导致越权，等级：高）的核心防线验证。
 *
 * 这里直接驱动 TenantLineInnerInterceptor 的 SQL 改写，而不是等 S3 建出带 family_id 的业务表再端到端验：
 * 隔离机制本身与具体业务表无关，S2 就能把它钉死；等到 S3 才验，一旦改写规则理解有误，
 * 返工面会扩散到所有已写好的业务 SQL。
 *
 * 用纯单元测试（不起 Spring 上下文），因为 AuthContextHolder 是 ThreadLocal、
 * FamilyTenantHandler 无外部依赖，隔离机制的可变输入只有「当前登录态」这一个。
 */
class FamilyTenantHandlerTest {

	private final TenantLineInnerInterceptor interceptor = new TenantLineInnerInterceptor(new FamilyTenantHandler());

	@AfterEach
	void clearContext() {
		AuthContextHolder.clear();
	}

	@Test
	@DisplayName("租户列名是 family_id")
	void tenantColumnIsFamilyId() {
		assertThat(interceptor.getTenantLineHandler().getTenantIdColumn()).isEqualTo("family_id");
	}

	@Test
	@DisplayName("查询被注入 family_id，业务 SQL 里没写也躲不过")
	void selectGetsFamilyIdInjected() {
		loginTo(7L);

		assertThat(rewrite("SELECT * FROM transaction WHERE id = 5"))
			.isEqualTo("SELECT * FROM transaction WHERE id = 5 AND family_id = 7");
	}

	@Test
	@DisplayName("没有 WHERE 的查询也会被补上 family_id，全表扫描式越权同样堵住")
	void selectWithoutWhereGetsFamilyIdInjected() {
		loginTo(7L);

		assertThat(rewrite("SELECT * FROM category")).contains("family_id = 7");
	}

	@Test
	@DisplayName("多表 JOIN 的每一张受管表都各自注入，不会只保护主表")
	void joinInjectsOnEveryTenantTable() {
		loginTo(7L);

		String sql = rewrite(
				"SELECT t.id FROM transaction t JOIN category c ON t.category_id = c.id WHERE t.id = 5");

		assertThat(sql).contains("t.family_id = 7").contains("c.family_id = 7");
	}

	@Test
	@DisplayName("更新与删除同样被注入：只读接口受保护不够，写接口越权危害更大")
	void updateAndDeleteGetFamilyIdInjected() {
		loginTo(7L);

		assertThat(rewrite("UPDATE transaction SET amount = 100 WHERE id = 5")).contains("family_id = 7");
		assertThat(rewrite("DELETE FROM transaction WHERE id = 5")).contains("family_id = 7");
	}

	@Test
	@DisplayName("插入被补上 family_id 列，业务代码不需要也不应该自己传这个值")
	void insertGetsFamilyIdColumnAdded() {
		loginTo(7L);

		assertThat(rewrite("INSERT INTO transaction (amount, remark) VALUES (100, '买菜')"))
			.contains("family_id")
			.contains("7");
	}

	@Test
	@DisplayName("白名单表原样放行：这些表没有 family_id 列，注入会直接 SQL 报错")
	void whitelistedTablesAreLeftAlone() {
		loginTo(7L);

		assertThat(rewrite("SELECT * FROM `user` WHERE id = 5")).doesNotContain("family_id");
		assertThat(rewrite("SELECT * FROM family WHERE id = 5")).doesNotContain("family_id = 7");
		assertThat(rewrite("SELECT * FROM family_member WHERE user_id = 5")).doesNotContain("family_id = 7");
		assertThat(rewrite("SELECT meta_value FROM schema_meta WHERE meta_key = 'timezone'")).doesNotContain("family_id");
	}

	@Test
	@DisplayName("白名单匹配要能吃下反引号、schema 前缀与大小写差异，否则 user 这种保留字表会被误注入")
	void whitelistMatchingNormalizesTableNames() {
		FamilyTenantHandler handler = new FamilyTenantHandler();

		assertThat(handler.ignoreTable("`user`")).isTrue();
		assertThat(handler.ignoreTable("homeledger.user")).isTrue();
		assertThat(handler.ignoreTable("FAMILY_MEMBER")).isTrue();
		assertThat(handler.ignoreTable("`Family`")).isTrue();
	}

	@Test
	@DisplayName("业务表一律不在白名单内：新增表默认受保护，不需要记得去登记")
	void businessTablesAreNotWhitelisted() {
		FamilyTenantHandler handler = new FamilyTenantHandler();

		for (String table : new String[] { "transaction", "category", "payment_account", "budget", "recurring_rule",
				"recurring_execution_log", "cat_deworming", "cat_setting", "cat", "cat_food_bag", "baby",
				"baby_growth", "baby_vaccine_plan", "baby_vaccine_record", "baby_milestone", "baby_medical" }) {
			assertThat(handler.ignoreTable(table)).as("表 %s 必须受租户隔离保护", table).isFalse();
		}
	}

	/**
	 * cat_setting 长得像用户级偏好表：每家庭至多一行、字段全是默认值、读写口吻与 reminder_setting 几乎一样，
	 * 而 reminder_setting 恰好在白名单里。把它当同类表挪进豁免名单不会编译报错、也不会立刻测试红，
	 * 只会让猫的设置读写全部撞上 family_id = -1 而静默落空——症状是用户改了周期、下次驱虫仍按旧周期算。
	 * 上面那条通用断言只覆盖「业务表默认受保护」，覆盖不到这种「新表被归错类」的改法，故单独钉一次。
	 */
	@Test
	@DisplayName("S6 四张猫表全部受隔离，含长得像用户级偏好的 cat_setting")
	void s6TablesAreAllTenantScoped() {
		FamilyTenantHandler handler = new FamilyTenantHandler();

		assertThat(handler.ignoreTable("cat")).isFalse();
		assertThat(handler.ignoreTable("cat_food_bag")).isFalse();
		assertThat(handler.ignoreTable("cat_deworming")).isFalse();
		assertThat(handler.ignoreTable("cat_setting")).isFalse();
	}

	/**
	 * 两张字典表**必须**留在白名单里，这条是本阶段最容易顺手做反的一处：
	 * 它们长得像「模块自带的新表」，而上面刚给 cat_setting 设过「新表默认受保护」的路障，
	 * 顺着那条惯性把这两张从白名单里划掉，代码照样编译、上面那条通用断言也照样绿——
	 * 症状只出现在运行期：字典表没有 family_id 列，注入会让查询直接 SQL 报错，
	 * 于是整张疫苗程序表与生长标准表在任何请求里都读不出来。
	 * 它们是迁移播种的静态数据、跨家庭共享，从来就不是租户数据（§5.2 的九条白名单含这两张）。
	 */
	@Test
	@DisplayName("S7 八张表：六张业务表受隔离，两张静态字典表必须留在白名单里")
	void s7TablesSplitByWhitelistMembership() {
		FamilyTenantHandler handler = new FamilyTenantHandler();

		assertThat(handler.ignoreTable("baby")).isFalse();
		assertThat(handler.ignoreTable("baby_growth")).isFalse();
		assertThat(handler.ignoreTable("baby_vaccine_plan")).isFalse();
		assertThat(handler.ignoreTable("baby_vaccine_record")).isFalse();
		assertThat(handler.ignoreTable("baby_milestone")).isFalse();
		assertThat(handler.ignoreTable("baby_medical")).isFalse();

		assertThat(handler.ignoreTable("vaccine_schedule_dict")).isTrue();
		assertThat(handler.ignoreTable("growth_standard_dict")).isTrue();
	}

	/**
	 * reminder_setting 是 S4 四张表里唯一不受隔离的那张，而且它 S2 就预置进了白名单——
	 * 意思是将来有人「清理」白名单把它移除时，代码不会立刻报错，只会让提醒开关的读写全部撞上
	 * family_id = -1 而静默落空，用户那边表现为开关永远保存不上。这条断言就是给那种改动设的路障。
	 */
	@Test
	@DisplayName("S4 四张新表：三张受隔离，reminder_setting 作为用户级表豁免")
	void s4TablesSplitByWhitelistMembership() {
		FamilyTenantHandler handler = new FamilyTenantHandler();

		assertThat(handler.ignoreTable("recurring_rule")).isFalse();
		assertThat(handler.ignoreTable("recurring_execution_log")).isFalse();
		assertThat(handler.ignoreTable("budget")).isFalse();
		assertThat(handler.ignoreTable("reminder_setting")).isTrue();
	}

	/**
	 * transaction 是 MySQL 的非保留关键字，裸表名在 DDL 与查询里都能用，但它是 JSqlParser 最容易误判成
	 * 别的语法结构的一个名字。S3 的隔离正确性全系于「这些形态都能被解析并注入 family_id」，故逐个钉住；
	 * 其中任一条退化成语法异常，表现都是运行期 500 而不是查错数据，很容易误判成别的 bug。
	 */
	@Test
	@DisplayName("transaction 作裸表名的各种形态都能被解析并注入")
	void transactionTableNameParsesInEveryShape() {
		loginTo(7L);

		assertThat(rewrite("SELECT COUNT(*) FROM transaction WHERE deleted = 0")).contains("family_id = 7");
		assertThat(rewrite("SELECT * FROM `transaction` WHERE id = 5")).contains("family_id = 7");
		assertThat(rewrite("SELECT t.id FROM transaction t WHERE t.biz_date = '2026-09-11'"))
			.contains("t.family_id = 7");
		assertThat(rewrite("SELECT category_id, SUM(amount) FROM transaction GROUP BY category_id"))
			.contains("family_id = 7");
	}

	@Test
	@DisplayName("登录态缺 familyId 时注入哨兵 -1 使 SQL 必然落空，而不是抛异常退化成 500")
	void missingFamilyIdFailsClosedWithSentinel() {
		// 完全无登录态（例如定时任务里误用了 mapper）
		String withoutContext = rewrite("SELECT * FROM transaction WHERE id = 5");
		assertThat(withoutContext).contains("family_id = -1");

		// 已登录但还没加入家庭：这是 S2 里真实会发生的状态
		AuthContextHolder.set(new AuthContext(1L, null, null));
		String withoutFamily = rewrite("SELECT * FROM transaction WHERE id = 5");
		assertThat(withoutFamily).contains("family_id = -1");

		// 写入方向也必须落空：哨兵值撞上 family_id 外键，插入直接失败（fail-closed）
		assertThat(rewrite("INSERT INTO transaction (amount) VALUES (100)")).contains("-1");
	}

	private void loginTo(Long familyId) {
		AuthContextHolder.set(new AuthContext(1L, familyId, AuthContext.ROLE_OWNER));
	}

	private String rewrite(String sql) {
		return interceptor.parserSingle(sql, null).replaceAll("\\s+", " ").trim();
	}

}
