package cn.homeledger.common;

/**
 * 业务拒绝。由 {@link GlobalExceptionHandler} 统一转成 {@link ApiResponse}，不向客户端泄漏堆栈（§5.3）。
 */
public class BizException extends RuntimeException {

	private final ErrorCode errorCode;

	public BizException(ErrorCode errorCode) {
		this(errorCode, errorCode.message());
	}

	public BizException(ErrorCode errorCode, String message) {
		super(message);
		this.errorCode = errorCode;
	}

	public ErrorCode errorCode() {
		return this.errorCode;
	}

}
