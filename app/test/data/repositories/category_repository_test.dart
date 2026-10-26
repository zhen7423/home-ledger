import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/category.dart';
import 'package:homeledger/data/repositories/category_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/dict_cache_store.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// Nginx 把后端 502 页面原样吐出来：HTTP 状态非 2xx、响应体也不是统一信封。
/// 这是断网之外最常见的「压根没到后端」，正是该回落缓存的那一类。
ResponseBody _gateway() => ResponseBody.fromString(
  '<html><body>502 Bad Gateway</body></html>',
  502,
  headers: {
    Headers.contentTypeHeader: ['text/html'],
  },
);

List<Category> _categories() => [
  Category(
    id: 1,
    type: 'EXPENSE',
    name: '餐饮',
    iconKey: 'bowl_noodle',
    colorIndex: 0,
    sortNo: 1,
    enabled: true,
    preset: true,
    children: [
      Category(
        id: 11,
        type: 'EXPENSE',
        name: '早餐',
        sortNo: 1,
        enabled: true,
        preset: true,
      ),
    ],
  ),
  const Category(
    id: 2,
    type: 'INCOME',
    name: '工资',
    iconKey: 'banknote',
    colorIndex: 1,
    sortNo: 1,
    enabled: true,
    preset: true,
  ),
];

void main() {
  late Directory root;
  late DictCacheStore cache;
  late CategoryRepository repository;

  /// 让仓库接下来按脚本回。每个用例自己决定回什么。
  void stubWith(ResponseBody Function(RequestOptions options) script) {
    repository = CategoryRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: ScriptedHttp(script),
        origin: 'http://test.local',
      ),
      cache: cache,
    );
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('category_repository');
    cache = DictCacheStore(directoryResolver: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('网络成功即整份覆盖缓存，并标成非缓存来源', () async {
    stubWith((options) => envelope(data: _json()));

    final result = await repository.tree();

    expect(result.fromCache, isFalse);
    expect(result.categories.map((c) => c.id), [1, 2]);
    expect(result.categories.first.children.single.name, '早餐');
    // 缓存里此刻是同一份内容：下一次断网就读它
    expect(await cache.readCategories(), result.categories);
  });

  test('传输层失败时回落到上一份缓存，并带上 fromCache 标记', () async {
    stubWith((options) => envelope(data: _json()));
    await repository.tree();

    stubWith((options) => _gateway());
    final offline = await repository.tree();

    expect(offline.fromCache, isTrue);
    expect(offline.categories.map((c) => c.id), [1, 2]);
  });

  test('业务错误不回落缓存：拿一份旧字典去选一个已删的类别更糟', () async {
    stubWith((options) => envelope(data: _json()));
    await repository.tree();

    stubWith(
      (options) => envelope(code: 'NO_FAMILY', message: '还没有家庭', status: 403),
    );

    await expectLater(
      repository.tree(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ServerErrorCode.noFamily,
        ),
      ),
    );
  });

  test('没有缓存可兜时照原样报错，不返回空列表假装成功', () async {
    stubWith((options) => _gateway());

    await expectLater(
      repository.tree(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ClientErrorCode.gateway,
        ),
      ),
    );
  });

  test('写操作直接打网络，带对方法、路径与请求体', () async {
    final http = ScriptedHttp((options) => envelope(data: {'id': 3}));
    repository = CategoryRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
      cache: cache,
    );

    await repository.create(type: 'EXPENSE', parentId: 1, name: '外卖');
    await repository.rename(3, '夜宵');
    await repository.toggle(3);
    await repository.remove(3);
    await repository.sort(type: 'EXPENSE', parentId: 1, orderedIds: [3, 4]);

    expect(http.calls.map((c) => '${c.method} ${c.path}'), [
      'POST /api/v1/categories',
      'PATCH /api/v1/categories/3',
      'PATCH /api/v1/categories/3/toggle',
      'DELETE /api/v1/categories/3',
      'PUT /api/v1/categories/sort',
    ]);
    expect(http.calls.first.body, {
      'type': 'EXPENSE',
      'parentId': 1,
      'name': '外卖',
    });
    expect(http.calls.last.body, {
      'type': 'EXPENSE',
      'parentId': 1,
      'orderedIds': [3, 4],
    });
  });
}

/// 后端回来的形状：树里每个节点都带全字段，小类的 iconKey / colorIndex 是 null。
List<Map<String, dynamic>> _json() => [
  for (final node in _categories()) _nodeJson(node),
];

Map<String, dynamic> _nodeJson(Category node) => {
  'id': node.id,
  'type': node.type,
  'name': node.name,
  'iconKey': node.iconKey,
  'colorIndex': node.colorIndex,
  'sortNo': node.sortNo,
  'enabled': node.enabled,
  'preset': node.preset,
  'children': [for (final child in node.children) _nodeJson(child)],
};
