import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/ui/core/auth_image.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// S10 档案照片的展示件（§4.3.1 / A6）。
///
/// 它必须走带 Bearer 的下载而不是 `Image.network`，所以这里钉的是「请求真正发出去了、
/// 字节原样渲染、失败落回占位图」三条行为；鉴权头本身由 `api_client_test` 那一层管。
void main() {
  /// 1×1 透明 PNG。解码失败的字节会在 `Image.memory` 里把异常抛到 FlutterError，
  /// 把「加载成功」的断言污染成「解码异常」，所以成功分支必须喂真图。
  final png1x1 = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );
  ProviderContainer scopeWith(
    HttpClientAdapter adapter, {
    IconData placeholderIcon = Icons.pets_outlined,
  }) {
    final client = ApiClient(
      storage: FakeTokenStorage(),
      adapter: adapter,
      origin: 'http://test.local',
    );
    return ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(client)],
    );
  }

  Future<void> pump(WidgetTester tester, ProviderContainer scope, String? url,
      {IconData icon = Icons.pets_outlined}) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          home: SizedBox(
            width: 80,
            height: 80,
            child: AuthImage(
              photoUrl: url,
              placeholderIcon: icon,
            ),
          ),
        ),
      ),
    );
    // 让 download 的 future 落定：dio 会给响应流挂超时 Timer，只 pump 一拍它还没被取消，
    // 测试结束时的假时钟会报「Timer 仍在等待」——沿用本项目其它页面用例的 pumpAndSettle。
    await tester.pumpAndSettle();
  }

  testWidgets('有 url：向鉴权端点发请求并渲染字节', (tester) async {
    final http = ScriptedHttp(
      (options) => binary(png1x1, contentType: 'image/png'),
    );
    final scope = scopeWith(http);
    addTearDown(scope.dispose);

    await pump(tester, scope, '/photos/abc123.jpg');

    expect(http.call.path, '/api/v1/photos/abc123.jpg');
    expect(http.call.bearer, isNull, reason: '没存令牌时不该带 Authorization（令牌注入另测）');
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('没有 url：一个请求都不发，渲染占位图标', (tester) async {
    final http = ScriptedHttp((options) => binary([1]));
    final scope = scopeWith(http);
    addTearDown(scope.dispose);

    await pump(tester, scope, null, icon: Icons.pets_outlined);

    expect(http.calls, isEmpty);
    expect(find.byIcon(Icons.pets_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('下载失败（照片已不存在/网络差）：落回占位图，不把错误抛给页面', (tester) async {
    final http = ScriptedHttp(
      (options) => envelope(code: 'RESOURCE_NOT_FOUND', status: 404),
    );
    final scope = scopeWith(http);
    addTearDown(scope.dispose);

    await pump(tester, scope, '/photos/deadbeef.jpg', icon: Icons.child_care_outlined);

    expect(find.byIcon(Icons.child_care_outlined), findsOneWidget);
    expect(tester.takeException(), isNull, reason: '加载失败不应让整页报错');
  });
}