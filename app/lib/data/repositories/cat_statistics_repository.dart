import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cat_statistics.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// §4.3.5 的猫咪统计两条端点。
///
/// **两条的入参刻意不对称**：消耗那条收区间，驱虫那条什么都不收——驱虫是按月循环的行为，
/// 给它一个区间选择器，选「本月」时就会看到一根柱子（§4.3.5、第 23 轮 (b)）。
///
/// 服务端自带 60 秒缓存（§5.1），这一层不再缓存也不做离线回落：总览快照只保总览页那三样，
/// 而统计页离线打开着也没有意义。
class CatStatisticsRepository {
  CatStatisticsRepository({required this._api});

  final ApiClient _api;

  Future<CatFoodConsumption> foodConsumption(
    CatFoodStatisticsQuery query,
  ) async =>
      CatFoodConsumption.fromJson(
        requireData(
          await _api.get(
            '/statistics/cat/food-consumption',
            query: query.toQuery(),
          ),
        ),
      );

  /// 无 query 参数。返回里的 `dueCountdown` 是全 App 倒计时的唯一来源（第 23 轮 (c)），
  /// 总览页与首页也读这一条，所以它不能按用户的提醒开关过滤。
  Future<CatDewormingStatistics> deworming() async =>
      CatDewormingStatistics.fromJson(
        requireData(await _api.get('/statistics/cat/deworming')),
      );
}

final catStatisticsRepositoryProvider = Provider<CatStatisticsRepository>(
  (ref) => CatStatisticsRepository(api: ref.watch(apiClientProvider)),
);
