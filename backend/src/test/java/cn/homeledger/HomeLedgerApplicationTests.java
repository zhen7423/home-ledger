package cn.homeledger;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.InnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.TenantLineInnerInterceptor;

@SpringBootTest
@ActiveProfiles("local")
class HomeLedgerApplicationTests {

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Autowired
	private MybatisPlusInterceptor mybatisPlusInterceptor;

	@Test
	void contextLoads() {
	}

	@Test
	void flywayMigrationAppliedGlobalConstants() {
		String timezone = jdbcTemplate.queryForObject(
				"SELECT meta_value FROM schema_meta WHERE meta_key = 'timezone'", String.class);
		assertThat(timezone).isEqualTo("Asia/Shanghai");
	}

	@Test
	void v2MigrationCreatedAccountAndFamilyTables() {
		List<String> tables = jdbcTemplate.queryForList("SHOW TABLES", String.class);
		assertThat(tables).contains("user", "user_auth_binding", "family", "family_member");
		assertThat(jdbcTemplate.queryForList("SHOW INDEX FROM `user` WHERE Key_name = 'uk_user_phone'"))
			.as("手机号唯一索引是注册防重的最后一道防线，Service 层的预检查存在并发窗口")
			.isNotEmpty();
	}

	/**
	 * 租户拦截器必须排在分页拦截器之前。分页拦截器 S3 才加，但顺序一旦搞反，分页的 COUNT 语句
	 * 会在注入 family_id 之前生成，统计总数跨家庭泄露——而列表内容是对的，功能测试看不出来，
	 * 只有这条断言能提前拦住。写成「若分页存在则租户下标更小」，S3 加分页时无需改本测试即自动生效。
	 */
	@Test
	void tenantInterceptorRunsBeforePagination() {
		List<InnerInterceptor> interceptors = mybatisPlusInterceptor.getInterceptors();
		int tenant = indexOf(interceptors, TenantLineInnerInterceptor.class);
		assertThat(tenant).as("家庭隔离拦截器必须已注册（§5.2 / 风险 R4）").isNotNegative();

		int pagination = indexOf(interceptors, PaginationInnerInterceptor.class);
		if (pagination >= 0) {
			assertThat(tenant).as("租户拦截器须排在分页之前，否则 COUNT 语句不带 family_id").isLessThan(pagination);
		}
	}

	private static int indexOf(List<InnerInterceptor> interceptors, Class<?> type) {
		for (int i = 0; i < interceptors.size(); i++) {
			if (type.isInstance(interceptors.get(i))) {
				return i;
			}
		}
		return -1;
	}

}
