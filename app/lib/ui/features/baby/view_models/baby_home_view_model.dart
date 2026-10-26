import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_statistics.dart';
import '../../../../data/repositories/baby_repository.dart';
import '../../../../data/repositories/baby_statistics_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../../data/services/baby_overview_cache_store.dart';
import '../../auth/view_models/auth_view_model.dart';

part 'baby_home_view_model.freezed.dart';

/// §4.4 总览那一屏。三段数据各走一条端点，合起来才是这一屏，所以它们同进同出。
@freezed
abstract class BabyHomeState with _$BabyHomeState {
  const factory BabyHomeState({
    @Default(<Baby>[]) List<Baby> babies,

    /// 每张宝宝卡上的最新体格与百分位段。`vaccineTodo` 的 `upcoming` / `overdueList`
    /// 是疫苗待办那一卡的两栏——总览页不为它们另起一次请求（§5.4 快照的前提）。
    BabyGrowthStatistics? latestGrowth,
    BabyVaccineStatistics? vaccineTodo,

    /// 数据来自快照而不是这次请求（§5.4）。为 true 时页面挂离线横幅并显示「数据截至 XX」。
    @Default(false) bool fromCache,
    DateTime? savedAt,
  }) = _BabyHomeState;
}

/// 本阶段**唯一的缓存回落**就住在这里：七个仓库一个都不 catch（§3.9），页面也不 catch。
///
/// 三条请求合起来才是那一屏，所以只有整份成功才算成功、整份失败才整份回落快照。
class BabyHomeViewModel extends AsyncNotifier<BabyHomeState> {
  @override
  Future<BabyHomeState> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const BabyHomeState();
    }
    return _load();
  }

  /// 下拉刷新与错误页的「重试」是同一条路径。**不清空状态**：问的还是同一个问题，
  /// 旧答案是当前已知最好的，清空只会让屏闪一下白（口径同猫总览那一页）。
  Future<void> refresh() async {
    try {
      state = AsyncData(await _load());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<BabyHomeState> _load() async {
    try {
      final results = await Future.wait<Object?>([
        _babies.list(),
        _statistics.growth(),
        _statistics.vaccine(),
      ]);
      final babies = results[0] as List<Baby>;
      final growth = results[1] as BabyGrowthStatistics;
      final vaccine = results[2] as BabyVaccineStatistics;
      await _cache.write(
        babies: babies,
        latestGrowth: growth,
        vaccineTodo: vaccine,
      );
      return BabyHomeState(
        babies: babies,
        latestGrowth: growth,
        vaccineTodo: vaccine,
      );
    } on ApiException catch (e) {
      // 401 / 403 / 404 是服务端明确给出的结果，盖一份旧快照上去等于把它藏起来。
      if (!e.isTransportFailure) {
        rethrow;
      }
      final snapshot = await _cache.read();
      if (snapshot == null) {
        rethrow;
      }
      return BabyHomeState(
        babies: snapshot.babies,
        latestGrowth: snapshot.latestGrowth,
        vaccineTodo: snapshot.vaccineTodo,
        fromCache: true,
        savedAt: snapshot.savedAt,
      );
    }
  }

  BabyRepository get _babies => ref.read(babyRepositoryProvider);

  BabyStatisticsRepository get _statistics =>
      ref.read(babyStatisticsRepositoryProvider);

  BabyOverviewCacheStore get _cache =>
      ref.read(babyOverviewCacheStoreProvider);
}

final babyHomeViewModelProvider =
    AsyncNotifierProvider<BabyHomeViewModel, BabyHomeState>(
      BabyHomeViewModel.new,
    );
