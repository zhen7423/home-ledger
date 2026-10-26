import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby_formula_statistics.dart';
import '../../../../data/repositories/baby_formula_statistics_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../auth/view_models/auth_view_model.dart';

/// §4.5.3 的奶粉消耗统计，宝宝统计页的「奶粉消耗」卡。
class BabyFormulaStatisticsViewModel
    extends AsyncNotifier<BabyFormulaStatistics> {
  @override
  Future<BabyFormulaStatistics> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      throw const ApiException(code: ClientErrorCode.network);
    }
    return ref.watch(babyFormulaStatisticsRepositoryProvider).formula();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final babyFormulaStatisticsViewModelProvider =
    AsyncNotifierProvider<BabyFormulaStatisticsViewModel, BabyFormulaStatistics>(
      BabyFormulaStatisticsViewModel.new,
    );