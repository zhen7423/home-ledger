import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/ui/core/error_copy.dart';

void main() {
  test('后端带文案时原样使用，不在前端另抄一份', () {
    const error = ApiException(
      code: 'INVITE_CODE_EXPIRED',
      message: '邀请码已过期，请向家庭创建者索取新的邀请码',
    );
    expect(errorCopy(error), '邀请码已过期，请向家庭创建者索取新的邀请码');
  });

  test('后端只给码没给文案时按传输层兜底', () {
    expect(
      errorCopy(const ApiException(code: ClientErrorCode.timeout)),
      '请求超时，请稍后重试',
    );
    expect(
      errorCopy(const ApiException(code: ClientErrorCode.gateway)),
      '服务器暂时不可用，请稍后重试',
    );
    expect(
      errorCopy(const ApiException(code: ClientErrorCode.network)),
      contains('连不上服务器'),
    );
  });

  test('认不出的异常给一句通用提示', () {
    expect(errorCopy(StateError('boom')), '操作失败了，请稍后重试');
    expect(errorCopy(null), '操作失败了，请稍后重试');
  });

  group('isSessionInvalid', () {
    test('这些码意味着本地令牌必须清掉', () {
      for (final code in [
        ServerErrorCode.tokenRevoked,
        ServerErrorCode.refreshTokenInvalid,
        ServerErrorCode.unauthorized,
        ServerErrorCode.accountDeactivated,
      ]) {
        expect(ApiException(code: code).isSessionInvalid, isTrue, reason: code);
      }
    });

    test('过期与业务错误不动登录态', () {
      expect(
        const ApiException(code: ServerErrorCode.tokenExpired).isSessionInvalid,
        isFalse,
      );
      expect(
        const ApiException(code: 'FAMILY_MEMBER_LIMIT').isSessionInvalid,
        isFalse,
      );
    });
  });

  test('requireData 在响应体不合约定时报 MALFORMED_RESPONSE 而不是崩在空指针上', () {
    expect(requireData({'a': 1}), {'a': 1});
    expect(
      () => requireData(null),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ClientErrorCode.malformedResponse,
        ),
      ),
    );
  });
}
