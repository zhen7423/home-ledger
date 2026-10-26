import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/network_status.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端可达性 → 界面上的三态。这一份要真的 `ApiClient` 加 `ScriptedHttp`：
/// 可达性流是 `ApiClient` 内部发的，拿仓库替身喂不出它。
void main() {
  late bool reachable;
  late ScriptedHttp http;
  late ApiClient client;
  late ProviderContainer container;

  /// 发一个请求，只为了看它把可达性推成什么，返回值与异常都不关心。
  Future<void> probe() async {
    try {
      await client.get('/families/current');
    } on ApiException {
      // 要的就是「它失败了」这件事本身。
    }
    // 广播流的订阅者是在下一个微任务里被叫到的。
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    reachable = true;
    http = ScriptedHttp(
      (options) => reachable ? envelope(data: {}) : gateway(),
    );
    client = ApiClient(
      storage: FakeTokenStorage(),
      adapter: http,
      origin: 'http://test.local',
    );
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [apiClientProvider.overrideWithValue(client)],
    );
    container.listen(networkStatusProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    client.dispose();
  });

  test('冷启动是 unknown，而 unknown 允许提交', () {
    expect(container.read(networkStatusProvider), NetworkStatus.unknown);
    expect(container.read(canSubmitProvider), isTrue);
  });

  test('第一次成功不发事件，所以状态停在 unknown 而不是被报成离线', () async {
    // `_lastReachable` 初值就是 true，`_emitReachability` 在这种前后一致的场合直接返回。
    // 「成功过一次」并不比「还没试过」更能说明什么，所以这一条断的是不是离线。
    await probe();

    expect(container.read(networkStatusProvider), isNot(NetworkStatus.offline));
    expect(http.calls, hasLength(1));
  });

  test('够不着后端之后是 offline，五处表单的保存按钮随之禁用', () async {
    reachable = false;
    await expectLater(
      client.get('/families/current'),
      throwsA(isA<ApiException>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(networkStatusProvider), NetworkStatus.offline);
    expect(container.read(canSubmitProvider), isFalse);
  });

  test('恢复：再一次成功把状态带回 online，按钮随之解禁', () async {
    reachable = false;
    await expectLater(
      client.get('/families/current'),
      throwsA(isA<ApiException>()),
    );
    await Future<void>.delayed(Duration.zero);

    reachable = true;
    await expectLater(client.get('/families/current'), completes);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(networkStatusProvider), NetworkStatus.online);
    expect(container.read(canSubmitProvider), isTrue);
  });

  test('读不懂的响应体不算离线：后端答话了，只是答的读不懂', () async {
    final broken = ApiClient(
      storage: FakeTokenStorage(),
      adapter: ScriptedHttp(
        (options) => ResponseBody.fromString(
          '[1,2]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      ),
      origin: 'http://test.local',
    );
    addTearDown(broken.dispose);

    await expectLater(
      broken.get('/families/current'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ClientErrorCode.malformedResponse,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    // 把它报成「离线模式」等于用没网盖掉一次契约破坏（F2④）。
    expect(container.read(networkStatusProvider), isNot(NetworkStatus.offline));
  });
}
