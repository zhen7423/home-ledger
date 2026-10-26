import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/services/cat_overview_cache_store.dart';

import '../../support/s6_fixtures.dart';

/// 单槽的猫咪总览快照。这个 store 没有 `clock` 注入口，`savedAt` 用的是 `DateTime.now()`，
/// 所以只断言它非空、不断言具体值。信封里躺着的是**成品模型**而不是响应原文，
/// 因此「读回来的是同一份」这条断言同时验掉了序列化的那一半。
void main() {
  late Directory root;
  late CatOverviewCacheStore store;

  const file = 'cat-overview.json';

  Future<void> putText(String text) async {
    await File('${root.path}/$file').writeAsString(text);
  }

  Future<void> putBody(Map<String, dynamic> body) async {
    await putText(jsonEncode(body));
  }

  String savedAtText() => DateTime(2026, 9, 14).toIso8601String();

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cat_overview_cache');
    store = CatOverviewCacheStore(directoryResolver: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('猫、当前袋、推算、倒计时原样读回来', () async {
    final currentBag = bagFixture(
      current: true,
      usageDays: null,
      dailyAverage: null,
    );
    await store.write(
      cats: [catFixture()],
      bag: currentBag,
      estimate: estimateFixture(),
      dueCountdown: [countdownFixture(daysToDue: 3)],
    );

    final cached = await store.read();
    expect(cached?.cats, [catFixture()]);
    expect(cached?.bag, currentBag);
    expect(cached?.estimate, estimateFixture());
    expect(cached?.dueCountdown.single.daysToDue, 3);
    expect(cached?.savedAt, isNotNull);
  });

  test('换一袋再写，旧的整份被替掉', () async {
    await store.write(
      cats: [catFixture()],
      bag: bagFixture(brand: '旧牌'),
      estimate: null,
      dueCountdown: const [],
    );
    await store.write(
      cats: [catFixture()],
      bag: bagFixture(brand: '新牌'),
      estimate: null,
      dueCountdown: const [],
    );

    expect((await store.read())?.bag?.brand, '新牌');
  });

  test('一袋都没有时两栏都是 null，读回来仍是一份快照', () async {
    // 「没有袋」与「数据坏了」是两件事：前者离线要显示空态，后者离线要显示错误态。
    // 写的时候这两栏就是 null，所以这一条验的是读那一侧不把 null 当成缺字段。
    await store.write(
      cats: [catFixture()],
      bag: null,
      estimate: null,
      dueCountdown: const [],
    );

    final cached = await store.read();
    expect(cached, isNotNull);
    expect(cached?.bag, isNull);
    expect(cached?.estimate, isNull);
    expect(cached?.cats, [catFixture()]);
  });

  test('没写过时读回 null，且不落一个空文件', () async {
    expect(await store.read(), isNull);
    expect(File('${root.path}/$file').existsSync(), isFalse);
  });

  test('坏 JSON 与顶层不是对象都当作没有快照', () async {
    await putText('{bad json');
    expect(await store.read(), isNull);

    await putText('[');
    expect(await store.read(), isNull);
  });

  test('缺 cats 键时当作没有快照：半份总览画出来是错的那份', () async {
    await putBody({'savedAt': savedAtText()});

    expect(await store.read(), isNull);
  });

  test('savedAt 不是能解析的串时当作没有快照', () async {
    await putBody({
      'savedAt': '昨天',
      'cats': [catFixture().toJson()],
      'bag': null,
      'estimate': null,
      'dueCountdown': <Map<String, dynamic>>[],
    });

    expect(await store.read(), isNull);
  });

  test('写完只留目标文件，中间那份 .tmp 已经 rename 走了', () async {
    await store.write(
      cats: const [],
      bag: null,
      estimate: null,
      dueCountdown: const [],
    );

    expect(root.listSync().map((e) => e.uri.pathSegments.last), [file]);
  });

  test('clear() 删掉快照，空目录上再调一次也不算失败', () async {
    await store.write(
      cats: [catFixture()],
      bag: null,
      estimate: null,
      dueCountdown: const [],
    );

    await store.clear();
    expect(await store.read(), isNull);

    await store.clear();
  });
}
