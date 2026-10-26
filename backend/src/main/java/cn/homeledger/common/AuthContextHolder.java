package cn.homeledger.common;

/**
 * 登录态线程本地载体。{@code FamilyTenantHandler} 是被 MyBatis 单例持有的拦截器，无法走请求作用域注入，
 * 只能用 ThreadLocal 取 familyId；由 JwtAuthFilter 在 finally 中清理，避免线程复用导致串号。
 */
public final class AuthContextHolder {

	private static final ThreadLocal<AuthContext> HOLDER = new ThreadLocal<>();

	private AuthContextHolder() {
	}

	public static void set(AuthContext context) {
		HOLDER.set(context);
	}

	/** 可能为 null：白名单表（user / family / family_member 等）的查询不要求登录态。 */
	public static AuthContext get() {
		return HOLDER.get();
	}

	public static AuthContext require() {
		AuthContext context = HOLDER.get();
		if (context == null) {
			throw new BizException(ErrorCode.UNAUTHORIZED);
		}
		return context;
	}

	public static void clear() {
		HOLDER.remove();
	}

}
