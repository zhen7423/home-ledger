/// 请求失败时抛出的唯一异常类型：既覆盖后端返回的业务错误，也覆盖根本没到后端的传输层错误。
///
/// code 取后端 ErrorCode 的枚举名，前端一律按 code 分支而不看 HTTP status——status 只表达语义类别，
/// 同一个 400 底下可能是「密码错误」也可能是「邀请码已过期」。toString 刻意不含 message 与任何令牌字段，
/// 免得被顺手打进日志（§4.1.2）。
class ApiException implements Exception {
  const ApiException({
    required this.code,
    this.message = '',
    this.traceId,
    this.statusCode,
  });

  final String code;
  final String message;
  final String? traceId;
  final int? statusCode;

  /// 续期也救不回来的几种：令牌被服务端吊销、续期令牌本身失效、令牌非法、账号已注销。
  /// 命中就该清掉本地令牌并把用户送回登录页。
  bool get isSessionInvalid => switch (code) {
    ServerErrorCode.tokenRevoked ||
    ServerErrorCode.refreshTokenInvalid ||
    ServerErrorCode.unauthorized ||
    ServerErrorCode.accountDeactivated => true,
    _ => false,
  };

  /// 压根没到后端、或到了但没给出可用响应。只有这一类失败才允许回落到本地缓存（§5.4）：
  /// 401 / 403 / 404 是服务端明确告诉你的结果，缓存一份旧字典上去就等于把「你没权限」
  /// 或「这个类别已删」藏起来，用户会拿着一个已经不存在的类别去记账。
  bool get isTransportFailure => switch (code) {
    ClientErrorCode.network ||
    ClientErrorCode.timeout ||
    ClientErrorCode.gateway ||
    ClientErrorCode.malformedResponse => true,
    _ => false,
  };

  /// 「够不着后端」。比 [isTransportFailure] 窄一个 `MALFORMED_RESPONSE`：
  /// 后端回了一段读不懂的内容，恰恰证明它答话了，把这种情况算作离线，
  /// 等于用「没网」把一次契约破坏盖过去——界面上写着「离线模式」，
  /// 而真正该修的是响应体。缓存回落继续用 isTransportFailure（S3 的既有口径），
  /// 横幅与按钮禁用用这一个。两个谓词不要合并成一个。
  bool get isUnreachable => switch (code) {
    ClientErrorCode.network ||
    ClientErrorCode.timeout ||
    ClientErrorCode.gateway => true,
    _ => false,
  };

  @override
  String toString() =>
      'ApiException($code, status=$statusCode, traceId=$traceId)';
}

/// 后端 ErrorCode 中前端需要单独分支的那几个。其余 code 一律直接展示后端回传的 message，
/// 不在前端另抄一份文案，否则改了后端忘了改前端就会前后矛盾。
abstract class ServerErrorCode {
  static const String ok = 'OK';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String tokenRevoked = 'TOKEN_REVOKED';
  static const String refreshTokenInvalid = 'REFRESH_TOKEN_INVALID';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String accountDeactivated = 'ACCOUNT_DEACTIVATED';
  static const String noFamily = 'NO_FAMILY';
}

/// 传输层错误的 code，由客户端自己命名，后端不会返回它们。文案见 ui/core/error_copy.dart。
abstract class ClientErrorCode {
  static const String network = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';
  static const String gateway = 'GATEWAY_ERROR';
  static const String malformedResponse = 'MALFORMED_RESPONSE';

  /// 响应是 403 且不带本后端的业务码——网关/反代的拦截页，而不是后端拒绝的某次具体操作。
  /// 单独归类是为了不落进 isTransportFailure：网关故障不该被「离线兜底」的旧缓存盖住。
  static const String accessDenied = 'ACCESS_DENIED';
}

/// 登录、注册、续期、改密码、家庭信息这几个接口后端一定回 data，拿不到就说明响应体不合约定。
/// 用它代替 `!` 硬解包，免得崩在一个看不出所以然的空指针上。
Map<String, dynamic> requireData(Map<String, dynamic>? data) =>
    data ?? (throw const ApiException(code: ClientErrorCode.malformedResponse));
