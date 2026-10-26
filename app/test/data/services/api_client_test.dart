import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/token_storage.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

const String _oldAccess = 'access-old';
const String _newAccess = 'access-new';

FakeTokenStorage _storage({Duration? expiresIn}) => FakeTokenStorage(
  tokens: StoredTokens(
    accessToken: _oldAccess,
    refreshToken: 'refresh-old',
    accessExpiresAt: DateTime.now().add(expiresIn ?? const Duration(hours: 1)),
  ),
);

ApiClient _client(FakeTokenStorage storage, ScriptedHttp http) =>
    ApiClient(storage: storage, adapter: http, origin: 'http://test.local');

void main() {
  test('Access Token 快到期时先续再发（§4.1.2 静默续期）', () async {
    final storage = _storage(expiresIn: const Duration(minutes: 1));
    final http = ScriptedHttp((options) {
      if (options.uri.path.endsWith('/auth/refresh')) {
        return refreshOk(_newAccess);
      }
      return envelope(data: {'name': '小明的家'});
    });
    final client = _client(storage, http);

    final data = await client.get('/families/current');

    expect(data, {'name': '小明的家'});
    expect(http.refreshCalls, 1);
    expect(http.accessTokens, ['Bearer $_newAccess']);
    expect(storage.writtenTokens.single.accessToken, _newAccess);
    client.dispose();
  });

  test('撞上 401 TOKEN_EXPIRED 时补续一次并重放原请求', () async {
    final storage = _storage();
    final http = ScriptedHttp((options) {
      if (options.uri.path.endsWith('/auth/refresh')) {
        return refreshOk(_newAccess);
      }
      if (options.headers['Authorization'] == 'Bearer $_oldAccess') {
        return envelope(code: 'TOKEN_EXPIRED', message: '登录已过期', status: 401);
      }
      return envelope(data: {'id': 1});
    });
    final client = _client(storage, http);

    expect(await client.get('/users/me'), {'id': 1});
    expect(http.refreshCalls, 1);
    expect(http.accessTokens, ['Bearer $_oldAccess', 'Bearer $_newAccess']);
    client.dispose();
  });

  test(
    'Refresh Token 已作废：清令牌、广播 sessionLost、抛 REFRESH_TOKEN_INVALID',
    () async {
      final storage = _storage(expiresIn: const Duration(minutes: 1));
      final http = ScriptedHttp(
        (options) => options.uri.path.endsWith('/auth/refresh')
            ? envelope(
                code: 'REFRESH_TOKEN_INVALID',
                message: '登录状态已失效，请重新登录',
                status: 401,
              )
            : envelope(data: {}),
      );
      final client = _client(storage, http);

      var sessionLost = false;
      final subscription = client.sessionLost.listen((_) => sessionLost = true);

      await expectLater(
        client.get('/families/current'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ServerErrorCode.refreshTokenInvalid,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.clearCount, 1);
      expect(sessionLost, isTrue);
      await subscription.cancel();
      client.dispose();
    },
  );

  test('离线时续期失败：不清令牌，带着旧 Access 往后端送', () async {
    final storage = _storage(expiresIn: const Duration(minutes: 1));
    final http = ScriptedHttp((options) => gateway());
    final client = _client(storage, http);

    var sessionLost = false;
    final subscription = client.sessionLost.listen((_) => sessionLost = true);

    // 续期请求自己就够不着后端，`_renew` 回 null 时 `_lastReachable` 已经是 false，
    // 于是拦截器走「照样发出去」那一支而不是清会话那一支：够不着后端不等于令牌作废。
    await expectLater(
      client.get('/families/current'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.isUnreachable,
          'isUnreachable',
          isTrue,
        ),
      ),
    );

    expect(http.refreshCalls, 1);
    expect(http.accessTokens, ['Bearer $_oldAccess']);
    expect(await storage.readTokens(), isNotNull);
    expect(storage.clearCount, 0);
    expect(sessionLost, isFalse);
    await subscription.cancel();
    client.dispose();
  });

  test('并发请求只续期一次——后端的 Refresh Token 一次一换，续第二次必失败', () async {
    final storage = _storage(expiresIn: const Duration(minutes: 1));
    final http = ScriptedHttp((options) {
      if (options.uri.path.endsWith('/auth/refresh')) {
        return refreshOk(_newAccess);
      }
      return envelope(data: {'path': options.uri.path});
    });
    final client = _client(storage, http);

    final results = await Future.wait([
      client.get('/families/current'),
      client.get('/users/me'),
    ]);

    expect(http.refreshCalls, 1);
    expect(results[0], {'path': '/api/v1/families/current'});
    expect(results[1], {'path': '/api/v1/users/me'});
    client.dispose();
  });

  test('HTTP 200 但业务码非 OK 也算失败，不会被误读成 data 为空', () async {
    final storage = _storage();
    final http = ScriptedHttp(
      (options) =>
          envelope(code: 'FAMILY_MEMBER_LIMIT', message: '该家庭成员已满 5 人，无法加入'),
    );
    final client = _client(storage, http);

    await expectLater(
      client.post('/families/join', body: {'inviteCode': '228286'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'FAMILY_MEMBER_LIMIT')
            .having((e) => e.message, 'message', '该家庭成员已满 5 人，无法加入'),
      ),
    );
    expect(storage.clearCount, 0);
    client.dispose();
  });

  test('GET /families/current 回 200 + data:null 表示还没有家庭，不是失败', () async {
    final storage = _storage();
    final http = ScriptedHttp((options) => envelope());
    final client = _client(storage, http);

    expect(await client.get('/families/current'), isNull);
    client.dispose();
  });

  test('getList 把 data 数组原样交出', () async {
    final storage = _storage();
    final http = ScriptedHttp(
      (options) => envelope(
        data: [
          {'id': 1, 'name': '餐饮'},
          {'id': 2, 'name': '交通'},
        ],
      ),
    );
    final client = _client(storage, http);

    expect(await client.getList('/categories'), [
      {'id': 1, 'name': '餐饮'},
      {'id': 2, 'name': '交通'},
    ]);
    client.dispose();
  });

  test('该回数组的端点回了 data:null，算畸形响应而不是空列表', () async {
    final storage = _storage();
    final http = ScriptedHttp((options) => envelope());
    final client = _client(storage, http);

    await expectLater(
      client.getList('/payment-accounts'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ClientErrorCode.malformedResponse,
        ),
      ),
    );
    client.dispose();
  });

  test('put 走 PUT 且带上请求体', () async {
    final storage = _storage();
    final http = ScriptedHttp((options) => envelope(data: {'id': 7}));
    final client = _client(storage, http);

    await client.put(
      '/payment-accounts/7',
      body: {'name': '微信', 'isDefault': true},
    );

    expect(http.call.method, 'PUT');
    expect(http.call.path, '/api/v1/payment-accounts/7');
    expect(http.call.body, {'name': '微信', 'isDefault': true});
    client.dispose();
  });

  test('查询参数里值为 null 的键不发往服务端', () async {
    final storage = _storage();
    final http = ScriptedHttp((options) => envelope(data: {'items': []}));
    final client = _client(storage, http);

    await client.get(
      '/transactions',
      query: {'yearMonth': '2026-09', 'type': null, 'categoryId': 12},
    );

    expect(http.call.query, {'yearMonth': '2026-09', 'categoryId': '12'});
    client.dispose();
  });

  test('上传撞上 401 TOKEN_EXPIRED 时补续并重放——FormData 必须克隆，否则二次 finalize 抛错', () async {
    final storage = _storage();
    final http = ScriptedHttp((options) {
      if (options.uri.path.endsWith('/auth/refresh')) {
        return refreshOk(_newAccess);
      }
      if (options.headers['Authorization'] == 'Bearer $_oldAccess') {
        return envelope(code: 'TOKEN_EXPIRED', message: '登录已过期', status: 401);
      }
      return envelope(data: {'id': 1, 'photoUrl': 'cat.png'});
    });
    final client = _client(storage, http);

    // dio 5.11.1 的 FormData.finalize() 第二次调用抛 StateError：不克隆重放体的话，
    // 这一行会以「连不上服务器」收场而不是拿到重放后的 200（扫描报告 2026-10-26 P1-8）。
    final data = await client.upload(
      '/cats/1/photo',
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'cat.png',
    );

    expect(data, {'id': 1, 'photoUrl': 'cat.png'});
    expect(http.refreshCalls, 1);
    expect(http.accessTokens, ['Bearer $_oldAccess', 'Bearer $_newAccess']);
    client.dispose();
  });
}
