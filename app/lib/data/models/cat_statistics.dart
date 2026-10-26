import 'package:freezed_annotation/freezed_annotation.dart';

import 'cat_food_bag.dart';

part 'cat_statistics.freezed.dart';
part 'cat_statistics.g.dart';

/// 猫粮消耗统计的区间（§4.3.5 第一条端点的入参）。
///
/// 不复用 `finance_statistics.dart` 里的 `StatisticsQuery`：那一份带 `createdBy`，发去猫咪端点
/// 会多一个服务端根本不收的查询参数。两行字段各写各的，比共一个带空字段的查询清楚。
///
/// 两个日期是 `"2026-09-01"` 这样的字符串而不是 `DateTime`：那是线上格式，直接进 `query:`。
/// 响应侧的日期才是 `DateTime`，见下面每一块。
@freezed
abstract class CatFoodStatisticsQuery with _$CatFoodStatisticsQuery {
  const CatFoodStatisticsQuery._();

  const factory CatFoodStatisticsQuery({String? startDate, String? endDate}) =
      _CatFoodStatisticsQuery;

  /// 只带非空的两个键：区间两端都不传就是「服务端自己补齐的整段时间」。
  Map<String, dynamic> toQuery() => {
    'startDate': ?startDate,
    'endDate': ?endDate,
  };

  factory CatFoodStatisticsQuery.fromJson(Map<String, dynamic> json) =>
      _$CatFoodStatisticsQueryFromJson(json);
}

/// 猫粮统计的前四块（概览卡 + 品牌占比 + 逐月趋势 + 每袋用时），对应 CatFoodConsumptionResponse。
///
/// `startDate` / `endDate` 回显的是服务端补齐并截断之后**真正用的**区间，不是客户端传什么回什么：
/// `days` 与 `dailyAverage` 都以这两个值为分母，界面上「日均」与「总克数 ÷ 天数」必须能互相核对得上。
/// `monthlyTrend` 恒为最近 12 个自然月、升序、缺月补 0，**不随区间变化**（同财务侧那张图的规矩）。
@freezed
abstract class CatFoodConsumption with _$CatFoodConsumption {
  const factory CatFoodConsumption({
    required DateTime startDate,
    required DateTime endDate,
    required int days,
    required int totalGrams,
    required int dailyAverage,
    required int finishedBags,
    @Default(<CatBrandSlice>[]) List<CatBrandSlice> brandBreakdown,
    @Default(<CatMonthGrams>[]) List<CatMonthGrams> monthlyTrend,
    @Default(<CatFoodBag>[]) List<CatFoodBag> bagUsages,
  }) = _CatFoodConsumption;

  factory CatFoodConsumption.fromJson(Map<String, dynamic> json) =>
      _$CatFoodConsumptionFromJson(json);
}

/// 品牌占比的一片。按克数而不是按袋数：两袋 500g 与一袋 2000g 在「哪个牌子吃得多」下是
/// 1000g 对 2000g。区间总克数为 0 时整个列表为空，而不是给一片 0% 的扇形。
@freezed
abstract class CatBrandSlice with _$CatBrandSlice {
  const factory CatBrandSlice({
    required String brand,
    required int grams,
    required int percent,
  }) = _CatBrandSlice;

  factory CatBrandSlice.fromJson(Map<String, dynamic> json) =>
      _$CatBrandSliceFromJson(json);
}

/// 逐月消耗的一根柱子，`month` 形如 `2026-09`，与财务侧的月度趋势同形。
@freezed
abstract class CatMonthGrams with _$CatMonthGrams {
  const factory CatMonthGrams({
    required String month,
    required int grams,
  }) = _CatMonthGrams;

  factory CatMonthGrams.fromJson(Map<String, dynamic> json) =>
      _$CatMonthGramsFromJson(json);
}

/// 驱虫统计的后三块（完成度 + 时间轴 + 到期倒计时）一次返回，对应 CatDewormingStatisticsResponse。
///
/// 两个窗口边界是把「近 12 个自然月」到底是哪一天摊开给界面：那句小字说明直接读它，
/// 前端不必再算一次 `minusMonths(11)`，也不必与服务端各持一份窗口定义。
@freezed
abstract class CatDewormingStatistics with _$CatDewormingStatistics {
  const factory CatDewormingStatistics({
    required DateTime windowStart,
    required DateTime windowEnd,
    @Default(<CatDewormingCompletion>[]) List<CatDewormingCompletion> completion,
    @Default(<CatDewormingTimelineItem>[])
    List<CatDewormingTimelineItem> timeline,
    @Default(<CatDueCountdownItem>[]) List<CatDueCountdownItem> dueCountdown,
  }) = _CatDewormingStatistics;

  factory CatDewormingStatistics.fromJson(Map<String, dynamic> json) =>
      _$CatDewormingStatisticsFromJson(json);
}

/// 驱虫完成度的一格，**一只猫两行**（内驱 / 外驱各一行）：`overdueDays` 挂在「下次日期」上，
/// 而一只猫有两个下次日期，合成一行就得给两列，前端反要按 type 挑一列。
///
/// 只算在册的猫。`rate` 上限 100，且 `due == 0` 时是 100 而不是 0——窗口内一次都不该做的猫，
/// 0% 是在指责用户什么都没干。一条记录都没有的猫也出这一格（`due` 有值、`done` 为 0）。
@freezed
abstract class CatDewormingCompletion with _$CatDewormingCompletion {
  const factory CatDewormingCompletion({
    required int catId,
    required String catName,
    required String type,
    required int due,
    required int done,
    required int rate,
    int? overdueDays,
  }) = _CatDewormingCompletion;

  factory CatDewormingCompletion.fromJson(Map<String, dynamic> json) =>
      _$CatDewormingCompletionFromJson(json);
}

/// 驱虫时间轴上的一个节点，近 12 个月内一条记录一个节点，**含已归档的猫**（历史那条照旧算它）。
/// 不带 `dosage`：时间轴上两行字已经满了。
@freezed
abstract class CatDewormingTimelineItem with _$CatDewormingTimelineItem {
  const factory CatDewormingTimelineItem({
    required int catId,
    required String catName,
    required String type,
    required DateTime doneDate,
    String? medicine,
  }) = _CatDewormingTimelineItem;

  factory CatDewormingTimelineItem.fromJson(Map<String, dynamic> json) =>
      _$CatDewormingTimelineItemFromJson(json);
}

/// 到期倒计时的一个条目，**全 App「距下次驱虫 N 天」的唯一来源**（第 23 轮 (c)）：
/// 猫咪总览页、统计页与首页都读它，而不是各自向 `GET /reminders/pending` 要一个数——
/// 那条按用户的提醒开关过滤，关掉外驱提醒会让一个数字凭空消失，而倒计时是事实陈述、不是通知。
///
/// `daysToDue` 与 `overdueDays` 互斥，判逾期的依据是后者非空。一条记录都没有的猫×类型不在这里。
@freezed
abstract class CatDueCountdownItem with _$CatDueCountdownItem {
  const factory CatDueCountdownItem({
    required int catId,
    required String catName,
    required String type,
    required DateTime nextDate,
    int? daysToDue,
    int? overdueDays,
  }) = _CatDueCountdownItem;

  factory CatDueCountdownItem.fromJson(Map<String, dynamic> json) =>
      _$CatDueCountdownItemFromJson(json);
}
