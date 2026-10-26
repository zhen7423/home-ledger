import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/cat.dart';
import '../../../../data/models/cat_food_bag.dart';
import '../../../../data/models/cat_food_estimate.dart';
import '../../../../data/models/cat_statistics.dart';
import '../../../../data/repositories/cat_overview_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../auth/view_models/auth_view_model.dart';

part 'cat_overview_view_model.freezed.dart';

/// §4.3 的总览那一屏。三份数据由 `CatOverviewRepository.load()` 一次交回，这里只负责装进状态。
@freezed
abstract class CatOverviewState with _$CatOverviewState {
  const factory CatOverviewState({
    @Default(<Cat>[]) List<Cat> cats,

    /// 余量卡的两半：那一袋是什么牌子、还能吃多久。同时为 null 就是「一袋都还没开过」。
    CatFoodBag? bag,
    CatFoodEstimate? estimate,
    @Default(<CatDueCountdownItem>[])
    List<CatDueCountdownItem> dueCountdown,

    /// 数据来自快照而不是这次请求（§5.4、验收用例 33）。为 true 时页面挂离线横幅并显示「数据截至 XX」。
    @Default(false) bool fromCache,
    DateTime? savedAt,
  }) = _CatOverviewState;
}

/// 倒计时的排序、逾期置顶与颜色**都由服务端给**（§4.3.5 那一块），页面按原序铺，一行 `sort` 都不写。
class CatOverviewViewModel extends AsyncNotifier<CatOverviewState> {
  @override
  Future<CatOverviewState> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const CatOverviewState();
    }
    return _load();
  }

  /// 下拉刷新与错误页的「重试」是同一条路径。**不清空状态**：统计页换条件时要清空是因为旧数字属于
  /// 另一个区间，留在那里界面是在说谎；这里问的还是同一个问题，旧答案是当前已知最好的，
  /// 清空只会让屏闪一下白。
  Future<void> refresh() async {
    try {
      state = AsyncData(await _load());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<CatOverviewState> _load() async {
    final result = await _repository.load();
    return CatOverviewState(
      cats: result.cats,
      bag: result.bag,
      estimate: result.estimate,
      dueCountdown: result.dueCountdown,
      fromCache: result.fromCache,
      // 在线那一支仓库给的 savedAt 就是 null，这里直接透传，不再判一次 fromCache
      savedAt: result.savedAt,
    );
  }

  CatOverviewRepository get _repository =>
      ref.read(catOverviewRepositoryProvider);
}

final catOverviewViewModelProvider =
    AsyncNotifierProvider<CatOverviewViewModel, CatOverviewState>(
      CatOverviewViewModel.new,
    );
