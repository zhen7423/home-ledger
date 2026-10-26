import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/cat_statistics.dart';
import '../../../../data/models/finance_statistics.dart';
import '../../../../data/repositories/cat_statistics_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/date_format.dart';
import '../../auth/view_models/auth_view_model.dart';

part 'cat_statistics_view_model.freezed.dart';

// `StatisticsRange` 在 `finance_statistics.dart` 里，区间选择器全模块共用一套，不另立枚举。

/// §4.3.5 的猫咪统计页状态。条件只有区间：**没有「按成员」那一维**，消耗是家庭整体口径（§4.3.4）；
/// 也**没有 `fromCache` / `savedAt`**，这一屏不做离线回落（只缓存总览那三样）。
@freezed
abstract class CatStatisticsState with _$CatStatisticsState {
  const factory CatStatisticsState({
    @Default(StatisticsRange.thisMonth) StatisticsRange range,
    DateTime? customStart,
    DateTime? customEnd,
    CatFoodConsumption? food,
    CatDewormingStatistics? deworming,
  }) = _CatStatisticsState;
}

class CatStatisticsViewModel extends AsyncNotifier<CatStatisticsState> {
  /// 最后一次尝试加载的条件。留在字段上而不是状态里：`AsyncError` 装不下 value。
  CatStatisticsState _target = const CatStatisticsState();

  @override
  Future<CatStatisticsState> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const CatStatisticsState();
    }
    return _load(const CatStatisticsState());
  }

  Future<void> selectRange(StatisticsRange range) =>
      _apply(_target.copyWith(range: range));

  /// 自定义区间的两个日期一次交进来。只挑了一头也是允许的：`catFoodQueryFor` 回 null，
  /// 这一趟不发请求，屏上已有的数据原地不动。
  Future<void> applyCustom(DateTime start, DateTime end) => _apply(
    _target.copyWith(
      range: StatisticsRange.custom,
      customStart: start,
      customEnd: end,
    ),
  );

  Future<void> retry() => _apply(_target);

  CatStatisticsRepository get _repository =>
      ref.read(catStatisticsRepositoryProvider);

  Future<void> _apply(CatStatisticsState target) async {
    _target = target.copyWith(food: null, deworming: null);
    // 条件先落地再发请求：chips 立刻停在用户点过的那一格，而不是等数据回来才跳过去。
    state = AsyncData(_target);
    try {
      state = AsyncData(await _load(_target));
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<CatStatisticsState> _load(CatStatisticsState target) async {
    final query = catFoodQueryFor(target);
    if (query == null) {
      return target;
    }
    // 两条一起发：驱虫那条不收条件、看着不必重取，但把它留在状态里等下一次单独刷新再动，
    // 会出现「饼图换到上月、时间轴还是本月」。服务端的统计缓存（§5.1）让这一次重取通常不落库，
    // 代价比半屏旧数据小。
    final results = await Future.wait<Object?>([
      _repository.foodConsumption(query),
      _repository.deworming(),
    ]);
    return target.copyWith(
      food: results[0] as CatFoodConsumption,
      deworming: results[1] as CatDewormingStatistics,
    );
  }
}

final catStatisticsViewModelProvider =
    AsyncNotifierProvider<CatStatisticsViewModel, CatStatisticsState>(
      CatStatisticsViewModel.new,
    );

/// 区间 chips → 查询条件。回 null 表示「自定义还没挑完」或「起始晚于结束」，两种都不发请求。
///
/// 返回的是 `CatFoodStatisticsQuery` 而不是财务的 `StatisticsQuery`：后者带 `createdBy`，
/// 发出去会多一个服务端不收的查询参数。规则与财务那份 `queryFor` 同一条——本月/本年的结束日取今天，
/// 日均的分母才不被还没过去的日子摊薄；但**不抽公共函数**：两份入参类型不同，抽出去要先造一个
/// 只装两个日期的中间类，而这两处的条件各自会长（财务那侧已经有 `createdBy`）。
CatFoodStatisticsQuery? catFoodQueryFor(
  CatStatisticsState state, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final (DateTime? start, DateTime? end) = switch (state.range) {
    StatisticsRange.thisMonth => (DateTime(today.year, today.month), today),
    StatisticsRange.lastMonth => (
      DateTime(today.year, today.month - 1),
      DateTime(today.year, today.month, 0),
    ),
    StatisticsRange.thisYear => (DateTime(today.year), today),
    StatisticsRange.lastYear => (
      DateTime(today.year - 1),
      DateTime(today.year - 1, 12, 31),
    ),
    StatisticsRange.custom => (state.customStart, state.customEnd),
  };
  if (start == null || end == null) {
    return null;
  }
  final from = _dateOnly(start);
  final to = _dateOnly(end);
  if (from.isAfter(to)) {
    return null;
  }
  return CatFoodStatisticsQuery(
    startDate: formatDate(from),
    endDate: formatDate(to),
  );
}

/// 财务那一份是私有函数、跨文件拿不到，所以这里再来一份。两行，不值得为它开一个公共文件。
DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
