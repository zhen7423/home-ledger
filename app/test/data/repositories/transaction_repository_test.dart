import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/transaction.dart';
import 'package:homeledger/data/models/transaction_page.dart';
import 'package:homeledger/data/repositories/transaction_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/transaction_cache_store.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';
import '../../support/finance_fixtures.dart';

/// 流水仓库的在线与离线两条路。缓存是真的（临时目录 + 固定时钟），网络是脚本化的：
/// 回落这一路的价值全在「读出来的是盘上那份」，拿替身缓存就测不到东西。
void main() {
  late Directory root;
  late TransactionCacheStore cache;
  late TransactionRepository repository;

  /// 让仓库接下来按脚本回。每个用例自己决定回什么。
  void stubWith(ResponseBody Function(RequestOptions options) script) {
    repository = TransactionRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: ScriptedHttp(script),
        origin: 'http://test.local',
      ),
      cache: cache,
    );
  }

  /// 在线拿到一页并把它写进缓存。
  Future<void> seedOnline(List<Transaction> rows) async {
    stubWith(
      (_) => envelope(
        data: transactionPage(page: 1, pages: 1, records: rows).toJson(),
      ),
    );
    await repository.page(const TransactionPageQuery());
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tx_repository');
    cache = TransactionCacheStore(
      directoryResolver: () async => root,
      clock: () => DateTime(2026, 9, 14),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('在线拿到的一页标着「不是缓存」，savedAt 留空', () async {
    stubWith(
      (_) => envelope(
        data: transactionPage(
          page: 1,
          pages: 1,
          records: [tx(id: 1, bizDate: DateTime(2026, 9, 10))],
        ).toJson(),
      ),
    );

    final result = await repository.page(const TransactionPageQuery());

    expect(result.fromCache, isFalse);
    expect(result.savedAt, isNull);
    expect(result.page.records.single.id, 1);
  });

  test('只有不带条件的查询才写缓存：翻页与筛选不许污染那份全集', () async {
    await seedOnline([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);
    expect((await cache.readRange(null, null)).rows, hasLength(1));

    stubWith(
      (_) => envelope(
        data: transactionPage(
          page: 1,
          pages: 1,
          records: [
            tx(id: 2, bizDate: DateTime(2026, 9, 11)),
            tx(id: 3, bizDate: DateTime(2026, 9, 12)),
          ],
        ).toJson(),
      ),
    );
    await repository.page(const TransactionPageQuery(categoryId: 1));

    expect((await cache.readRange(null, null)).rows, hasLength(1));
  });

  test('够不着后端时回落到缓存，并带上「数据截至」的时刻', () async {
    await seedOnline([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);

    stubWith((_) => gateway());
    final result = await repository.page(const TransactionPageQuery());

    expect(result.fromCache, isTrue);
    expect(result.savedAt, isNotNull);
    expect(result.page.records.map((row) => row.id), [1]);
  });

  test('回落时 pages 是 1：离线没有下一页可翻', () async {
    await seedOnline([
      tx(id: 1, bizDate: DateTime(2026, 9, 10)),
      tx(id: 2, bizDate: DateTime(2026, 9, 11)),
    ]);

    stubWith((_) => gateway());
    final page = (await repository.page(const TransactionPageQuery())).page;

    expect(page.pages, 1);
    expect(page.total, page.records.length);
    expect(page.page, 1);
  });

  test('回落时在内存里重算筛选', () async {
    await cache.merge([
      tx(id: 1, bizDate: DateTime(2026, 9, 10), type: FlowType.expense),
      tx(id: 2, bizDate: DateTime(2026, 9, 11), type: FlowType.income),
    ]);

    stubWith((_) => gateway());
    final result = await repository.page(
      const TransactionPageQuery(type: FlowType.expense),
    );

    expect(result.fromCache, isTrue);
    expect(result.page.records.map((row) => row.id), [1]);
  });

  test('回落时月度小计也是重算的，不是服务端上次给的那一份', () async {
    stubWith(
      (_) => envelope(
        data: transactionPage(
          page: 1,
          pages: 1,
          records: [
            tx(id: 1, bizDate: DateTime(2026, 9, 10)),
            tx(id: 2, bizDate: DateTime(2026, 9, 11), type: FlowType.income),
          ],
          // 服务端那份小计是随手写的数，回落时不该继续挂在这里
          summaries: [monthSummary('2026-09', count: 500)],
        ).toJson(),
      ),
    );
    await repository.page(const TransactionPageQuery());

    stubWith((_) => gateway());
    final page = (await repository.page(const TransactionPageQuery())).page;

    expect(page.monthSummaries, summarizeByMonth(page.records));
    expect(page.monthSummaries.single.count, 2);
  });

  test('从来没缓存过时照原样报错，不交出一张空列表', () async {
    stubWith((_) => gateway());

    await expectLater(
      repository.page(const TransactionPageQuery()),
      throwsA(isA<ApiException>()),
    );
  });

  test('业务错误不回落缓存：拿一份旧流水去盖「你没权限」更糟', () async {
    await seedOnline([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);

    stubWith(
      (_) => envelope(code: 'NO_FAMILY', message: '还没有加入家庭', status: 403),
    );

    await expectLater(
      repository.page(const TransactionPageQuery()),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NO_FAMILY')),
    );
  });

  test('写操作同步缓存：记一笔进缓存、改日期换月份、删一笔摘掉', () async {
    stubWith(
      (_) => envelope(data: tx(id: 5, bizDate: DateTime(2026, 9, 10)).toJson()),
    );
    await repository.create(
      amount: '10.00',
      categoryId: 1,
      accountId: 1,
      bizDate: '2026-09-10',
    );
    expect(await cache.readId(5), isNotNull);

    // 改了 bizDate 会让这一条落到另一个月文件里，漏掉 removeId 就会出现两行。
    stubWith(
      (_) => envelope(data: tx(id: 5, bizDate: DateTime(2026, 8, 10)).toJson()),
    );
    await repository.update(
      5,
      amount: '10.00',
      categoryId: 1,
      accountId: 1,
      bizDate: '2026-08-10',
    );
    expect((await cache.readId(5))?.bizDate, DateTime(2026, 8, 10));
    expect(
      (await cache.readRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30))).rows,
      isEmpty,
    );

    stubWith((_) => envelope());
    await repository.remove(5);
    expect(await cache.readId(5), isNull);
  });

  test('离线时单笔详情读缓存，缓存里没有才照原样报错', () async {
    await cache.merge([tx(id: 3, bizDate: DateTime(2026, 9, 10))]);

    stubWith((_) => gateway());

    expect(
      await repository.get(3),
      isA<Transaction>().having((t) => t.id, 'id', 3),
    );
    await expectLater(repository.get(99), throwsA(isA<ApiException>()));
  });
}
