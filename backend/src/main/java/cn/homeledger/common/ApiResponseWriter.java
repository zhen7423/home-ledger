package cn.homeledger.common;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import jakarta.servlet.http.HttpServletResponse;

/**
 * Servlet 层（JwtAuthFilter、AuthenticationEntryPoint、AccessDeniedHandler）走不到 @RestControllerAdvice，
 * 用这个组件写出与 GlobalExceptionHandler 完全一致的响应体，避免前端遇到两套错误格式。
 */
@Component
public class ApiResponseWriter {

	private final ObjectMapper objectMapper;

	public ApiResponseWriter(ObjectMapper objectMapper) {
		this.objectMapper = objectMapper;
	}

	public void write(HttpServletResponse response, ErrorCode errorCode, String message) throws IOException {
		if (response.isCommitted()) {
			return;
		}
		response.resetBuffer();
		response.setStatus(errorCode.status().value());
		response.setContentType(MediaType.APPLICATION_JSON_VALUE);
		response.setCharacterEncoding(StandardCharsets.UTF_8.name());
		response.getWriter().write(this.objectMapper.writeValueAsString(ApiResponse.error(errorCode.code(), message)));
		response.flushBuffer();
	}

	public void write(HttpServletResponse response, ErrorCode errorCode) throws IOException {
		write(response, errorCode, errorCode.message());
	}

}
