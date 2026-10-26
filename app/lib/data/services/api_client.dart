import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/token_response.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// 一次成功下载的结果。刻意不做成 freezed：几 MB 的字节数组参与值相等比较毫无意义，
/// 而 freezed 生成的 == 会逐字节比一遍。
class DownloadedFile {
  const DownloadedFile({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;

  /// 服务端给的文件名（含中文与扩展名），直接拿去分享，前端不另拼一个。
  final String filename;

  /// 分享面板按它决定「用 Excel 打开」还是「当文本看」。
  final String contentType;
}

/// 全项目唯一的 Dio 封装：挂 Bearer 头、静默续期、解包统一响应体、把失败统一翻译成 ApiException。
///
/// 续期分两道：请求前发现 Access Token 快到期就先续（主动）；万一还是撞上 401 TOKEN_EXPIRED，
/// 就补续一次再重放原请求（被动，兜时钟偏差）。两道都用 QueuedInterceptor 串行化——后端的
/// Refresh Token 是一次一换的，并发续期会让第二个请求拿着已作废的令牌去换，直接失败。
class ApiClient {
  ApiClient({
    required this._storage,
    HttpClientAdapter? adapter,
    String? origin,
  }) : _dio = _buildDio(adapter, origin),
       _plain = _buildDio(adapter, origin) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  /// §6.1.1：基址由 --dart-define=API_BASE_URL 注入。默认走 10.0.2.2 是因为 Android 模拟器里的
  /// localhost 指向模拟器自己；默认端口 18088 即 Nginx，与生产同一条路径。真机联调改传局域网 IP。
  ///
  /// release 构建未注入时在这里直接抛错而不是静默回退模拟器地址：那样的 APK 装到真机上只表现为
  /// 「所有请求失败」，且无从排查（扫描报告 2026-10-26 P1-9）。debug/profile 保持回退，本地起手就能跑。
  static const String _injectedOrigin = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get defaultOrigin {
    if (_injectedOrigin.isNotEmpty) {
      return _injectedOrigin;
    }
    if (kReleaseMode) {
      throw StateError(
        'release 构建缺少服务端基址：请用 --dart-define=API_BASE_URL=<https://…> 重新构建',
      );
    }
    return 'http://10.0.2.2:18088';
  }

  static const String _apiPrefix = '/api/v1';

  /// 离过期还剩这么久就提前续期。取 5 分钟是为了让一次「打开 App → 浏览 → 提交」的完整操作
  /// 不会中途撞上过期。
  static const Duration _renewSkew = Duration(minutes: 5);

  static const String _authorizationHeader = 'Authorization';

  static const String _retriedKey = 'homeledger.retried';

  final TokenStorage _storage;

  final Dio _dio;

  /// 不带拦截器的孪生实例，专供续期与重放使用。
  ///
  /// 必须分开：在拦截器回调里再用 _dio 发请求会重新入队，而当前任务还占着队列，等于自己等自己。
  final Dio _plain;

  final StreamController<void> _sessionLost =
      StreamController<void>.broadcast();

  /// 令牌已彻底失效（续期失败，或服务端回了 TOKEN_REVOKED 这类码）。路由守卫订阅它把用户送回登录页。
  Stream<void> get sessionLost => _sessionLost.stream;

  final StreamController<bool> _reachability =
      StreamController<bool>.broadcast();

  /// `true` = 后端刚刚答过话，`false` = 刚刚够不着它。只在真的发生变化时发，
  /// 不发心跳：订阅方（NetworkStatus）拿它当状态用，重复值只会白白重建整棵页面树。
  Stream<bool> get reachability => _reachability.stream;

  bool _lastReachable = true;

  void _markReachable() => _emitReachability(true);

  void _markUnreachable() => _emitReachability(false);

  void _emitReachability(bool reachable) {
    if (reachable == _lastReachable || _reachability.isClosed) {
      return;
    }
    _lastReachable = reachable;
    _reachability.add(reachable);
  }

  Future<Map<String, dynamic>?> get(
    String path, {
    Map<String, dynamic>? query,
  }) async => _asObject(await _send('GET', path, query: query));

  /// 取 data 是数组的端点（类别树、支付方式清单）。
  ///
  /// 这里不给 `data: null` 留活路：那两个端点后端一定回数组，回 null 说明契约被破坏了。
  /// 静默当成空列表，界面上就是「你还没有任何类别」，把服务端故障演成用户没数据。
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _send('GET', path, query: query);
    if (data is! List) {
      throw const ApiException(code: ClientErrorCode.malformedResponse);
    }
    final rows = <Map<String, dynamic>>[];
    for (final row in data) {
      if (row is! Map<String, dynamic>) {
        throw const ApiException(code: ClientErrorCode.malformedResponse);
      }
      rows.add(row);
    }
    return rows;
  }

  Future<Map<String, dynamic>?> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async => _asObject(await _send('POST', path, body: body, query: query));

  Future<Map<String, dynamic>?> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async => _asObject(await _send('PUT', path, body: body, query: query));

  Future<Map<String, dynamic>?> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async => _asObject(await _send('PATCH', path, body: body, query: query));

  Future<Map<String, dynamic>?> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async => _asObject(await _send('DELETE', path, body: body, query: query));

  /// 上传二进制（S10 档案照片，§4.3.1 / §4.4.1）。
  ///
  /// 走带拦截器的 _dio，续期与 401 重放照旧生效。BODY 是 multipart，dio 遇到 FormData
  /// 会自己盖掉 BaseOptions 的 JSON content-type、换成带 boundary 的 multipart/form-data，
  /// 这里不需要也不应该再指一遍。上传端点只认 `file` 这一个 part；文件本身的格式由后端
  /// 按魔数判，part 的 Content-Type 传不传无所谓，故不提供该参数。
  Future<Map<String, dynamic>?> upload(
    String path, {
    required Uint8List bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    try {
      final response = await _dio.request<Object?>(
        path,
        data: form,
        options: Options(method: 'POST'),
      );
      _markReachable();
      return _asObject(_unwrapData(response.data));
    } on DioException catch (e) {
      throw await _handleFailure(_asApiException(e));
    } on ApiException catch (e) {
      throw await _handleFailure(e);
    }
  }

  /// 下载二进制。走的是带拦截器的 _dio，所以续期与 401 重放照旧生效。
  Future<DownloadedFile> download(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request<List<int>>(
        path,
        queryParameters: _withoutNulls(query),
        options: Options(method: 'GET', responseType: ResponseType.bytes),
      );
      _markReachable();
      return DownloadedFile(
        bytes: Uint8List.fromList(response.data ?? const <int>[]),
        filename: _filenameOf(response.headers),
        contentType: response.headers.value(Headers.contentTypeHeader) ?? '',
      );
    } on DioException catch (e) {
      throw await _handleFailure(_asApiException(e));
    }
  }

  static final RegExp _encodedFilename = RegExp("filename\\*=UTF-8''([^;]+)");

  static final RegExp _plainFilename = RegExp('filename="?([^";]+)"?');

  /// dio 5.11.1 的 `Headers` 只给了 accept / contentEncoding / contentLength / contentType /
  /// wwwAuthenticate 五个常量，**没有 `contentDispositionHeader`**，这里只能写字面量。
  static const String _disposition = 'content-disposition';

  static String _filenameOf(Headers headers) {
    final disposition = headers.value(_disposition) ?? '';
    final encoded = _encodedFilename.firstMatch(disposition);
    final name = encoded != null
        ? Uri.decodeComponent(encoded.group(1)!)
        : _plainFilename.firstMatch(disposition)?.group(1) ?? 'export.bin';
    // 名字来自响应头，不能直接拼进本地路径：一个 ../ 就能写到缓存目录外面去。
    final safe = name.replaceAll(RegExp(r'[\\/]'), '_').trim();
    return safe.isEmpty ? 'export.bin' : safe;
  }

  void dispose() {
    _dio.close(force: true);
    _plain.close(force: true);
    _sessionLost.close();
    _reachability.close();
  }

  static Dio _buildDio(HttpClientAdapter? adapter, String? origin) {
    final dio = Dio(
      BaseOptions(
        baseUrl: '${origin ?? defaultOrigin}$_apiPrefix',
        connectTimeout: const Duration(seconds: 10),
        // 上传 ≤5MB 照片时发送阶段也可能卡死（弱网半开连接），receiveTimeout 罩不住发送侧，
        // 必须单独给一个（dio 5 中 sendTimeout 只对有 body 的请求生效）。
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ),
    );
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
    }
    return dio;
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: _withoutNulls(query),
        options: Options(method: method),
      );
      _markReachable();
      return _unwrapData(response.data);
    } on DioException catch (e) {
      throw await _handleFailure(_asApiException(e));
    } on ApiException catch (e) {
      throw await _handleFailure(e);
    }
  }

  /// 调用处传 null 表示「这一项没选」，这种键得在出门前摘掉：留在 map 里会被拼进查询串，
  /// 于是 `?categoryId=` 之类的东西真去了后端，筛选条件凭空多一条。
  static Map<String, dynamic> _withoutNulls(Map<String, dynamic>? query) {
    if (query == null) {
      return const {};
    }
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null) {
        cleaned[key] = value;
      }
    });
    return cleaned;
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _storage.readTokens();
    if (tokens == null) {
      handler.next(options);
      return;
    }
    if (!tokens.expiresWithin(_renewSkew)) {
      _authorize(options, tokens.accessToken);
      handler.next(options);
      return;
    }
    final renewed = await _renew();
    if (renewed == null) {
      // 够不着后端不等于令牌作废：带着旧令牌继续发，让它在网络层失败，
      // 仓库那一层才回落到缓存。真作废的令牌会在网络恢复后由 401 清掉。
      if (!_lastReachable) {
        _authorize(options, tokens.accessToken);
        handler.next(options);
        return;
      }
      await _dropSession();
      handler.reject(
        DioException(
          requestOptions: options,
          error: const ApiException(code: ServerErrorCode.refreshTokenInvalid),
        ),
      );
      return;
    }
    _authorize(options, renewed.accessToken);
    handler.next(options);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    if (_asApiException(e).code != ServerErrorCode.tokenExpired ||
        e.requestOptions.extra[_retriedKey] == true) {
      handler.next(e);
      return;
    }
    final renewed = await _renew();
    if (renewed == null) {
      if (_lastReachable) {
        await _dropSession();
      }
      handler.next(e);
      return;
    }
    final replay = e.requestOptions..extra[_retriedKey] = true;
    _authorize(replay, renewed.accessToken);
    // FormData 只能被 finalize 一次：重放前必须克隆，否则 dio 在第二次 fetch 时抛
    // StateError('The FormData has already been finalized.')，上传撞上 401 静默续期的
    // 场景会被误报成 NETWORK_ERROR（扫描报告 2026-10-26 P1-8）。
    if (replay.data is FormData) {
      replay.data = (replay.data as FormData).clone();
    }
    try {
      handler.resolve(await _plain.fetch<Object?>(replay));
    } on DioException catch (replayError) {
      handler.next(replayError);
    }
  }

  /// 换一对新令牌并落盘。任何一步不成立都返回 null，由调用方决定是清会话还是原样报错。
  Future<TokenResponse?> _renew() async {
    final tokens = await _storage.readTokens();
    if (tokens == null) {
      return null;
    }
    try {
      final response = await _plain.post<Object?>(
        '/auth/refresh',
        data: {'refreshToken': tokens.refreshToken},
      );
      final renewed = TokenResponse.fromJson(
        requireData(_asObject(_unwrapData(response.data))),
      );
      await _storage.writeTokens(renewed);
      return renewed;
    } on DioException catch (e) {
      if (_asApiException(e).isUnreachable) {
        _markUnreachable();
      }
      return null;
    } on ApiException {
      return null;
    }
  }

  /// 主动续期失败时拦截器已经清过一次，这里再进来就直接返回，免得 sessionLost 为同一次失效响两回。
  Future<void> _dropSession() async {
    if (await _storage.readTokens() == null) {
      return;
    }
    await _storage.clearTokens();
    if (!_sessionLost.isClosed) {
      _sessionLost.add(null);
    }
  }

  /// 会话已废的错误在这里统一清令牌，省得每个 ViewModel 各判一遍。返回原异常交回调用处抛出。
  Future<ApiException> _handleFailure(ApiException e) async {
    if (e.isUnreachable) {
      _markUnreachable();
    }
    if (e.isSessionInvalid) {
      await _dropSession();
    }
    return e;
  }

  /// 剥掉 {code, message, data, traceId} 外壳，把 data 原样交出，**不假定它的形状**。
  ///
  /// HTTP 2xx 却带着非 OK 的业务码也要当失败处理，否则上层会拿到一个 null 的 data，
  /// 把「服务端报了错」误读成「这个用户还没有家庭」。
  Object? _unwrapData(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const ApiException(code: ClientErrorCode.malformedResponse);
    }
    final code = body['code'];
    if (code != ServerErrorCode.ok) {
      throw ApiException(
        code: code is String ? code : ClientErrorCode.malformedResponse,
        message: body['message'] as String? ?? '',
        traceId: body['traceId'] as String?,
      );
    }
    return body['data'];
  }

  /// data 该是一个对象的端点。null 原样交回——`GET /families/current` 就用 null 表示
  /// 「还没有家庭」，见需求文档 §8；是数组或标量才算畸形。
  Map<String, dynamic>? _asObject(Object? data) {
    if (data == null) {
      return null;
    }
    if (data is! Map<String, dynamic>) {
      throw const ApiException(code: ClientErrorCode.malformedResponse);
    }
    return data;
  }

  ApiException _asApiException(DioException e) {
    if (e.error is ApiException) {
      return e.error! as ApiException;
    }
    final body = _bodyOf(e);
    if (body is Map<String, dynamic> && body['code'] is String) {
      return ApiException(
        code: body['code'] as String,
        message: body['message'] as String? ?? '',
        traceId: body['traceId'] as String?,
        statusCode: e.response?.statusCode,
      );
    }
    return ApiException(
      code: _transportCode(e),
      statusCode: e.response?.statusCode,
    );
  }

  /// 下载请求的 responseType 是 bytes，出错时响应体是一串字节而不是 Map。
  /// 导出超限那种 400 回的正是 JSON，解不回来就会被当成「响应体畸形」，
  /// 用户看到的是「服务器返回的内容无法识别」而不是真正那句「请缩小时间区间」。
  Object? _bodyOf(DioException e) {
    final body = e.response?.data;
    if (body is! List<int>) {
      return body;
    }
    try {
      return jsonDecode(utf8.decode(body));
    } on FormatException {
      return body;
    }
  }

  /// 传输层失败的归类。这些 code 后端不会返回，文案由 ui/core/error_copy.dart 兜。
  String _transportCode(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => ClientErrorCode.timeout,
    DioExceptionType.badCertificate => ClientErrorCode.network,
    // 拿到响应但不是我们的响应体：Nginx 的 502/504 页面、或 Spring 兜底的 404 JSON 都落在这里。
    // 401/403 不带业务码说明不是后端答的话（网关拦截页）：401 按会话失效处理送回登录页，
    // 403 归为 ACCESS_DENIED——两者都不许算「离线」，否则缓存回落会把网关故障演成离线模式
    // （扫描报告 2026-10-26 P3-2）。
    DioExceptionType.badResponse => switch (e.response?.statusCode ?? 0) {
      >= 500 => ClientErrorCode.gateway,
      401 => ServerErrorCode.unauthorized,
      403 => ClientErrorCode.accessDenied,
      _ => ClientErrorCode.malformedResponse,
    },
    _ => ClientErrorCode.network,
  };

  static void _authorize(RequestOptions options, String accessToken) {
    options.headers[_authorizationHeader] = 'Bearer $accessToken';
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(storage: ref.watch(tokenStorageProvider));
  ref.onDispose(client.dispose);
  return client;
});
