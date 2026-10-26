package cn.homeledger.common;

import org.slf4j.MDC;

/**
 * 统一响应体。
 */
public record ApiResponse<T>(String code, String message, T data, String traceId) {

	public static final String TRACE_ID_MDC_KEY = "traceId";

	public static final String CODE_OK = "OK";

	public static <T> ApiResponse<T> ok(T data) {
		return new ApiResponse<>(CODE_OK, "成功", data, MDC.get(TRACE_ID_MDC_KEY));
	}

	public static ApiResponse<Void> ok() {
		return new ApiResponse<>(CODE_OK, "成功", null, MDC.get(TRACE_ID_MDC_KEY));
	}

	public static <T> ApiResponse<T> error(String code, String message) {
		return new ApiResponse<>(code, message, null, MDC.get(TRACE_ID_MDC_KEY));
	}

}
