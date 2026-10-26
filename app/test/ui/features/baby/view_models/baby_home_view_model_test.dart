import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_statistics.dart';
import 'package:homeledger/data/repositories/baby_repository.dart';
import 'package:homeledger/data/repositories/baby_statistics_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/baby_overview_cache_store.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_home_view_model.dart';

import '../../../../support/fake_http.dart';
import '../../../../support/fake_token_storage.dart';
import '../../../../support/s7_fixtures.dart';

/// 总览那一屏的数据路径。三条请求合起来才是这一屏，所以「哪一条失败算失败」「快照什么时候
/// 才允许盖上去」这些判断只在这一层做得了——仓库那一层七个都不 catch（§3.9）。
///
/// 两个读仓库都用**真身**（只把网络与快照目录换成替身）：换成假仓库就把被测的那段逻辑
/// 本身替换掉了。它自己谁也不失效，所以这一份里没有「写完之后谁被拽起来」那一组。
void main() {
  /// 三条端点各回一份样例。`includeArchived=false` 那一份只带在册的宝宝。
  ResponseBody online(RequestOptions options) => switch (options.uri.path) {
    '/api/v1/babies' => envelope(data: [babyFixture().toJson()]),
    '/api/v1/statistics/baby/growth' => envelope(
      data: growthStatisticsFixture().toJson(),
    ),
    '/api/v1/statistics/baby/vaccine' => envelope(
      data: vaccineStatisticsFixture().toJson(),
    ),
    _ => envelope(code: 'NOT_FOUND'),
  };

  late ScriptedHttp http;

  /// 换脚本而不是换替身：`ApiClient` 在建容器那一刻就抓住了适配器，中途给 `http`
  /// 重新赋值只换得掉外层变量，容器里那个照样按老脚本答（同
  /// `baby_growth_view_model_test.dart` 里同名变量的说明）。
  late ResponseBody Function(RequestOptions) script;

  ProviderContainer newContainer({_FakeOverviewCache? cache}) {
    final store = cache ?? _FakeOverviewCache();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
        babyRepositoryProvider.overrideWithValue(
          BabyRepository(
            api: ApiClient(
              storage: FakeTokenStorage(),
              adapter: http,
              origin: 'http://test.local',
            ),
          ),
        ),
        babyStatisticsRepositoryProvider.overrideWithValue(
          BabyStatisticsRepository(
            api: ApiClient(
              storage: FakeTokenStorage(),
              adapter: http,
              origin: 'http://test.local',
            ),
          ),
        ),
        babyOverviewCacheStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    script = online;
    http = ScriptedHttp((options) => script(options));
  });

  group('离线那一支', () {
    test('够不着后端且有快照时显示快照，并把 savedAt 交给横幅', () async {
      final cache = _FakeOverviewCache()
        ..snapshot = overviewFixture(
          savedAt: DateTime(2026, 9, 14, 8, 0),
          babies: [babyFixture(name: '上次的宝宝')],
        );
      script = (_) => gateway();
      final container = newContainer(cache: cache);

      final loaded = await container.read(babyHomeViewModelProvider.future);

      expect(loaded.fromCache, isTrue);
      expect(loaded.savedAt, DateTime(2026, 9, 14, 8, 0));
      expect(loaded.babies.single.name, '上次的宝宝');
    });

    test('够不着后端且没有快照时报错，而不是回一份空档案假装成功', () async {
      // 空档案在界面上是「还没有宝宝，去建档」——那是一句真话，而此刻的真实情况是够不着后端。
      script = (_) => gateway();
      final container = newContainer();

      await expectLater(
        container.read(babyHomeViewModelProvider.future),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ClientErrorCode.gateway,
          ),
        ),
      );
    });

    test('服务端明确回的 403 不盖快照上去，哪怕手上有一份', () async {
      // 403 是「你在这一家没有这个人」这类明确结论，盖一份旧档案上去等于把它藏起来。
      final cache = _FakeOverviewCache()..snapshot = overviewFixture();
      script = (_) => envelope(code: 'FORBIDDEN', status: 403);
      final container = newContainer(cache: cache);

      await expectLater(
        container.read(babyHomeViewModelProvider.future),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'FORBIDDEN')),
      );
      expect(cache.reads, 0);
    });
  });

  group('在线那一支', () {
    test('三条请求按档案、体格、疫苗的顺序发出，一次都不能少', () async {
      final container = newContainer();

      await container.read(babyHomeViewModelProvider.future);

      // 快照要能整份存下来，前提就是这一屏的数据全在这三条里（§5.4）。
      expect(http.calls.map((c) => c.path), [
        '/api/v1/babies',
        '/api/v1/statistics/baby/growth',
        '/api/v1/statistics/baby/vaccine',
      ]);
      // 三条都不带 `?babyId=`：总览看的是整个家庭。`/babies` 那一份带 `includeArchived=false`，
      // 那是「只看在册的」而不是「只看某一个宝宝」，两者别混。
      expect(http.calls.every((c) => !c.query.containsKey('babyId')), isTrue);
    });

    test('在线读到新数据后整份覆盖快照', () async {
      final cache = _FakeOverviewCache();
      final container = newContainer(cache: cache);

      final loaded = await container.read(babyHomeViewModelProvider.future);

      expect(loaded.fromCache, isFalse);
      expect(cache.writes, hasLength(1));
      expect(cache.writes.single.babies, [babyFixture()]);
      expect(cache.writes.single.latestGrowth, growthStatisticsFixture());
      expect(cache.writes.single.vaccineTodo, vaccineStatisticsFixture());
    });

    test('一条失败整份失败：只写完档案不落快照', () async {
      // 三条合起来才是那一屏，半份快照存下去就是「离线时总览少两块」。
      final cache = _FakeOverviewCache();
      script = (options) =>
          options.uri.path == '/api/v1/statistics/baby/vaccine'
          ? envelope(code: 'INTERNAL_ERROR', status: 500)
          : online(options);
      final container = newContainer(cache: cache);

      await expectLater(
        container.read(babyHomeViewModelProvider.future),
        throwsA(isA<ApiException>()),
      );
      expect(cache.writes, isEmpty);
    });

    test('refresh 失败时不把旧数据清空，只把状态改成错误', () async {
      final container = newContainer();
      final first = await container.read(babyHomeViewModelProvider.future);
      expect(first.babies, [babyFixture()]);

      script = (_) => gateway();

      await container.read(babyHomeViewModelProvider.notifier).refresh();

      // 旧答案是当前已知最好的，清空只会让屏闪一下白（口径同猫总览那一页）。
      expect(container.read(babyHomeViewModelProvider).hasError, isTrue);
    });

    test('快照写失败不影响这一屏出数', () async {
      // 缓存是优化不是功能：写不下去时这一屏照常显示刚读回来的那份。
      final cache = _FakeOverviewCache()..failWrites = true;
      final container = newContainer(cache: cache);

      final loaded = await container.read(babyHomeViewModelProvider.future);

      expect(loaded.babies, [babyFixture()]);
      expect(loaded.fromCache, isFalse);
    });
  });

  group('没登录', () {
    test('一个请求都不发，状态是空的', () async {
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [authViewModelProvider.overrideWith(_SignedOut.new)],
      );
      addTearDown(container.dispose);

      final loaded = await container.read(babyHomeViewModelProvider.future);

      expect(loaded.babies, isEmpty);
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

/// 快照目录的替身。写下来的每一份都留着，因为这一层要断的是「覆盖了几次、盖进去的是什么」；
/// 读那一侧只有一个槽，正是单槽快照的形状。
class _FakeOverviewCache implements BabyOverviewCacheStore {
  BabyOverview? snapshot;

  final List<BabyOverview> writes = [];

  int reads = 0;

  bool failWrites = false;

  @override
  Future<BabyOverview?> read() async {
    reads++;
    return snapshot;
  }

  @override
  Future<void> write({
    required List<Baby> babies,
    BabyGrowthStatistics? latestGrowth,
    BabyVaccineStatistics? vaccineTodo,
  }) async {
    if (failWrites) {
      // 真那一份把任何异常都吞掉（缓存是优化不是功能），替身照它的契约来。
      return;
    }
    writes.add(
      BabyOverview(
        savedAt: DateTime(2026, 9, 15, 10, 30),
        babies: babies,
        latestGrowth: latestGrowth,
        vaccineTodo: vaccineTodo,
      ),
    );
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}
