import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/period_value.dart';
import 'package:homeledger/data/repositories/recurring_rule_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端 `RecurringRuleResponse` 的形状：日期是 `yyyy-MM-dd` 与 `LocalDateTime`，
/// 周期参数是一个扁平 JSON 对象，名称由服务端实时解析后带在行上。
Map<String, dynamic> _ruleJson({int id = 7, String? endDate}) => {
  'id': id,
  'name': '房租',
  'type': 'EXPENSE',
  'amount': '3000.00',
  'categoryId': 3,
  'categoryName': '居住',
  'subCategoryId': null,
  'subCategoryName': null,
  'accountId': 1,
  'accountName': '微信',
  'periodType': 'MONTHLY',
  'periodValue': {
    'daysOfMonth': [1, 15],
  },
  'startDate': '2026-09-01',
  'endDate': endDate,
  'enabled': true,
  'createdAt': '2026-09-01T09:30:00',
  'updatedAt': '2026-09-10T20:15:30',
};

/// 一次提交的最小草稿。字段默认值照「每月 1 日房租」给，用例只覆盖自己要验的那一项。
RecurringRuleDraft _draft({DateTime? endDate}) => RecurringRuleDraft(
  name: '房租',
  amount: '3000.00',
  categoryId: 3,
  accountId: 1,
  periodType: 'MONTHLY',
  periodValue: const PeriodValue(daysOfMonth: [1]),
  startDate: DateTime(2026, 9, 13),
  endDate: endDate,
);

void main() {
  late ScriptedHttp http;
  late RecurringRuleRepository repository;

  /// 每个用例自己决定回什么；`http` 留着断言请求。
  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = RecurringRuleRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  setUp(() => stubWith((options) => envelope(data: [])));

  test('清单不传 type 时查询串是空的，传了才带这一个键', () async {
    stubWith((options) => envelope(data: [_ruleJson()]));
    await repository.list();
    expect(http.call.query, isEmpty);
    expect(http.call.path, '/api/v1/recurring-rules');

    await repository.list(type: 'INCOME');
    expect(http.calls.last.query, {'type': 'INCOME'});
  });

  test('清单解析出周期参数与实时名称，日期解成 DateTime', () async {
    stubWith((options) => envelope(data: [_ruleJson()]));

    final rows = await repository.list();

    final row = rows.single;
    expect(row.id, 7);
    expect(row.periodValue.daysOfMonth, [1, 15]);
    expect(row.periodValue.intervalDays, isNull);
    expect(row.categoryName, '居住');
    expect(row.startDate, DateTime(2026, 9, 1));
    expect(row.updatedAt, DateTime(2026, 9, 10, 20, 15, 30));
    expect(row.endDate, isNull);
  });

  test('详情走单条端点，不拿清单里那一行凑', () async {
    stubWith((options) => envelope(data: _ruleJson(endDate: '2027-08-31')));

    final row = await repository.byId(7);

    expect(http.call.method, 'GET');
    expect(http.call.path, '/api/v1/recurring-rules/7');
    expect(row.endDate, DateTime(2027, 8, 31));
  });

  test('新增的请求体：日期是 yyyy-MM-dd，金额是字符串，没有 type 这个键', () async {
    stubWith((options) => envelope(data: _ruleJson()));

    await repository.create(_draft());

    expect(http.call.method, 'POST');
    expect(http.call.path, '/api/v1/recurring-rules');
    expect(http.call.body, {
      'name': '房租',
      'amount': '3000.00',
      'categoryId': 3,
      'subCategoryId': null,
      'accountId': 1,
      'periodType': 'MONTHLY',
      // 四种周期参数一起发，没用到的那三个是 null。Jackson 解出来与「没带这个键」
      // 完全等价，后端按 periodType 判「哪个字段该有值」时看的也是值而不是键的存在。
      'periodValue': {
        'intervalDays': null,
        'weekdays': null,
        'daysOfMonth': [1],
        'month': null,
      },
      // 带时刻的串后端的 LocalDate 解不开，这是这条测试存在的理由
      'startDate': '2026-09-13',
      'endDate': null,
    });
    // 收支类型由后端从大类推出来，客户端传了也不算，多发一次只会让人以为能传
    expect((http.call.body! as Map).containsKey('type'), isFalse);
  });

  test('截止日期填了才出现在请求体里', () async {
    stubWith((options) => envelope(data: _ruleJson()));

    await repository.create(_draft(endDate: DateTime(2027, 8, 31)));

    expect((http.call.body! as Map)['endDate'], '2027-08-31');
  });

  test('编辑是同一个请求体加一条 PUT，后端没有「只改这一项」的端点', () async {
    stubWith((options) => envelope(data: _ruleJson()));

    await repository.update(7, _draft());

    expect(http.call.method, 'PUT');
    expect(http.call.path, '/api/v1/recurring-rules/7');
    expect((http.call.body! as Map).keys, [
      'name',
      'amount',
      'categoryId',
      'subCategoryId',
      'accountId',
      'periodType',
      'periodValue',
      'startDate',
      'endDate',
    ]);
    final period = (http.call.body! as Map)['periodValue']! as Map;
    expect(period['daysOfMonth'], [1]);
    expect(period['intervalDays'], isNull);
    expect((http.call.body! as Map)['startDate'], '2026-09-13');
  });

  test('启停只发一个 PATCH，没有请求体', () async {
    stubWith((options) => envelope(data: _ruleJson()));

    final row = await repository.toggle(7);

    expect(http.call.method, 'PATCH');
    expect(http.call.path, '/api/v1/recurring-rules/7/toggle');
    expect(http.call.body, isNull);
    expect(row.enabled, isTrue);
  });

  test('删除只认 id，软删与停用在后端是两件事', () async {
    stubWith((options) => envelope(data: null));

    await repository.remove(7);

    expect(http.call.method, 'DELETE');
    expect(http.call.path, '/api/v1/recurring-rules/7');
  });

  test('执行记录解析出补记标记，金额不在这一份数据里', () async {
    stubWith(
      (options) => envelope(
        data: [
          {
            'id': 1,
            'bizDate': '2026-09-01',
            'transactionId': 900,
            'executedDate': '2026-09-01',
            'backfilled': false,
          },
          {
            'id': 2,
            'bizDate': '2026-08-31',
            'transactionId': 880,
            'executedDate': '2026-09-02',
            'backfilled': true,
          },
        ],
      ),
    );

    final rows = await repository.executions(7);

    expect(http.call.path, '/api/v1/recurring-rules/7/executions');
    expect(rows.map((e) => e.backfilled), [false, true]);
    expect(rows.last.bizDate, DateTime(2026, 8, 31));
    expect(rows.last.executedDate, DateTime(2026, 9, 2));
    expect(rows.first.transactionId, 900);
  });
}
