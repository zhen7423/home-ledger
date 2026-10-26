import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/cat.dart';
import 'package:homeledger/data/models/cat_food_bag.dart';
import 'package:homeledger/data/models/cat_food_estimate.dart';
import 'package:homeledger/data/models/cat_statistics.dart';
import 'package:homeledger/data/repositories/cat_overview_repository.dart';
import 'package:homeledger/data/repositories/cat_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/cat_overview_cache_store.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/cat/view_models/cat_overview_view_model.dart';
import 'package:homeledger/ui/features/cat/view_models/cat_view_model.dart';

import '../../../support/fake_cat_overview_repository.dart';
import '../../../support/fake_http.dart';
import '../../../support/fake_token_storage.dart';
import '../../../support/s6_fixtures.dart';

/// 总览那一屏的数据路径。离线回落与写快照住在仓库里、视图模型只把 `fromCache` 与
/// `savedAt` 透传给横幅，所以这几条用例走的是**真仓库**（只把网络与快照目录换成替身）：
/// 换成假仓库就等于把被测的那段逻辑本身替换掉了。
void main() {
  late _FakeOverviewCache cache;

  CatDewormingStatistics dewormingStatistics({int countdownRows = 2}) =>
      CatDewormingStatistics(
        windowStart: DateTime(2026, 9, 1),
        windowEnd: DateTime(2026, 9, 15),
        dueCountdown: [
          countdownFixture(catId: 1, catName: '咪咪', daysToDue: 3),
          if (countdownRows > 1)
            countdownFixture(
              catId: 2,
              catName: '大橘',
              type: 'INTERNAL',
              overdueDays: 1,
            ),
        ],
      );

  /// 三条 GET 各自回一份样例。`/cat-food-bags/current` 回 `data: null` 是「一袋都还没开」。
  /// 按 `options.uri.path` 分派：适配器这一层的 `options.path` 已被 baseUrl 前缀剥掉，
  /// 剩下 `/cats`，和 `calls` 里记的完整路径不是一回事。
  ResponseBody online(RequestOptions options) => switch (options.uri.path) {
    '/api/v1/cats' => envelope(data: [catFixture().toJson()]),
    '/api/v1/cat-food-bags/current' => envelope(data: null),
    '/api/v1/statistics/cat/deworming' => envelope(
      data: dewormingStatistics().toJson(),
    ),
    _ => envelope(code: 'NOT_FOUND'),
  };

  ProviderContainer newContainer({
    CatOverviewRepository? repository,
    CatRepository? cats,
  }) {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
        if (repository != null)
          catOverviewRepositoryProvider.overrideWithValue(repository),
        if (cats != null) catRepositoryProvider.overrideWithValue(cats),
      ],
    );
    // 只 read 一次的 provider 可能算完就被回收，先挂个监听把它留住。
    container.listen(catOverviewViewModelProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }

  CatOverviewRepository realRepository(
    ResponseBody Function(RequestOptions options) script,
  ) => CatOverviewRepository(
    api: ApiClient(
      storage: FakeTokenStorage(),
      adapter: ScriptedHttp(script),
      origin: 'http://test.local',
    ),
    cache: cache,
  );

  setUp(() {
    cache = _FakeOverviewCache();
  });

  group('离线那一支', () {
    test('断网且有快照时显示快照，并把 savedAt 交给横幅', () async {
      cache.snapshot = (
        savedAt: DateTime(2026, 9, 14, 8, 0),
        cats: [catFixture(name: '上次的猫')],
        bag: bagFixture(),
        estimate: null,
        dueCountdown: const [],
      );
      final container = newContainer(repository: realRepository((_) => gateway()));

      final loaded = await container.read(catOverviewViewModelProvider.future);

      expect(loaded.fromCache, isTrue);
      expect(loaded.savedAt, DateTime(2026, 9, 14, 8, 0));
      expect(loaded.cats.single.name, '上次的猫');
    });

    test('断网且没有快照时报错，而不是回一份空列表假装成功', () async {
      // 空列表在界面上是「还没有猫，去建档」——那是一句真话，而此刻的真实情况是够不着后端。
      final container = newContainer(repository: realRepository((_) => gateway()));

      await expectLater(
        container.read(catOverviewViewModelProvider.future),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ClientErrorCode.gateway,
          ),
        ),
      );
    });

    test('联网读到新数据后整份覆盖快照', () async {
      final container = newContainer(repository: realRepository(online));

      final loaded = await container.read(catOverviewViewModelProvider.future);

      expect(loaded.fromCache, isFalse);
      expect(cache.writes, hasLength(1));
      expect(cache.writes.single.cats, [catFixture()]);
      // 一袋都没开时这两栏写下去的就是 null，读回来仍然是「没有袋」而不是坏数据
      expect(cache.writes.single.bag, isNull);
      expect(cache.writes.single.estimate, isNull);
    });

    test('倒计时的来源只有那一条统计端点，不碰待提醒', () async {
      final http = ScriptedHttp(online);
      final container = newContainer(
        repository: CatOverviewRepository(
          api: ApiClient(
            storage: FakeTokenStorage(),
            adapter: http,
            origin: 'http://test.local',
          ),
          cache: cache,
        ),
      );

      final loaded = await container.read(catOverviewViewModelProvider.future);

      // 第 23 轮 (c)：倒计时是事实陈述而不是通知，把两个 CAT_* 开关关掉它照样在。
      // 这一条断的是「这一屏压根没去读 pending」，多一条请求就当场露出来。
      expect(loaded.dueCountdown, hasLength(2));
      expect(http.calls.map((c) => c.path), [
        '/api/v1/cats',
        '/api/v1/cat-food-bags/current',
        '/api/v1/statistics/cat/deworming',
      ]);
    });
  });

  group('写操作之后', () {
    test('建档、改名、归档、删除四个都让总览重取一次', () async {
      final overview = FakeCatOverviewRepository(
        result: CatOverviewLoadResult(
          [catFixture()],
          null,
          null,
          [countdownFixture()],
          fromCache: false,
        ),
      );
      final container = newContainer(
        repository: overview,
        cats: _FakeCatRepository(),
      );
      await container.read(catOverviewViewModelProvider.future);
      final notifier = container.read(catViewModelProvider.notifier);
      const draft = CatDraft(
        name: '咪咪',
        gender: 'FEMALE',
        birthdayEstimated: false,
        neutered: 'NO',
      );

      // 改名会动到总览的卡片行、统计页的时间轴与倒计时，三处都在服务端算完，
      // 客户端只能整份重取，所以这四条走的是同一个 `_fanOut()`。
      // 逐条写不用循环：循环里第一条红掉看不出另外三条是不是也被同一条 bug 连着。
      var expected = 1;
      Future<void> refetched(Future<String?> Function() write) async {
        expect(await write(), isNull);
        await container.read(catOverviewViewModelProvider.future);
        expect(overview.loadCalls, ++expected);
      }

      await refetched(() => notifier.create(draft));
      await refetched(() => notifier.save(1, draft));
      await refetched(() => notifier.toggleArchive(1));
      await refetched(() => notifier.remove(1));
    });
  });
}

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

/// 快照目录的替身。写下来的每一份都留着，因为这一层要断的是「覆盖了几次、盖进去的是什么」；
/// 读那一侧只有一个槽，正是单槽快照的形状。
class _FakeOverviewCache implements CatOverviewCacheStore {
  _Snapshot? snapshot;

  final List<_Snapshot> writes = [];

  @override
  Future<_Snapshot?> read() async => snapshot;

  @override
  Future<void> write({
    required List<Cat> cats,
    required CatFoodBag? bag,
    required CatFoodEstimate? estimate,
    required List<CatDueCountdownItem> dueCountdown,
  }) async {
    writes.add((
      savedAt: DateTime(2026, 9, 15, 10, 30),
      cats: cats,
      bag: bag,
      estimate: estimate,
      dueCountdown: dueCountdown,
    ));
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}

typedef _Snapshot = ({
  DateTime savedAt,
  List<Cat> cats,
  CatFoodBag? bag,
  CatFoodEstimate? estimate,
  List<CatDueCountdownItem> dueCountdown,
});

/// 档案写操作只用来验「写完有没有把总览拽起来」，本身的行为在页面用例那一层。
class _FakeCatRepository implements CatRepository {
  @override
  Future<List<Cat>> list({bool includeArchived = false}) async => const [];

  @override
  Future<void> create(CatDraft draft) async {}

  @override
  Future<void> update(int id, CatDraft draft) async {}

  @override
  Future<void> toggle(int id) async {}

  @override
  Future<void> remove(int id) async {}

  @override
  Future<void> uploadPhoto(int id, Uint8List bytes, String filename) async {}

  @override
  Future<void> clearPhoto(int id) async {}
}
