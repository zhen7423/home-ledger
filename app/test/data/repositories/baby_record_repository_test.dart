import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/baby_record_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端 `BabyMilestoneResponse` 一行的形状：只有 `occurDate` 一个日期列，
/// 内置常用项与自由输入落的是同一个 `title`（§4.4.5）。
Map<String, dynamic> _milestoneJson({int id = 400, String? description}) => {
  'id': id,
  'babyId': 1,
  'occurDate': '2026-01-08',
  'title': '第一次抬头',
  'description': description,
};

/// 后端 `BabyMedicalResponse` 一行的形状：`costAmount` 是十进制串（§1.4 第 15 条），
/// 它只是记录、不带任何财务语义。
Map<String, dynamic> _medicalJson({
  int id = 500,
  String? costAmount = '128.50',
}) => {
  'id': id,
  'babyId': 1,
  'visitDate': '2026-08-03',
  'hospital': '市妇幼保健院',
  'department': '儿内科',
  'diagnosis': '上呼吸道感染',
  'medicine': '小儿氨酚黄那敏颗粒',
  'costAmount': costAmount,
  'remark': null,
};

void main() {
  late ScriptedHttp http;
  late BabyRecordRepository repository;

  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = BabyRecordRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  setUp(() => stubWith((options) => envelope(data: [])));

  group('里程碑', () {
    test('清单不重排，服务端已经按发生日期升序排好', () async {
      stubWith((options) => envelope(data: [_milestoneJson()]));

      final rows = await repository.listMilestones();

      expect(http.call.path, '/api/v1/baby-milestones');
      expect(http.call.query, isEmpty);
      expect(rows.single.occurDate, DateTime(2026, 1, 8));
      expect(rows.single.title, '第一次抬头');

      await repository.listMilestones(babyId: 3);
      expect(http.calls.last.query, {'babyId': '3'});
    });

    test('新增请求体四个键逐字，日期是不带时刻的 yyyy-MM-dd', () async {
      stubWith((options) => envelope(data: _milestoneJson()));

      await repository.createMilestone(
        MilestoneDraft(
          babyId: 1,
          occurDate: DateTime(2026, 1, 8),
          title: '第一次抬头',
          description: '趴在床上抬了十几秒',
        ),
      );

      expect(http.call.method, 'POST');
      expect(http.call.path, '/api/v1/baby-milestones');
      // `title` 没有字典：内置常用项与自由输入发出去的是同一个键（§4.4.5）。
      expect(http.call.body, {
        'babyId': 1,
        'occurDate': '2026-01-08',
        'title': '第一次抬头',
        'description': '趴在床上抬了十几秒',
      });
    });

    test('改一条时描述清空发 null 键；宝宝照发但服务端会忽略它', () async {
      stubWith((options) => envelope(data: _milestoneJson()));

      await repository.updateMilestone(
        400,
        MilestoneDraft(
          babyId: 1,
          occurDate: DateTime(2026, 1, 8),
          title: '第一次抬头',
        ),
      );

      expect(http.call.method, 'PATCH');
      expect(http.call.path, '/api/v1/baby-milestones/400');
      expect((http.call.body! as Map).containsKey('description'), isTrue);
      expect((http.call.body! as Map)['description'], isNull);
      // 后端那条 DTO 里没有 `babyId`、多传的被忽略，但整份覆盖的表单里宝宝选择器一直在。
      expect((http.call.body! as Map)['babyId'], 1);
    });

    test('删除只认 id', () async {
      stubWith((options) => envelope(data: null));

      await repository.removeMilestone(400);

      expect(http.call.method, 'DELETE');
      expect(http.call.path, '/api/v1/baby-milestones/400');
    });
  });

  group('就诊记录', () {
    test('清单不重排，服务端按就诊日期降序（就诊是回看）', () async {
      stubWith((options) => envelope(data: [_medicalJson()]));

      final rows = await repository.listMedicals();

      expect(http.call.path, '/api/v1/baby-medicals');
      expect(http.call.query, isEmpty);
      expect(rows.single.visitDate, DateTime(2026, 8, 3));
      expect(rows.single.costAmount, '128.50');
    });

    test('新增请求体八个键逐字，除宝宝与就诊日期外全是选填', () async {
      stubWith((options) => envelope(data: _medicalJson()));

      await repository.createMedical(
        MedicalDraft(
          babyId: 1,
          visitDate: DateTime(2026, 8, 3),
          hospital: '市妇幼保健院',
          costAmount: '128.50',
        ),
      );

      expect(http.call.method, 'POST');
      expect(http.call.path, '/api/v1/baby-medicals');
      // 金额按字符串原样发出，与流水同一条理由；它与记账没有任何联动（§4.4.5）。
      expect(http.call.body, {
        'babyId': 1,
        'visitDate': '2026-08-03',
        'hospital': '市妇幼保健院',
        'department': null,
        'diagnosis': null,
        'medicine': null,
        'costAmount': '128.50',
        'remark': null,
      });
    });

    test('改一条时清空的栏位发 null 键而不是把键摘掉', () async {
      stubWith((options) => envelope(data: _medicalJson()));

      await repository.updateMedical(
        500,
        MedicalDraft(babyId: 1, visitDate: DateTime(2026, 8, 3)),
      );

      expect(http.call.method, 'PATCH');
      expect(http.call.path, '/api/v1/baby-medicals/500');
      for (final key in [
        'hospital',
        'department',
        'diagnosis',
        'medicine',
        'costAmount',
        'remark',
      ]) {
        expect((http.call.body! as Map).containsKey(key), isTrue, reason: key);
        expect((http.call.body! as Map)[key], isNull, reason: key);
      }
    });

    test('删除只认 id', () async {
      stubWith((options) => envelope(data: null));

      await repository.removeMedical(500);

      expect(http.call.method, 'DELETE');
      expect(http.call.path, '/api/v1/baby-medicals/500');
    });
  });
}
