import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/baby_statistics.dart';
import '../../../../data/repositories/baby_statistics_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../auth/view_models/auth_view_model.dart';

part 'baby_statistics_view_model.freezed.dart';

/// §4.4.6 的统计页状态，两段各一半。条件只有一个 `babyId`，而且是路由给的——页面上没有筛选控件。
@freezed
abstract class BabyStatisticsState with _$BabyStatisticsState {
  const factory BabyStatisticsState({
    /// 体格段：每个宝宝的最新一档与三段增量。
    BabyGrowthStatistics? growth,

    /// 疫苗段：完成率、四态计数、待种与逾期两张小列表，外加跨宝宝的里程碑时间轴。
    BabyVaccineStatistics? vaccine,
  }) = _BabyStatisticsState;
}

/// 两条端点一起发：它们同属这一屏的两段，先回来哪段就先显示哪段会出现「上面还是上一轮的宝宝」。
/// 服务端的统计缓存（§5.1）让重取通常不落库，代价比半屏旧数据小。
///
/// 参数化成 `int?` 的 family：`?babyId=` 是路由给的，传了只统计那一个宝宝，缺省是全家庭。
class BabyStatisticsViewModel extends AsyncNotifier<BabyStatisticsState> {
  BabyStatisticsViewModel(this.babyId);

  final int? babyId;

  @override
  Future<BabyStatisticsState> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const BabyStatisticsState();
    }
    return _load();
  }

  /// 离线横幅上的「重试」。统计页不做快照（§5.4），所以这里没有缓存回落可走。
  Future<void> refresh() async {
    try {
      state = AsyncData(await _load());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<BabyStatisticsState> _load() async {
    final results = await Future.wait<Object?>([
      _repository.growth(babyId: babyId),
      _repository.vaccine(babyId: babyId),
    ]);
    return BabyStatisticsState(
      growth: results[0] as BabyGrowthStatistics,
      vaccine: results[1] as BabyVaccineStatistics,
    );
  }

  BabyStatisticsRepository get _repository =>
      ref.read(babyStatisticsRepositoryProvider);
}

final babyStatisticsViewModelProvider =
    AsyncNotifierProvider.family<
      BabyStatisticsViewModel,
      BabyStatisticsState,
      int?
    >(BabyStatisticsViewModel.new);
