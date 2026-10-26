package cn.homeledger.config;

import java.util.Locale;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.baomidou.mybatisplus.extension.plugins.handler.TenantLineHandler;

import cn.homeledger.common.AuthContext;
import cn.homeledger.common.AuthContextHolder;
import net.sf.jsqlparser.expression.Expression;
import net.sf.jsqlparser.expression.LongValue;

/**
 * §5.2 家庭级数据隔离的落地点：family_id 作为租户列，由 TenantLineInnerInterceptor 在 SQL 解析层
 * 对全部 select / insert / update / delete 自动注入，业务代码无从绕过，新增表默认受保护。
 */
@Component
public class FamilyTenantHandler implements TenantLineHandler {

	/**
	 * 无 family_id 隔离语义的全局表，必须显式列举（§5.2）。禁止改成「该表没有 family_id 列就自动跳过」——
	 * 隐式规则会让「忘写列」与「本就不该隔离」两种情况无法区分，前者正是越权的成因。新增业务表若被误加进来，
	 * 等于该表彻底失去隔离，代码评审须逐条核对本集合。
	 */
	static final Set<String> NON_TENANT_TABLES = Set.of("user", "user_auth_binding", "family", "family_member",
			"schema_meta", "module_preference", "reminder_setting", "vaccine_schedule_dict", "growth_standard_dict");

	/**
	 * 登录态缺 familyId 时注入的哨兵值。选 -1 而不是抛异常：异常会被 MyBatis 的
	 * DefaultSqlSession 包成 PersistenceException、再被 mybatis-spring 译成 MyBatisSystemException，
	 * 统一异常处理拿不到原始 BizException，用户会看到 500 而非明确文案。哨兵值保证查询必然落空、
	 * 写入必然撞 family_id 外键（fail-closed），用户-facing 的明确拒绝由 @RequiresFamily + 拦截器给出。
	 */
	static final long NO_FAMILY_SENTINEL = -1L;

	private static final Logger log = LoggerFactory.getLogger(FamilyTenantHandler.class);

	@Override
	public String getTenantIdColumn() {
		return "family_id";
	}

	@Override
	public boolean ignoreTable(String tableName) {
		return NON_TENANT_TABLES.contains(normalize(tableName));
	}

	@Override
	public Expression getTenantId() {
		AuthContext context = AuthContextHolder.get();
		Long familyId = (context == null) ? null : context.familyId();
		if (familyId == null) {
			log.warn("租户上下文缺少 familyId，注入哨兵值 {} 使本次 SQL 必然落空（userId={}）", NO_FAMILY_SENTINEL,
					context == null ? null : context.userId());
			return new LongValue(NO_FAMILY_SENTINEL);
		}
		return new LongValue(familyId);
	}

	private static String normalize(String tableName) {
		String stripped = tableName.replace("`", "").trim();
		int dot = stripped.lastIndexOf('.');
		if (dot >= 0) {
			stripped = stripped.substring(dot + 1);
		}
		return stripped.toLowerCase(Locale.ROOT);
	}

}
