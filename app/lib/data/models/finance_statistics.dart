import 'package:freezed_annotation/freezed_annotation.dart';

import 'month_summary.dart';

part 'finance_statistics.freezed.dart';
part 'finance_statistics.g.dart';

/// 统计页一次拿全，对应后端的 FinanceStatisticsResponse（§8）。
///
/// **不含预算。** 预算执行恒显示当月且不随时间范围变化（§4.2.6），那一块直接复用 S4 的
/// `budgetProgressViewModelProvider`，不在这里重复提供。
///
/// `monthlyTrend` 恒为最近 12 个自然月、升序、缺月补 0，**不随 startDate / endDate 变化**。
/// 界面上那一段因此不跟着区间 chips 重画——用户切了区间发现趋势图纹丝不动是对的，
/// 加一句「最近 12 个月」的副标题就够了。
@freezed
abstract class FinanceStatistics with _$FinanceStatistics {
  const factory FinanceStatistics({
    required DateTime startDate,
    required DateTime endDate,
    required List<CategorySlice> categoryBreakdown,
    required List<MonthSummary> monthlyTrend,
    required List<DailyPoint> dailyTrend,
    required List<AccountSlice> accountBreakdown,
    required List<MemberSlice> memberComparison,
  }) = _FinanceStatistics;

  factory FinanceStatistics.fromJson(Map<String, dynamic> json) =>
      _$FinanceStatisticsFromJson(json);
}

/// 类别占比的一片。同一个类既表示大类也表示它下面的一片小类，靠 `subCategories` 空不空区分。
///
/// `categoryId` 为 null 只有一种含义：Top 8 之外合并出来的「其他」。它不是一片真的类别，
/// `subCategories` 恒为空，**界面上要据此禁掉它的下钻**——点进去只会得到一张空饼图。
///
/// 作为小类出现时 `categoryId` 装的是小类的 id，`percent` 是**相对父大类**的占比而不是相对总支出：
/// 下钻看到的饼图加起来该是 100%。
@freezed
abstract class CategorySlice with _$CategorySlice {
  const factory CategorySlice({
    int? categoryId,
    required String name,
    required String amount,
    required int percent,
    @Default(<CategorySlice>[]) List<CategorySlice> subCategories,
  }) = _CategorySlice;

  factory CategorySlice.fromJson(Map<String, dynamic> json) =>
      _$CategorySliceFromJson(json);
}

/// 区间内某一天的支出。区间内每一天都有一项，没支出的服务端已经补了 0，
/// 前端拿到就能直接画，不必自己算「这个月有几天」。
@freezed
abstract class DailyPoint with _$DailyPoint {
  const factory DailyPoint({required DateTime date, required String expense}) =
      _DailyPoint;

  factory DailyPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyPointFromJson(json);
}

/// 支付方式占比的一条。后端不做 Top N 截断，所以这里不会出现 categoryId 为 null 那种「其他」项。
@freezed
abstract class AccountSlice with _$AccountSlice {
  const factory AccountSlice({
    required int accountId,
    required String name,
    required String amount,
    required int percent,
  }) = _AccountSlice;

  factory AccountSlice.fromJson(Map<String, dynamic> json) =>
      _$AccountSliceFromJson(json);
}

/// 某个成员在某个大类上的支出。`categoryId` 为 null 表示落在「其他」那一档里，口径同 [CategorySlice]。
@freezed
abstract class CategoryAmount with _$CategoryAmount {
  const factory CategoryAmount({int? categoryId, required String amount}) =
      _CategoryAmount;

  factory CategoryAmount.fromJson(Map<String, dynamic> json) =>
      _$CategoryAmountFromJson(json);
}

/// 成员支出对比的一组。
///
/// `byCategory` 与同一份响应里的 `categoryBreakdown` **逐项对齐**：同长度、同顺序、同 categoryId
/// （含末尾那个 categoryId 为 null 的「其他」档）。所以「按大类」视图可以直接按下标取颜色，
/// 不必再做一次 id 匹配——两个列表各排各的话，柱子会与饼图的颜色对不上。这条契约由后端 B9 的一个测试钉住。
///
/// `nickname` 对已退出成员取的是 family_member.nickname_snapshot（§4.2.6）。
@freezed
abstract class MemberSlice with _$MemberSlice {
  const factory MemberSlice({
    required int userId,
    required String nickname,
    required String total,
    required List<CategoryAmount> byCategory,
  }) = _MemberSlice;

  factory MemberSlice.fromJson(Map<String, dynamic> json) =>
      _$MemberSliceFromJson(json);
}

/// 统计与导出共用的查询条件。导出接口的入参与统计完全一致（B7），所以从统计页跳导出页时
/// 把这一份原样带过去，就是 §4.2.7 说的「继承时间范围与记录人」。
///
/// 需要 `fromJson`：统计快照缓存要把「这份数据是在什么条件下算出来的」一起存下来（F4），
/// 离线时界面得把区间 chips 拨回快照真正覆盖的那一段。
@freezed
abstract class StatisticsQuery with _$StatisticsQuery {
  const StatisticsQuery._();

  const factory StatisticsQuery({
    String? startDate,
    String? endDate,
    int? createdBy,
  }) = _StatisticsQuery;

  /// 日期一律是 `"2026-09-01"` 这样的字符串而不是 `DateTime`，理由同 `TransactionPageQuery`。
  /// null 值不用在这里摘，`ApiClient._withoutNulls` 出门前会处理。
  Map<String, dynamic> toQuery() => {
    'startDate': startDate,
    'endDate': endDate,
    'createdBy': createdBy,
  };

  factory StatisticsQuery.fromJson(Map<String, dynamic> json) =>
      _$StatisticsQueryFromJson(json);
}

/// 时间范围选择器的那五格（§4.2.6，全模块统一的一套）。导出页复用同一套控件，多一格「全部」，
/// 那一格不是枚举成员——它对应的是 `StatisticsQuery` 两个日期都为 null，见 F7⑤。
///
/// 放在模型文件而不是 `statistics_view_model.dart`，是因为它的中文标签住在 `ui/core/range_copy.dart`，
/// 而 `ui/core/` 不能反过来 import `ui/features/`（`period_copy.dart` import 的是 `data/models/`，同一个道理）。
enum StatisticsRange { thisMonth, lastMonth, thisYear, lastYear, custom }
