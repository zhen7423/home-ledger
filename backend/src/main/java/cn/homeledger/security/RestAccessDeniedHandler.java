package cn.homeledger.security;

import java.io.IOException;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import cn.homeledger.common.ApiResponseWriter;
import cn.homeledger.common.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 已认证但权限不足时的统一 403 响应体。家庭内的资源归属不走到这里——§5.2 要求跨家庭访问返回 404
 * 而非 403，避免暴露资源是否存在，那条路径由租户拦截器 + RESOURCE_NOT_FOUND 承担。
 */
@Component
public class RestAccessDeniedHandler implements AccessDeniedHandler {

	private final ApiResponseWriter responseWriter;

	public RestAccessDeniedHandler(ApiResponseWriter responseWriter) {
		this.responseWriter = responseWriter;
	}

	@Override
	public void handle(HttpServletRequest request, HttpServletResponse response,
			AccessDeniedException accessDeniedException) throws IOException {
		this.responseWriter.write(response, ErrorCode.FORBIDDEN);
	}

}
