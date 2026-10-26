package cn.homeledger.common;

import java.io.IOException;
import java.util.UUID;
import java.util.regex.Pattern;

import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * §5.6 可观测性与 §8 响应体 traceId 的来源。必须排在 springSecurityFilterChain（order = -100）之前，
 * 否则 401/403 响应体拿不到 traceId。
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class TraceIdFilter extends OncePerRequestFilter {

	public static final String HEADER = "X-Request-Id";

	/** 客户端回传的 traceId 只接受安全字符集，避免把控制字符写进日志或响应头。 */
	private static final Pattern ACCEPTED = Pattern.compile("[A-Za-z0-9._-]{1,64}");

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
			throws ServletException, IOException {
		String incoming = request.getHeader(HEADER);
		String traceId = (incoming != null && ACCEPTED.matcher(incoming).matches()) ? incoming : newTraceId();
		MDC.put(ApiResponse.TRACE_ID_MDC_KEY, traceId);
		response.setHeader(HEADER, traceId);
		try {
			chain.doFilter(request, response);
		}
		finally {
			MDC.remove(ApiResponse.TRACE_ID_MDC_KEY);
		}
	}

	private static String newTraceId() {
		return UUID.randomUUID().toString().replace("-", "").substring(0, 16);
	}

}
