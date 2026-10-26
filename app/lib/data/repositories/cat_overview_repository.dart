import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cat.dart';
import '../models/cat_food_bag.dart';
import '../models/cat_food_estimate.dart';
import '../models/cat_statistics.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/cat_overview_cache_store.dart';

/// 总览页一次加载的结果。`fromCache` 为 true 时四个字段都来自快照，`savedAt` 是快照自己的时间戳。
///
/// 在线那一支的 `bag` 与 `estimate` 来自同一个 `/cat-food-bags/current` 对象，两栏同为 null
/// 就是「一袋都还没开过」；离线那一支同形状，页面因此不需要在「这是缓存来的」之外再做任何判断。
class CatOverviewLoadResult {
  const CatOverviewLoadResult(
    this.cats,
    this.bag,
    this.estimate,
    this.dueCountdown, {
    required this.fromCache,
    this.savedAt,
  });

  final List<Cat> cats;
  final CatFoodBag? bag;
  final CatFoodEstimate? estimate;
  final List<CatDueCountdownItem> dueCountdown;
  final bool fromCache;
  final DateTime? savedAt;
}

/// 总览页的一次加载。三个端点合起来才是那一屏，分开加载会出现「卡片有猫、余量还在转」。
///
/// `deworming()` 拿的是**整份驱虫统计**而只用其中 `dueCountdown` 一块：那一块在全 App 只有这一个
/// 来源（第 23 轮 (c)）。为了少传两块数据另开一条倒计时端点，会把「倒计时」变成两个真相，
/// 而服务端已经替整份响应进过一次缓存。
///
/// 缓存回落的口径照 `StatisticsRepository`：只有 `isTransportFailure` 才回落。
/// 401 / 403 / 404 是服务端明确给出的结果，盖一份旧快照上去等于把它藏起来。
class CatOverviewRepository {
  CatOverviewRepository({required this._api, required this._cache});

  final ApiClient _api;
  final CatOverviewCacheStore _cache;

  Future<CatOverviewLoadResult> load() async {
    try {
      // 泛型是 `Object?` 而不是 `Map<String, dynamic>?`：三条里有一条是 `getList`，返回的是 List，
      // 塞不进 Map 那个泛型。`Object?` 仍然给每个 future 都挂上了错误处理，按下标强转即可。
      // 不用「先起三个 future 再分别 await」：第一条抛异常时函数直接返回，剩下两条的错误
      // 会变成测试里无人认领的「未处理的异步错误」（同 `statistics_repository.dart` 那句）。
      final results = await Future.wait<Object?>([
        _api.getList('/cats'),
        _api.get('/cat-food-bags/current'),
        _api.get('/statistics/cat/deworming'),
      ]);
      final cats = (results[0] as List<Map<String, dynamic>>)
          .map(Cat.fromJson)
          .toList();
      // current 的 data 为 null 是「一袋都还没开」，不是契约被破坏，所以这条不过 requireData
      final current = results[1] == null
          ? null
          : CatFoodCurrent.fromJson(results[1]! as Map<String, dynamic>);
      final statistics = CatDewormingStatistics.fromJson(
        requireData(results[2] as Map<String, dynamic>?),
      );
      await _cache.write(
        cats: cats,
        bag: current?.bag,
        estimate: current?.estimate,
        dueCountdown: statistics.dueCountdown,
      );
      return CatOverviewLoadResult(
        cats,
        current?.bag,
        current?.estimate,
        statistics.dueCountdown,
        fromCache: false,
      );
    } on ApiException catch (e) {
      if (!e.isTransportFailure) {
        rethrow;
      }
      final snapshot = await _cache.read();
      if (snapshot == null) {
        rethrow;
      }
      return CatOverviewLoadResult(
        snapshot.cats,
        snapshot.bag,
        snapshot.estimate,
        snapshot.dueCountdown,
        fromCache: true,
        savedAt: snapshot.savedAt,
      );
    }
  }
}

final catOverviewRepositoryProvider = Provider<CatOverviewRepository>(
  (ref) => CatOverviewRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(catOverviewCacheStoreProvider),
  ),
);
