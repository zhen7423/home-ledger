import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 按脚本回答请求的后端替身：不发网络，只吐出预先写好的响应体，同时把每次请求记下来供断言。
///
/// 令牌续期、查询串拼装、请求体编码这些细节都在这里被看清——断言写在 `calls` 上，
/// 而不是靠 Response 里回显的字段反推。
class ScriptedHttp implements HttpClientAdapter {
  ScriptedHttp(this._script);

  final ResponseBody Function(RequestOptions options) _script;

  final List<HttpCall> calls = [];

  int get refreshCalls =>
      calls.where((c) => c.path.endsWith('/auth/refresh')).length;

  /// 续期请求自己不带业务语义，看鉴权头时把它排掉。
  List<String?> get accessTokens => [
    for (final c in calls.where((c) => !c.path.endsWith('/auth/refresh')))
      c.bearer,
  ];

  HttpCall get call => calls.single;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // 重放会就地改写原 RequestOptions，所以必须当场快照，否则记到的是改写后的头
    calls.add((
      path: options.uri.path,
      bearer: options.headers['Authorization'] as String?,
      method: options.method,
      query: options.uri.queryParameters,
      // dio 5.11 在适配器这一层仍留着原始对象，编码出的 JSON 只进 requestStream
      body: options.data,
    ));
    return _script(options);
  }

  @override
  void close({bool force = false}) {}
}

/// 一次请求的快照。
typedef HttpCall = ({
  String path,
  String? bearer,
  String method,
  Map<String, String> query,
  Object? body,
});

/// 统一响应体 `{code, message, data, traceId}`。HTTP status 与业务码分开给，
/// 正因为后端会回 200 + 非 OK 的码，前端才需要 `getList` / `_unwrapData` 那套判法。
ResponseBody envelope({
  String code = 'OK',
  String message = '成功',
  Object? data,
  int status = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode({
      'code': code,
      'message': message,
      'data': data,
      'traceId': 'trace-1',
    }),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// 换新令牌成功时的响应体。
ResponseBody refreshOk(String newAccessToken) => envelope(
  data: {
    'tokenType': 'Bearer',
    'accessToken': newAccessToken,
    'accessExpiresInSeconds': 7200,
    'refreshToken': 'refresh-new',
    'refreshExpiresInSeconds': 2592000,
  },
);

/// Nginx 把后端 502 页面原样吐出来：状态非 2xx、响应体也不是统一信封。
/// 这是断网之外最常见的「压根没到后端」，`isTransportFailure` 与 `isUnreachable` 都为 true。
ResponseBody gateway() => ResponseBody.fromString(
  '<html><body>502 Bad Gateway</body></html>',
  502,
  headers: {
    Headers.contentTypeHeader: ['text/html'],
  },
);

/// 导出下载用的响应体：字节流 + `content-disposition`。
///
/// dio 5.11.1 的 `Headers` 没有 `contentDispositionHeader` 这个常量（只有 accept /
/// contentEncoding / contentLength / contentType / wwwAuthenticate 五个），只能写字面量。
ResponseBody binary(
  List<int> bytes, {
  String contentType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  String? disposition,
}) => ResponseBody.fromBytes(
  bytes,
  200,
  headers: {
    Headers.contentTypeHeader: [contentType],
    if (disposition != null) 'content-disposition': [disposition],
  },
);
