import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/budget_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

void main() {
  late ScriptedHttp http;
  late BudgetRepository repository;

  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = BudgetRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  test('清单解析三个维度的行，未用的那侧 id 与名称都是 null', () async {
    stubWith(
      (options) => envelope(
        data: [
          {'id': 1, 'scope': 'FAMILY', 'amount': '5000.00'},
          {
            'id': 2,
            'scope': 'CATEGORY',
            'categoryId': 3,
            'categoryName': '餐饮',
            'amount': '2000.00',
          },
          {
            'id': 3,
            'scope': 'MEMBER',
            'memberUserId': 10,
            'memberName': '小明',
            'amount': '1500.00',
          },
        ],
      ),
    );

    final rows = await repository.list();

    expect(http.call.method, 'GET');
    expect(http.call.path, '/api/v1/budgets');
    expect(rows.map((b) => b.scope), ['FAMILY', 'CATEGORY', 'MEMBER']);
    expect(rows.first.categoryId, isNull);
    expect(rows[1].categoryName, '餐饮');
    expect(rows.last.memberName, '小明');
    // 金额自始至终是字符串，落成 double 就会在 0.1 + 0.2 上出错
    expect(rows.first.amount, '5000.00');
  });

  test('保存把每行包在 items 里整体交出，未用的维度键仍带着 null', () async {
    stubWith((options) => envelope(data: null));

    await repository.save([
      const BudgetDraftItem(scope: 'FAMILY', amount: '5000.00'),
      const BudgetDraftItem(
        scope: 'CATEGORY',
        categoryId: 3,
        amount: '2000.00',
      ),
    ]);

    expect(http.call.method, 'PUT');
    expect(http.call.path, '/api/v1/budgets');
    expect(http.call.body, {
      'items': [
        {
          'scope': 'FAMILY',
          'categoryId': null,
          'memberUserId': null,
          'amount': '5000.00',
        },
        {
          'scope': 'CATEGORY',
          'categoryId': 3,
          'memberUserId': null,
          'amount': '2000.00',
        },
      ],
    });
  });

  test('清空与保存一份空清单是两份不同的请求体，items 这个键不会被顺手摘掉', () async {
    stubWith((options) => envelope(data: null));

    await repository.save(null);
    final cleared = http.calls.first.body;
    await repository.save([]);
    final emptied = http.calls.last.body;

    // 查询串那边有 `_withoutNulls` 会把 null 键摘掉；请求体没有这一步，也不该有。
    // 哪天有人「统一一下」，这里会变成两条 {"items": []}，用户点没点保存就分不出来了。
    expect(cleared, {'items': null});
    expect(emptied, {'items': []});
  });

  test('进度不传月份就是本月，查询串里不会凭空多出一个月', () async {
    stubWith(
      (options) => envelope(
        data: [
          {
            'month': '2026-09',
            'scope': 'FAMILY',
            'amount': '5000.00',
            'used': '4000.00',
            'remaining': '1000.00',
            'usedPercent': 80,
            'level': 'WARNING',
            'remainingDays': 12,
          },
        ],
      ),
    );

    final rows = await repository.progress();

    expect(http.call.path, '/api/v1/budgets/progress');
    expect(http.call.query, isEmpty);
    expect(rows.single.level, 'WARNING');
    expect(rows.single.remainingDays, 12);
  });

  test('进度按月取，月份原样进查询串', () async {
    stubWith((options) => envelope(data: []));

    await repository.progress(month: '2026-08');

    expect(http.call.query, {'month': '2026-08'});
  });
}
