import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/category.dart';
import 'package:homeledger/data/models/payment_account.dart';
import 'package:homeledger/data/services/dict_cache_store.dart';

const Category _dining = Category(
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
);

const PaymentAccount _cash = PaymentAccount(
  id: 7,
  name: '现金',
  sortNo: 1,
  isDefault: true,
  enabled: true,
);

void main() {
  late Directory root;
  late DictCacheStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dict_cache_store');
    store = DictCacheStore(directoryResolver: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('写进去的类别与支付方式原样读回来', () async {
    await store.writeCategories([_dining]);
    await store.writeAccounts([_cash]);

    expect(await store.readCategories(), [_dining]);
    expect(await store.readAccounts(), [_cash]);
  });

  test('整份覆盖：第二次写的结果替掉第一次，不追加', () async {
    await store.writeAccounts([_cash]);
    await store.writeAccounts([
      _cash,
      const PaymentAccount(
        id: 8,
        name: '微信',
        sortNo: 2,
        isDefault: false,
        enabled: true,
      ),
    ]);

    final accounts = await store.readAccounts();
    expect(accounts.map((a) => a.id), [7, 8]);
  });

  test('一份写盘不碰另一份', () async {
    await store.writeCategories([_dining]);
    await store.writeAccounts([_cash]);
    await store.writeCategories(const []);

    expect(await store.readCategories(), isEmpty);
    expect(await store.readAccounts(), [_cash]);
  });

  test('还没写过时读出空列表', () async {
    expect(await store.readCategories(), isEmpty);
    expect(await store.readAccounts(), isEmpty);
  });

  test('文件不存在时压根不创建', () async {
    await store.readCategories();

    expect(File('${root.path}/dict-categories.json').existsSync(), isFalse);
  });

  test('坏 JSON、缺 items、条目不是对象，一律当作没有缓存而不是抛出来', () async {
    await File('${root.path}/dict-categories.json').writeAsString('{不是JSON');
    expect(await store.readCategories(), isEmpty);

    await File(
      '${root.path}/dict-categories.json',
    ).writeAsString('{"savedAt":"x"}');
    expect(await store.readCategories(), isEmpty);

    await File(
      '${root.path}/dict-categories.json',
    ).writeAsString('{"savedAt":"x","items":[null,3]}');
    expect(await store.readCategories(), isEmpty);
  });

  test('字段对不上的旧缓存同样当作没有', () async {
    await File(
      '${root.path}/dict-accounts.json',
    ).writeAsString('{"savedAt":"x","items":[{"id":"不可能是字符串"}]}');

    expect(await store.readAccounts(), isEmpty);
  });

  test('写完只留下目标文件，中间那份 .tmp 已经 rename 走了', () async {
    await store.writeCategories([_dining]);

    final names = root
        .listSync()
        .map((entity) => entity.uri.pathSegments.last)
        .toList();
    expect(names, ['dict-categories.json']);
  });

  test('clear() 两份都清空，之后再读是空', () async {
    await store.writeCategories([_dining]);
    await store.writeAccounts([_cash]);

    await store.clear();

    expect(await store.readCategories(), isEmpty);
    expect(await store.readAccounts(), isEmpty);
  });

  test('目录还没有缓存文件时 clear() 不算失败', () async {
    await store.clear();

    expect(root.listSync(), isEmpty);
  });
}
