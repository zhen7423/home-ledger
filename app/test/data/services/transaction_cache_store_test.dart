import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/transaction.dart';
import 'package:homeledger/data/services/transaction_cache_store.dart';

import '../../support/finance_fixtures.dart';

/// 按月分文件的流水缓存。真落盘，所以全是普通 `test()`：
/// 用 `testWidgets` 的话假时钟推不动真实的文件 IO，S4 在那条路上白等了七分钟。
void main() {
  late Directory root;
  late TransactionCacheStore store;
  late DateTime now;

  /// 目录里 `tx-` 开头的文件名，排过序好比对。
  List<String> cachedNames() =>
      root
          .listSync()
          .map((entity) => entity.uri.pathSegments.last)
          .where((name) => name.startsWith('tx-'))
          .toList()
        ..sort();

  /// 手工摆一份月份文件出去，用来造「窗口外的月份」「写崩留下的垃圾」这些现场。
  Future<void> putFile(String name, {required Transaction row}) async {
    await File('${root.path}/$name').writeAsString(
      jsonEncode({
        'savedAt': DateTime(2026, 6, 1).toIso8601String(),
        'items': [row.toJson()],
      }),
    );
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tx_cache');
    now = DateTime(2026, 9, 14);
    store = TransactionCacheStore(
      directoryResolver: () async => root,
      clock: () => now,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('合并进去的流水原样读回来', () async {
    await store.merge([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);

    final rows = (await store.readRange(null, null)).rows;
    expect(rows.single.id, 1);
  });

  test('同 id 覆盖：编辑过一笔之后缓存里不留改前的样子', () async {
    await store.merge([
      tx(id: 1, bizDate: DateTime(2026, 9, 10), amount: '10.00'),
    ]);
    await store.merge([
      tx(id: 1, bizDate: DateTime(2026, 9, 10), amount: '20.00'),
    ]);

    final rows = (await store.readRange(null, null)).rows;
    expect(rows.single.amount, '20.00');
  });

  test('跨月翻页时按自然月一个文件', () async {
    await store.merge([
      tx(id: 1, bizDate: DateTime(2026, 9, 10)),
      tx(id: 2, bizDate: DateTime(2026, 8, 20)),
    ]);

    expect(cachedNames(), ['tx-2026-08.json', 'tx-2026-09.json']);
  });

  test('区间没碰到的月份压根不读：8 月那份坏了也不影响 9 月', () async {
    await store.merge([
      tx(id: 1, bizDate: DateTime(2026, 9, 10)),
      tx(id: 2, bizDate: DateTime(2026, 8, 20)),
    ]);
    await File('${root.path}/tx-2026-08.json').writeAsString('{坏掉的');

    final rows = (await store.readRange(
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 30),
    )).rows;
    expect(rows.map((row) => row.id), [1]);
  });

  test('savedAt 取本次读到的几份里最早那个写入时刻', () async {
    now = DateTime(2026, 9, 1, 8);
    await store.merge([tx(id: 2, bizDate: DateTime(2026, 8, 20))]);
    now = DateTime(2026, 9, 14, 8);
    await store.merge([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);

    expect(
      (await store.readRange(null, null)).savedAt,
      DateTime(2026, 9, 1, 8),
    );
  });

  test('三个月窗口一次读全，交出去是日期升序', () async {
    await store.merge([
      tx(id: 3, bizDate: DateTime(2026, 9, 10)),
      tx(id: 2, bizDate: DateTime(2026, 8, 20)),
      tx(id: 1, bizDate: DateTime(2026, 7, 5)),
    ]);

    // 降序是仓库在 page() 里排的（F4⑦），这一层只管把窗口内的月份拼齐。
    final rows = (await store.readRange(null, null)).rows;
    expect(rows.map((row) => row.id), [1, 2, 3]);
  });

  test('窗口之外的月份读不到', () async {
    await putFile(
      'tx-2026-05.json',
      row: tx(id: 9, bizDate: DateTime(2026, 5, 20)),
    );

    final result = await store.readRange(null, null);
    expect(result.rows, isEmpty);
    expect(result.savedAt, isNull);
  });

  test('淘汰：写一次就把掉出窗口的那个月删掉', () async {
    await putFile(
      'tx-2026-05.json',
      row: tx(id: 9, bizDate: DateTime(2026, 5, 20)),
    );

    await store.merge([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);

    expect(cachedNames(), ['tx-2026-09.json']);
  });

  test('认不出月份的 tx- 文件一律当垃圾删', () async {
    await File('${root.path}/tx-垃圾.json').writeAsString('{}');
    await File('${root.path}/tx-2026-09.json.tmp').writeAsString('{}');

    await store.merge([tx(id: 1, bizDate: DateTime(2026, 8, 20))]);

    // .tmp 以 tx- 开头所以进得了待删清单，但它匹配不上月份正则，跟着一起走。
    expect(cachedNames(), ['tx-2026-08.json']);
  });

  test('removeId 之后 savedAt 不动：删掉一条不等于刚刚同步过', () async {
    now = DateTime(2026, 9, 1);
    await store.merge([
      tx(id: 1, bizDate: DateTime(2026, 9, 10)),
      tx(id: 2, bizDate: DateTime(2026, 9, 11)),
    ]);
    await store.removeId(1);
    now = DateTime(2026, 9, 14);

    final result = await store.readRange(null, null);
    expect(result.rows.map((row) => row.id), [2]);
    expect(result.savedAt, DateTime(2026, 9, 1));
  });

  test('readId 命中给那条，不命中给 null 而不是抛', () async {
    await store.merge([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);

    expect((await store.readId(1))?.id, 1);
    expect(await store.readId(999), isNull);
  });

  test('clear() 带走所有 tx- 文件，空目录上再调一次也不算失败', () async {
    await store.merge([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);

    await store.clear();
    expect(cachedNames(), isEmpty);

    await store.clear();
  });

  test('空列表一个文件都不建，连淘汰都不跑', () async {
    await store.merge(const []);

    expect(root.listSync(), isEmpty);
  });
}
