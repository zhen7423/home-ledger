import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/baby_formula_statistics.dart';
import '../services/api_client.dart';

/// §4.5.3 的奶粉消耗统计。
class BabyFormulaStatisticsRepository {
  BabyFormulaStatisticsRepository({required this._api});

  final ApiClient _api;

  Future<BabyFormulaStatistics> formula() async {
    final data = await _api.get('/statistics/baby/formula');
    if (data == null) {
      throw StateError('统计端点返回了空 data');
    }
    return BabyFormulaStatistics.fromJson(data);
  }
}

final babyFormulaStatisticsRepositoryProvider =
    Provider<BabyFormulaStatisticsRepository>(
  (ref) => BabyFormulaStatisticsRepository(api: ref.watch(apiClientProvider)),
);