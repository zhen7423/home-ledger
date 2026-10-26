import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/baby_vaccine_plan_repository.dart';
import 'package:homeledger/data/repositories/baby_vaccine_record_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端 `BabyVaccinePlanResponse` 一行的形状。`status` 是落库四态、`displayStatus` 是展示态，
/// 两个都给（§4.4.4）：界面按后者上色，而「标记 / 撤销」判的是前者。
/// `plannedDate` / `effectiveDate` 是 2026-10-26 需求②的三层日期（未改期时 effective = due）。
Map<String, dynamic> _planJson({
  int id = 200,
  String status = 'PENDING',
  String displayStatus = 'UPCOMING',
  bool manual = true,
  int? recordId,
  String? plannedDate,
  String? effectiveDate,
}) => {
  'id': id,
  'babyId': 1,
  'vaccineName': '乙肝疫苗',
  'doseNo': '1',
  'dueDate': '2026-09-20',
  'plannedDate': plannedDate,
  'effectiveDate': effectiveDate ?? plannedDate ?? '2026-09-20',
  'status': status,
  'skipReason': null,
  'recordId': recordId,
  'manual': manual,
  'displayStatus': displayStatus,
};

/// 后端 `BabyVaccineRecordResponse` 一行的形状：`givenDate` 是 `yyyy-MM-dd`，
/// `nextDate` 是落库值（只读展示），批号与不良反应在这一层只进不出。
Map<String, dynamic> _recordJson({
  int id = 300,
  int? planId = 200,
  String? nextDate,
}) => {
  'id': id,
  'babyId': 1,
  'planId': planId,
  'vaccineName': '乙肝疫苗',
  'doseNo': '1',
  'givenDate': '2025-09-16',
  'clinic': '社区卫生服务中心',
  'batchNo': null,
  'reaction': null,
  'nextDate': nextDate,
  'remark': null,
};

void main() {
  late ScriptedHttp http;
  late BabyVaccinePlanRepository plans;
  late BabyVaccineRecordRepository records;

  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    final api = ApiClient(
      storage: FakeTokenStorage(),
      adapter: http,
      origin: 'http://test.local',
    );
    plans = BabyVaccinePlanRepository(api: api);
    records = BabyVaccineRecordRepository(api: api);
  }

  setUp(() => stubWith((options) => envelope(data: [])));

  group('应种清单', () {
    test('不传 babyId 时整个家庭那一份，那一项压根不进查询串', () async {
      stubWith((options) => envelope(data: [_planJson()]));

      final rows = await plans.list();

      expect(http.call.path, '/api/v1/baby-vaccine-plans');
      expect(http.call.query, isEmpty);
      // 服务端已经按应种日期升序排好，前端不重排——这一条断的是它原样收下。
      expect(rows.single.dueDate, DateTime(2026, 9, 20));
      expect(rows.single.status, 'PENDING');
      expect(rows.single.displayStatus, 'UPCOMING');
      expect(rows.single.manual, isTrue);

      await plans.list(babyId: 3);
      expect(http.calls.last.query, {'babyId': '3'});
    });

    test('手动加一条自费项只发四个字段，没有跟着生日平移这件事要表达', () async {
      stubWith((options) => envelope(data: _planJson()));

      await plans.createManual(
        ManualPlanDraft(
          babyId: 1,
          vaccineName: '五联疫苗',
          doseNo: '加强针',
          dueDate: DateTime(2026, 10, 1),
        ),
      );

      expect(http.call.method, 'POST');
      expect(http.call.path, '/api/v1/baby-vaccine-plans');
      expect(http.call.body, {
        'babyId': 1,
        'vaccineName': '五联疫苗',
        'doseNo': '加强针',
        'dueDate': '2026-10-01',
      });
    });

    test('标记跳过时带上原因，撤销时不带那个键', () async {
      stubWith((options) => envelope(data: _planJson()));

      await plans.mark(200, 'SKIPPED', '医生建议延后');

      expect(http.call.method, 'PATCH');
      expect(http.call.path, '/api/v1/baby-vaccine-plans/200');
      expect(http.call.body, {'status': 'SKIPPED', 'reason': '医生建议延后'});

      await plans.mark(200, 'PENDING', null);

      // 撤销本来就没有原因可填，带一个 null 进去只是让请求体多一个没有含义的字段。
      // 这一轮 `calls` 里已经有两条，只能看最后那条。
      expect(http.calls.last.body, {'status': 'PENDING'});
      expect((http.calls.last.body! as Map).containsKey('reason'), isFalse);
    });

    test('删除只认 id，字典生成的行能不能删由服务端说了算', () async {
      stubWith((options) => envelope(data: null));

      await plans.remove(200);

      expect(http.call.method, 'DELETE');
      expect(http.call.path, '/api/v1/baby-vaccine-plans/200');
    });

    test('设置计划日期打到 PUT 子路径；清除时发 null 键（2026-10-26 需求②）', () async {
      stubWith((options) => envelope(data: _planJson()));

      await plans.setPlannedDate(200, DateTime(2026, 11, 5));

      expect(http.call.method, 'PUT');
      expect(http.call.path, '/api/v1/baby-vaccine-plans/200/planned-date');
      expect(http.call.body, {'plannedDate': '2026-11-05'});

      await plans.setPlannedDate(200, null);

      expect(http.calls.last.body, {'plannedDate': null});
    });

    test('改过期的行原样接住三层日期：due 原定、planned 用户定、effective 展示', () async {
      stubWith(
        (options) => envelope(
          data: [
            _planJson(
              plannedDate: '2026-10-08',
              effectiveDate: '2026-10-08',
            ),
          ],
        ),
      );

      final rows = await plans.list();

      expect(rows.single.dueDate, DateTime(2026, 9, 20));
      expect(rows.single.plannedDate, DateTime(2026, 10, 8));
      expect(rows.single.effectiveDate, DateTime(2026, 10, 8));
    });
  });

  group('接种记录', () {
    test('清单不重排，`nextDate` 为空是正常状态而不是缺数据', () async {
      stubWith(
        (options) => envelope(data: [_recordJson(), _recordJson(id: 301)]),
      );

      final rows = await records.list();

      expect(http.call.path, '/api/v1/baby-vaccine-records');
      expect(http.call.query, isEmpty);
      expect(rows.first.givenDate, DateTime(2025, 9, 16));
      expect(rows.first.planId, 200);
      // 该疫苗在本宝宝清单里没有未完成剂次时它是空的，界面上不显示这一栏。
      expect(rows.first.nextDate, isNull);
    });

    test('录一条时发七个字段，没指定 planId 就发 null 交给服务端自动匹配', () async {
      stubWith((options) => envelope(data: _recordJson()));

      await records.create(
        VaccineRecordDraft(
          babyId: 1,
          vaccineName: '乙肝疫苗',
          doseNo: '1',
          givenDate: DateTime(2025, 9, 16),
        ),
      );

      expect(http.call.method, 'POST');
      expect(http.call.path, '/api/v1/baby-vaccine-records');
      // `nextDate` 不在 Draft 里（§4.4.4）：服务端把「没给」与「给了 null」当同一件事。
      expect(http.call.body, {
        'babyId': 1,
        'vaccineName': '乙肝疫苗',
        'doseNo': '1',
        'givenDate': '2025-09-16',
        'planId': null,
        'clinic': null,
        'remark': null,
      });
      expect((http.call.body! as Map).containsKey('nextDate'), isFalse);
    });

    test('手动指定 planId 时以它为准，照样原样发出去', () async {
      stubWith((options) => envelope(data: _recordJson(planId: 999)));

      await records.create(
        VaccineRecordDraft(
          babyId: 1,
          vaccineName: '乙肝疫苗',
          doseNo: '2',
          givenDate: DateTime(2026, 3, 16),
          planId: 999,
          clinic: '社区卫生服务中心',
          remark: '补种',
        ),
      );

      expect((http.call.body! as Map)['planId'], 999);
      expect((http.call.body! as Map)['remark'], '补种');
    });

    test('改一条时清空的栏位发 null 键，疫苗名与剂次也在其中', () async {
      stubWith((options) => envelope(data: _recordJson()));

      await records.update(
        300,
        VaccineRecordDraft(
          babyId: 1,
          vaccineName: '五联疫苗',
          doseNo: '1',
          givenDate: DateTime(2025, 9, 16),
          planId: 200,
        ),
      );

      expect(http.call.method, 'PATCH');
      expect(http.call.path, '/api/v1/baby-vaccine-records/300');
      // 服务端先撤销旧绑定、再按新的「疫苗名称 + 剂次」重新匹配（§1.4 第 20 条）。
      expect((http.call.body! as Map)['vaccineName'], '五联疫苗');
      expect((http.call.body! as Map)['planId'], 200);
      expect((http.call.body! as Map).containsKey('clinic'), isTrue);
      expect((http.call.body! as Map)['clinic'], isNull);
    });

    test('删除只认 id，对应应种项退回待接种由服务端办', () async {
      stubWith((options) => envelope(data: null));

      await records.remove(300);

      expect(http.call.method, 'DELETE');
      expect(http.call.path, '/api/v1/baby-vaccine-records/300');
    });
  });
}
