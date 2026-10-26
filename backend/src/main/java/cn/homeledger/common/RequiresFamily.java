package cn.homeledger.common;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 标记「必须先有家庭」才能调用的端点。由 {@link FamilyScopeInterceptor} 在进入 Controller 前拦截，
 * 使无家庭用户得到明确的 NO_FAMILY 403，而不是落到租户拦截器的兜底哨兵值上得到空结果或 500。
 */
@Documented
@Target({ ElementType.TYPE, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
public @interface RequiresFamily {

}
