import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/baby_growth_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端 `BabyGrowthResponse` 一行的形状：三个度量的名字带单位后缀（`heightCm`），
/// 值是不带零归一化的十进制串，`deltaFromPrevious` 是读时派生出来的那一段。
Map<String, dynamic> _growthJson({
  int id = 100,
  int babyId = 1,
  String measureDate = '2026-09-10',
  Map<String, dynamic>? delta = const {
    'days': 30,
    'heightCm': '1.5',
    'weightKg': '0.40',
    'headCm': null,
  },
}) => {
  'id': id,
  'babyId': babyId,
  'measureDate': measureDate,
  'heightCm': '76.5',
  'weightKg': '9.80',
  'headCm': null,
  'remark': null,
  'deltaFromPrevious': delta,
};

BabyGrowthDraft _draft({DateTime? measureDate, String? weightKg}) =>
    BabyGrowthDraft(
      babyId: 1,
      measureDate: measureDate ?? DateTime(2026, 9, 10),
      heightCm: '76.5',
      weightKg: weightKg,
      headCm: null,
      remark: null,
    );

void main() {
  late ScriptedHttp http;
  late BabyGrowthRepository repository;

  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = BabyGrowthRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  setUp(() => stubWith((options) => envelope(data: [])));

  test('不传 babyId 时整个家庭的清单，那一项压根不进查询串', () async {
    stubWith((options) => envelope(data: [_growthJson()]));

    final rows = await repository.list();

    expect(http.call.path, '/api/v1/baby-growths');
    // 传 null 表示「没选这一项筛选」，留在 map 里会被拼成 `?babyId=` 真发出去。
    expect(http.call.query, isEmpty);
    expect(rows.single.measureDate, DateTime(2026, 9, 10));
    expect(rows.single.heightCm, '76.5');

    await repository.list(babyId: 3);
    expect(http.calls.last.query, {'babyId': '3'});
  });

  test('「较上一次」那一段原样解出来：三项各自可空，「没量那一项」是 null 不是 0', () async {
    stubWith((options) => envelope(data: [_growthJson()]));

    final delta = (await repository.list()).single.deltaFromPrevious;

    expect(delta?.days, 30);
    expect(delta?.heightCm, '1.5');
    expect(delta?.weightKg, '0.40');
    // 界面上「较上次没量头围」整段不显示，而「较上次头围没变」是 '0'——两者靠 null 区分（§4.4.2）。
    expect(delta?.headCm, isNull);
  });

  test('首条记录没有「上一次」，整个键是 null', () async {
    stubWith((options) => envelope(data: [_growthJson(delta: null)]));

    expect((await repository.list()).single.deltaFromPrevious, isNull);
  });

  test('记一次的请求体六个键逐字，日期是不带时刻的 yyyy-MM-dd', () async {
    stubWith((options) => envelope(data: _growthJson()));

    await repository.create(_draft(weightKg: '9.80'));

    expect(http.call.method, 'POST');
    expect(http.call.path, '/api/v1/baby-growths');
    // 三个度量是字符串而不是 double：解析成 double 再格式化回去会在「3.50」与「3.5」之间横跳。
    expect(http.call.body, {
      'babyId': 1,
      'measureDate': '2026-09-10',
      'heightCm': '76.5',
      'weightKg': '9.80',
      'headCm': null,
      'remark': null,
    });
  });

  test('改一条时宝宝也照发，且清空的那一格发 null 键而不是把键摘掉', () async {
    stubWith((options) => envelope(data: _growthJson()));

    await repository.update(100, _draft());

    expect(http.call.method, 'PATCH');
    expect(http.call.path, '/api/v1/baby-growths/100');
    // PATCH 是整份覆盖：漏键等于「保留旧值」，用户把体重那一格删干净了就该真的没有体重。
    expect((http.call.body! as Map).containsKey('weightKg'), isTrue);
    expect((http.call.body! as Map)['weightKg'], isNull);
    // 记录可以改到另一个宝宝头上，所以宝宝选择器那一格一直在，漏掉它反而成了「这一格不参与保存」。
    expect((http.call.body! as Map)['babyId'], 1);
  });

  test('删除只认 id', () async {
    stubWith((options) => envelope(data: null));

    await repository.remove(100);

    expect(http.call.method, 'DELETE');
    expect(http.call.path, '/api/v1/baby-growths/100');
  });
}
