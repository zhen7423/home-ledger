import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/cat_food_bag_repository.dart';
import 'package:homeledger/data/repositories/cat_setting_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端 `CatFoodBagResponse` 一行的形状。日期是 `yyyy-MM-dd`（服务端是 `LocalDate`），
/// 当前袋的 `usageDays` / `dailyAverage` 两栏回 null。
Map<String, dynamic> _bagJson({
  int id = 10,
  bool current = false,
  int? usageDays = 40,
  int? dailyAverage = 50,
}) => {
  'id': id,
  'brand': '测试牌',
  'packGrams': 2000,
  'startedDate': '2026-08-01',
  'usageDays': usageDays,
  'dailyAverage': dailyAverage,
  'current': current,
  'remark': null,
};

/// `CatFoodEstimateResponse`。九个字段全非空，推不出的信号是整个 `estimate` 为 null。
Map<String, dynamic> _estimateJson() => {
  'usedDays': 11,
  'dailyAverage': 50,
  'consumedGrams': 550,
  'remainingGrams': 1450,
  'remainingPercent': 73,
  'daysLeft': 29,
  'depletionDate': '2026-10-14',
  'fromHistory': true,
  'overEstimate': false,
};

CatFoodBagDraft _draft({String? remark}) => CatFoodBagDraft(
  brand: '测试牌',
  packGrams: 2000,
  startedDate: DateTime(2026, 9, 13),
  remark: remark,
);

void main() {
  late ScriptedHttp http;
  late CatFoodBagRepository repository;
  late CatSettingRepository settings;

  /// 每个用例自己决定回什么；`http` 留着断言请求。末尾那个 group 验的是设置，
  /// 两个仓库共用同一个 `ApiClient`，看的是同一份 `calls`。
  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    final api = ApiClient(
      storage: FakeTokenStorage(),
      adapter: http,
      origin: 'http://test.local',
    );
    repository = CatFoodBagRepository(api: api);
    settings = CatSettingRepository(api: api);
  }

  setUp(() => stubWith((options) => envelope(data: [])));

  test('清单原样接住服务端给的升序，当前袋那两个派生栏读成 null', () async {
    stubWith(
      (options) => envelope(
        data: [
          _bagJson(id: 5),
          _bagJson(id: 7, current: true, usageDays: null, dailyAverage: null),
        ],
      ),
    );

    final rows = await repository.list();

    expect(http.call.method, 'GET');
    expect(http.call.path, '/api/v1/cat-food-bags');
    expect(http.call.query, isEmpty);
    expect(rows.map((b) => b.id), [5, 7]);
    expect(rows.first.startedDate, DateTime(2026, 8, 1));
    expect(rows.last.current, isTrue);
    expect(rows.last.usageDays, isNull);
    expect(rows.last.dailyAverage, isNull);
  });

  test('新增请求体只有四个键，克数是整数、日期是 yyyy-MM-dd', () async {
    stubWith((options) => envelope(data: _bagJson()));

    await repository.create(_draft());

    expect(http.call.method, 'POST');
    expect(http.call.path, '/api/v1/cat-food-bags');
    // 界面上那一栏写 kg，发出去的是整数克：一个 `double` 都没有，也就没有 2000.0 这种写法。
    // 备注没填照样带一个 null 键，因为 PATCH 在这条链路上是整份表单覆盖。
    expect(http.call.body, {
      'brand': '测试牌',
      'packGrams': 2000,
      'startedDate': '2026-09-13',
      'remark': null,
    });
  });

  test('编辑打到带 id 的 PATCH，请求体与新增同一份', () async {
    stubWith((options) => envelope(data: _bagJson(id: 7)));

    await repository.update(7, _draft(remark: '换粮过渡期'));

    expect(http.call.method, 'PATCH');
    expect(http.call.path, '/api/v1/cat-food-bags/7');
    expect(http.call.body, {
      'brand': '测试牌',
      'packGrams': 2000,
      'startedDate': '2026-09-13',
      'remark': '换粮过渡期',
    });
  });

  test('删除只认 id，没有「停用一个猫粮袋」这种端点', () async {
    stubWith((options) => envelope(data: null));

    await repository.remove(7);

    expect(http.call.method, 'DELETE');
    expect(http.call.path, '/api/v1/cat-food-bags/7');
  });

  group('当前袋的三态', () {
    test('一袋都还没开时 data 是 null，这不按异常处理', () async {
      stubWith((options) => envelope(data: null));

      expect(await repository.current(), isNull);
      expect(http.call.method, 'GET');
      expect(http.call.path, '/api/v1/cat-food-bags/current');
      // 这条挡的是有人顺手把这里也过一遍 `requireData`：那会把「还没开袋」报成服务端故障。
    });

    test('开了袋但推不出时 bag 非 null、estimate 为 null', () async {
      stubWith(
        (options) => envelope(
          data: {
            'bag': _bagJson(
              id: 7,
              current: true,
              usageDays: null,
              dailyAverage: null,
            ),
            'estimate': null,
          },
        ),
      );

      final current = await repository.current();

      expect(current!.bag!.id, 7);
      expect(current.bag!.current, isTrue);
      expect(current.estimate, isNull);
    });

    test('两栏都有时推算的九个字段一个不丢', () async {
      stubWith(
        (options) => envelope(
          data: {
            'bag': _bagJson(
              id: 7,
              current: true,
              usageDays: null,
              dailyAverage: null,
            ),
            'estimate': _estimateJson(),
          },
        ),
      );

      final current = await repository.current();

      final estimate = current!.estimate!;
      expect(estimate.usedDays, 11);
      expect(estimate.dailyAverage, 50);
      expect(estimate.consumedGrams, 550);
      expect(estimate.remainingGrams, 1450);
      expect(estimate.remainingPercent, 73);
      expect(estimate.daysLeft, 29);
      expect(estimate.depletionDate, DateTime(2026, 10, 14));
      expect(estimate.fromHistory, isTrue);
      expect(estimate.overEstimate, isFalse);
    });
  });

  group('猫咪设置只有 GET 与 PUT 两个动词', () {
    test('从没存过设置时服务端回的是那三个默认值', () async {
      stubWith(
        (options) => envelope(
          data: {
            'internalMonths': 3,
            'externalMonths': 1,
            'estimatedDailyGrams': null,
            'estimateTakenOverByHistory': false,
          },
        ),
      );

      final setting = await settings.get();

      expect(http.call.method, 'GET');
      expect(http.call.path, '/api/v1/cat-settings');
      expect(setting.internalMonths, 3);
      expect(setting.externalMonths, 1);
      expect(setting.estimatedDailyGrams, isNull);
      expect(setting.estimateTakenOverByHistory, isFalse);
    });

    test('保存是整份 upsert，清空预估那一栏发出去的也是 null 键', () async {
      stubWith(
        (options) => envelope(
          data: {
            'internalMonths': 2,
            'externalMonths': 1,
            'estimatedDailyGrams': null,
            'estimateTakenOverByHistory': true,
          },
        ),
      );

      final saved = await settings.save(
        const CatSettingDraft(internalMonths: 2, externalMonths: 1),
      );

      expect(http.call.method, 'PUT');
      expect(http.call.path, '/api/v1/cat-settings');
      // 「改回按历史袋算」是一个真实的用户意图，被 `if` 摘掉这个键就退成了「保留旧值」。
      expect(http.call.body, {
        'internalMonths': 2,
        'externalMonths': 1,
        'estimatedDailyGrams': null,
      });
      // PUT 的响应里带着现算的那个开关，所以 `save` 不必再重拉一次 GET。
      expect(saved.estimateTakenOverByHistory, isTrue);
    });

    test('预估日均填了数才发得出数', () async {
      stubWith(
        (options) => envelope(
          data: {
            'internalMonths': 3,
            'externalMonths': 1,
            'estimatedDailyGrams': 60,
            'estimateTakenOverByHistory': false,
          },
        ),
      );

      final saved = await settings.save(
        const CatSettingDraft(
          internalMonths: 3,
          externalMonths: 1,
          estimatedDailyGrams: 60,
        ),
      );

      expect((http.call.body! as Map)['estimatedDailyGrams'], 60);
      expect(saved.estimatedDailyGrams, 60);
    });
  });
}
