import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/baby_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端 `BabyResponse` 一行的形状：`birthDate` 是 `yyyy-MM-dd`，库里那一列叫 `enabled`
/// 而到这里已经翻成 `archived`，`ageText` 由服务端算好下发（§1.4 第 8 条）。
Map<String, dynamic> _babyJson({
  int id = 1,
  String birthDate = '2025-09-16',
  bool archived = false,
  String? birthWeight = '3.35',
}) => {
  'id': id,
  'name': '小明',
  'gender': 'MALE',
  'birthDate': birthDate,
  'birthHeight': '50.0',
  'birthWeight': birthWeight,
  'remark': null,
  'archived': archived,
  'ageText': '1 岁 0 个月',
};

BabyDraft _draft({DateTime? birthDate, String? birthWeight, String? remark}) =>
    BabyDraft(
      name: '小明',
      gender: 'MALE',
      birthDate: birthDate ?? DateTime(2025, 9, 16),
      birthHeight: '50.0',
      birthWeight: birthWeight,
      remark: remark,
    );

void main() {
  late ScriptedHttp http;
  late BabyRepository repository;

  /// 每个用例自己决定回什么；`http` 留着断言请求。
  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = BabyRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  setUp(() => stubWith((options) => envelope(data: [])));

  test('清单缺省只要未归档的，档案页的「全部」自己传 includeArchived', () async {
    stubWith(
      (options) =>
          envelope(data: [_babyJson(), _babyJson(id: 2, archived: true)]),
    );

    final rows = await repository.list();

    expect(http.call.method, 'GET');
    expect(http.call.path, '/api/v1/babies');
    // 缺省传 false 而不是把键摘掉：这一条是后端那侧「不传即未归档」之外的第二道，
    // 显式发 false 让请求自己说清要的是哪一份。
    expect(http.call.query, {'includeArchived': 'false'});
    expect(rows.map((b) => b.id), [1, 2]);
    expect(rows.first.birthDate, DateTime(2025, 9, 16));
    expect(rows.first.ageText, '1 岁 0 个月');
    expect(rows.last.archived, isTrue);

    await repository.list(includeArchived: true);
    expect(http.calls.last.query, {'includeArchived': 'true'});
  });

  test('建档请求体六个键逐字，日期是不带时刻的 yyyy-MM-dd', () async {
    stubWith((options) => envelope(data: _babyJson()));

    await repository.create(_draft(remark: '早产两周'));

    expect(http.call.method, 'POST');
    expect(http.call.path, '/api/v1/babies');
    // 带时刻的串后端那个 LocalDate 解不开；三个度量用字符串与金额同一条理由（§1.4 第 15 条）。
    expect(http.call.body, {
      'name': '小明',
      'gender': 'MALE',
      'birthDate': '2025-09-16',
      'birthHeight': '50.0',
      'birthWeight': null,
      'remark': '早产两周',
    });
  });

  test('改档案时清空的字段发的是 null 键，而不是把键摘掉', () async {
    stubWith((options) => envelope(data: _babyJson()));

    await repository.update(1, _draft());

    expect(http.call.method, 'PATCH');
    expect(http.call.path, '/api/v1/babies/1');
    // PATCH 在这条链路上是整份覆盖：漏键等于「保留旧值」，用户把出生体重删空了就删不掉。
    expect((http.call.body! as Map).containsKey('birthWeight'), isTrue);
    expect((http.call.body! as Map)['birthWeight'], isNull);
    expect((http.call.body! as Map)['remark'], isNull);
  });

  test('归档与恢复共用一条 PATCH，不带请求体也不带方向', () async {
    stubWith((options) => envelope(data: _babyJson(archived: true)));

    await repository.toggle(1);

    // 后端那一条按当前的 `enabled` 自己判方向，所以这里没有一个 `bool archived` 参数：
    // 按钮文案由界面上的 `Baby.archived` 出，契约里也没有第二条开关端点。
    expect(http.call.method, 'PATCH');
    expect(http.call.path, '/api/v1/babies/1/archive');
    expect(http.call.body, isNull);
    expect(http.call.query, isEmpty);
  });

  test('删除只认 id，软删与归档在后端是两件事', () async {
    stubWith((options) => envelope(data: null));

    await repository.remove(1);

    expect(http.call.method, 'DELETE');
    expect(http.call.path, '/api/v1/babies/1');
  });

  test('传档案照片：multipart POST，part 名叫 file', () async {
    stubWith((options) => envelope(data: _babyJson()));

    await repository.uploadPhoto(1, Uint8List.fromList([1, 2, 3]), 'baby.png');

    expect(http.call.method, 'POST');
    expect(http.call.path, '/api/v1/babies/1/photo');
    final form = http.call.body! as FormData;
    expect(form.files, hasLength(1));
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'baby.png');
  });

  test('清档案照片：DELETE 同一条子路径，不带请求体', () async {
    stubWith((options) => envelope(data: _babyJson()));

    await repository.clearPhoto(1);

    expect(http.call.method, 'DELETE');
    expect(http.call.path, '/api/v1/babies/1/photo');
    expect(http.call.body, isNull);
  });
}
