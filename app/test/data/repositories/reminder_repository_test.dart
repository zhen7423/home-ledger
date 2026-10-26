import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/reminder_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

void main() {
  late ScriptedHttp http;
  late ReminderRepository repository;

  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = ReminderRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  test('开关清单按服务端给的顺序解析，label 与 pushed 都来自后端', () async {
    stubWith(
      (options) => envelope(
        data: [
          {
            'type': 'BUDGET_OVERRUN',
            'label': '预算已超支',
            'enabled': true,
            'pushed': true,
          },
          {
            'type': 'BUDGET_WARNING',
            'label': '预算即将超支',
            'enabled': false,
            'pushed': false,
          },
        ],
      ),
    );

    final rows = await repository.settings();

    expect(http.call.path, '/api/v1/reminders/settings');
    expect(rows.map((r) => r.type), ['BUDGET_OVERRUN', 'BUDGET_WARNING']);
    // pushed 是枚举算出来的，用户在界面上改不了，只能显示给他看
    expect(rows.map((r) => r.pushed), [true, false]);
    expect(rows.last.enabled, isFalse);
  });

  test('保存开关交回整份列表，每项只带 type 与 enabled', () async {
    stubWith((options) => envelope(data: null));

    await repository.saveSettings(const [
      ReminderSettingItem(type: 'BUDGET_OVERRUN', enabled: false),
      ReminderSettingItem(type: 'BUDGET_WARNING', enabled: true),
    ]);

    expect(http.call.method, 'PUT');
    expect(http.call.body, {
      'items': [
        {'type': 'BUDGET_OVERRUN', 'enabled': false},
        {'type': 'BUDGET_WARNING', 'enabled': true},
      ],
    });
  });

  test('待提醒解析出模块与跳转路由，预算两档都没有定时时刻', () async {
    stubWith(
      (options) => envelope(
        data: [
          {
            'type': 'BUDGET_OVERRUN',
            'module': 'FINANCE',
            'key': 'BUDGET_OVERRUN:C:3',
            'title': '餐饮已超支',
            'body': '本月已支出 2100 元，超出预算 100 元',
            'route': '/finance/budgets',
            'fireAt': null,
            'fireDate': null,
          },
        ],
      ),
    );

    final rows = await repository.pending();

    expect(http.call.path, '/api/v1/reminders/pending');
    expect(rows.single.key, 'BUDGET_OVERRUN:C:3');
    expect(rows.single.route, '/finance/budgets');
    // module 决定角标挂到哪个 Tab 上，「哪个类型属于哪个模块」由服务端给（§4.5.2）
    expect(rows.single.module, 'FINANCE');
    // 有 fireAt 是猫与疫苗那两类的定时提醒，那时才走 zonedSchedule
    expect(rows.single.fireAt, isNull);
    expect(rows.single.fireDate, isNull);
  });

  test('空数组是「一切正常」，不是错误', () async {
    stubWith((options) => envelope(data: []));

    expect(await repository.pending(), isEmpty);
  });
}
