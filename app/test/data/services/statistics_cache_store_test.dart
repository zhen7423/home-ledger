import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/services/statistics_cache_store.dart';

import '../../support/s5_fixtures.dart';

/// 单槽的统计快照。这个 store 没有 `clock` 注入口，`savedAt` 用的是 `DateTime.now()`，
/// 所以只断言它非空、不断言具体值。
void main() {
  late Directory root;
  late StatisticsCacheStore store;

  const query = StatisticsQuery(startDate: '2026-09-01', endDate: '2026-09-14');
  const other = StatisticsQuery(startDate: '2026-08-01', endDate: '2026-08-31');

  Future<void> putBody(Map<String, dynamic> body) async {
    await File(
      '${root.path}/stats-finance.json',
    ).writeAsString(jsonEncode(body));
  }

  Future<void> putText(String text) async {
    await File('${root.path}/stats-finance.json').writeAsString(text);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('stats_cache');
    store = StatisticsCacheStore(directoryResolver: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('写进去的条件、概览、五图原样读回来', () async {
    await store.write(query: query, summary: summary(), overview: overview());

    final cached = await store.read();
    expect(cached?.query, query);
    expect(cached?.summary, summary());
    expect(cached?.overview, overview());
    expect(cached?.savedAt, isNotNull);
  });

  test('换一套条件再写，旧的整份被替掉', () async {
    await store.write(query: query, summary: summary(), overview: overview());
    await store.write(
      query: other,
      summary: summary(expense: '999.00'),
      overview: overview(),
    );

    final cached = await store.read();
    expect(cached?.query, other);
    expect(cached?.summary.expense, '999.00');
  });

  test('没写过时读回 null，且不落一个空文件', () async {
    expect(await store.read(), isNull);

    expect(File('${root.path}/stats-finance.json').existsSync(), isFalse);
  });

  test('顶层不是 JSON 对象时当作没有快照', () async {
    await putText('[');

    expect(await store.read(), isNull);
  });

  test('缺 overview 键时当作没有快照：半份统计画出来是错的那份', () async {
    await putBody({
      'savedAt': DateTime(2026, 9, 14).toIso8601String(),
      'query': query.toJson(),
      'summary': summary().toJson(),
    });

    expect(await store.read(), isNull);
  });

  test('savedAt 不是能解析的串时当作没有快照', () async {
    await putBody({
      'savedAt': '昨天',
      'query': query.toJson(),
      'summary': summary().toJson(),
      'overview': overview().toJson(),
    });

    expect(await store.read(), isNull);
  });

  test('写完只留目标文件，中间那份 .tmp 已经 rename 走了', () async {
    await store.write(query: query, summary: summary(), overview: overview());

    expect(root.listSync().map((e) => e.uri.pathSegments.last), [
      'stats-finance.json',
    ]);
  });

  test('clear() 删掉快照，空目录上再调一次也不算失败', () async {
    await store.write(query: query, summary: summary(), overview: overview());

    await store.clear();
    expect(await store.read(), isNull);

    await store.clear();
  });
}
