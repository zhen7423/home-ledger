import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/baby_curve_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_curve_view_model.dart';

import '../../../../support/fake_http.dart';
import '../../../../support/fake_token_storage.dart';
import '../../../../support/s7_fixtures.dart';

/// 曲线这一页是**叶子**：它不改任何行，后面的记录表单也不读它。要钉的是另外两件事——
/// 缺省指标落在哪一个键上（路由不带 `?metric=` 时不能让请求少一个参数），
/// 以及切指标走的是 family 的新键而不是 `invalidate`（否则那五个 chips 会跟着闪一次加载态）。
void main() {
  late ScriptedHttp http;

  ProviderContainer open({ResponseBody Function(RequestOptions)? script}) {
    http = ScriptedHttp(
      script ?? (_) => envelope(data: curveFixture().toJson()),
    );
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
        babyCurveRepositoryProvider.overrideWithValue(
          BabyCurveRepository(
            api: ApiClient(
              storage: FakeTokenStorage(),
              adapter: http,
              origin: 'http://test.local',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('参数', () {
    test('路由不带 metric 时按 HEIGHT 发，且这个键一定在查询串里', () async {
      final container = open();

      await container.read(
        babyCurveViewModelProvider(curveQueryFor(7, null)).future,
      );

      expect(http.call.path, '/api/v1/baby-growths/curve');
      // 缺省不是「省掉这个参数」：服务端那条端点要求它，少一个键就是 400。
      expect(http.call.query, {'babyId': '7', 'metric': 'HEIGHT'});
    });

    test('显式指标原样透传', () async {
      final container = open();

      await container.read(
        babyCurveViewModelProvider(curveQueryFor(7, 'BMI')).future,
      );

      expect(http.call.query, {'babyId': '7', 'metric': 'BMI'});
    });

    test('实际用的表名读响应里的 standardMetric，不拿入参回显', () async {
      // 体重别身高的表按年龄二选一，请求发的是 WEIGHT_HEIGHT、服务端可能选 WEIGHT_LENGTH。
      final container = open(
        script: (_) => envelope(
          data: curveFixture(
            metric: 'WEIGHT_HEIGHT',
            standardMetric: 'WEIGHT_LENGTH',
          ).toJson(),
        ),
      );

      final curve = await container.read(
        babyCurveViewModelProvider(curveQueryFor(1, 'WEIGHT_HEIGHT')).future,
      );

      expect(curve?.metric, 'WEIGHT_HEIGHT');
      expect(curve?.standardMetric, 'WEIGHT_LENGTH');
    });
  });

  group('切指标只换一个键', () {
    test('两个指标各发一次，回到第一个不再发', () async {
      final container = open();
      final height = curveQueryFor(1, 'HEIGHT');
      final weight = curveQueryFor(1, 'WEIGHT');

      await container.read(babyCurveViewModelProvider(height).future);
      await container.read(babyCurveViewModelProvider(weight).future);
      // 再读一次第一个：它没被 invalidate 过，状态还在，不该再打一次请求。
      await container.read(babyCurveViewModelProvider(height).future);

      expect(http.calls, hasLength(2));
      expect(
        container.read(babyCurveViewModelProvider(height)).requireValue,
        isNotNull,
      );
    });

    test('换个宝宝是新的一份，前一个的线不跟着变', () async {
      final container = open(
        script: (options) => envelope(
          data: curveFixture(
            babyId: int.parse(options.uri.queryParameters['babyId']!),
          ).toJson(),
        ),
      );

      final first = await container.read(
        babyCurveViewModelProvider(curveQueryFor(1, null)).future,
      );
      await container.read(
        babyCurveViewModelProvider(curveQueryFor(2, null)).future,
      );

      expect(first?.babyId, 1);
      expect(
        container
            .read(babyCurveViewModelProvider(curveQueryFor(1, null)))
            .requireValue
            ?.babyId,
        1,
      );
    });
  });

  group('重试与失败', () {
    test('重试成功：再发一次，状态换成新那份', () async {
      final container = open();
      final query = curveQueryFor(1, null);
      await container.read(babyCurveViewModelProvider(query).future);

      await container
          .read(babyCurveViewModelProvider(query).notifier)
          .refresh();

      expect(http.calls, hasLength(2));
      expect(
        container.read(babyCurveViewModelProvider(query)).hasError,
        isFalse,
      );
    });

    test('重试撞上网关：状态转成错误，曲线页没有快照可回落', () async {
      var first = true;
      final container = open(
        script: (_) {
          if (first) {
            first = false;
            return envelope(data: curveFixture().toJson());
          }
          return gateway();
        },
      );
      final query = curveQueryFor(1, null);
      await container.read(babyCurveViewModelProvider(query).future);

      await container
          .read(babyCurveViewModelProvider(query).notifier)
          .refresh();

      expect(
        container.read(babyCurveViewModelProvider(query)).hasError,
        isTrue,
      );
    });

    test('首屏就失败：provider 直接是错误态', () async {
      final container = open(script: (_) => gateway());

      await expectLater(
        container.read(
          babyCurveViewModelProvider(curveQueryFor(1, null)).future,
        ),
        throwsA(anything),
      );
      expect(
        container
            .read(babyCurveViewModelProvider(curveQueryFor(1, null)))
            .hasError,
        isTrue,
      );
    });
  });

  group('词表与登录态', () {
    test('缺省指标在可选清单里，而 WEIGHT_LENGTH 不在', () {
      // WEIGHT_LENGTH 是服务端按年龄选的表，不是用户能选的指标（§1.4 第 23 条）。
      expect(growthMetrics, contains(defaultGrowthMetric));
      expect(growthMetrics, isNot(contains('WEIGHT_LENGTH')));
      expect(growthMetrics, hasLength(5));
    });

    test('未登录不发请求，状态为空', () async {
      http = ScriptedHttp((_) => envelope(data: curveFixture().toJson()));
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_SignedOut.new),
          babyCurveRepositoryProvider.overrideWithValue(
            BabyCurveRepository(
              api: ApiClient(
                storage: FakeTokenStorage(),
                adapter: http,
                origin: 'http://test.local',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final curve = await container.read(
        babyCurveViewModelProvider(curveQueryFor(1, null)).future,
      );

      expect(curve, isNull);
      expect(http.calls, isEmpty);
    });
  });
}

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _SignedOut extends AuthViewModel {
  @override
  AuthState build() => const AuthState();
}
