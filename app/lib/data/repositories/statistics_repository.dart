import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/finance_statistics.dart';
import '../models/transaction_summary.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/statistics_cache_store.dart';

/// 一次统计加载的结果。`fromCache` 为 true 时，`query` 与 `savedAt` 是**快照里那一份**，
/// 不是调用方传进来的那一份——界面要照它把区间 chips 拨回去，并显示「数据截至 XX」。
class StatisticsLoadResult {
  const StatisticsLoadResult(
    this.summary,
    this.overview, {
    required this.query,
    required this.fromCache,
    this.savedAt,
  });

  final TransactionSummary summary;
  final FinanceStatistics overview;
  final StatisticsQuery query;
  final bool fromCache;
  final DateTime? savedAt;
}

/// §4.2.6 的统计。两个端点合成一次加载：概览卡片与五张图的筛选条件完全相同，
/// 分成两次调用会让页面先出现半张脸。
///
/// 缓存回落的口径照 `CategoryRepository`（S3）：只有 `isTransportFailure` 才回落。
/// 401 / 403 / 404 是服务端明确给出的结果，拿一份旧统计盖上去等于把它藏起来。
class StatisticsRepository {
  StatisticsRepository({required this._api, required this._cache});

  final ApiClient _api;
  final StatisticsCacheStore _cache;

  Future<StatisticsLoadResult> load(StatisticsQuery query) async {
    try {
      // Future.wait 而不是两个已启动的 future 顺序 await：前者会给每个 future 都挂上错误处理，
      // 后者在第一个抛异常时会让第二个的错误变成「未处理的异步错误」，测试里直接炸红。
      final results = await Future.wait<Map<String, dynamic>?>([
        _api.get('/transactions/summary', query: query.toQuery()),
        _api.get('/statistics/finance/overview', query: query.toQuery()),
      ]);
      final summary = TransactionSummary.fromJson(requireData(results[0]));
      final overview = FinanceStatistics.fromJson(requireData(results[1]));
      await _cache.write(query: query, summary: summary, overview: overview);
      return StatisticsLoadResult(
        summary,
        overview,
        query: query,
        fromCache: false,
      );
    } on ApiException catch (e) {
      if (!e.isTransportFailure) {
        rethrow;
      }
      final cached = await _cache.read();
      if (cached == null) {
        rethrow;
      }
      return StatisticsLoadResult(
        cached.summary,
        cached.overview,
        query: cached.query,
        fromCache: true,
        savedAt: cached.savedAt,
      );
    }
  }
}

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => StatisticsRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(statisticsCacheStoreProvider),
  ),
);
