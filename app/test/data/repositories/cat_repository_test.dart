import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/cat_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端 `CatResponse` 一行的形状：`birthday` 是 `yyyy-MM-dd`，`createdAt` 带时刻，
/// 库里那一列叫 `enabled` 而到这里已经翻成 `archived`。
Map<String, dynamic> _catJson({
  int id = 1,
  String? birthday = '2024-03-17',
  bool archived = false,
}) => {
  'id': id,
  'name': '咪咪',
  'gender': 'FEMALE',
  'birthday': birthday,
  'birthdayEstimated': birthday != null,
  'breed': '中华田园猫',
  'weightKg': '4.25',
  'neutered': 'YES',
  'remark': null,
  'archived': archived,
  'createdAt': '2026-09-01T09:30:00',
};

CatDraft _draft({DateTime? birthday, String? remark}) => CatDraft(
  name: '咪咪',
  gender: 'FEMALE',
  birthday: birthday,
  birthdayEstimated: false,
  breed: '中华田园猫',
  weightKg: '4.25',
  neutered: 'YES',
  remark: remark,
);

void main() {
  late ScriptedHttp http;
  late CatRepository repository;

  /// 每个用例自己决定回什么；`http` 留着断言请求。
  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = CatRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  setUp(() => stubWith((options) => envelope(data: [])));

  test('清单缺省只要未归档的，归档那一屏自己传 includeArchived', () async {
    stubWith(
      (options) => envelope(
        data: [
          _catJson(),
          _catJson(id: 2, birthday: null, archived: true),
        ],
      ),
    );

    final rows = await repository.list();

    expect(http.call.method, 'GET');
    expect(http.call.path, '/api/v1/cats');
    expect(http.call.query, {'includeArchived': 'false'});
    expect(rows.map((c) => c.id), [1, 2]);
    expect(rows.first.birthday, DateTime(2024, 3, 17));
    expect(rows.first.createdAt, DateTime(2026, 9, 1, 9, 30));
    expect(rows.last.archived, isTrue);
    expect(rows.last.birthday, isNull);

    await repository.list(includeArchived: true);
    expect(http.calls.last.query, {'includeArchived': 'true'});
  });

  test('建档请求体九个键逐字，日期是不带时刻的 yyyy-MM-dd', () async {
    stubWith((options) => envelope(data: _catJson()));

    await repository.create(
      _draft(birthday: DateTime(2024, 3, 17), remark: '领养来的'),
    );

    expect(http.call.method, 'POST');
    expect(http.call.path, '/api/v1/cats');
    // 带时刻的串后端那个 LocalDate 解不开，这条与 `weightKg` 用字符串都是同一类口径。
    expect(http.call.body, {
      'name': '咪咪',
      'gender': 'FEMALE',
      'birthday': '2024-03-17',
      'birthdayEstimated': false,
      'breed': '中华田园猫',
      'weightKg': '4.25',
      'neutered': 'YES',
      'remark': '领养来的',
    });
  });

  test('改档案时清空生日发的是 null 键，而不是把这个键摘掉', () async {
    stubWith((options) => envelope(data: _catJson(birthday: null)));

    await repository.update(1, _draft());

    expect(http.call.method, 'PATCH');
    expect(http.call.path, '/api/v1/cats/1');
    // PATCH 在这条链路上是整份表单覆盖：漏键等于「保留旧值」，用户删掉的东西就删不掉了。
    expect((http.call.body! as Map).containsKey('birthday'), isTrue);
    expect((http.call.body! as Map)['birthday'], isNull);
    expect((http.call.body! as Map)['remark'], isNull);
  });

  test('归档与恢复共用一条 PATCH，不带请求体也不带方向', () async {
    stubWith((options) => envelope(data: _catJson(archived: true)));

    await repository.toggle(1);

    // 后端那一条按当前的 `enabled` 自己判方向，所以这里没有一个 `bool archived` 参数：
    // 按钮文案由界面上的 `Cat.archived` 出，契约里也没有第二条开关端点。
    expect(http.call.method, 'PATCH');
    expect(http.call.path, '/api/v1/cats/1/archive');
    expect(http.call.body, isNull);
    expect(http.call.query, isEmpty);
  });

  test('删除只认 id，软删与归档在后端是两件事', () async {
    stubWith((options) => envelope(data: null));

    await repository.remove(1);

    expect(http.call.method, 'DELETE');
    expect(http.call.path, '/api/v1/cats/1');
  });

  test('传档案照片：multipart POST，part 名叫 file，字节原样带上', () async {
    stubWith((options) => envelope(data: _catJson()));

    await repository.uploadPhoto(1, Uint8List.fromList([1, 2, 3]), 'meow.jpg');

    expect(http.call.method, 'POST');
    expect(http.call.path, '/api/v1/cats/1/photo');
    // dio 在适配器这一层仍留着原始 FormData 对象，正好断 part 形状
    final form = http.call.body! as FormData;
    expect(form.files, hasLength(1));
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'meow.jpg');
  });

  test('清档案照片：DELETE 同一条子路径，不带请求体', () async {
    stubWith((options) => envelope(data: null));

    await repository.clearPhoto(1);

    expect(http.call.method, 'DELETE');
    expect(http.call.path, '/api/v1/cats/1/photo');
    expect(http.call.body, isNull);
  });
}
