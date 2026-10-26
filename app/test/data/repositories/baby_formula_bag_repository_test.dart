import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/baby_formula_bag_repository.dart';
import 'package:homeledger/data/services/api_client.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';

/// 后端 `BabyFormulaBagResponse` 一行的形状。日期是 `yyyy-MM-dd`（服务端是 `LocalDate`），
/// 当前罐的 `usageDays` / `dailyAverage` 两栏回 null，`estimatedDailyGrams` 是开罐时手填的预估（可空）。
Map<String, dynamic> _bagJson({
  int id = 10,
  bool current = false,
  int? usageDays = 20,
  int? dailyAverage = 40,
  int? estimatedDailyGrams,
  String? startedTime,
}) => {
  'id': id,
  'brand': '测试牌',
  'packGrams': 800,
  'startedDate': '2026-08-01',
  'startedTime': startedTime,
  'estimatedDailyGrams': estimatedDailyGrams,
  'usageDays': usageDays,
  'dailyAverage': dailyAverage,
  'current': current,
  'remark': null,
};

/// `BabyFormulaEstimateResponse`。九个字段全非空，推不出的信号是整个 `estimate` 为 null。
Map<String, dynamic> _estimateJson() => {
  'usedDays': 6,
  'dailyAverage': 53,
  'consumedGrams': 318,
  'remainingGrams': 482,
  'remainingPercent': 60,
  'daysLeft': 9,
  'depletionDate': '2026-10-14',
  'fromHistory': true,
  'overEstimate': false,
};

BabyFormulaBagDraft _draft({
  int? estimatedDailyGrams,
  String? remark,
  String? startedTime,
}) => BabyFormulaBagDraft(
  brand: '测试牌',
  packGrams: 800,
  startedDate: DateTime(2026, 9, 13),
  startedTime: startedTime,
  estimatedDailyGrams: estimatedDailyGrams,
  remark: remark,
);

void main() {
  late ScriptedHttp http;
  late BabyFormulaBagRepository repository;

  void stubWith(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = BabyFormulaBagRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  setUp(() => stubWith((options) => envelope(data: [])));

  test('清单原样接住服务端给的升序，当前罐那两个派生栏读成 null', () async {
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
    expect(http.call.path, '/api/v1/baby-formula-bags');
    expect(http.call.query, isEmpty);
    expect(rows.map((b) => b.id), [5, 7]);
    expect(rows.first.startedDate, DateTime(2026, 8, 1));
    expect(rows.last.current, isTrue);
    expect(rows.last.usageDays, isNull);
    expect(rows.last.dailyAverage, isNull);
    expect(rows.first.estimatedDailyGrams, isNull);
  });

  test('新增请求体把预估日均带上；没填时发 null 键（整份表单覆盖）', () async {
    stubWith((options) => envelope(data: _bagJson()));

    await repository.create(_draft(estimatedDailyGrams: 100, remark: '二段'));

    expect(http.call.method, 'POST');
    expect(http.call.path, '/api/v1/baby-formula-bags');
    expect(http.call.body, {
      'brand': '测试牌',
      'packGrams': 800,
      'startedDate': '2026-09-13',
      // 开罐时间同一套整份覆盖语义：键永远在，null = 只记日期
      'startedTime': null,
      'estimatedDailyGrams': 100,
      'remark': '二段',
    });
  });

  test('填了开罐时间就按 HH:mm 发出去；回读时原样接住服务端的时刻', () async {
    stubWith((options) {
      if (options.method == 'POST') {
        return envelope(data: _bagJson());
      }
      return envelope(data: [_bagJson(startedTime: '08:30:45')]);
    });

    await repository.create(_draft(startedTime: '08:30'));

    expect((http.call.body! as Map)['startedTime'], '08:30');
    expect((await repository.list()).first.startedTime, '08:30:45');
  });

  test('没填预估日均时同一个键仍发出去，值是 null', () async {
    stubWith((options) => envelope(data: _bagJson()));

    await repository.create(_draft());

    expect((http.call.body! as Map)['estimatedDailyGrams'], isNull);
    expect((http.call.body! as Map).containsKey('estimatedDailyGrams'), isTrue);
  });

  test('编辑打到带 id 的 PATCH，请求体与新增同一份', () async {
    stubWith((options) => envelope(data: _bagJson(id: 7)));

    await repository.update(7, _draft(remark: '满月换段'));

    expect(http.call.method, 'PATCH');
    expect(http.call.path, '/api/v1/baby-formula-bags/7');
    expect((http.call.body! as Map)['remark'], '满月换段');
  });

  test('删除只认 id', () async {
    stubWith((options) => envelope(data: null));

    await repository.remove(7);

    expect(http.call.method, 'DELETE');
    expect(http.call.path, '/api/v1/baby-formula-bags/7');
  });

  group('当前罐的三态', () {
    test('一罐都还没开时 data 是 null，这不按异常处理', () async {
      stubWith((options) => envelope(data: null));

      expect(await repository.current(), isNull);
      expect(http.call.path, '/api/v1/baby-formula-bags/current');
    });

    test('开了罐但推不出时 bag 非 null、estimate 为 null', () async {
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

      final estimate = (await repository.current())!.estimate!;

      expect(estimate.usedDays, 6);
      expect(estimate.dailyAverage, 53);
      expect(estimate.consumedGrams, 318);
      expect(estimate.remainingGrams, 482);
      expect(estimate.remainingPercent, 60);
      expect(estimate.daysLeft, 9);
      expect(estimate.depletionDate, DateTime(2026, 10, 14));
      expect(estimate.fromHistory, isTrue);
      expect(estimate.overEstimate, isFalse);
    });
  });
}