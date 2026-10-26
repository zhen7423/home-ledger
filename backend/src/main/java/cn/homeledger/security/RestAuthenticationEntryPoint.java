package cn.homeledger.security;

import java.io.IOException;

import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import cn.homeledger.common.ApiResponseWriter;
import cn.homeledger.common.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 替换 Security 默认的空响应体 401，让未认证也走 §8 的统一响应体，前端只需处理一种错误格式。
 * <p>
 * 唯一例外是浏览器直接打开后台地址：App / curl 这类 API 客户端要的是 JSON；而浏览器地址栏访问
 * 没有数据可看，甩一坨 JSON 对人毫无帮助，改为 302 重定向到 {@link #LOGIN_REQUIRED_PATH} 提示页
 * 输出一段说明。判定只认浏览器的导航特征（Accept 含 text/html、Sec-Fetch-Mode: navigate），
 * 不会误伤任何 API 客户端。
 */
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

	/**
	 * 浏览器访问提示页路径。必须在 Security 的 PERMIT_ALL 里放行：若它本身也需要认证，
	 * 重定向会再次撞上本入口点，形成无限 302。
	 */
	public static final String LOGIN_REQUIRED_PATH = "/login-required";

	private final ApiResponseWriter responseWriter;

	public RestAuthenticationEntryPoint(ApiResponseWriter responseWriter) {
		this.responseWriter = responseWriter;
	}

	@Override
	public void commence(HttpServletRequest request, HttpServletResponse response,
			AuthenticationException authException) throws IOException {
		if (isBrowserNavigation(request)) {
			response.sendRedirect(response.encodeRedirectURL(request.getContextPath() + LOGIN_REQUIRED_PATH));
			return;
		}
		this.responseWriter.write(response, ErrorCode.UNAUTHORIZED);
	}

	/**
	 * 浏览器导航的两个特征信号：Accept 里偏好 text/html（Chrome / Safari / Edge 地址栏导航都带），
	 * 或现代浏览器顶层导航自带的 Sec-Fetch-Mode: navigate。API 客户端两者皆无，保持 JSON。
	 */
	private static boolean isBrowserNavigation(HttpServletRequest request) {
		String accept = request.getHeader("Accept");
		if (accept != null && accept.contains("text/html")) {
			return true;
		}
		return "navigate".equalsIgnoreCase(request.getHeader("Sec-Fetch-Mode"));
	}

}