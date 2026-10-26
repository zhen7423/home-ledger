import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/baby_statistics_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_statistics_view_model.dart';

import '../../../../support/fake_http.dart';
import '../../../../support/fake_token_storage.dart';
import '../../../../support/s7_fixtures.dart';

/// 统计页是**自成一体的叶**：它读两条端点，谁也不失效，也没有快照可回落（§5.4）。
/// 要钉的是「两条一起发」「同一个 babyId 发给两条」以及一条失败时不许半屏旧数据。
void main() {
  late ScriptedHttp http;

  /// 见 `baby_growth_view_model_test.dart` 里同名变量的说明。
  late ResponseBody Function(RequestOptions) script;

  ResponseBody online(RequestOptions options) => switch (options.uri.path) {
    '/api/v1/statistics/baby/growth' => envelope(
      data: growthStatisticsFixture().toJson(),
    ),
    '/api/v1/statistics/baby/vaccine' => envelope(
      data: vaccineStatisticsFixture().toJson(),
    ),
    _ => envelope(code: 'NOT_FOUND'),
  };

  ProviderContainer open() {
    script = online;
    http = ScriptedHttp((options) => script(options));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
        babyStatisticsRepositoryProvider.overrideWithValue(
          BabyStatisticsRepository(
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

  group('两条端点一起发', () {
    test('不给 babyId 时两条都发空查询串，就是全家庭那一份', () async {
      final container = open();

      await container.read(babyStatisticsViewModelProvider(null).future);

      expect(http.calls.map((c) => c.path), [
        '/api/v1/statistics/baby/growth',
        '/api/v1/statistics/baby/vaccine',
      ]);
      expect(http.calls.every((c) => c.query.isEmpty), isTrue);
    });

    test('给了 babyId 时两条收的是同一个值，不能只发给其中一条', () async {
      final container = open();

      await container.read(babyStatisticsViewModelProvider(7).future);

      // 半份筛选的统计页比不筛还糟：上面是全家的体格、下面是这个宝宝的疫苗。
      expect(http.calls.map((c) => c.query), [
        {'babyId': '7'},
        {'babyId': '7'},
      ]);
    });

    test('两段合成一份状态，不会出现半屏还是上一轮的', () async {
      final container = open();

      final state = await container.read(
        babyStatisticsViewModelProvider(null).future,
      );

      expect(state.growth?.perBaby, hasLength(1));
      expect(state.vaccine?.milestoneTimeline, hasLength(2));
    });

    test('不同 babyId 是各自一份，互不覆盖', () async {
      final container = open();

      await container.read(babyStatisticsViewModelProvider(7).future);
      await container.read(babyStatisticsViewModelProvider(null).future);

      expect(http.calls, hasLength(4));
      expect(
        container.read(babyStatisticsViewModelProvider(7)).requireValue.growth,
        isNotNull,
      );
    });
  });

  group('失败与重试', () {
    test('一条失败整份失败，不把另一条先到的数据显出来', () async {
      final container = open();
      script = (options) =>
          options.uri.path == '/api/v1/statistics/baby/vaccine'
          ? envelope(code: 'INTERNAL_ERROR', status: 500)
          : online(options);

      await expectLater(
        container.read(babyStatisticsViewModelProvider(null).future),
        throwsA(isA<ApiException>()),
      );
      expect(
        container.read(babyStatisticsViewModelProvider(null)).hasError,
        isTrue,
      );
    });

    test('服务端明确回的 403 原样抛出，不去找什么快照', () async {
      final container = open();
      script = (_) => envelope(code: 'FORBIDDEN', status: 403);

      await expectLater(
        container.read(babyStatisticsViewModelProvider(null).future),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'FORBIDDEN')),
      );
    });

    test('重试成功：两条都重发，状态换成新那份', () async {
      final container = open();
      await container.read(babyStatisticsViewModelProvider(null).future);

      await container
          .read(babyStatisticsViewModelProvider(null).notifier)
          .refresh();

      expect(http.calls, hasLength(4));
      expect(
        container.read(babyStatisticsViewModelProvider(null)).hasError,
        isFalse,
      );
    });

    test('重试失败：状态转成错误，没有快照可回落', () async {
      final container = open();
      await container.read(babyStatisticsViewModelProvider(null).future);
      script = (_) => gateway();

      await container
          .read(babyStatisticsViewModelProvider(null).notifier)
          .refresh();

      expect(
        container.read(babyStatisticsViewModelProvider(null)).hasError,
        isTrue,
      );
    });
  });

  group('没登录', () {
    test('一个请求都不发，状态是两段都空的那一份', () async {
      script = online;
      http = ScriptedHttp((options) => script(options));
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [authViewModelProvider.overrideWith(_SignedOut.new)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        babyStatisticsViewModelProvider(null).future,
      );

      expect(state.growth, isNull);
      expect(state.vaccine, isNull);
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
  AuthState build() => const AuthState(status: SessionStatus.signedOut);
}
