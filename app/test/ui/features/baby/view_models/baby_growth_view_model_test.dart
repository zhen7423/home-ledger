import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby_growth.dart';
import 'package:homeledger/data/repositories/baby_growth_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_curve_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_growth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_home_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_statistics_view_model.dart';

import '../../../../support/fake_http.dart';
import '../../../../support/fake_token_storage.dart';
import '../../../../support/s7_fixtures.dart';

/// 身高体重那一组。它是「较上一次」的写入方，而那一列是**读时派生**的：改一格或删一条都会
/// 改到这个宝宝后面各条，所以三个下游（曲线点集、统计的最新增量与三段、总览卡上那一行）
/// 一次都不能漏。三条写走同一条 `_fanOut()`，逐条写而不是循环——循环里第一条红掉
/// 看不出另外两条是不是也被同一条 bug 连着。
void main() {
  late _Builds builds;
  late ScriptedHttp http;

  /// 适配器每次转发到这个变量而不是直接抓着函数：有几条用例要在同一只容器里
  /// 把「中间那次请求」换成失败，重造一只容器就断不了「写完之后同一层再读」这件事。
  late ResponseBody Function(RequestOptions) script;

  /// `/baby-growths` 一律回这份清单；写接口回 `data: null`（它们只回一条记录，界面上用不上）。
  ResponseBody online(RequestOptions options) =>
      options.method == 'GET' && options.uri.path == '/api/v1/baby-growths'
      ? envelope(
          data: [growthFixture().toJson(), growthFixture(id: 101).toJson()],
        )
      : envelope(data: null);

  ProviderContainer open() {
    builds = _Builds();
    script = online;
    http = ScriptedHttp((options) => script(options));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
        babyGrowthRepositoryProvider.overrideWithValue(
          BabyGrowthRepository(
            api: ApiClient(
              storage: FakeTokenStorage(),
              adapter: http,
              origin: 'http://test.local',
            ),
          ),
        ),
        babyHomeViewModelProvider.overrideWith(() => _StubHome(builds)),
        babyStatisticsViewModelProvider.overrideWith2(
          (_) => _StubStatistics(builds),
        ),
        babyCurveViewModelProvider.overrideWith2(
          (query) => _StubCurve(builds, query),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> warm(ProviderContainer container) async {
    await container.read(babyGrowthViewModelProvider.future);
    await container.read(babyHomeViewModelProvider.future);
    await container.read(babyStatisticsViewModelProvider(null).future);
    await container.read(
      babyCurveViewModelProvider(curveQueryFor(1, null)).future,
    );
    expect([builds.home, builds.statistics, builds.curve], [1, 1, 1]);
  }

  Future<void> rereadAll(ProviderContainer container) async {
    await container.read(babyHomeViewModelProvider.future);
    await container.read(babyStatisticsViewModelProvider(null).future);
    await container.read(
      babyCurveViewModelProvider(curveQueryFor(1, null)).future,
    );
  }

  BabyGrowthViewModel notifier(ProviderContainer container) =>
      container.read(babyGrowthViewModelProvider.notifier);

  BabyGrowthDraft draft({String? heightCm = '77.0'}) => BabyGrowthDraft(
    babyId: 1,
    measureDate: DateTime(2026, 10, 10),
    heightCm: heightCm,
    weightKg: '10.10',
  );

  group('三处下游一个都不能漏', () {
    test('记一次：曲线、统计、总览三处全重取', () async {
      final container = open();
      await warm(container);

      expect(await notifier(container).create(draft()), isNull);
      await rereadAll(container);

      expect(builds.curve, 2, reason: '多了一个点');
      expect(builds.statistics, 2, reason: '最新一档与三段增量都变了');
      expect(builds.home, 2, reason: '总览卡上那一行最新体格');
    });

    test('改一条：与新增走同一条路，三处照样全重取', () async {
      // 改一格度量值同样会改到后面各条的「较上一次」，两者没有分别。
      final container = open();
      await warm(container);

      expect(await notifier(container).save(100, draft()), isNull);
      await rereadAll(container);

      expect([builds.curve, builds.statistics, builds.home], [2, 2, 2]);
    });

    test('删一条：三处也全重取，「较上一次」是读时派生的', () async {
      final container = open();
      await warm(container);

      expect(await notifier(container).remove(100), isNull);
      await rereadAll(container);

      expect([builds.curve, builds.statistics, builds.home], [2, 2, 2]);
    });

    test('服务端拒了那次写：一个都不重取，错误原样交给调用方', () async {
      final container = open();
      await warm(container);
      script = (_) => envelope(code: 'VALIDATION_ERROR', message: '测量日期不能晚于今天');

      final error = await notifier(container).create(draft());
      await rereadAll(container);

      expect(error, '测量日期不能晚于今天');
      expect([builds.curve, builds.statistics, builds.home], [1, 1, 1]);
    });
  });

  group('写了再重拉', () {
    test('写成功后重拉的是**全量**那份，不要按宝宝重拉', () async {
      final container = open();
      await container.read(babyGrowthViewModelProvider.future);

      await notifier(container).create(draft());

      // 状态是全量的：「只看这个宝宝」由界面自己 where，把过滤写进状态会跨页面残留。
      // 首拉、写入、写完重拉三次都不带 `babyId`。
      expect(http.calls.map((c) => c.query), [
        <String, String>{},
        <String, String>{},
        <String, String>{},
      ]);
      expect(
        container.read(babyGrowthViewModelProvider).requireValue,
        hasLength(2),
      );
    });

    test('给某个宝宝记一条也重拉全量，那两个宝宝的行都在', () async {
      final container = open();
      await container.read(babyGrowthViewModelProvider.future);
      final rows = container.read(babyGrowthViewModelProvider).requireValue;

      // 没有 `GET /baby-growths/{id}`，编辑表单就是靠这份全量按 id 回填的。
      expect(notifier(container).byId(101)?.id, 101);
      expect(notifier(container).byId(999), isNull);
      expect(rows.map((r) => r.id), [100, 101]);
    });

    test('重拉失败：状态改成错误，调用方照样拿到那句文案', () async {
      final container = open();
      await container.read(babyGrowthViewModelProvider.future);
      // 写成功之后那次重拉失败：状态转错误，而调用方照样拿到那句话。
      script = (options) =>
          options.method == 'GET' ? gateway() : envelope(data: null);

      final error = await notifier(container).create(draft());

      expect(error, '服务器暂时不可用，请稍后重试');
      expect(container.read(babyGrowthViewModelProvider).hasError, isTrue);
    });
  });
}

class _Builds {
  int home = 0;
  int statistics = 0;
  int curve = 0;
}

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubHome extends BabyHomeViewModel {
  _StubHome(this.builds);

  final _Builds builds;

  @override
  Future<BabyHomeState> build() async {
    builds.home++;
    return const BabyHomeState();
  }
}

class _StubStatistics extends BabyStatisticsViewModel {
  _StubStatistics(this.builds) : super(null);

  final _Builds builds;

  @override
  Future<BabyStatisticsState> build() async {
    builds.statistics++;
    return const BabyStatisticsState();
  }
}

class _StubCurve extends BabyCurveViewModel {
  _StubCurve(this.builds, BabyCurveQuery query) : super(query);

  final _Builds builds;

  @override
  Future<BabyCurve?> build() async {
    builds.curve++;
    return null;
  }
}
