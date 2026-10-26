package cn.homeledger.common;

import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 在进入 Controller 前落实 {@link RequiresFamily}，抛出的 BizException 由 GlobalExceptionHandler 统一转 403。
 */
public class FamilyScopeInterceptor implements HandlerInterceptor {

	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
		if (!(handler instanceof HandlerMethod handlerMethod)) {
			return true;
		}
		boolean required = handlerMethod.hasMethodAnnotation(RequiresFamily.class)
				|| handlerMethod.getBeanType().isAnnotationPresent(RequiresFamily.class);
		if (required && !AuthContextHolder.require().hasFamily()) {
			throw new BizException(ErrorCode.NO_FAMILY);
		}
		return true;
	}

}
