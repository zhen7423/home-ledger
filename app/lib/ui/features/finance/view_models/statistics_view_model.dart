import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/finance_statistics.dart';
import '../../../../data/models/transaction_summary.dart';
import '../../../../data/repositories/statistics_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/date_format.dart';
import '../../auth/view_models/auth_view_model.dart';

part 'statistics_view_model.freezed.dart';

// `StatisticsRange` 在 `finance_statistics.dart` 里（F3②），import 段已经有了，这里不再声明一遍。

@freezed
abstract class StatisticsState with _$StatisticsState {
  const factory StatisticsState({
    @Default(StatisticsRange.thisMonth) StatisticsRange range,
    DateTime? customStart,
    DateTime? customEnd,
    int? createdBy,
    TransactionSummary? summary,
    FinanceStatistics? overview,

    /// 数据来自统计快照而不是这次请求（§5.4）。为 true 时界面上要挂离线横幅。
    @Default(false) bool fromCache,
    DateTime? savedAt,
  }) = _StatisticsState;
}

/// 统计页。**换条件就是换一份数据，一律重发请求，不在本地重算**——所有聚合都在服务端做（§5.1），
/// 前端手里连原始流水都没有（缓存里最多三个月，而区间可以选到去年）。
///
/// 方法名里没有 `update`：Riverpod 3 的 AsyncNotifier 子类不允许定义叫 `update` 的方法（§3.8）。
class StatisticsViewModel extends AsyncNotifier<StatisticsState> {
  /// 最后一次尝试加载的条件。留在 Notifier 的字段上而不是状态里，就是因为 AsyncError 装不下它。
  StatisticsState _target = const StatisticsState();

  @override
  Future<StatisticsState> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const StatisticsState();
    }
    return _load(const StatisticsState());
  }

  Future<void> selectRange(StatisticsRange range) =>
      _apply(_target.copyWith(range: range));

  /// 自定义区间的两个日期一次交进来。只挑了一头就调用是允许的：`queryFor` 会回 null，
  /// 这一趟不发请求，界面上已经有的数据原地不动。
  Future<void> applyCustom(DateTime start, DateTime end) => _apply(
    _target.copyWith(
      range: StatisticsRange.custom,
      customStart: start,
      customEnd: end,
    ),
  );

  /// `null` 表示「全部成员」。
  Future<void> selectRecorder(int? userId) =>
      _apply(_target.copyWith(createdBy: userId));

  /// 错误页上那个「重试」。用 `_target` 而不是 `state.value`：AsyncError 会把 value 一起丢掉，
  /// 而重试该重发的是用户刚挑的那一组条件，不是本月。
  Future<void> retry() => _apply(_target);

  StatisticsRepository get _repository =>
      ref.read(statisticsRepositoryProvider);

  Future<void> _apply(StatisticsState target) async {
    // summary 与 overview 一并清空：留着旧数字的话，用户点了「上月」而屏上还是本月的金额，
    // 请求在飞的那一两秒里界面是在说谎。清空后页面自己显示加载中（F7④）。
    _target = target.copyWith(summary: null, overview: null);
    // 条件先落地再发请求：界面那排 chips 立刻停在用户点过的那一格，而不是等数据回来才跳过去。
    state = AsyncData(_target);
    try {
      state = AsyncData(await _load(_target));
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<StatisticsState> _load(StatisticsState target) async {
    final query = queryFor(target);
    if (query == null) {
      return target;
    }
    final result = await _repository.load(query);
    return result.fromCache
        ? alignToQuery(
            target.copyWith(
              summary: result.summary,
              overview: result.overview,
              fromCache: true,
              savedAt: result.savedAt,
            ),
            result.query,
          )
        : target.copyWith(
            summary: result.summary,
            overview: result.overview,
            fromCache: false,
            savedAt: null,
          );
  }
}

final statisticsViewModelProvider =
    AsyncNotifierProvider<StatisticsViewModel, StatisticsState>(
      StatisticsViewModel.new,
    );

/// 界面上的区间选择 → 查询条件。回 null 表示「自定义区间还没挑完」或「起始晚于结束」，两种都不发请求。
///
/// **本月与本年的结束日取今天，不取期末。** 日均支出的分母是区间自然日数（§4.2.6），
/// 拿还没过去的日子当分母，9 月 14 日看到的「本月日均」会被摊薄一半；
/// 每日支出图右边也会长出 16 根空柱子。后端在两个日期都不传时同样把结束日解析成今天（B5），两边口径一致。
///
/// `now` 可注入只为测试：不注入的话「本月」这条断言到了下个月就会自己变绿或变红。
StatisticsQuery? queryFor(StatisticsState state, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final (DateTime? start, DateTime? end) = switch (state.range) {
    StatisticsRange.thisMonth => (DateTime(today.year, today.month), today),
    StatisticsRange.lastMonth => (
      DateTime(today.year, today.month - 1),
      // 第 0 天 = 上个月的最后一天，Dart 自己会回卷，不必手写跨年分支。
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
  // 起始晚于结束时后端回 400（B5）。这里直接不发：界面上那两个日期是分别挑的，
  // 中间必然有一瞬间是反的，拿这一瞬间去换一个错误提示没有意义。
  if (from.isAfter(to)) {
    return null;
  }
  return StatisticsQuery(
    startDate: formatDate(from),
    endDate: formatDate(to),
    createdBy: state.createdBy,
  );
}

/// 快照里的条件 → 界面上的区间选择。命中缓存时调用：chips 上写着「本月」而数据是上周算的，
/// 比明确摆出一个自定义区间更容易被当成 bug。记录人也一起对齐，理由相同。
StatisticsState alignToQuery(
  StatisticsState state,
  StatisticsQuery query, {
  DateTime? now,
}) {
  final start = DateTime.tryParse(query.startDate ?? '');
  final end = DateTime.tryParse(query.endDate ?? '');
  for (final candidate in StatisticsRange.values) {
    if (candidate == StatisticsRange.custom) {
      continue;
    }
    final probe = queryFor(
      state.copyWith(range: candidate, createdBy: query.createdBy),
      now: now,
    );
    if (probe != null &&
        probe.startDate == query.startDate &&
        probe.endDate == query.endDate) {
      return state.copyWith(
        range: candidate,
        createdBy: query.createdBy,
        customStart: null,
        customEnd: null,
      );
    }
  }
  return state.copyWith(
    range: StatisticsRange.custom,
    createdBy: query.createdBy,
    customStart: start,
    customEnd: end,
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
