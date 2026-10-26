import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/repositories/statistics_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/statistics_cache_store.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';
import '../../support/s5_fixtures.dart';

/// 统计的一次加载 = 两个端点 + 一份单槽快照。快照是真的（临时目录），因为
/// 「回落时把区间 chips 拨回快照覆盖的那一段」这条规则全靠它带回来的那份条件。
void main() {
  late Directory root;
  late StatisticsCacheStore cache;
  late StatisticsRepository repository;
  late ScriptedHttp http;

  const thisMonth = StatisticsQuery(
    startDate: '2026-09-01',
    endDate: '2026-09-14',
  );
  const lastMonth = StatisticsQuery(
    startDate: '2026-08-01',
    endDate: '2026-08-31',
  );

  void stub(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = StatisticsRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
      cache: cache,
    );
  }

  /// 两个端点各回各的，这正是仓库里那句 `Future.wait` 的形状。
  void stubOnline() {
    stub(
      (options) => options.uri.path.endsWith('/transactions/summary')
          ? envelope(data: summary().toJson())
          : envelope(data: overview().toJson()),
    );
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('stats_repository');
    cache = StatisticsCacheStore(directoryResolver: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('两个端点都打，且带的是同一套条件', () async {
    stubOnline();

    await repository.load(thisMonth);

    expect(
      http.calls.map((c) => c.path),
      containsAll([
        '/api/v1/transactions/summary',
        '/api/v1/statistics/finance/overview',
      ]),
    );
    // null 的那一项被 ApiClient 摘掉了，条件相同就是查询串相同。
    expect(http.calls.first.query, {
      'startDate': '2026-09-01',
      'endDate': '2026-09-14',
    });
    expect(http.calls.last.query, http.calls.first.query);
  });

  test('在线回来的结果标着非缓存，条件就是传进去那一份', () async {
    stubOnline();

    final result = await repository.load(thisMonth);

    expect(result.fromCache, isFalse);
    expect(result.savedAt, isNull);
    expect(result.query, thisMonth);
    expect(result.summary.expense, '3200.00');
  });

  test('成功一次就把这份结果写进快照', () async {
    stubOnline();

    await repository.load(thisMonth);

    final cached = await cache.read();
    expect(cached?.query, thisMonth);
    expect(cached?.summary, summary());
    expect(cached?.overview, overview());
  });

  test('回落时交出去的条件与时刻都来自快照，界面据此拨回 chips', () async {
    stubOnline();
    await repository.load(lastMonth);

    stub((_) => gateway());
    final result = await repository.load(thisMonth);

    expect(result.fromCache, isTrue);
    expect(result.query, lastMonth);
    expect(result.savedAt, isNotNull);
  });

  test('没有快照时照原样报错：一张空饼图比一句失败更糟', () async {
    stub((_) => gateway());

    await expectLater(repository.load(thisMonth), throwsA(isA<ApiException>()));
  });

  test('业务错误不读快照：拿旧统计盖掉「你没权限」是藏问题', () async {
    stubOnline();
    await repository.load(thisMonth);

    stub((_) => envelope(code: 'FORBIDDEN', message: '无权访问该家庭', status: 403));

    await expectLater(
      repository.load(lastMonth),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });
}
