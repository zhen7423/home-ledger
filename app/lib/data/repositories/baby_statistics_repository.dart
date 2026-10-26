import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/baby_statistics.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// §4.4.6 的宝宝统计两条端点。两条收同一个可选 `babyId`：统计页各带一个宝宝筛选，
/// 缺省为全家庭——「全家庭」不是另一条端点，只是入参为空的同一条。
///
/// 服务端自带 60 秒缓存（§5.1），这一层不再缓存也不做离线回落：总览快照只保总览页那三样，
/// 而统计页离线打开着也没有意义。
class BabyStatisticsRepository {
  BabyStatisticsRepository({required this._api});

  final ApiClient _api;

  /// 每个宝宝的最新一档与百分位段、三段增量一次返回。标准表本身不下发——
  /// 体质指数与百分位档都由服务端按内置表算好，曲线那条端点才带那 546 行原始数据。
  Future<BabyGrowthStatistics> growth({int? babyId}) async =>
      BabyGrowthStatistics.fromJson(
        requireData(
          await _api.get('/statistics/baby/growth', query: {'babyId': babyId}),
        ),
      );

  /// 完成率、四态计数、待种与逾期两张小列表、接种时间轴，外加跨宝宝的里程碑时间轴。
  ///
  /// 待种与逾期两张列表是全 App 疫苗提醒的唯一来源（§4.4.6），所以它不能按任何开关过滤。
  Future<BabyVaccineStatistics> vaccine({int? babyId}) async =>
      BabyVaccineStatistics.fromJson(
        requireData(
          await _api.get('/statistics/baby/vaccine', query: {'babyId': babyId}),
        ),
      );
}

final babyStatisticsRepositoryProvider = Provider<BabyStatisticsRepository>(
  (ref) => BabyStatisticsRepository(api: ref.watch(apiClientProvider)),
);
