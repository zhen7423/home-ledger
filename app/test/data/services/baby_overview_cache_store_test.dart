import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/services/baby_overview_cache_store.dart';

import '../../support/s7_fixtures.dart';

/// 单槽的宝宝总览快照。这个 store 没有 `clock` 注入口，`savedAt` 用的是 `DateTime.now()`，
/// 所以只断言它非空、不断言具体值。信封里躺着的是**成品模型**而不是响应原文，
/// 因此「读回来的是同一份」这条断言同时验掉了序列化的那一半。
///
/// 与猫那一份的关键分别：`babies` 是必填的那一段，少它就是这一份坏了——一个宝宝都还没建时
/// 空的是那张表，而不是缺这个键。
void main() {
  late Directory root;
  late BabyOverviewCacheStore store;

  const file = 'baby-overview.json';

  Future<void> putText(String text) async {
    await File('${root.path}/$file').writeAsString(text);
  }

  Future<void> putBody(Map<String, dynamic> body) async {
    await putText(jsonEncode(body));
  }

  String savedAtText() => DateTime(2026, 9, 14).toIso8601String();

  setUp(() async {
    root = await Directory.systemTemp.createTemp('baby_overview_cache');
    store = BabyOverviewCacheStore(directoryResolver: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('档案、最新体格、疫苗待办原样读回来', () async {
    await store.write(
      babies: [babyFixture()],
      latestGrowth: growthStatisticsFixture(),
      vaccineTodo: vaccineStatisticsFixture(),
    );

    final cached = await store.read();
    expect(cached?.babies, [babyFixture()]);
    expect(cached?.latestGrowth, growthStatisticsFixture());
    expect(cached?.vaccineTodo, vaccineStatisticsFixture());
    expect(cached?.savedAt, isNotNull);
  });

  test('换一批再写，旧的整份被替掉', () async {
    await store.write(babies: [babyFixture(name: '旧名')]);
    await store.write(babies: [babyFixture(name: '新名')]);

    expect((await store.read())?.babies.single.name, '新名');
  });

  test('一个宝宝都没有时后两段是 null，读回来仍是一份快照', () async {
    // 「还没有宝宝」与「数据坏了」是两件事：前者离线要显示空态，后者离线要显示错误态。
    // 建档之前统计那两条端点也回空表，所以写的时候后两段本就是 null。
    await store.write(babies: const []);

    final cached = await store.read();
    expect(cached, isNotNull);
    expect(cached?.babies, isEmpty);
    expect(cached?.latestGrowth, isNull);
    expect(cached?.vaccineTodo, isNull);
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

  test('缺 babies 键时当作没有快照：半份总览画出来是错的那份', () async {
    await putBody({'savedAt': savedAtText(), 'latestGrowth': null});

    expect(await store.read(), isNull);
  });

  test('savedAt 不是能解析的串时当作没有快照', () async {
    await putBody({
      'savedAt': '昨天',
      'babies': [babyFixture().toJson()],
      'latestGrowth': null,
      'vaccineTodo': null,
    });

    expect(await store.read(), isNull);
  });

  test('写完只留目标文件，中间那份 .tmp 已经 rename 走了', () async {
    await store.write(babies: const []);

    expect(root.listSync().map((e) => e.uri.pathSegments.last), [file]);
  });

  test('clear() 删掉快照，空目录上再调一次也不算失败', () async {
    await store.write(babies: [babyFixture()]);

    await store.clear();
    expect(await store.read(), isNull);

    await store.clear();
  });
}
