package cn.homeledger.common;

import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * §5.3「后端异常统一封装，不向客户端泄漏堆栈信息」。继承 ResponseEntityExceptionHandler 是为了让 405 / 415 /
 * 404 这类框架异常也走统一响应体，而不是退回 Spring 默认的 ProblemDetail 格式。
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(BizException.class)
    public ResponseEntity<ApiResponse<Void>> handleBizException(BizException ex) {
        ErrorCode errorCode = ex.errorCode();
        if (errorCode == ErrorCode.NOT_IMPLEMENTED) {
            // 501 落在 is5xxServerError 里，但它是 §4.1.3 / §4.1.7 刻意保留的占位而非故障；
            // 按 ERROR 加堆栈记会污染错误看板，让真正的 500 淹在里面
            log.info("接口本期未开放: {}", ex.getMessage());
        } else if (errorCode.status().is5xxServerError()) {
            log.error("业务异常 {}: {}", errorCode.code(), ex.getMessage(), ex);
        } else {
            log.info("业务拒绝 {}: {}", errorCode.code(), ex.getMessage());
        }
        return ResponseEntity.status(errorCode.status())
                .body(ApiResponse.<Void>error(errorCode.code(), ex.getMessage()));
    }

    /**
     * 方法级安全（@PreAuthorize 等）抛出的 AccessDeniedException 目前没有来源——项目只用
     * URL 级规则，越权全部走 BizException(FORBIDDEN)。显式挂在这里是防患：一旦将来引入方法级
     * 安全，兜底的 handleUnexpected 会把它变 500，403 的语义就丢了（扫描报告 P2-4）。
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException ex) {
        log.info("访问被拒: {}", ex.getMessage());
        return ResponseEntity.status(ErrorCode.FORBIDDEN.status())
                .body(ApiResponse.<Void>error(ErrorCode.FORBIDDEN.code(), ErrorCode.FORBIDDEN.message()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception ex) {
        log.error("未处理异常", ex);
        ErrorCode errorCode = ErrorCode.INTERNAL_ERROR;
        return ResponseEntity.status(errorCode.status()).body(ApiResponse.<Void>error(errorCode.code(), errorCode.message()));
    }

    @Override
    protected ResponseEntity<Object> handleExceptionInternal(Exception ex, Object body, HttpHeaders headers,
            HttpStatusCode statusCode, WebRequest request) {
        log.info("请求处理失败 [{}]: {}", statusCode.value(), ex.getMessage());
        ErrorCode errorCode = switch (statusCode.value()) {
            case 404 ->
                ErrorCode.RESOURCE_NOT_FOUND;
            case 405 ->
                ErrorCode.METHOD_NOT_ALLOWED;
            case 415 ->
                ErrorCode.UNSUPPORTED_MEDIA_TYPE;
            case 500 ->
                ErrorCode.INTERNAL_ERROR;
            default ->
                ErrorCode.BAD_REQUEST;
        };
        String message = errorCode.message();
        if (ex instanceof MethodArgumentNotValidException invalid) {
            String detail = invalid.getBindingResult()
                    .getFieldErrors()
                    .stream()
                    .map(field -> field.getField() + " " + field.getDefaultMessage())
                    .collect(Collectors.joining("；"));
            if (!detail.isBlank()) {
                errorCode = ErrorCode.VALIDATION_FAILED;
                message = detail;
            }
        } else if (ex instanceof MaxUploadSizeExceededException) {
            // multipart 上限（10 MB）拦住的是没经过客户端压缩的大文件，业务侧那句按配置派生的
            // 「照片不能超过 N MB」轮不到说话（S10 审查 I1）；状态码仍是 Spring 给的 413
            errorCode = ErrorCode.BAD_REQUEST;
            message = "照片太大了，请先压缩后再上传";
        }
        return ResponseEntity.status(statusCode)
                .headers(headers)
                .body(ApiResponse.error(errorCode.code(), message));
    }

}
